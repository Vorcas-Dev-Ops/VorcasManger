import jwt from 'jsonwebtoken';
import dotenv from 'dotenv';

dotenv.config();

const SECRET_KEY = process.env.JWT_SECRET || 'your_secret_key';

export const verifyToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  if (!authHeader) {
    return res.status(401).json({ error: 'No token provided' });
  }

  const token = authHeader.split(' ')[1];
  if (!token) {
    return res.status(401).json({ error: 'Malformed token' });
  }

  try {
    const decoded = jwt.verify(token, SECRET_KEY);
    req.user = decoded; // Should contain userId and roleName
    next();
  } catch (err) {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
};

export const checkRole = (allowedRoles) => {
  return (req, res, next) => {
    if (!req.user) {
      console.log('checkRole: No user in request');
      return res.status(403).json({ error: 'Forbidden: No user context' });
    }
    
    const userRole = req.user.roleName ? req.user.roleName.toUpperCase() : '';
    const normalizedAllowed = allowedRoles.map(r => r.toUpperCase());
    
    if (!normalizedAllowed.includes(userRole)) {
      console.log(`checkRole FAILURE: User role '${userRole}' not in ${JSON.stringify(normalizedAllowed)}`);
      return res.status(403).json({ error: 'Forbidden: Insufficient role' });
    }
    next();
  };
};

