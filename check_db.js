const db = require('./backend/config/db');
async function check() {
    try {
        const apps = await db.query('SELECT * FROM real_appointments ORDER BY created_at DESC LIMIT 5');
        console.log("=== APPOINTMENTS ===");
        console.log(JSON.stringify(apps.rows, null, 2));

        const pQuery = `
          SELECT ra.id, ra.doctor_id, ra.patient_id, p1.full_name as patient_name, p2.full_name as doctor_name
          FROM real_appointments ra
          LEFT JOIN profiles p1 ON ra.patient_id = p1.id
          LEFT JOIN profiles p2 ON ra.doctor_id = p2.id
          ORDER BY ra.created_at DESC LIMIT 5
        `;
        const joins = await db.query(pQuery);
        console.log("\n=== APPOINTMENTS WITH JOINS ===");
        console.log(JSON.stringify(joins.rows, null, 2));
    } catch (e) {
        console.error(e);
    } finally {
        process.exit();
    }
}
check();
