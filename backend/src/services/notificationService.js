import admin from 'firebase-admin';
import pool from '../config/db.js';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const serviceAccountPath = path.join(__dirname, '../config/serviceAccountKey.json');

let messaging;

// Initialize Firebase Admin
try {
  if (fs.existsSync(serviceAccountPath)) {
    const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
    messaging = admin.messaging();
    console.log('Firebase Admin initialized successfully.');
  } else {
    console.warn('Firebase Service Account Key missing. Push notifications will be logged to console only.');
  }
} catch (error) {
  console.error('Error initializing Firebase Admin:', error);
}

const notificationService = {
  /**
   * Send a push notification and save to history
   * @param {number} userId - The target user ID
   * @param {string} title - Notification title
   * @param {string} body - Notification body
   * @param {string} type - Notification type (TASK/MEETING/LEAVE)
   */
  send: async (userId, title, body, type = 'GENERAL') => {
    try {
      // 1. Save to Database History
      await pool.query(
        'INSERT INTO notifications (user_id, title, body, type) VALUES ($1, $2, $3, $4)',
        [userId, title, body, type]
      );

      // 2. Fetch User's FCM Token
      const userRes = await pool.query('SELECT fcm_token FROM users WHERE id = $1', [userId]);
      const token = userRes.rows[0]?.fcm_token;

      if (token && messaging) {
        const message = {
          notification: { title, body },
          token: token,
          data: { type }
        };

        await messaging.send(message);
        console.log(`Push notification sent to user ${userId}`);
      } else if (!token) {
        console.log(`User ${userId} has no registered FCM token. History saved.`);
      } else {
        console.log(`[STUB] Push alert for ${userId}: "${title}: ${body}"`);
      }
    } catch (error) {
      console.error('Error in NotificationService.send:', error);
    }
  },

  /**
   * Send notification to multiple users
   * @param {number[]} userIds - Array of target user IDs
   * @param {string} title 
   * @param {string} body 
   * @param {string} type 
   */
  sendToMultiple: async (userIds, title, body, type = 'GENERAL') => {
    for (const userId of userIds) {
      await notificationService.send(userId, title, body, type);
    }
  }
};

export default notificationService;
