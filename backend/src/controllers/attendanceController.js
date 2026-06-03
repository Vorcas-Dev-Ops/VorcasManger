import express from 'express';
import pool from '../config/db.js';

const router = express.Router();

// Get IST Time helper
const getIstTime = () => {
    return new Date(new Date().toLocaleString('en-US', { timeZone: 'Asia/Kolkata' }));
};

// Check-in Handler
router.post('/check-in', async (req, res) => {
    const { employeeId, latitude, longitude } = req.body;

    console.log(`Check-in Request: employeeId=${employeeId}, lat=${latitude}, long=${longitude}`);

    if (!employeeId || latitude === undefined || longitude === undefined) {
        return res.status(400).json({ error: 'Missing required fields' });
    }

    try {
        // Check if already checked in for today
        const checkResult = await pool.query(
            'SELECT id FROM attendance WHERE employee_id = \$1 AND attendance_date = CURRENT_DATE AND check_out_time IS NULL',
            [employeeId]
        );

        if (checkResult.rows.length > 0) {
            return res.status(400).json({ error: 'Already checked in for today' });
        }

        // Detect Lateness (NO LONGER TRACKED as per user request)
        const isLate = false;

        const result = await pool.query(
            'INSERT INTO attendance (employee_id, check_in_time, location_lat, location_long, attendance_date, is_late) VALUES (\$1, CURRENT_TIMESTAMP, \$2, \$3, CURRENT_DATE, \$4) RETURNING id',
            [employeeId, latitude, longitude, isLate]
        );

        const id = result.rows[0].id;
        console.log(`Check-in Successful for employeeId: ${employeeId}, ID: ${id}`);
        res.json({ id, message: 'Checked in successfully' });

    } catch (err) {
        console.error('Attendance Check-in ERROR:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Check-out Handler
router.post('/check-out', async (req, res) => {
    const { employeeId, attendanceId, reason } = req.body;

    if (!employeeId || !attendanceId) {
        return res.status(400).json({ error: 'Missing required fields' });
    }

    try {
        // Detect Early Checkout (Threshold: 06:00 PM IST)
        const istNow = getIstTime();
        const isEarly = istNow.getHours() < 18;

        // Calculate work hours and update
        await pool.query(
            `UPDATE attendance SET 
             check_out_time = CURRENT_TIMESTAMP, 
             work_hours = EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - check_in_time)) / 3600, 
             is_early_checkout = \$1, 
             early_checkout_reason = \$2 
             WHERE id = \$3 AND employee_id = \$4`,
            [isEarly, reason, attendanceId, employeeId]
        );

        res.json({
            message: 'Checked out successfully',
            isEarly: isEarly,
            reported: false,
        });

    } catch (err) {
        console.error('Attendance Check-out ERROR:', err);
        res.status(500).json({ error: 'Internal server error: ' + err.message });
    }
});

// Get Status Handler
router.get('/status/:employeeId', async (req, res) => {
    const { employeeId } = req.params;
    console.log(`DEBUG: Fetching status for employeeId: ${employeeId}`);

    try {
        // Check for active session today (check_out_time is null)
        const result = await pool.query(
            'SELECT id, check_in_time, check_out_time, location_lat, location_long, is_late FROM attendance WHERE employee_id = $1 AND attendance_date = CURRENT_DATE ORDER BY check_in_time DESC LIMIT 1',
            [employeeId]
        );

        if (result.rows.length === 0) {
            console.log(`DEBUG: No active session for ${employeeId}`);
            return res.json({ status: 'NOT_CHECKED_IN' });
        }

        const row = result.rows[0];
        const attendanceId = row.id;
        console.log(`DEBUG: Active attendanceId: ${attendanceId}`);

        if (row.check_out_time !== null) {
            console.log(`DEBUG: Already checked out today for ${employeeId}`);
            return res.json({
                status: 'CHECKED_OUT',
                attendanceId: attendanceId,
                checkInTime: row.check_in_time ? new Date(row.check_in_time).toISOString() : null,
                checkOutTime: row.check_out_time ? new Date(row.check_out_time).toISOString() : null,
                isLate: row.is_late || false,
            });
        }

        // Calculate breaks
        const breaksResult = await pool.query(
            'SELECT id, break_start, break_end FROM attendance_breaks WHERE attendance_id = $1',
            [attendanceId]
        );

        let accumulatedBreakSeconds = 0;
        let currentBreakStart = null;
        let activeBreakId = null;

        for (const bRow of breaksResult.rows) {
            const start = bRow.break_start ? new Date(bRow.break_start) : null;
            const end = bRow.break_end ? new Date(bRow.break_end) : null;
            
            if (start && end) {
                accumulatedBreakSeconds += Math.floor((end.getTime() - start.getTime()) / 1000);
            } else if (start && !end) {
                currentBreakStart = start.toISOString();
                activeBreakId = bRow.id;
            }
        }

        const response = {
            attendanceId: attendanceId,
            checkInTime: row.check_in_time ? new Date(row.check_in_time).toISOString() : null,
            accumulatedBreakSeconds: accumulatedBreakSeconds,
            isLate: row.is_late || false,
        };

        if (activeBreakId) {
            res.json({
                ...response,
                status: 'ON_BREAK',
                breakId: activeBreakId,
                currentBreakStart: currentBreakStart,
            });
        } else {
            res.json({
                ...response,
                status: 'CHECKED_IN',
                lat: row.location_lat,
                long: row.location_long,
            });
        }

    } catch (err) {
        console.error('GetStatus Error:', err);
        res.status(500).json({ error: 'Internal server error: ' + err.message });
    }
});

// Get History Handler
router.get('/history/:employeeId', async (req, res) => {
    const { employeeId } = req.params;
    console.log(`Fetching attendance history for employee PK ID: ${employeeId}`);

    try {
        const result = await pool.query(
            `SELECT a.id, a.check_in_time as "checkInTime", a.check_out_time as "checkOutTime", 
                    a.location_lat as "latitude", a.location_long as "longitude", 
                    a.attendance_date::text as "date", a.work_hours as "workHours", 
                    a.is_late as "isLate", a.is_early_checkout as "isEarly",
                    COALESCE((
                        SELECT SUM(EXTRACT(EPOCH FROM (break_end - break_start)))
                        FROM attendance_breaks 
                        WHERE attendance_id = a.id AND break_end IS NOT NULL
                    ), 0) as "breakSeconds"
             FROM attendance a 
             WHERE a.employee_id = $1 
             ORDER BY a.attendance_date DESC, a.check_in_time DESC 
             LIMIT 30`,
            [employeeId]
        );

        console.log(`Found ${result.rows.length} attendance records for employee ${employeeId}`);

        // Format dates to ISO strings with safety checks
        const history = result.rows.map(row => {
            return {
                ...row,
                checkInTime: row.checkInTime ? new Date(row.checkInTime).toISOString() : null,
                checkOutTime: row.checkOutTime ? new Date(row.checkOutTime).toISOString() : null,
                date: row.date, // already a string from DB (YYYY-MM-DD)
                latitude: row.latitude ? parseFloat(row.latitude) : null,
                longitude: row.longitude ? parseFloat(row.longitude) : null,
                workHours: row.workHours ? parseFloat(row.workHours) : null,
                breakSeconds: row.breakSeconds ? parseFloat(row.breakSeconds) : 0,
                id: parseInt(row.id)
            };
        });

        res.json(history);

    } catch (err) {
        console.error('GetHistory Error for employeeId ' + employeeId + ':', err);
        res.status(500).json({ error: 'Internal server error: ' + err.message });
    }
});

// Get Staff Today Attendance (Admin/Manager)
router.get('/staff-today', async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT e.first_name, e.last_name, a.check_in_time, a.check_out_time, 
                    a.location_lat, a.location_long, r.role_name 
             FROM employees e 
             LEFT JOIN attendance a ON e.id = a.employee_id AND a.attendance_date = CURRENT_DATE 
             JOIN roles r ON e.role_id = r.id 
             ORDER BY e.first_name ASC`
        );

        const staffAttendance = result.rows.map(row => ({
            name: `${row.first_name} ${row.last_name}`,
            checkIn: row.check_in_time ? new Date(row.check_in_time).toISOString() : null,
            checkOut: row.check_out_time ? new Date(row.check_out_time).toISOString() : null,
            lat: row.location_lat ? parseFloat(row.location_lat) : null,
            long: row.location_long ? parseFloat(row.location_long) : null,
            role: row.role_name,
            status: row.check_in_time === null ? 'ABSENT' : (row.check_out_time === null ? 'PRESENT' : 'COMPLETED'),
        }));

        res.json(staffAttendance);

    } catch (err) {
        console.error('StaffTodayAttendance Error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Start Break Handler
router.post('/break/start', async (req, res) => {
    const { attendanceId } = req.body;

    if (!attendanceId) {
        return res.status(400).json({ error: 'attendanceId is required' });
    }

    try {
        const result = await pool.query(
            'INSERT INTO attendance_breaks (attendance_id, break_start) VALUES (\$1, CURRENT_TIMESTAMP) RETURNING id',
            [attendanceId]
        );
        res.json({ message: 'Break started', breakId: result.rows[0].id });
    } catch (err) {
        console.error('StartBreak Error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// End Break Handler
router.post('/break/end', async (req, res) => {
    const { breakId } = req.body;

    if (!breakId) {
        return res.status(400).json({ error: 'breakId is required' });
    }

    try {
        await pool.query(
            'UPDATE attendance_breaks SET break_end = CURRENT_TIMESTAMP WHERE id = \$1',
            [breakId]
        );
        res.json({ message: 'Break ended successfully' });
    } catch (err) {
        console.error('EndBreak Error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

export default router;

