import express from 'express';
import pool from '../config/db.js';
import notificationService from '../services/notificationService.js';

// Auto-migration: Ensure calendar-related columns and task_assignments table exist
(async () => {
    try {
        // 1. Add new columns to tasks
        await pool.query(`
            ALTER TABLE tasks 
            ADD COLUMN IF NOT EXISTS task_type VARCHAR(20) DEFAULT 'TASK',
            ADD COLUMN IF NOT EXISTS start_time TIME,
            ADD COLUMN IF NOT EXISTS meeting_link TEXT,
            ADD COLUMN IF NOT EXISTS github_url TEXT
        `);

        // 2. Create task_assignments table
        await pool.query(`
            CREATE TABLE IF NOT EXISTS task_assignments (
                id SERIAL PRIMARY KEY,
                task_id INTEGER REFERENCES tasks(id) ON DELETE CASCADE,
                employee_id INTEGER REFERENCES employees(id),
                UNIQUE(task_id, employee_id)
            )
        `);

        // 3. Migrate existing data from tasks.assigned_to to task_assignments
        const tasksWithAssignees = await pool.query('SELECT id, assigned_to FROM tasks WHERE assigned_to IS NOT NULL');
        for (const row of tasksWithAssignees.rows) {
            await pool.query(
                'INSERT INTO task_assignments (task_id, employee_id) VALUES (\$1, \$2) ON CONFLICT DO NOTHING',
                [row.id, row.assigned_to]
            );
        }

        console.log('Task schema and assignments updated successfully.');
    } catch (err) {
        console.error('Error during task multi-assignee migration:', err);
    }
})();

const router = express.Router();

