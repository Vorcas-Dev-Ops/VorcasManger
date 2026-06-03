import express from 'express';
import pool from '../config/db.js';

const router = express.Router();

// Get All Departments
router.get('/', async (req, res) => {
    try {
        const result = await pool.query('SELECT id, department_name as name, description FROM departments ORDER BY department_name ASC');
        res.json(result.rows);
    } catch (err) {
        console.error('DepartmentController GetAll Error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Create Department
router.post('/', async (req, res) => {
    const { name, description } = req.body;
    try {
        await pool.query('INSERT INTO departments (department_name, description) VALUES (\$1, \$2)', [name || 'New Department', description || '']);
        res.json({ message: 'Department created' });
    } catch (err) {
        console.error('DepartmentController Create Error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Update Department
router.put('/:id', async (req, res) => {
    const { id } = req.params;
    const { name, description } = req.body;
    try {
        await pool.query('UPDATE departments SET department_name = \$1, description = \$2 WHERE id = \$3', [name || 'Updated Department', description || '', id]);
        res.json({ message: 'Department updated' });
    } catch (err) {
        console.error('DepartmentController Update Error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Delete Department
router.delete('/:id', async (req, res) => {
    const { id } = req.params;
    try {
        await pool.query('DELETE FROM departments WHERE id = \$1', [id]);
        res.json({ message: 'Department deleted' });
    } catch (err) {
        console.error('DepartmentController Delete Error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

export default router;

