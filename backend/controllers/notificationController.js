const db = require('../config/db');
const { sendToUser } = require('../services/socketService');

//internal helper for other controllers
async function createNotification(userId, title, message, type, relatedId = null) {
  try {
    const { rows } = await db.query(
      `INSERT INTO public.system_notifications (user_id, title, message, type, related_id)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING *`,
      [userId, title, message, type, relatedId]
    );

    //after inserting, send a socket event with the complete notification payload
    sendToUser(userId, 'new_system_notification', rows[0]);

    return rows[0];
  } catch (error) {
    console.error('Error creating notification:', error);
    return null;
  }
}

async function getMyNotifications(req, res, next) {
  try {
    const { rows } = await db.query(
      `SELECT * FROM public.system_notifications 
       WHERE user_id = $1 
       ORDER BY created_at DESC 
       LIMIT 50`,
      [req.user.id]
    );
    res.json({ success: true, data: rows });
  } catch (err) {
    next(err);
  }
}

async function markAsRead(req, res, next) {
  try {
    const { id } = req.params;
    const { rows } = await db.query(
      `UPDATE public.system_notifications 
       SET is_read = true 
       WHERE id = $1 AND user_id = $2 
       RETURNING *`,
      [id, req.user.id]
    );
    res.json({ success: true, data: rows[0] });
  } catch (err) {
    next(err);
  }
}

async function markAllAsRead(req, res, next) {
  try {
    await db.query(
      `UPDATE public.system_notifications 
       SET is_read = true 
       WHERE user_id = $1`,
      [req.user.id]
    );
    res.json({ success: true });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  createNotification,
  getMyNotifications,
  markAsRead,
  markAllAsRead
};
