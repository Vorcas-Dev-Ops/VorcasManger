import express from 'express';
import pool from '../config/db.js';
import notificationService from '../services/notificationService.js';

const router = express.Router();

// Request Leave
router.post('/request', async (req, res) => {
    const { employee_id, leave_type, start_date, end_date, reason } = req.body;

    if (!employee_id || !leave_type || !start_date) {
        return res.status(400).json({ error: 'Missing required fields' });
    }

    try {
        // Get requester role and supervisor
        const empRes = await pool.query(
            `SELECT e.first_name, e.last_name, s.user_id as supervisor_user_id, r.role_name 
             FROM employees e 
             LEFT JOIN employees s ON e.supervisor_id = s.id 
             JOIN roles r ON e.role_id = r.id 
             WHERE e.id = $1`,
            [employee_id]
        );

        if (empRes.rows.length === 0) {
            return res.status(404).json({ error: 'Employee not found' });
        }

        const requester = empRes.rows[0];
        const roleName = requester.role_name;
        
        let initialStatus = 'PENDING_TL';
        if (roleName === 'TEAM_LEAD') initialStatus = 'PENDING_HR';
        else if (roleName === 'HR') initialStatus = 'PENDING_ADMIN';

        if (leave_type !== 'Sick Leave') {
            const maxDays = leave_type === 'Annual Leave' ? 18 : (leave_type === 'Casual Leave' ? 2 : 0);
            if (maxDays > 0) {
                const year = new Date(start_date).getFullYear();
                const usedResult = await pool.query(
                    `SELECT SUM(end_date - start_date + 1) as used_days 
                     FROM leave_requests 
                     WHERE employee_id = $1 AND leave_type = $2 AND status != 'REJECTED' 
                     AND EXTRACT(YEAR FROM start_date) = $3`,
                    [employee_id, leave_type, year]
                );
                
                const usedDays = parseInt(usedResult.rows[0].used_days) || 0;
                const requestedDays = Math.ceil((new Date(end_date) - new Date(start_date)) / (1000 * 60 * 60 * 24)) + 1;
                
                if (usedDays + requestedDays > maxDays) {
                    return res.status(400).json({ error: 'Insufficient leave balance' });
                }
            }
        }

        await pool.query(
            `INSERT INTO leave_requests (employee_id, leave_type, start_date, end_date, reason, status, created_at) 
             VALUES ($1, $2, $3, $4, $5, $6, CURRENT_TIMESTAMP)`,
            [employee_id, leave_type, start_date, end_date, reason, initialStatus]
        );

        // --- Post-Insert: Notify Appropriate Personnel ---
        try {
            const empName = `${requester.first_name} ${requester.last_name}`;
            const message = `${empName} has requested ${leave_type} leave.`;
            
            if (initialStatus === 'PENDING_TL' && requester.supervisor_user_id) {
                await notificationService.send(requester.supervisor_user_id, 'New Leave Request', message, 'LEAVE');
            } else if (initialStatus === 'PENDING_HR') {
                const hrRes = await pool.query("SELECT user_id FROM employees e JOIN roles r ON e.role_id = r.id WHERE r.role_name = 'HR'");
                for (const hr of hrRes.rows) {
                    if (hr.user_id) await notificationService.send(hr.user_id, 'New Leave Request', message, 'LEAVE');
                }
            } else if (initialStatus === 'PENDING_ADMIN') {
                const adminRes = await pool.query("SELECT user_id FROM employees e JOIN roles r ON e.role_id = r.id WHERE r.role_name IN ('ADMIN', 'SUPER_ADMIN')");
                for (const admin of adminRes.rows) {
                    if (admin.user_id) await notificationService.send(admin.user_id, 'New Leave Request', message, 'LEAVE');
                }
            }
        } catch (notifyErr) {
            console.error('Notification Error (Leave Request):', notifyErr);
        }

        res.json({ message: 'Leave request submitted successfully' });
    } catch (err) {
        console.error('LeaveController RequestLeave Error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Get Leave History
router.get('/history/:employeeId', async (req, res) => {
    const { employeeId } = req.params;

    try {
        const result = await pool.query(
            `SELECT id, employee_id as "employee_id", leave_type as "leave_type", 
                    start_date as "start_date", end_date as "end_date", reason, 
                    status, approved_by as "approved_by", created_at as "created_at" 
             FROM leave_requests WHERE employee_id = \$1 ORDER BY created_at DESC`,
            [employeeId]
        );

        const history = result.rows.map(row => ({
            ...row,
            start_date: row.start_date ? row.start_date.toISOString() : null,
            end_date: row.end_date ? row.end_date.toISOString() : null,
            created_at: row.created_at ? row.created_at.toISOString() : null
        }));

        res.json(history);
    } catch (err) {
        console.error('LeaveController GetHistory Error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Get Pending Leaves (Admin/Management)
router.get('/pending', async (req, res) => {
    try {
        const userRole = req.user ? req.user.roleName : '';
        let statusFilter = "l.status LIKE 'PENDING%'";
        
        if (userRole === 'HR') {
            statusFilter = "l.status IN ('PENDING_TL', 'PENDING_HR')";
        } else if (userRole === 'ADMIN' || userRole === 'SUPER_ADMIN') {
            statusFilter = "l.status LIKE 'PENDING_%'";
        }

        const result = await pool.query(
            `SELECT l.id, l.employee_id as "employee_id", l.leave_type as "leave_type", 
                    l.start_date as "start_date", l.end_date as "end_date", l.reason, 
                    l.status, e.first_name, e.last_name, l.created_at as "created_at" 
             FROM leave_requests l 
             JOIN employees e ON l.employee_id = e.id 
             WHERE ${statusFilter} ORDER BY l.created_at ASC`
        );

        const pending = result.rows.map(row => ({
            ...row,
            employee_name: `${row.first_name} ${row.last_name}`,
            start_date: row.start_date ? row.start_date.toISOString() : null,
            end_date: row.end_date ? row.end_date.toISOString() : null,
            created_at: row.created_at ? row.created_at.toISOString() : null
        }));

        res.json(pending);
    } catch (err) {
        console.error('LeaveController GetPending Error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Approve/Reject Leave
router.post('/approve', async (req, res) => {
    const { status, approver_id, leave_id } = req.body;

    if (!leave_id || !status) {
        return res.status(400).json({ error: 'Missing leave_id or status' });
    }

    try {
        let newStatus = status;
        const userRole = req.user ? (req.user.roleName || '').toUpperCase() : '';
        const actingEmployeeId = req.user?.employeeId || approver_id;
        
        if (status === 'APPROVED') {
            if (userRole === 'TEAM_LEAD') {
                newStatus = 'PENDING_HR';
            } else if (['HR', 'ADMIN', 'SUPER_ADMIN'].includes(userRole)) {
                newStatus = 'APPROVED';
            }
        }

        console.log(`Updating leave ${leave_id} to ${newStatus} by employee ${actingEmployeeId}`);

        const updateRes = await pool.query(
            'UPDATE leave_requests SET status = $1, approved_by = $2 WHERE id = $3 RETURNING *',
            [newStatus, actingEmployeeId, leave_id]
        );

        if (updateRes.rows.length === 0) {
            return res.status(404).json({ error: 'Leave request not found' });
        }

        // --- Post-Update: Notify Stakeholders ---
        try {
            const leaveRes = await pool.query(
                `SELECT l.employee_id, e.user_id, e.first_name, e.last_name 
                 FROM leave_requests l 
                 JOIN employees e ON l.employee_id = e.id 
                 WHERE l.id = $1`,
                [leave_id]
            );

            if (leaveRes.rows.length > 0) {
                const requesterUserId = leaveRes.rows[0].user_id;
                const actingUserId = req.user?.userId;
                
                // 1. Notify Employee about their status change
                let messageBody = '';
                const empFullName = `${leaveRes.rows[0].first_name} ${leaveRes.rows[0].last_name}`;
                if (newStatus === 'APPROVED') {
                    messageBody = `The leave request for ${empFullName} has been fully approved.`;
                } else if (newStatus === 'REJECTED') {
                    messageBody = `The leave request for ${empFullName} has been rejected.`;
                } else if (newStatus === 'PENDING_HR') {
                    messageBody = `The leave request for ${empFullName} has been approved by the Team Lead and is now pending HR approval.`;
                }

                // Only send if there's a message and the recipient is NOT the person who just clicked 'Approve'
                // (Prevents the TL from getting a notification about their own action if testing on same user context)
                if (requesterUserId && requesterUserId !== actingUserId && messageBody) {
                    await notificationService.send(
                        requesterUserId,
                        'Leave Status Update',
                        messageBody,
                        'LEAVE'
                    );
                }

                // 2. If status moved to PENDING_HR, notify HR team
                if (newStatus === 'PENDING_HR') {
                    const hrRes = await pool.query(
                        "SELECT user_id FROM employees e JOIN roles r ON e.role_id = r.id WHERE r.role_name = 'HR'"
                    );
                    const hrUserIds = hrRes.rows.map(r => r.user_id).filter(id => id);
                    if (hrUserIds.length > 0) {
                        await notificationService.sendToMultiple(
                            hrUserIds,
                            'Final Leave Approval Required',
                            `A leave request from ${empFullName} has been approved by a TL and requires your final review.`,
                            'LEAVE'
                        );
                    }
                }
            }
        } catch (notifyErr) {
            console.error('Notification Error (Leave Approve):', notifyErr);
        }

        res.json({ message: 'Leave request updated successfully' });
    } catch (err) {
        console.error('LeaveController ApproveLeave Error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Get Leave Balances
router.get('/balances/:employeeId', async (req, res) => {
    const { employeeId } = req.params;

    try {
        // Count PENDING requests
        const pendingResult = await pool.query(
            'SELECT COUNT(*) FROM leave_requests WHERE employee_id = \$1 AND status LIKE \'PENDING%\'',
            [employeeId]
        );
        const pendingCount = parseInt(pendingResult.rows[0].count);

        // Sum used days for APPROVED requests in current year
        const year = new Date().getFullYear();
        const usedResult = await pool.query(
            `SELECT leave_type, SUM(end_date - start_date + 1) as used_days 
             FROM leave_requests 
             WHERE employee_id = \$1 AND status = 'APPROVED' 
             AND EXTRACT(YEAR FROM start_date) = \$2 
             GROUP BY leave_type`,
            [employeeId, year]
        );

        const usedMap = {};
        usedResult.rows.forEach(row => {
            usedMap[row.leave_type] = parseInt(row.used_days);
        });

        const annualBalance = 18 - (usedMap['Annual Leave'] || 0);
        const casualBalance = 2 - (usedMap['Casual Leave'] || 0);

        const balances = [
            { type: 'Annual Leave', balance: annualBalance < 0 ? 0 : annualBalance, unit: 'Days' },
            { type: 'Sick Leave', balance: 5 - (usedMap['Sick Leave'] || 0), unit: 'Days' },
            { type: 'Casual Leave', balance: casualBalance < 0 ? 0 : casualBalance, unit: 'Days' },
            { type: 'Pending Requests', balance: pendingCount, unit: 'Request' },
        ];

        res.json(balances);
    } catch (err) {
        console.error('LeaveController GetBalances Error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

export default router;

