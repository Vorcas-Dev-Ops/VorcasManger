import express from 'express';
import pool from '../config/db.js';

const router = express.Router();
 
// Auto-migration: Ensure column names match application logic (message -> body)
(async () => {
  try {
    // Check if 'message' column exists and rename it to 'body'
    const checkColumn = await pool.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'notifications' AND column_name = 'message'
    `);
    
    if (checkColumn.rows.length > 0) {
      await pool.query('ALTER TABLE notifications RENAME COLUMN message TO body');
      console.log('Notification table migrated: message -> body');
    }
  } catch (err) {
    console.error('Error during notification migration:', err);
  }
})();

// Get notification history for a user
router.get('/:userId', async (req, res) => {
  const { userId } = req.params;

  try {
    const result = await pool.query(
      'SELECT id, title, body, type, is_read, created_at FROM notifications WHERE user_id = $1 ORDER BY created_at DESC LIMIT 50',
      [userId]
    );

    res.json(result.rows);
  } catch (err) {
    console.error('NotificationController GetHistory Error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Mark notification as read
router.post('/read/:notificationId', async (req, res) => {
  const { notificationId } = req.params;

  try {
    await pool.query(
      'UPDATE notifications SET is_read = true WHERE id = $1',
      [notificationId]
    );
    res.json({ message: 'Notification marked as read' });
  } catch (err) {
    console.error('NotificationController MarkRead Error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Mark all as read
router.post('/read-all/:userId', async (req, res) => {
  const { userId } = req.params;

  try {
    await pool.query(
      'UPDATE notifications SET is_read = true WHERE user_id = $1',
      [userId]
    );
    res.json({ message: 'All notifications marked as read' });
  } catch (err) {
    console.error('NotificationController MarkReadAll Error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;
