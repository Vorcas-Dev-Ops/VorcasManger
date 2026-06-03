import express from 'express';
import pool from '../config/db.js';

const router = express.Router();

// Get Documents By Employee
router.get('/:employeeId', async (req, res) => {
    const { employeeId } = req.params;
    try {
        const result = await pool.query(
            `SELECT id, employee_id as "employee_id", title, file_url as "file_url", type, created_at as "created_at" 
             FROM documents WHERE employee_id = \$1 ORDER BY created_at DESC`,
            [employeeId]
        );
        
        const docs = result.rows.map(row => ({
            ...row,
            created_at: row.created_at ? row.created_at.toISOString() : null
        }));

        res.json(docs);
    } catch (err) {
        console.error('DocumentController GetByEmployee Error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Upload Document
router.post('/upload', async (req, res) => {
    const { employee_id, title, file_url, type } = req.body;
    try {
        await pool.query(
            'INSERT INTO documents (employee_id, title, file_url, type) VALUES (\$1, \$2, \$3, \$4)',
            [employee_id, title, file_url, type]
        );
        res.json({ message: 'Document uploaded successfully' });
    } catch (err) {
        console.error('DocumentController Upload Error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

export default router;

