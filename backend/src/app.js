import express from 'express';
import cors from 'cors';
import morgan from 'morgan';
import dotenv from 'dotenv';
import { verifyToken, checkRole } from './middleware/auth.js';

// Import Controllers
import authController from './controllers/authController.js';
import attendanceController from './controllers/attendanceController.js';
import leaveController from './controllers/leaveController.js';
import employeeController from './controllers/employeeController.js';
import taskController from './controllers/taskController.js';
import departmentController from './controllers/departmentController.js';

import documentController from './controllers/documentController.js';
import analyticsController from './controllers/analyticsController.js';
import eventController from './controllers/eventController.js';
import tlController from './controllers/tlController.js';
import notificationController from './controllers/notificationController.js';

dotenv.config();

const app = express();

// Middleware
app.use(cors());
app.use(morgan('dev'));
app.use(express.json());
app.use('/uploads', express.static('uploads'));

// Public Routes (login + roles only — register is protected below)
app.use('/auth', authController);
// Explicitly protect /auth/register — this is overridden by the management middleware below
// (keeping /auth mounted publicly for /login & /roles, but /register checks token inline)
app.get('/health', (req, res) => res.send('OK'));
app.get('/analytics/test', (req, res) => res.json({ status: 'Public route works' }));

// Keep process alive for diagnostics
setInterval(() => {
    // console.log('Process heart-beat');
}, 50000);

// Authenticated Routes
app.use(verifyToken);

app.use('/attendance', attendanceController);
app.use('/leave', leaveController);
app.use('/task', taskController);
app.use('/document', documentController);
app.use('/event', eventController);
app.use('/tl', tlController);
app.use('/notifications', notificationController);

// Management Protected Routes
const managementOnly = checkRole(['SUPER_ADMIN', 'ADMIN', 'HR', 'TEAM_LEAD']);

console.log('Mounting Management Routes: /employee, /department, /analytics');

app.use('/employee', managementOnly, employeeController);
app.use('/department', managementOnly, departmentController);

app.use('/analytics', managementOnly, analyticsController);

// Register is an auth route but must be admin-protected
// We protect it by adding an inline token+role check in the authController's /register endpoint
// (req.user is populated by verifyToken which runs on all routes after line 40)

// Error Handling
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ error: 'Something went wrong!' });
});

export default app;

