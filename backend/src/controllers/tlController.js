import express from 'express';
import pool from '../config/db.js';

const router = express.Router();

// Get Dashboard Stats for TL
router.get('/dashboard-stats/:tlId', async (req, res) => {
    const { tlId } = req.params;

    try {
        // Get team member IDs
        const teamResult = await pool.query(
            'SELECT id FROM employees WHERE supervisor_id = $1',
            [tlId]
        );
        const memberIds = teamResult.rows.map(row => row.id);
        console.log('getDashboardStats tlId:', tlId, 'memberIds:', memberIds);

        if (memberIds.length === 0) {
            return res.json({
                taskOverview: { TODO: 0, IN_PROGRESS: 0, DONE: 0 },
                overdueCount: 0,
                highPriorityCount: 0,
                teamCount: 0,
                presentCount: 0,
                metrics: { velocity: 0, bugs: 0, uptime: '100%' }
            });
        }

        // Task Summary
        const tasksResult = await pool.query(
            'SELECT status, COUNT(*)::int FROM tasks WHERE assigned_to = ANY($1) GROUP BY status',
            [memberIds]
        );
        const taskMap = { TODO: 0, IN_PROGRESS: 0, DONE: 0 };
        tasksResult.rows.forEach(row => {
            if (row.status === 'PENDING') taskMap.TODO += row.count;
            else if (row.status === 'COMPLETED') taskMap.DONE += row.count;
            else if (taskMap.hasOwnProperty(row.status)) taskMap[row.status] += row.count;
        });

        // Overdue Count
        const overdueResult = await pool.query(
            "SELECT COUNT(*)::int FROM tasks WHERE assigned_to = ANY($1) AND status != 'COMPLETED' AND deadline < NOW()",
            [memberIds]
        );
        const overdueCount = overdueResult.rows[0].count;

        // High Priority Count
        const priorityResult = await pool.query(
            "SELECT COUNT(*)::int FROM tasks WHERE assigned_to = ANY($1) AND priority = 'HIGH' AND status != 'COMPLETED'",
            [memberIds]
        );
        const highPriorityCount = priorityResult.rows[0].count;

        // Attendance List for Snapshot
        const attendListResult = await pool.query(
            `SELECT e.id, e.first_name, e.last_name, MAX(a.check_in_time) as check_in_time 
             FROM employees e 
             LEFT JOIN attendance a ON e.id = a.employee_id AND a.attendance_date = CURRENT_DATE 
             WHERE e.supervisor_id = $1
             GROUP BY e.id, e.first_name, e.last_name`,
            [tlId]
        );
        const squadAttendance = attendListResult.rows.map(row => ({
            id: row.id,
            name: `${row.first_name} ${row.last_name}`,
            status: row.check_in_time ? 'ONLINE' : 'OFFLINE',
            checkIn: row.check_in_time
        }));
        const presentCount = squadAttendance.filter(m => m.status === 'ONLINE').length;

        res.json({
            taskOverview: taskMap,
            overdueCount: overdueCount,
            highPriorityCount: highPriorityCount,
            teamCount: memberIds.length,
            presentCount: presentCount,
            squad: squadAttendance,
            metrics: { velocity: 48, bugs: 4, uptime: '99.9%' } 
        });

    } catch (err) {
        console.error('TlController DashboardStats Error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Get Squad Task Progress (Detailed Report)
router.get('/squad-progress/:tlId', async (req, res) => {
    const { tlId } = req.params;
    try {
        const result = await pool.query(
            `SELECT 
                e.id, 
                e.first_name || ' ' || e.last_name as name,
                e.status,
                e.phone,
                r.role_name as role,
                COUNT(t.id) as total_tasks,
                COUNT(CASE WHEN t.status = 'COMPLETED' THEN 1 END) as done_tasks,
                COUNT(CASE WHEN t.status != 'COMPLETED' AND t.deadline < NOW() THEN 1 END) as overdue_tasks
             FROM employees e
             JOIN roles r ON e.role_id = r.id
             LEFT JOIN tasks t ON e.id = t.assigned_to
             WHERE e.supervisor_id = $1
             GROUP BY e.id, e.first_name, e.last_name, e.status, e.phone, r.role_name`,
            [tlId]
        );

        const progress = result.rows.map(row => ({
            id: row.id,
            name: row.name,
            status: row.status,
            phone: row.phone,
            role: row.role,
            total: parseInt(row.total_tasks),
            done: parseInt(row.done_tasks),
            overdue: parseInt(row.overdue_tasks),
            percentage: row.total_tasks > 0 ? Math.round((row.done_tasks / row.total_tasks) * 100) : 0
        }));

        res.json(progress);
    } catch (err) {
        console.error('TlController GetSquadProgress Error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Get Squad
router.get('/squad/:tlId', async (req, res) => {
    const { tlId } = req.params;
    try {
        const result = await pool.query(
            `SELECT e.id, e.first_name, e.last_name, r.role_name, e.status, e.profile_picture_url 
             FROM employees e 
             JOIN roles r ON e.role_id = r.id 
             WHERE e.supervisor_id = $1`,
            [tlId]
        );

        const squad = result.rows.map(row => ({
            id: row.id,
            name: `${row.first_name} ${row.last_name}`,
            role: row.role_name,
            status: row.status,
            avatarUrl: row.profile_picture_url,
        }));

        res.json(squad);
    } catch (err) {
        console.error('TlController GetSquad Error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Get Team Attendance
router.get('/team-attendance/:tlId', async (req, res) => {
    const { tlId } = req.params;
    try {
        const result = await pool.query(
            `SELECT e.id, e.first_name, e.last_name, MAX(a.check_in_time) as check_in_time 
             FROM employees e 
             LEFT JOIN attendance a ON e.id = a.employee_id AND a.attendance_date = CURRENT_DATE 
             WHERE e.supervisor_id = $1
             GROUP BY e.id, e.first_name, e.last_name`,
            [tlId]
        );

        const attendance = result.rows.map(row => ({
            id: row.id,
            name: `${row.first_name} ${row.last_name}`,
            checkIn: row.check_in_time ? new Date(row.check_in_time).toISOString() : null,
            status: row.check_in_time === null ? 'OFFLINE' : 'ONLINE',
        }));

        res.json(attendance);
    } catch (err) {
        console.error('TlController GetTeamAttendance Error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Get Team Tasks
router.get('/team-tasks/:tlId', async (req, res) => {
    const { tlId } = req.params;
    try {
        const result = await pool.query(
            `SELECT t.id, t.title, t.status, e.first_name, e.last_name 
             FROM tasks t 
             JOIN employees e ON t.assigned_to = e.id 
             WHERE e.supervisor_id = $1 ORDER BY t.created_at DESC`,
            [tlId]
        );

        const tasks = result.rows.map(row => ({
            id: row.id,
            title: row.title,
            status: row.status,
            assignedTo: `${row.first_name} ${row.last_name}`,
        }));

        res.json(tasks);
    } catch (err) {
        console.error('TlController GetTeamTasks Error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Get Team Leaves
router.get('/team-leaves/:tlId', async (req, res) => {
    const { tlId } = req.params;

    try {
        // Get team member IDs
        const teamResult = await pool.query(
            'SELECT id FROM employees WHERE supervisor_id = $1',
            [tlId]
        );
        const memberIds = teamResult.rows.map(row => row.id);
        console.log('getTeamLeaves tlId:', tlId, 'memberIds:', memberIds);

        if (memberIds.length === 0) {
            return res.json([]);
        }

        const result = await pool.query(
            `SELECT l.id, e.first_name, e.last_name, r.role_name, l.leave_type, l.start_date, l.end_date, l.reason, e.profile_picture_url 
             FROM leave_requests l 
             JOIN employees e ON l.employee_id = e.id 
             JOIN roles r ON e.role_id = r.id 
             WHERE l.employee_id = ANY($1) AND l.status = 'PENDING_TL' 
             ORDER BY l.created_at DESC`,
            [memberIds]
        );

        const leaves = result.rows.map(row => ({
            id: row.id,
            name: `${row.first_name} ${row.last_name}`,
            role: row.role_name,
            type: row.leave_type,
            startDate: row.start_date ? row.start_date.toISOString() : null,
            endDate: row.end_date ? row.end_date.toISOString() : null,
            reason: row.reason,
            avatarUrl: row.profile_picture_url,
        }));

        res.json(leaves);
    } catch (err) {
        console.error('TlController GetTeamLeaves Error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Get Employees without a supervisor (eligible to join a squad)
router.get('/unassigned-employees', async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT e.id, e.first_name, e.last_name, r.role_name, e.status, e.profile_picture_url 
             FROM employees e 
             JOIN roles r ON e.role_id = r.id 
             WHERE e.supervisor_id IS NULL AND r.role_name = 'EMPLOYEE'`
        );

        const unassigned = result.rows.map(row => ({
            id: row.id,
            name: `${row.first_name} ${row.last_name}`,
            role: row.role_name,
            status: row.status,
            avatarUrl: row.profile_picture_url,
        }));

        res.json(unassigned);
    } catch (err) {
        console.error('TlController GetUnassigned Error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Add Employee to Squad
router.post('/add-to-squad', async (req, res) => {
    const { tlId, employeeId } = req.body;
    if (!tlId || !employeeId) {
        return res.status(400).json({ error: 'tlId and employeeId are required' });
    }

    try {
        await pool.query(
            'UPDATE employees SET supervisor_id = $1 WHERE id = $2',
            [tlId, employeeId]
        );
        res.json({ message: 'Employee added to squad successfully' });
    } catch (err) {
        console.error('TlController AddToSquad Error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

export default router;