// Get Tasks By Employee
router.get('/assigned/:employeeId', async (req, res) => {
    const { employeeId } = req.params;

    try {
        const result = await pool.query(
            `SELECT t.id, t.title, t.description, t.status, t.deadline as "due_date", 
                    t.task_type as "task_type", t.start_time as "start_time", t.meeting_link as "meeting_link",
                    t.github_url as "github_url",
                    t.created_at as "created_at",
                    string_agg(DISTINCT e.first_name || ' ' || e.last_name, ', ') as "assignee_names",
                    array_agg(DISTINCT ta2.employee_id) FILTER (WHERE ta2.employee_id IS NOT NULL) as "assignee_ids"
             FROM tasks t
             LEFT JOIN task_assignments ta2 ON t.id = ta2.task_id
             LEFT JOIN employees e ON ta2.employee_id = e.id
             WHERE 
                EXISTS (SELECT 1 FROM task_assignments ta WHERE ta.task_id = t.id AND ta.employee_id = $1)
                OR t.assigned_to = $1
                OR t.assigned_by = $1
             GROUP BY t.id
             ORDER BY t.created_at DESC`,
            [employeeId]
        );

        const tasks = result.rows.map(row => ({
            ...row,
            due_date: row.due_date ? new Date(row.due_date).toISOString() : null,
            created_at: row.created_at ? new Date(row.created_at).toISOString() : new Date().toISOString()
        }));

        res.json(tasks);
    } catch (err) {
        console.error('TaskController GetTasks Error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});


// Create Task
router.post('/create', async (req, res) => {
    const { title, description, assigned_to, department_id, status, due_date, task_type, start_time, meeting_link, github_url, assigned_by } = req.body;
    console.log(`DEBUG: Creating task with data:`, req.body);

    const client = await pool.connect();
    try {
        await client.query('BEGIN');

        // Insert task
        const taskResult = await client.query(
            'INSERT INTO tasks (title, description, assigned_to, department_id, status, deadline, task_type, start_time, meeting_link, github_url, assigned_by) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11) RETURNING id',
            [title, description, Array.isArray(assigned_to) ? assigned_to[0] : (assigned_to || null), department_id, status || 'PENDING', due_date, task_type || 'TASK', start_time || null, meeting_link || null, github_url || null, assigned_by || null]
        );
        
        const taskId = taskResult.rows[0].id;

        // Handle multiple assignees
        if (Array.isArray(assigned_to)) {
            for (const employeeId of assigned_to) {
                await client.query(
                    'INSERT INTO task_assignments (task_id, employee_id) VALUES (\$1, \$2) ON CONFLICT DO NOTHING',
                    [taskId, employeeId]
                );
            }
        } else if (assigned_to) {
            await client.query(
                'INSERT INTO task_assignments (task_id, employee_id) VALUES (\$1, \$2) ON CONFLICT DO NOTHING',
                [taskId, assigned_to]
            );
        }

        await client.query('COMMIT');

        // --- Post-Commit: Send Notifications ---
        try {
            const assigneeIds = Array.isArray(assigned_to) ? assigned_to : (assigned_to ? [assigned_to] : []);
            if (assigneeIds.length > 0) {
                const userRes = await pool.query('SELECT user_id FROM employees WHERE id = ANY($1)', [assigneeIds]);
                const userIds = userRes.rows.map(r => r.user_id);
                
                await notificationService.sendToMultiple(
                    userIds,
                    'New Task Assigned',
                    `You have been assigned a new task: ${title}`,
                    'TASK'
                );
            }
        } catch (notifyErr) {
            console.error('Notification Error (Task Create):', notifyErr);
        }

        res.json({ message: 'Task created successfully', taskId });
    } catch (err) {
        await client.query('ROLLBACK');
        console.error('TaskController CreateTask Error:', err);
        res.status(500).json({ error: 'Internal server error' });
    } finally {
        client.release();
    }
});

// Update Task Status
router.post('/update-status', async (req, res) => {
    const { id, status } = req.body;

    try {
        await pool.query(
            'UPDATE tasks SET status = $1 WHERE id = $2',
            [status, id]
        );

        // --- Send Notification if Completed ---
        if (status === 'COMPLETED' || status === 'DONE') {
            try {
                const taskInfo = await pool.query(
                    'SELECT title, assigned_by FROM tasks WHERE id = $1',
                    [id]
                );
                if (taskInfo.rows.length > 0 && taskInfo.rows[0].assigned_by) {
                    const assignerId = taskInfo.rows[0].assigned_by;
                    const title = taskInfo.rows[0].title;
                    
                    const userRes = await pool.query('SELECT user_id FROM employees WHERE id = $1', [assignerId]);
                    if (userRes.rows.length > 0) {
                        await notificationService.send(
                            userRes.rows[0].user_id,
                            'Task Completed',
                            `Task "${title}" has been marked as completed.`,
                            'TASK'
                        );
                    }
                }
            } catch (notifyErr) {
                console.error('Notification Error (Task Update):', notifyErr);
            }
        }

        res.json({ message: 'Task status updated successfully' });
    } catch (err) {
        console.error('TaskController UpdateStatus Error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Get All Tasks (Admin)
router.get('/all', async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT t.id, t.title, t.description, t.department_id, t.github_url,
                    t.status, t.deadline as "due_date", t.created_at,
                    t.task_type as "task_type", t.start_time as "start_time", t.meeting_link as "meeting_link",
                    d.department_name,
                    string_agg(e.first_name || ' ' || e.last_name, ', ') as "assignee_names",
                    array_agg(e.id) as "assignee_ids"
             FROM tasks t
             LEFT JOIN task_assignments ta ON t.id = ta.task_id
             LEFT JOIN employees e ON ta.employee_id = e.id
             LEFT JOIN departments d ON t.department_id = d.id
             GROUP BY t.id, d.department_name
             ORDER BY t.created_at DESC`
        );

        const tasks = result.rows.map(row => ({
            ...row,
            assignee_name: row.assignee_names || (row.department_name ? `Dept: \${row.department_name}` : 'Global'),
            due_date: row.due_date ? new Date(row.due_date).toISOString() : null,
            created_at: row.created_at ? new Date(row.created_at).toISOString() : null
        }));

        res.json(tasks);
    } catch (err) {
        console.error('TaskController GetAll Error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

export default router;

