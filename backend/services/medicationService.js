const db = require('../config/db');

async function createMedication({ userId, medicineName, dosage, frequency, startDate, endDate, reminderTimes, isActive, metadata }) {
    const { rows } = await db.query(
        `INSERT INTO public.medication_schedules 
      (patient_id, medicine_name, dosage, frequency, start_date, end_date, reminder_times, is_active, metadata)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
     RETURNING *`,
        [userId, medicineName, dosage, frequency, startDate, endDate, reminderTimes, isActive !== false, metadata]
    );
    return rows[0];
}

async function getUserMedications(userId, includeInactive) {
    const query = includeInactive
        ? `SELECT * FROM public.medication_schedules WHERE patient_id = $1 ORDER BY created_at DESC`
        : `SELECT * FROM public.medication_schedules WHERE patient_id = $1 AND is_active = true ORDER BY created_at DESC`;

    const { rows } = await db.query(query, [userId]);
    return rows;
}

async function getMedicationById(id) {
    const { rows } = await db.query(`SELECT * FROM public.medication_schedules WHERE id = $1`, [id]);
    return rows[0];
}

async function updateMedication(id, userId, data) {
    const { medicineName, dosage, frequency, startDate, endDate, reminderTimes, isActive, metadata } = data;
    const { rows } = await db.query(
        `UPDATE public.medication_schedules 
     SET medicine_name = $1, dosage = $2, frequency = $3, start_date = $4, end_date = $5, 
         reminder_times = $6, is_active = $7, metadata = $8, updated_at = NOW()
     WHERE id = $9 AND patient_id = $10
     RETURNING *`,
        [medicineName, dosage, frequency, startDate, endDate, reminderTimes, isActive, metadata, id, userId]
    );
    return rows[0];
}

async function deactivateMedication(id, userId) {
    const { rows } = await db.query(
        `UPDATE public.medication_schedules SET is_active = false, updated_at = NOW() 
     WHERE id = $1 AND patient_id = $2 RETURNING *`,
        [id, userId]
    );
    return rows[0];
}

async function getTodaysMedications(userId) {
    const { rows } = await db.query(
        `SELECT * FROM public.medication_schedules 
     WHERE patient_id = $1 AND is_active = true 
       AND CURRENT_DATE BETWEEN start_date AND COALESCE(end_date, '2099-12-31')`,
        [userId]
    );
    return rows;
}

async function getMedicationsDueAtTime(userId, time) {
    const { rows } = await db.query(
        `SELECT * FROM public.medication_schedules 
     WHERE patient_id = $1 AND is_active = true AND $2 = ANY(reminder_times)`,
        [userId, time]
    );
    return rows;
}

async function getMedicationsByDateRange(userId, startDate, endDate) {
    const { rows } = await db.query(
        `SELECT * FROM public.medication_schedules 
     WHERE patient_id = $1 AND (start_date, end_date) OVERLAPS ($2::date, $3::date)`,
        [userId, startDate, endDate]
    );
    return rows;
}

async function searchMedications(userId, query) {
    const { rows } = await db.query(
        `SELECT * FROM public.medication_schedules 
     WHERE patient_id = $1 AND medicine_name ILIKE $2`,
        [userId, `%${query}%`]
    );
    return rows;
}

async function getMedicationStatistics(userId) {
    const { rows } = await db.query(
        `SELECT count(*) as total, count(case when is_active then 1 end) as active
     FROM public.medication_schedules WHERE patient_id = $1`,
        [userId]
    );
    return rows[0];
}

module.exports = {
    createMedication,
    getUserMedications,
    getMedicationById,
    updateMedication,
    deactivateMedication,
    getTodaysMedications,
    getMedicationsDueAtTime,
    getMedicationsByDateRange,
    searchMedications,
    getMedicationStatistics,
};

