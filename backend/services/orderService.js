const db = require('../config/db');

//MEDICATION ORDERS
 
async function createMedicationOrder({ patientId, pharmacyId, items, totalAmount, deliveryAddress, prescriptionUrl, paymentMethod }) {
    const { rows } = await db.query(
        `INSERT INTO public.medication_orders 
        (patient_id, pharmacy_id, items, total_amount, delivery_address, prescription_url, payment_method)
        VALUES ($1, $2, $3, $4, $5, $6, $7)
        RETURNING *`,
        [patientId, pharmacyId, JSON.stringify(items), totalAmount, deliveryAddress, prescriptionUrl, paymentMethod]
    );
    return rows[0];
}

async function getPatientMedicationOrders(patientId) {
    const { rows } = await db.query(
        `SELECT o.*, p.full_name as pharmacy_name, p.address as pharmacy_address
         FROM medication_orders o
         JOIN profiles p ON o.pharmacy_id = p.id
         WHERE o.patient_id = $1
         ORDER BY o.created_at DESC`,
        [patientId]
    );
    return rows;
}

async function getPharmacyOrders(pharmacyId) {
    const { rows } = await db.query(
        `SELECT o.*, p.full_name as patient_name, p.address as patient_profile_address
         FROM medication_orders o
         JOIN profiles p ON o.patient_id = p.id
         WHERE o.pharmacy_id = $1
         ORDER BY o.created_at DESC`,
        [pharmacyId]
    );
    return rows;
}

async function updateMedicationOrderStatus(orderId, status) {
    const { rows } = await db.query(
        `UPDATE medication_orders SET status = $1, updated_at = NOW() WHERE id = $2 RETURNING *`,
        [status, orderId]
    );
    return rows[0];
}

//LAB REQUESTS
 
async function createLabRequest({ patientId, labId, testType, amount, paymentMethod, scheduledAt }) {
    const { rows } = await db.query(
        `INSERT INTO public.lab_requests (patient_id, lab_id, test_type, amount, payment_method, scheduled_at)
         VALUES ($1, $2, $3, $4, $5, $6)
         RETURNING *`,
        [patientId, labId, testType, amount, paymentMethod, scheduledAt]
    );
    return rows[0];
}

async function getPatientLabRequests(patientId) {
    const { rows } = await db.query(
        `SELECT r.*, p.full_name as lab_name, p.address as lab_address
         FROM lab_requests r
         JOIN profiles p ON r.lab_id = p.id
         WHERE r.patient_id = $1
         ORDER BY r.created_at DESC`,
        [patientId]
    );
    return rows;
}

async function getLabRequests(labId) {
    const { rows } = await db.query(
        `SELECT r.*, p.full_name as patient_name
         FROM lab_requests r
         JOIN profiles p ON r.patient_id = p.id
         WHERE r.lab_id = $1
         ORDER BY r.created_at DESC`,
        [labId]
    );
    return rows;
}

async function updateLabRequestStatus(requestId, status, resultUrl = null) {
    let query = `UPDATE lab_requests SET status = $1, updated_at = NOW() `;
    let params = [status, requestId];
    
    if (resultUrl) {
        query += `, result_url = $3 `;
        params.push(resultUrl);
    }
    
    query += `WHERE id = $2 RETURNING *`;
    
    const { rows } = await db.query(query, params);
    return rows[0];
}

module.exports = {
    createMedicationOrder,
    getPatientMedicationOrders,
    getPharmacyOrders,
    updateMedicationOrderStatus,
    createLabRequest,
    getPatientLabRequests,
    getLabRequests,
    updateLabRequestStatus
};

