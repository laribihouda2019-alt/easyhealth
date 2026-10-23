const db = require('./backend/config/db');
async function cleanData() {
    try {
        console.log("Deleting appointments where patient_id == doctor_id...");
        const res = await db.query(`DELETE FROM real_appointments WHERE patient_id = doctor_id RETURNING id`);
        console.log(`Deleted ${res.rowCount} self-booked appointments.`);
    } catch (e) {
        console.error(e);
    } finally {
        process.exit();
    }
}
cleanData();
