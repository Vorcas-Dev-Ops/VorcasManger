import express from 'express';
import jwt from 'jsonwebtoken';
import pool from '../config/db.js';
import dotenv from 'dotenv';
import bcrypt from 'bcryptjs';
import { OAuth2Client } from 'google-auth-library';
import { verifyToken } from '../middleware/auth.js';

dotenv.config();

const router = express.Router();
const SECRET_KEY = process.env.JWT_SECRET || 'your_secret_key';
const BCRYPT_ROUNDS = 10;
const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

// ──────────────────────────────────────────────────────────────────────────────
// Startup Migration: Ensure must_change_password column exists + re-hash plain passwords
// ──────────────────────────────────────────────────────────────────────────────
(async () => {
  try {
    await pool.query(`
      ALTER TABLE users
      ADD COLUMN IF NOT EXISTS must_change_password BOOLEAN NOT NULL DEFAULT true,
      ADD COLUMN IF NOT EXISTS fcm_token TEXT,
      ADD COLUMN IF NOT EXISTS password_changed_at TIMESTAMPTZ
    `);

    // 2. Add profile_picture_url to employees if it doesn't exist
    await pool.query(`
      ALTER TABLE employees
      ADD COLUMN IF NOT EXISTS profile_picture_url TEXT
    `);

    // 3. Re-hash any plain-text passwords (those not starting with "$2")
    const users = await pool.query(
      `SELECT id, password_hash FROM users WHERE password_hash NOT LIKE '$2%'`
    );
    for (const user of users.rows) {
      const hashed = await bcrypt.hash(user.password_hash, BCRYPT_ROUNDS);
      await pool.query('UPDATE users SET password_hash = $1 WHERE id = $2', [hashed, user.id]);
    }
    if (users.rows.length > 0) {
      console.log(`Auth migration: Re-hashed ${users.rows.length} plain-text password(s).`);
    }

    // 4. Seed password_changed_at for existing accounts that don't have it
    await pool.query(`UPDATE users SET password_changed_at = NOW() WHERE password_changed_at IS NULL`);

    console.log('Auth migration complete.');
  } catch (err) {
    console.error('Auth migration error:', err.message);
  }
})();

