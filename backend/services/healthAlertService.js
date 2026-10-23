const db = require('../config/db');

async function createHealthAlert({ userId, alertType, title, body, sentByAi, isRead, metadata }) {
    const { rows } = await db.query(
        `INSERT INTO public.health_alerts (user_id, alert_type, title, body, sent_by_ai, is_read, metadata)
     VALUES ($1, $2, $3, $4, $5, $6, $7)
     RETURNING *`,
        [userId, alertType, title, body, sentByAi || false, isRead || false, metadata]
    );
    return rows[0];
}

async function getUserHealthAlerts(userId) {
    const { rows } = await db.query(
        `SELECT * FROM public.health_alerts WHERE user_id = $1 ORDER BY created_at DESC`,
        [userId]
    );
    return rows;
}

async function getUnreadHealthAlerts(userId) {
    const { rows } = await db.query(
        `SELECT * FROM public.health_alerts WHERE user_id = $1 AND is_read = false ORDER BY created_at DESC`,
        [userId]
    );
    return rows;
}

async function markAsRead(id, userId) {
    const { rows } = await db.query(
        `UPDATE public.health_alerts SET is_read = true, updated_at = NOW() 
     WHERE id = $1 AND user_id = $2 RETURNING *`,
        [id, userId]
    );
    return rows[0];
}

async function markAllAsRead(userId) {
    await db.query(
        `UPDATE public.health_alerts SET is_read = true, updated_at = NOW() WHERE user_id = $1`,
        [userId]
    );
}

async function deleteHealthAlert(id, userId) {
    await db.query(`DELETE FROM public.health_alerts WHERE id = $1 AND user_id = $2`, [id, userId]);
}

async function getAlertsByType(userId, alertType) {
    const { rows } = await db.query(
        `SELECT * FROM public.health_alerts WHERE user_id = $1 AND alert_type = $2 ORDER BY created_at DESC`,
        [userId, alertType]
    );
    return rows;
}

async function getAlertsByDateRange(userId, startDate, endDate) {
    const { rows } = await db.query(
        `SELECT * FROM public.health_alerts 
     WHERE user_id = $1 AND created_at BETWEEN $2 AND $3
     ORDER BY created_at DESC`,
        [userId, startDate, endDate]
    );
    return rows;
}

async function getAiGeneratedAlerts(userId) {
    const { rows } = await db.query(
        `SELECT * FROM public.health_alerts WHERE user_id = $1 AND sent_by_ai = true ORDER BY created_at DESC`,
        [userId]
    );
    return rows;
}

async function getHealthAlertStatistics(userId) {
    const { rows } = await db.query(
        `SELECT count(*) as total, count(case when not is_read then 1 end) as unread
     FROM public.health_alerts WHERE user_id = $1`,
        [userId]
    );
    return rows[0];
}

async function getAlertTypeStatistics() {
    const { rows } = await db.query(
        `SELECT alert_type, count(*) as count FROM public.health_alerts GROUP BY alert_type ORDER BY count DESC`
    );
    return rows;
}

module.exports = {
    createHealthAlert,
    getUserHealthAlerts,
    getUnreadHealthAlerts,
    markAsRead,
    markAllAsRead,
    deleteHealthAlert,
    getAlertsByType,
    getAlertsByDateRange,
    getAiGeneratedAlerts,
    getHealthAlertStatistics,
    getAlertTypeStatistics,
};

