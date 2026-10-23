const db = require('./backend/config/db');

async function alterDB() {
    try {
        console.log("Adding columns to real_appointments...");
        await db.query(`ALTER TABLE real_appointments ADD COLUMN IF NOT EXISTS patient_name VARCHAR(255);`);
        await db.query(`ALTER TABLE real_appointments ADD COLUMN IF NOT EXISTS doctor_name VARCHAR(255);`);
        console.log("Database altered successfully.");
    } catch (e) {
        console.error("Error altering DB:", e);
    } finally {
        process.exit();
    }
}

alterDB();
