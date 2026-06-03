import express from 'express';
import pool from '../config/db.js';

const router = express.Router();

// Get Dashboard Summary
router.get('/summary', async (req, res) => {
    try {
        const userLevel = req.user?.hierarchyLevel || 99;

        const totalEmp = await pool.query(
            `SELECT COUNT(*)::int FROM employees e 
             JOIN roles r ON e.role_id = r.id 
             WHERE UPPER(e.status) = 'ACTIVE' AND r.hierarchy_level >= \$1`,
            [userLevel]
        );
        
        const activeNow = await pool.query(
            `SELECT COUNT(*)::int FROM attendance a 
             JOIN employees e ON a.employee_id = e.id 
             JOIN roles r ON e.role_id = r.id 
             WHERE a.attendance_date = CURRENT_DATE AND a.check_out_time IS NULL AND r.hierarchy_level >= \$1`,
            [userLevel]
        );

        const leaveRequests = await pool.query(
            `SELECT COUNT(*)::int FROM leave_requests l 
             JOIN employees e ON l.employee_id = e.id 
             JOIN roles r ON e.role_id = r.id 
             WHERE l.status LIKE 'PENDING%' AND r.hierarchy_level >= \$1`,
            [userLevel]
        );

        const newHires = await pool.query(
            `SELECT COUNT(*)::int FROM employees e 
             JOIN roles r ON e.role_id = r.id 
             WHERE e.hire_date > CURRENT_DATE - INTERVAL '30 days' AND r.hierarchy_level >= \$1`,
            [userLevel]
        );

        res.json({
            totalEmployees: totalEmp.rows[0].count,
            activeNow: activeNow.rows[0].count,
            leaveRequests: leaveRequests.rows[0].count,
            newHires: newHires.rows[0].count,
        });
    } catch (err) {
        console.error('Dashboard Summary Error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Get Workforce Stats
router.get('/workforce', async (req, res) => {
    try {
        const userLevel = req.user?.hierarchyLevel || 99;

        const roleCounts = await pool.query(
            `SELECT r.role_name as label, COUNT(e.id)::int as value 
             FROM roles r 
             LEFT JOIN employees e ON r.id = e.role_id 
             WHERE r.hierarchy_level >= \$1 
             GROUP BY r.role_name`,
            [userLevel]
        );
        
        res.json(roleCounts.rows);
    } catch (err) {
        console.error('Workforce Stats Error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Get Attendance Stats (Last 7 Days)
router.get('/attendance', async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT attendance_date::text as date, 
                    COUNT(id)::int as present,
                    COUNT(id) FILTER (WHERE is_late = true)::int as late,
                    ((SELECT COUNT(*)::int FROM employees WHERE UPPER(status) = 'ACTIVE') - COUNT(id)::int) as absent
             FROM attendance 
             WHERE attendance_date > CURRENT_DATE - INTERVAL '7 days' 
             GROUP BY attendance_date ORDER BY attendance_date ASC`
        );
        
        res.json(result.rows);
    } catch (err) {
        console.error('Attendance Stats Error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Admin Dashboard — Aggregated overview for admin dashboard tab
router.get('/admin-dashboard', async (req, res) => {
    try {
        // Total employees
        const totalEmp = await pool.query(`SELECT COUNT(*)::int FROM employees WHERE UPPER(status) = 'ACTIVE'`);

        // Active now (checked in today, not checked out)
        const activeNow = await pool.query(
            `SELECT COUNT(*)::int FROM attendance WHERE attendance_date = CURRENT_DATE AND check_out_time IS NULL`
        );

        // Pending leave requests
        const pendingLeaves = await pool.query(`SELECT COUNT(*)::int FROM leave_requests WHERE status LIKE 'PENDING%'`);

        // Tasks by status
        const tasksByStatus = await pool.query(
            `SELECT status, COUNT(*)::int as count FROM tasks GROUP BY status`
        );
        const taskMap = { PENDING: 0, IN_PROGRESS: 0, DONE: 0 };
        tasksByStatus.rows.forEach(r => { taskMap[r.status] = r.count; });
        const activeTasks = taskMap.PENDING + taskMap.IN_PROGRESS;

        // Weekly attendance by day of week (last 7 days)
        const weeklyAttendance = await pool.query(
            `SELECT TO_CHAR(attendance_date, 'DY') as day_label,
                    attendance_date,
                    COUNT(*)::int as count
             FROM attendance
             WHERE attendance_date > CURRENT_DATE - INTERVAL '7 days'
             GROUP BY attendance_date
             ORDER BY attendance_date ASC`
        );

        // Calculate presence rate
        const totalToday = totalEmp.rows[0].count;
        const presentToday = activeNow.rows[0].count;
        const presenceRate = totalToday > 0 ? Math.round((presentToday / totalToday) * 1000) / 10 : 0;

        // Recent leave requests (last 5)
        const recentLeaves = await pool.query(
            `SELECT l.id, e.first_name, e.last_name, l.leave_type, l.created_at
             FROM leave_requests l
             JOIN employees e ON l.employee_id = e.id
             ORDER BY l.created_at DESC LIMIT 5`
        );

        const alerts = recentLeaves.rows.map(r => ({
            title: `${r.first_name} ${r.last_name}`,
            subtitle: `${r.leave_type} request`,
            createdAt: r.created_at ? new Date(r.created_at).toISOString() : null,
        }));

        res.json({
            totalEmployees: totalEmp.rows[0].count,
            activeNow: presentToday,
            pendingLeaves: pendingLeaves.rows[0].count,
            activeTasks,
            tasksByStatus: taskMap,
            presenceRate,
            weeklyAttendance: weeklyAttendance.rows,
            alerts,
        });
    } catch (err) {
        console.error('Admin Dashboard Error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Super Admin Dashboard — Aggregated overview for super admin dashboard tab
router.get('/super-admin-dashboard', async (req, res) => {
    try {
        // Total employees
        const totalEmp = await pool.query(`SELECT COUNT(*)::int as count FROM employees WHERE UPPER(status) = 'ACTIVE'`);
        const total = totalEmp.rows[0].count;

        // Active now (checked in today, not checked out)
        const activeNow = await pool.query(
            `SELECT COUNT(DISTINCT employee_id)::int as count FROM attendance WHERE attendance_date = CURRENT_DATE AND check_out_time IS NULL`
        );
        const presentToday = activeNow.rows[0].count;

        // Pending leave requests
        const pendingLeaves = await pool.query(`SELECT COUNT(*)::int as count FROM leave_requests WHERE status LIKE 'PENDING%'`);

        // Tasks status
        const tasksByStatus = await pool.query(
            `SELECT status, COUNT(*)::int as count FROM tasks GROUP BY status`
        );
        const taskMap = { PENDING: 0, IN_PROGRESS: 0, DONE: 0 };
        tasksByStatus.rows.forEach(r => { taskMap[r.status] = r.count; });
        const activeTasks = taskMap.PENDING + taskMap.IN_PROGRESS;

        // Presence rate
        const presenceRate = total > 0 ? Math.round((presentToday / total) * 100) : 0;

        // Weekly attendance trends (last 7 days)
        const weeklyTrends = await pool.query(
            `SELECT TO_CHAR(attendance_date, 'DY') as day_label,
                    attendance_date,
                    COUNT(*)::int as count
             FROM attendance
             WHERE attendance_date > CURRENT_DATE - INTERVAL '7 days'
             GROUP BY attendance_date
             ORDER BY attendance_date ASC`
        );

        // Department Focus — Workload Distribution (Active Tasks per Department)
        const totalActiveTasksRes = await pool.query(`SELECT COUNT(*)::int FROM tasks WHERE status != 'DONE'`);
        const totalActiveTasks = totalActiveTasksRes.rows[0].count;

        const deptStats = await pool.query(
            `SELECT d.department_name as department,
                    COUNT(DISTINCT e.id)::int as employee_count,
                    COUNT(DISTINCT t.id)::int as task_count
             FROM departments d
             LEFT JOIN employees e ON e.department_id = d.id AND UPPER(e.status) = 'ACTIVE'
             LEFT JOIN tasks t ON t.assigned_to = e.id AND t.status != 'DONE'
             GROUP BY d.id, d.department_name
             ORDER BY employee_count DESC`
        );

        const departments = deptStats.rows.map(r => ({
            name: r.department,
            employee_count: r.employee_count,
            taskCount: r.task_count,
            rate: totalActiveTasks > 0 ? Math.round((r.task_count / totalActiveTasks) * 100) : 0,
        }));


        res.json({
            metrics: {
                totalEmployees: total,
                activeNow: presentToday,
                revenueBurn: '$4.2M / $1.1M', // Placeholder as per design
                securityAlerts: 2,           // Placeholder as per design
                pendingLeaves: pendingLeaves.rows[0].count,
                activeTasks: activeTasks,
                presenceRate: presenceRate,
            },
            weeklyTrends: weeklyTrends.rows,
            departments: departments,
        });
    } catch (err) {
        console.error('Super Admin Dashboard Error:', err);
        res.status(500).json({ error: 'Internal server error', details: err.message });
    }
});

// Workforce Distribution — Role-based counts for PieChart
router.get('/workforce-distribution', async (req, res) => {
    try {
        const roleCounts = await pool.query(
            `SELECT r.role_name as label, COUNT(e.id)::int as value 
             FROM roles r 
             LEFT JOIN employees e ON r.id = e.role_id 
             GROUP BY r.role_name`
        );
        
        res.json(roleCounts.rows);
    } catch (err) {
        console.error('Workforce Distribution Error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Attendance Overview — For the admin attendance tab
router.get('/attendance-overview', async (req, res) => {
    try {
        // Total active employees
        const totalEmp = await pool.query(`SELECT COUNT(*)::int FROM employees WHERE UPPER(status) = 'ACTIVE'`);
        const total = totalEmp.rows[0].count;

        // Present today
        const presentToday = await pool.query(
            `SELECT COUNT(DISTINCT employee_id)::int FROM attendance WHERE attendance_date = CURRENT_DATE`
        );
        const present = presentToday.rows[0].count;
        const dailyPresencePercent = total > 0 ? Math.round((present / total) * 1000) / 10 : 0;


        // Early checkouts today
        const earlyCheckouts = await pool.query(
            `SELECT COUNT(*)::int FROM attendance WHERE attendance_date = CURRENT_DATE AND is_early_checkout = true`
        );

        // Weekly trends (last 7 days)
        const weeklyTrends = await pool.query(
            `SELECT attendance_date::text as date,
                    TO_CHAR(attendance_date, 'DY') as day_label,
                    COUNT(*)::int as count
             FROM attendance
             WHERE attendance_date > CURRENT_DATE - INTERVAL '7 days'
             GROUP BY attendance_date
             ORDER BY attendance_date ASC`
        );

        // Peak activity — day with highest attendance count
        let peakDay = 'N/A';
        let peakCount = 0;
        weeklyTrends.rows.forEach(r => {
            if (r.count > peakCount) {
                peakCount = r.count;
                peakDay = r.day_label;
            }
        });

        // Department-level attendance stats (top performers)
        const deptStats = await pool.query(
            `SELECT d.department_name as department,
                    COUNT(DISTINCT e.id)::int as total_members,
                    COUNT(DISTINCT a.employee_id)::int as present_today
             FROM departments d
             LEFT JOIN employees e ON e.department_id = d.id AND UPPER(e.status) = 'ACTIVE'
             LEFT JOIN attendance a ON a.employee_id = e.id AND a.attendance_date = CURRENT_DATE
             GROUP BY d.id, d.department_name
             ORDER BY present_today DESC`
        );

        const departments = deptStats.rows.map(r => ({
            department: r.department,
            totalMembers: r.total_members,
            presentToday: r.present_today,
            rate: r.total_members > 0 ? Math.round((r.present_today / r.total_members) * 100) : 0,
        }));

        // Today's attendance log (names and times)
        const todayLog = await pool.query(
            `SELECT e.first_name, e.last_name, a.check_in_time, a.is_late 
             FROM attendance a 
             JOIN employees e ON a.employee_id = e.id 
             WHERE a.attendance_date = CURRENT_DATE 
             ORDER BY a.check_in_time DESC`
        );

        res.json({
            dailyPresencePercent,
            present,
            total,
            earlyCheckouts: earlyCheckouts.rows[0].count,
            weeklyTrends: weeklyTrends.rows,
            peakDay,
            departments,
            todayLog: todayLog.rows.map(r => ({
                name: `${r.first_name} ${r.last_name}`,
                time: r.check_in_time,
            })),
        });
    } catch (err) {
        console.error('Attendance Overview Error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Task Overview — For admin tasks screen
router.get('/task-overview', async (req, res) => {
    try {
        // Task counts by status
        const statusCounts = await pool.query(
            `SELECT status, COUNT(*)::int as count FROM tasks GROUP BY status`
        );
        const taskMap = { PENDING: 0, IN_PROGRESS: 0, DONE: 0 };
        statusCounts.rows.forEach(r => { taskMap[r.status] = r.count; });

        // All tasks with assignee
        const tasks = await pool.query(
            `SELECT t.id, t.title, t.description, t.status, t.deadline,
                    t.created_at, e.first_name, e.last_name
             FROM tasks t
             LEFT JOIN employees e ON t.assigned_to = e.id
             ORDER BY t.created_at DESC`
        );

        const taskList = tasks.rows.map(r => ({
            id: r.id,
            title: r.title,
            description: r.description,
            status: r.status,
            deadline: r.deadline ? new Date(r.deadline).toISOString().split('T')[0] : null,
            createdAt: r.created_at ? new Date(r.created_at).toISOString() : null,
            assignedTo: r.first_name ? `${r.first_name} ${r.last_name}` : 'Unassigned',
        }));

        res.json({
            statusCounts: taskMap,
            tasks: taskList,
        });
    } catch (err) {
        console.error('Task Overview Error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

export default router;