// Login Handler
router.post('/login', async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ error: 'Email and password required' });
  }

  console.log(`Login attempt for: ${email}`);

  try {
    const userResult = await pool.query(
      'SELECT id, password_hash, role_id, must_change_password, password_changed_at FROM users WHERE email = $1 AND is_active = true',
      [email]
    );

    if (userResult.rows.length === 0) {
      console.log('Login failed: User not found or inactive');
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const user = userResult.rows[0];
    const passwordHash = user.password_hash;

    // Match using bcrypt
    const isMatch = await bcrypt.compare(password, passwordHash);
    if (!isMatch) {
      console.log('Login failed: Password mismatch');
      return res.status(401).json({ error: 'Invalid credentials' });
    }
    console.log('Password verified successfully.');

    // Check 90-day password expiry
    const PASSWORD_EXPIRY_DAYS = 90;
    let mustChangePassword = user.must_change_password;
    if (!mustChangePassword && user.password_changed_at) {
      const daysSinceChange = Math.floor(
        (Date.now() - new Date(user.password_changed_at).getTime()) / (1000 * 60 * 60 * 24)
      );
      if (daysSinceChange >= PASSWORD_EXPIRY_DAYS) {
        console.log(`Password expired for user ${user.id} (${daysSinceChange} days old). Forcing reset.`);
        mustChangePassword = true;
        await pool.query('UPDATE users SET must_change_password = true WHERE id = $1', [user.id]);
      }
    }

    const userId = user.id;
    const roleId = user.role_id;

    // Fetch employee data and role info
    const empResult = await pool.query(
      `SELECT e.id, r.role_name, r.hierarchy_level, e.first_name, e.last_name, 
              e.phone, e.profile_picture_url, e.hire_date, d.department_name
       FROM employees e 
       JOIN roles r ON e.role_id = r.id 
       LEFT JOIN departments d ON e.department_id = d.id
       WHERE e.user_id = \$1`,
      [userId]
    );

    if (empResult.rows.length === 0) {
      return res.status(401).json({ error: 'Employee profile not found' });
    }

    const employee = empResult.rows[0];
    const employeeId = employee.id;
    const roleName = employee.role_name;
    const hierarchyLevel = employee.hierarchy_level;
    const firstName = employee.first_name;
    const lastName = employee.last_name;

    const payload = {
      userId,
      employeeId,
      roleId,
      roleName,
      hierarchyLevel,
      mustChangePassword,
    };

    const token = jwt.sign(payload, SECRET_KEY, { expiresIn: '24h' });

    res.json({
      token,
      user: {
        id: userId,
        email,
        roleId,
        roleName: employee.role_name,
        employeeId: employee.id,
        firstName: employee.first_name,
        lastName: employee.last_name,
        hierarchyLevel: employee.hierarchy_level,
        mustChangePassword,
        phone: employee.phone,
        profilePictureUrl: employee.profile_picture_url,
        joinedDate: employee.hire_date,
        departmentName: employee.department_name,
      }
    });

  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Register Handler (Administrative - requires SUPER_ADMIN or ADMIN token)
router.post('/register', async (req, res) => {
  // Inline auth check (this route is public-mounted, so we verify manually)
  const authHeader = req.headers['authorization'];
  if (!authHeader) return res.status(401).json({ error: 'No token provided' });
  const token = authHeader.split(' ')[1];
  let caller;
  try {
    caller = jwt.verify(token, SECRET_KEY);
  } catch {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
  const callerRole = (caller.roleName || '').toUpperCase();
  if (!['SUPER_ADMIN', 'ADMIN', 'HR'].includes(callerRole)) {
    return res.status(403).json({ error: 'Forbidden: Only administrative roles (HR, Admin) can create users' });
  }

  const { 
    email, password, role_id, 
    employee_id, first_name, last_name, phone, 
    department_id, supervisor_id, status 
  } = req.body;

  if (!email || !password || !role_id || !first_name || !last_name) {
    return res.status(400).json({ error: 'Missing required fields' });
  }

  // Enforce hierarchy: Non-Super-Admins cannot create users with equal or higher rank
  // Super Admin = hierarchy_level 1
  const callerLevel = caller.hierarchyLevel ?? 99;
  if (callerLevel !== 1) {
    try {
      const targetRoleRes = await pool.query('SELECT hierarchy_level FROM roles WHERE id = \$1', [role_id]);
      if (targetRoleRes.rows.length === 0) return res.status(400).json({ error: 'Invalid role_id' });
      const targetLevel = targetRoleRes.rows[0].hierarchy_level;
      
      if (targetLevel <= callerLevel) {
        return res.status(403).json({ error: 'Forbidden: Cannot create a user with rank equal to or higher than your own' });
      }
    } catch (err) {
      console.error('Role check error:', err);
      return res.status(500).json({ error: 'Role validation failed' });
    }
  }


  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // ── Generate Employee ID Automatically if not provided ──
    let finalEmpId = employee_id;
    if (!finalEmpId) {
      // Find the highest EMP numeric part
      const lastEmpRes = await client.query(
        "SELECT employee_id FROM employees WHERE employee_id ~ '^EMP[0-9]+$' ORDER BY id DESC LIMIT 1"
      );
      let nextNum = 1;
      if (lastEmpRes.rows.length > 0) {
        const lastId = lastEmpRes.rows[0].employee_id;
        const lastNum = parseInt(lastId.replace('EMP', ''));
        nextNum = lastNum + 1;
      }
      finalEmpId = `EMP${nextNum.toString().padStart(3, '0')}`;
    }

    // Check if user exists
    const checkUser = await client.query('SELECT id FROM users WHERE email = \$1', [email]);
    if (checkUser.rows.length > 0) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'User with this email already exists' });
    }

    // 1. Insert into users table
    const hashedPassword = await bcrypt.hash(password, BCRYPT_ROUNDS);
    const userInsert = await client.query(
      `INSERT INTO users (email, password_hash, role_id, is_active) 
       VALUES ($1, $2, $3, true) RETURNING id`,
      [email, hashedPassword, role_id]
    );

    const userId = userInsert.rows[0].id;

    // 2. Insert into employees table
    const empInsert = await client.query(
      `INSERT INTO employees 
       (user_id, employee_id, first_name, last_name, phone, department_id, role_id, supervisor_id, hire_date, status) 
       VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9, \$10) RETURNING id`,
      [
        userId,
        finalEmpId,
        first_name,
        last_name,
        phone,
        department_id,
        role_id,
        supervisor_id,
        new Date().toISOString().split('T')[0], // Use current date for hire_date
        status || 'ACTIVE'
      ]
    );

    await client.query('COMMIT');
    res.status(201).json({ 
      message: 'User and employee profile created successfully',
      userId,
      employeeId: empInsert.rows[0].id
    });

  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Registration error:', err);
    res.status(500).json({ error: 'Internal server error' });
  } finally {
    client.release();
  }
});

