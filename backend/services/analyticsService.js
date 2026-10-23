const db = require('../config/db');

async function createAnonymizedDiagnosis(data) {
    const { pseudoId, ageRange, gender, country, city, primaryCondition, symptoms, outcome, source, metadata } = data;
    const { rows } = await db.query(
        `INSERT INTO public.anonymized_diagnoses 
      (pseudo_id, age_range, gender, country, city, primary_condition, symptoms, outcome, source, metadata)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
     RETURNING *`,
        [pseudoId, ageRange, gender, country, city, primaryCondition, symptoms, outcome, source, metadata]
    );
    return rows[0];
}

async function getAllAnonymizedDiagnoses() {
    const { rows } = await db.query(`SELECT * FROM public.anonymized_diagnoses ORDER BY created_at DESC LIMIT 100`);
    return rows;
}

async function getDiagnosesByCondition(condition) {
    const { rows } = await db.query(
        `SELECT * FROM public.anonymized_diagnoses WHERE primary_condition ILIKE $1`,
        [`%${condition}%`]
    );
    return rows;
}

async function getDiagnosesByAgeRange(ageRange) {
    const { rows } = await db.query(`SELECT * FROM public.anonymized_diagnoses WHERE age_range = $1`, [ageRange]);
    return rows;
}

async function getDiagnosesByLocation(country, city) {
    let query = `SELECT * FROM public.anonymized_diagnoses WHERE 1=1`;
    const params = [];
    if (country) {
        params.push(country);
        query += ` AND country = $${params.length}`;
    }
    if (city) {
        params.push(city);
        query += ` AND city = $${params.length}`;
    }
    const { rows } = await db.query(query, params);
    return rows;
}

async function getDiagnosesBySymptoms(symptom) {
    const { rows } = await db.query(
        `SELECT * FROM public.anonymized_diagnoses WHERE symptoms ? $1`,
        [symptom]
    );
    return rows;
}

async function getDiagnosesBySource(source) {
    const { rows } = await db.query(`SELECT * FROM public.anonymized_diagnoses WHERE source = $1`, [source]);
    return rows;
}

async function getConditionStatistics() {
    const { rows } = await db.query(
        `SELECT primary_condition as condition, count(*) as count FROM public.anonymized_diagnoses GROUP BY primary_condition ORDER BY count DESC`
    );
    return rows;
}

async function getAgeConditionStatistics() {
    const { rows } = await db.query(
        `SELECT age_range, count(*) as count 
     FROM public.anonymized_diagnoses GROUP BY age_range ORDER BY age_range`
    );
    return rows;
}

async function getCommonSymptoms() {
    //this is complex with jsonb, stubbing for now
    return [];
}

async function getRegionalStatistics() {
    const { rows } = await db.query(
        `SELECT country, city, count(*) as count FROM public.anonymized_diagnoses GROUP BY country, city ORDER BY count DESC`
    );
    return rows;
}

async function getOutcomeStatistics() {
    const { rows } = await db.query(
        `SELECT outcome, count(*) as count FROM public.anonymized_diagnoses GROUP BY outcome ORDER BY count DESC`
    );
    return rows;
}

async function getDashboardSummary(userId, role) {
    if (role === 'doctor') {
        const appointmentsCount = await db.query(
            `SELECT 
                COUNT(*) as total,
                COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending,
                COUNT(CASE WHEN status = 'confirmed' AND DATE(scheduled_at) = CURRENT_DATE THEN 1 END) as today
             FROM public.real_appointments WHERE doctor_id = $1`,
            [userId]
        );

        const unreadMessages = await db.query(
            `SELECT COUNT(*) as count FROM public.messages WHERE recipient_id = $1 AND read_at IS NULL`,
            [userId]
        );

        return {
            consultationsCount: appointmentsCount.rows[0].total,
            pendingAppointmentsCount: appointmentsCount.rows[0].pending,
            todaysConsultationsCount: appointmentsCount.rows[0].today,
            unreadMessagesCount: unreadMessages.rows[0].count
        };
    } else if (role === 'patient') {
        const appointmentsCount = await db.query(
            `SELECT 
                COUNT(*) as upcoming
             FROM public.real_appointments 
             WHERE patient_id = $1 AND scheduled_at >= NOW() AND status IN ('pending', 'confirmed')`,
            [userId]
        );

        const unreadMessages = await db.query(
            `SELECT COUNT(*) as count FROM public.messages WHERE recipient_id = $1 AND read_at IS NULL`,
            [userId]
        );

        const medicationsCount = await db.query(
            `SELECT COUNT(*) as count FROM public.medication_schedules 
             WHERE patient_id = $1 AND is_active = true AND (end_date IS NULL OR end_date >= CURRENT_DATE)`,
            [userId]
        );

        return {
            upcomingAppointmentsCount: parseInt(appointmentsCount.rows[0].upcoming) || 0,
            unreadMessagesCount: parseInt(unreadMessages.rows[0].count) || 0,
            activeMedicationsCount: parseInt(medicationsCount.rows[0].count) || 0
        };
    } else if (role === 'pharmacy' || role === 'lab') {
        const unreadMessages = await db.query(
            `SELECT COUNT(*) as count FROM public.messages WHERE recipient_id = $1 AND read_at IS NULL`,
            [userId]
        );

        //for pharmacies: pending deliveries; For labs: pending analyses (could be expanded)
        return {
            unreadMessagesCount: parseInt(unreadMessages.rows[0].count) || 0,
            activityCount: 0, // Placeholder for role-specific tasks
            pendingCount: 0
        };
    } else if (role === 'admin') {
        const userStats = await db.query(
            `SELECT 
                COUNT(*) as total,
                COUNT(CASE WHEN role = 'doctor' THEN 1 END) as doctors,
                COUNT(CASE WHEN role = 'pharmacy' THEN 1 END) as pharmacies,
                COUNT(CASE WHEN is_approved = false THEN 1 END) as pending
             FROM public.profiles`
        );

        return {
            totalUsersCount: parseInt(userStats.rows[0].total) || 0,
            pendingVerificationsCount: parseInt(userStats.rows[0].pending) || 0,
            doctorsCount: parseInt(userStats.rows[0].doctors) || 0,
            pharmaciesCount: parseInt(userStats.rows[0].pharmacies) || 0
        };
    }
    return {};
}

module.exports = {
    createAnonymizedDiagnosis,
    getAllAnonymizedDiagnoses,
    getDiagnosesByCondition,
    getDiagnosesByAgeRange,
    getDiagnosesByLocation,
    getDiagnosesBySymptoms,
    getDiagnosesBySource,
    getConditionStatistics,
    getAgeConditionStatistics,
    getCommonSymptoms,
    getRegionalStatistics,
    getOutcomeStatistics,
    getDashboardSummary
};

