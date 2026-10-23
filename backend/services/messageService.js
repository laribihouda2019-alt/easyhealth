const db = require('../config/db');

//Service to handle message-related operations implementation uses the messages table directly
 

async function sendMessage({ senderId, recipientId, appointmentId, messageType, content, isFromAi, metadata }) {
    const { rows } = await db.query(
        `INSERT INTO public.messages
      (sender_id, recipient_id, appointment_id, message_type, content, is_from_ai, metadata)
     VALUES ($1, $2, $3, $4, $5, $6, $7)
     RETURNING *`,
        [senderId, recipientId, appointmentId, messageType || 'text', content, isFromAi || false, metadata]
    );
    return rows[0];
}

async function getConversation(userA, userB) {
    const { rows } = await db.query(
        `SELECT m.*, sender.full_name as sender_name, recipient.full_name as recipient_name
     FROM public.messages m
     LEFT JOIN profiles sender ON m.sender_id = sender.id
     LEFT JOIN profiles recipient ON m.recipient_id = recipient.id
     WHERE (sender_id = $1 AND recipient_id = $2)
        OR (sender_id = $2 AND recipient_id = $1)
     ORDER BY sent_at ASC`,
        [userA, userB]
    );
    return rows;
}

async function getUserMessages(userId) {
    const { rows } = await db.query(
        `SELECT m.*, other.full_name as other_user_name
     FROM public.messages m
     JOIN profiles other ON (m.sender_id = other.id OR m.recipient_id = other.id)
     WHERE (sender_id = $1 OR recipient_id = $1)
       AND other.id != $1
     ORDER BY sent_at DESC`,
        [userId]
    );
    return rows;
}

async function getUnreadMessages(userId) {
    const { rows } = await db.query(
        `SELECT * FROM public.messages
     WHERE recipient_id = $1 AND read_at IS NULL
     ORDER BY sent_at DESC`,
        [userId]
    );
    return rows;
}

async function markAsRead(messageId, userId) {
    const { rows } = await db.query(
        `UPDATE public.messages
     SET read_at = NOW()
     WHERE id = $1 AND recipient_id = $2
     RETURNING *`,
        [messageId, userId]
    );
    return rows[0];
}

async function markConversationAsRead(userId, otherUserId) {
    await db.query(
        `UPDATE public.messages
     SET read_at = NOW()
     WHERE recipient_id = $1 AND sender_id = $2 AND read_at IS NULL`,
        [userId, otherUserId]
    );
}

async function getAppointmentMessages(appointmentId) {
    const { rows } = await db.query(
        `SELECT * FROM public.messages
     WHERE appointment_id = $1
     ORDER BY sent_at ASC`,
        [appointmentId]
    );
    return rows;
}

async function deleteMessage(messageId, userId) {
    const { rows } = await db.query(
        `DELETE FROM public.messages
     WHERE id = $1 AND (sender_id = $2 OR recipient_id = $2)
     RETURNING *`,
        [messageId, userId]
    );
    return rows[0];
}

module.exports = {
    sendMessage,
    getConversation,
    getUserMessages,
    getUnreadMessages,
    markAsRead,
    markConversationAsRead,
    getAppointmentMessages,
    deleteMessage,
};

