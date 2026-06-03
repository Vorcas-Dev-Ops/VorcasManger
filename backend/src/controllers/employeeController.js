import express from 'express';
import pool from '../config/db.js';

const router = express.Router();

// Get All Employees
router.get('/', async (req, res) => {
  const callerLevel = req.user?.hierarchyLevel ?? 99;
  try {
    let query = `
      SELECT e.id, e.user_id as "user_id", e.employee_id as "employee_id", 
             e.first_name as "first_name", e.last_name as "last_name", e.phone, 
             e.department_id as "department_id", d.department_name as "department_name",
             e.role_id as "role_id", e.supervisor_id as "supervisor_id", 
             e.hire_date as "hire_date", e.status, 
             r.role_name as "role_name", r.hierarchy_level as "hierarchy_level" 
      FROM employees e 
      JOIN roles r ON e.role_id = r.id 
      LEFT JOIN departments d ON e.department_id = d.id
    `;
    let params = [];
    
    // Hide SUPER_ADMIN (level 1) from non-Super-Admins
    if (callerLevel !== 1) {
      query += ' WHERE r.hierarchy_level > 1';
    }
    
    query += ' ORDER BY e.first_name ASC';
    
    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch (err) {
    console.error('GetAllEmployees Error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get Employee By ID
router.get('/:id', async (req, res) => {
  const { id } = req.params;
  try {
    const result = await pool.query(
      `SELECT id, user_id as "user_id", employee_id as "employee_id", 
              first_name as "first_name", last_name as "last_name", phone, 
              department_id as "department_id", role_id as "role_id", 
              supervisor_id as "supervisor_id", hire_date as "hire_date", status 
       FROM employees WHERE id = \$1`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Employee not found' });
    }

    res.json(result.rows[0]);
  } catch (err) {
    console.error('GetEmployeeById Error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Create Employee
router.post('/', async (req, res) => {
  const payload = req.body;
  try {
    const result = await pool.query(
      `INSERT INTO employees 
       (user_id, employee_id, first_name, last_name, phone, department_id, role_id, supervisor_id, hire_date, status) 
       VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9, \$10) RETURNING id`,
      [
        payload.user_id,
        payload.employee_id,
        payload.first_name,
        payload.last_name,
        payload.phone,
        payload.department_id,
        payload.role_id,
        payload.supervisor_id,
        payload.hire_date,
        payload.status || 'ACTIVE',
      ]
    );
    res.json({ id: result.rows[0].id, message: 'Employee created successfully' });
  } catch (err) {
    console.error('CreateEmployee Error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Update Employee
router.put('/:id', async (req, res) => {
  const { id } = req.params;
  const payload = req.body;
  const callerLevel = req.user?.hierarchyLevel ?? 99;

  try {
    // Enforce hierarchy: Non-Super-Admins cannot modify peers or superiors
    if (callerLevel !== 1) {
      const targetEmp = await pool.query(
        'SELECT r.hierarchy_level FROM employees e JOIN roles r ON e.role_id = r.id WHERE e.id = \$1',
        [id]
      );
      if (targetEmp.rows.length > 0) {
        const targetLevel = targetEmp.rows[0].hierarchy_level;
        if (targetLevel <= callerLevel) {
          return res.status(403).json({ error: 'Forbidden: Cannot modify a user at equal or higher rank.' });
        }
      }
      
      // Also check if new role assignment is valid
      if (payload.role_id) {
        const newRole = await pool.query('SELECT hierarchy_level FROM roles WHERE id = \$1', [payload.role_id]);
        if (newRole.rows.length > 0 && newRole.rows[0].hierarchy_level <= callerLevel) {
          return res.status(403).json({ error: 'Forbidden: Cannot assign a role at equal or higher rank.' });
        }
      }
    }

    await pool.query(
      `UPDATE employees SET 
       employee_id = \$1, first_name = \$2, last_name = \$3, phone = \$4, 
       department_id = \$5, role_id = \$6, supervisor_id = \$7, hire_date = \$8, status = \$9 
       WHERE id = \$10`,
      [
        payload.employee_id,
        payload.first_name,
        payload.last_name,
        payload.phone,
        payload.department_id,
        payload.role_id,
        payload.supervisor_id,
        payload.hire_date,
        payload.status,
        id,
      ]
    );
    res.json({ message: 'Employee updated successfully' });
  } catch (err) {
    console.error('UpdateEmployee Error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Update Employee Role (with hierarchy check)
router.put('/:id/role', async (req, res) => {
  const { id } = req.params;
  const { role_id } = req.body;
  const callerLevel = req.user?.hierarchyLevel ?? 99; // From JWT via verifyToken middleware

  try {
    // 1. Fetch the target employee's current hierarchy level
    const targetEmp = await pool.query(
      `SELECT e.user_id, r.hierarchy_level 
       FROM employees e JOIN roles r ON e.role_id = r.id 
       WHERE e.id = $1`,
      [id]
    );
    if (targetEmp.rows.length === 0) {
      return res.status(404).json({ error: 'Employee not found' });
    }
    const targetLevel = targetEmp.rows[0].hierarchy_level;
    const targetUserId = targetEmp.rows[0].user_id;

    // 2. Fetch the new role's hierarchy level
    const newRoleResult = await pool.query(
      'SELECT hierarchy_level FROM roles WHERE id = $1', [role_id]
    );
    if (newRoleResult.rows.length === 0) {
      return res.status(400).json({ error: 'Invalid role_id' });
    }
    const newRoleLevel = newRoleResult.rows[0].hierarchy_level;

    // 3. Enforce hierarchy: Non-Super-Admins cannot manage equals or superiors
    // Super Admin = hierarchy_level 1
    if (callerLevel !== 1) {
      if (targetLevel <= callerLevel) {
        return res.status(403).json({ error: 'Cannot modify the role of a user at equal or higher rank.' });
      }
      if (newRoleLevel <= callerLevel) {
        return res.status(403).json({ error: 'Cannot assign a role equal to or higher than your own rank.' });
      }
    }

    // 4. Update both employees and users tables in a transaction
    await pool.query('BEGIN');
    await pool.query('UPDATE employees SET role_id = $1 WHERE id = $2', [role_id, id]);
    await pool.query('UPDATE users SET role_id = $1 WHERE id = $2', [role_id, targetUserId]);
    await pool.query('COMMIT');

    res.json({ message: 'Role updated successfully' });
  } catch (err) {
    await pool.query('ROLLBACK');
    console.error('UpdateEmployeeRole Error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Delete Employee
router.delete('/:id', async (req, res) => {
  const { id } = req.params;
  const callerLevel = req.user?.hierarchyLevel ?? 99;

  try {
    // Enforce hierarchy
    if (callerLevel !== 1) {
      const targetEmp = await pool.query(
        'SELECT r.hierarchy_level FROM employees e JOIN roles r ON e.role_id = r.id WHERE e.id = \$1',
        [id]
      );
      if (targetEmp.rows.length > 0) {
        if (targetEmp.rows[0].hierarchy_level <= callerLevel) {
          return res.status(403).json({ error: 'Forbidden: Cannot delete a user at equal or higher rank.' });
        }
      }
    }

    await pool.query('DELETE FROM employees WHERE id = \$1', [id]);
    res.json({ message: 'Employee deleted successfully' });
  } catch (err) {
    console.error('DeleteEmployee Error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;

