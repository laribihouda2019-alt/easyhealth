const db = require('../config/db');

/**
 * MEDICAL RECORDS
 */
async function createRecord({ patientId, title, category, fileUrl, notes }) {
    const { rows } = await db.query(
        `INSERT INTO public.medical_records (patient_id, title, category, file_url, notes)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING *`,
        [patientId, title, category, fileUrl, notes]
    );
    return rows[0];
}

async function getRecordsByPatient(patientId) {
    const { rows } = await db.query(
        `SELECT * FROM public.medical_records 
         WHERE patient_id = $1 
         ORDER BY created_at DESC`,
        [patientId]
    );
    return rows;
}

async function deleteRecord(recordId, patientId) {
    const { rows } = await db.query(
        `DELETE FROM public.medical_records 
         WHERE id = $1 AND patient_id = $2 
         RETURNING *`,
        [recordId, patientId]
    );
    return rows[0];
}

module.exports = {
    createRecord,
    getRecordsByPatient,
    deleteRecord
};