// Roles Handler
router.get('/roles', async (req, res) => {
  // Optional auth: if token provided, filter by hierarchy
  const authHeader = req.headers['authorization'];
  let callerLevel = 99;
  if (authHeader) {
    try {
      const token = authHeader.split(' ')[1];
      const decoded = jwt.verify(token, SECRET_KEY);
      callerLevel = decoded.hierarchyLevel ?? 99;
    } catch (e) {
      // Ignore token if invalid for /roles
    }
  }

  try {
    let query = 'SELECT id, role_name as "roleName", hierarchy_level as "hierarchyLevel" FROM roles';
    let params = [];
    
    // Hide SUPER_ADMIN (level 1) from everyone except those with level 1
    if (callerLevel !== 1) {
      query += ' WHERE hierarchy_level > 1';
    }
    
    query += ' ORDER BY hierarchy_level ASC';
    
    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch (err) {
    console.error('Get roles error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Change Password Handler
router.post('/change-password', async (req, res) => {
  const authHeader = req.headers['authorization'];
  if (!authHeader) return res.status(401).json({ error: 'No token provided' });
  const token = authHeader.split(' ')[1];
  
  let caller;
  try {
    caller = jwt.verify(token, SECRET_KEY);
  } catch {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }

  const { oldPassword, newPassword } = req.body;
  if (!oldPassword || !newPassword) {
    return res.status(400).json({ error: 'Old and new passwords are required' });
  }

  try {
    const userResult = await pool.query('SELECT password_hash FROM users WHERE id = $1', [caller.userId]);
    if (userResult.rows.length === 0) return res.status(404).json({ error: 'User not found' });
    
    const user = userResult.rows[0];
    const isMatch = await bcrypt.compare(oldPassword, user.password_hash);
    if (!isMatch) {
      return res.status(401).json({ error: 'Incorrect old password' });
    }

    const hashedNew = await bcrypt.hash(newPassword, BCRYPT_ROUNDS);
    await pool.query(
      'UPDATE users SET password_hash = $1, must_change_password = false, password_changed_at = NOW() WHERE id = $2',
      [hashedNew, caller.userId]
    );

    res.json({ message: 'Password updated successfully' });
  } catch (err) {
    console.error('Change password error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Force Password Reset for All Users (Admin/Super Admin only)
router.post('/force-reset-all', async (req, res) => {
  const authHeader = req.headers['authorization'];
  if (!authHeader) return res.status(401).json({ error: 'No token provided' });
  const token = authHeader.split(' ')[1];
  let caller;
  try {
    caller = jwt.verify(token, SECRET_KEY);
  } catch {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }

  const callerRole = (caller.roleName || '').toUpperCase();
  if (!['SUPER_ADMIN', 'ADMIN'].includes(callerRole)) {
    return res.status(403).json({ error: 'Access denied. Admins only.' });
  }

  try {
    // Force all non-admin users to reset their passwords on next login
    const result = await pool.query(
      `UPDATE users u
       SET must_change_password = true
       FROM employees e
       JOIN roles r ON e.role_id = r.id
       WHERE u.id = e.user_id
         AND r.role_name NOT IN ('SUPER_ADMIN', 'ADMIN')
         AND u.is_active = true
       RETURNING u.id`
    );
    console.log(`Force reset triggered by ${caller.roleName} (userId ${caller.userId}): ${result.rowCount} users affected.`);
    res.json({ message: `Password reset forced for ${result.rowCount} user(s). They must change their password on next login.`, count: result.rowCount });
  } catch (err) {
    console.error('Force reset error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Google Login Handler
router.post('/google-login', async (req, res) => {
  const { idToken } = req.body;
  if (!idToken) {
    return res.status(400).json({ error: 'Missing Google ID token' });
  }

  try {
    const ticket = await client.verifyIdToken({
      idToken,
      audience: process.env.GOOGLE_CLIENT_ID,
    });
    const payload = ticket.getPayload();
    const email = payload.email;

    if (!email) {
      return res.status(401).json({ error: 'Invalid Google account email' });
    }

    // Lookup user by email just like regular login
    const userResult = await pool.query(
      'SELECT id, role_id, must_change_password FROM users WHERE email = $1 AND is_active = true',
      [email]
    );

    if (userResult.rows.length === 0) {
      return res.status(401).json({ error: 'No employee account found for this Google account' });
    }

    const user = userResult.rows[0];
    const userId = user.id;
    const roleId = user.role_id;

    // Fetch employee data and role info
    const empResult = await pool.query(
      `SELECT e.id, r.role_name, r.hierarchy_level, e.first_name, e.last_name 
       FROM employees e 
       JOIN roles r ON e.role_id = r.id 
       WHERE e.user_id = $1`,
      [userId]
    );

    if (empResult.rows.length === 0) {
      return res.status(401).json({ error: 'Employee profile not found' });
    }

    const employee = empResult.rows[0];
    const employeeId = employee.id;
    const roleName = employee.role_name;
    const hierarchyLevel = employee.hierarchy_level;
    const firstName = employee.first_name;
    const lastName = employee.last_name;

    const tokenPayload = {
      userId,
      employeeId,
      roleId,
      roleName,
      hierarchyLevel,
      mustChangePassword: false, // Google auth skips forced password reset
    };

    const token = jwt.sign(tokenPayload, SECRET_KEY, { expiresIn: '24h' });

    res.json({
      token,
      user: {
        id: userId,
        email,
        roleId,
        roleName,
        employeeId,
        firstName,
        lastName,
        hierarchyLevel,
        mustChangePassword: false,
      }
    });

  } catch (err) {
    res.status(500).json({ error: 'Failed to authenticate with Google' });
  }
});

// Update FCM Token Handler
router.post('/update-fcm-token', async (req, res) => {
  const authHeader = req.headers['authorization'];
  if (!authHeader) return res.status(401).json({ error: 'No token provided' });
  const token = authHeader.split(' ')[1];
  
  let caller;
  try {
    caller = jwt.verify(token, SECRET_KEY);
  } catch {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }

  const { fcmToken } = req.body;
  if (!fcmToken) {
    return res.status(400).json({ error: 'FCM token is required' });
  }

  try {
    await pool.query('UPDATE users SET fcm_token = $1 WHERE id = $2', [fcmToken, caller.userId]);
    res.json({ message: 'FCM token updated successfully' });
  } catch (err) {
    console.error('Update FCM token error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get My Profile
router.get('/profile', verifyToken, async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT u.id as "id", u.email, u.role_id as "roleId", r.role_name as "roleName", 
              e.id as "employeeId", e.first_name as "firstName", e.last_name as "lastName", 
              e.phone, e.profile_picture_url as "profilePictureUrl", 
              e.hire_date as "joinedDate", r.hierarchy_level as "hierarchyLevel",
              u.must_change_password as "mustChangePassword",
              d.department_name as "departmentName"
       FROM users u
       JOIN employees e ON u.id = e.user_id
       JOIN roles r ON u.role_id = r.id
       LEFT JOIN departments d ON e.department_id = d.id
       WHERE u.id = $1`,
      [req.user.userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Profile not found' });
    }

    res.json(result.rows[0]);
  } catch (err) {
    console.error('GetProfile Error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Update My Profile
router.put('/profile', verifyToken, async (req, res) => {
  const { firstName, lastName, phone, profilePictureUrl } = req.body;
  
  try {
    await pool.query(
      `UPDATE employees SET 
       first_name = $1, last_name = $2, phone = $3, profile_picture_url = $4
       WHERE user_id = $5`,
      [firstName, lastName, phone, profilePictureUrl, req.user.userId]
    );

    res.json({ message: 'Profile updated successfully' });
  } catch (err) {
    console.error('UpdateProfile Error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;

