const db = require('../config/db');

async function createSymptomLog({ userId, symptoms, description, painLevel, metadata }) {
    const { rows } = await db.query(
        `INSERT INTO public.symptoms (user_id, symptoms, description, pain_level, metadata)
     VALUES ($1, $2, $3, $4, $5)
     RETURNING *`,
        [userId, symptoms, description, painLevel, metadata]
    );
    return rows[0];
}

async function getUserSymptoms(userId, limit, offset) {
    const { rows } = await db.query(
        `SELECT * FROM public.symptoms WHERE user_id = $1 ORDER BY created_at DESC LIMIT $2 OFFSET $3`,
        [userId, limit, offset]
    );
    return rows;
}

async function getSymptomById(id) {
    const { rows } = await db.query(`SELECT * FROM public.symptoms WHERE id = $1`, [id]);
    return rows[0];
}

async function updateSymptomLog(id, userId, { symptoms, description, painLevel, metadata }) {
    const { rows } = await db.query(
        `UPDATE public.symptoms 
     SET symptoms = $1, description = $2, pain_level = $3, metadata = $4, updated_at = NOW()
     WHERE id = $5 AND user_id = $6
     RETURNING *`,
        [symptoms, description, painLevel, metadata, id, userId]
    );
    return rows[0];
}

async function deleteSymptomLog(id, userId) {
    await db.query(`DELETE FROM public.symptoms WHERE id = $1 AND user_id = $2`, [id, userId]);
}

async function getSymptomsByDateRange(userId, startDate, endDate) {
    const { rows } = await db.query(
        `SELECT * FROM public.symptoms 
     WHERE user_id = $1 AND created_at BETWEEN $2 AND $3
     ORDER BY created_at DESC`,
        [userId, startDate, endDate]
    );
    return rows;
}

async function getRecentSymptoms(userId) {
    const { rows } = await db.query(
        `SELECT * FROM public.symptoms WHERE user_id = $1 ORDER BY created_at DESC LIMIT 5`,
        [userId]
    );
    return rows;
}

async function searchSymptoms(userId, query) {
    const { rows } = await db.query(
        `SELECT * FROM public.symptoms 
     WHERE user_id = $1 AND (symptoms ILIKE $2 OR description ILIKE $2)
     ORDER BY created_at DESC`,
        [userId, `%${query}%`]
    );
    return rows;
}

async function getSymptomStatistics(userId) {
    const { rows } = await db.query(
        `SELECT symptoms, count(*) as count 
     FROM public.symptoms 
     WHERE user_id = $1 
     GROUP BY symptoms 
     ORDER BY count DESC`,
        [userId]
    );
    return rows;
}

async function getCommonSymptoms() {
    const { rows } = await db.query(
        `SELECT symptoms, count(*) as count 
     FROM public.symptoms 
     GROUP BY symptoms 
     ORDER BY count DESC 
     LIMIT 10`
    );
    return rows;
}

module.exports = {
    createSymptomLog,
    getUserSymptoms,
    getSymptomById,
    updateSymptomLog,
    deleteSymptomLog,
    getSymptomsByDateRange,
    getRecentSymptoms,
    searchSymptoms,
    getSymptomStatistics,
    getCommonSymptoms,
};

