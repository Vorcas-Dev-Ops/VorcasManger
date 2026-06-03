import express from 'express';
import pool from '../config/db.js';
import notificationService from '../services/notificationService.js';

const router = express.Router();

// Get All Events
router.get('/', async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT id, title, description, event_date as "eventDate", 
                    event_type as "eventType", created_by as "createdBy", 
                    created_at as "createdAt" 
             FROM company_events ORDER BY event_date ASC`
        );

        const events = result.rows.map(row => ({
            ...row,
            eventDate: row.eventDate ? row.eventDate.toISOString() : null,
            createdAt: row.createdAt ? row.createdAt.toISOString() : null
        }));

        res.json(events);
    } catch (err) {
        console.error('EventController GetAll Error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Create Event
router.post('/', async (req, res) => {
    const { title, description, eventDate, eventType, createdBy } = req.body;

    if (!title || !eventDate || !eventType || !createdBy) {
        return res.status(400).json({ error: 'Missing required fields' });
    }

    try {
        await pool.query(
            'INSERT INTO company_events (title, description, event_date, event_type, created_by) VALUES ($1, $2, $3, $4, $5)',
            [title, description, eventDate, eventType, createdBy]
        );

        // --- Post-Insert: Notify All Users ---
        try {
            const usersRes = await pool.query('SELECT id FROM users WHERE is_active = true');
            const userIds = usersRes.rows.map(r => r.id);
            await notificationService.sendToMultiple(
                userIds,
                'New Event Scheduled',
                `A new ${eventType}: "${title}" has been scheduled for ${new Date(eventDate).toLocaleDateString()}.`,
                'MEETING'
            );
        } catch (notifyErr) {
            console.error('Notification Error (Event Create):', notifyErr);
        }

        res.json({ message: 'Event created successfully' });
    } catch (err) {
        console.error('EventController Create Error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

export default router;

