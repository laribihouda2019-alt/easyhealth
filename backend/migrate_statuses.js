const db = require('./config/db');

async function migrate() {
    try {
        console.log('Starting migration...');
        await db.query(`ALTER TABLE real_appointments DROP CONSTRAINT IF EXISTS real_appointments_status_check`);
        await db.query(`ALTER TABLE real_appointments ADD CONSTRAINT real_appointments_status_check CHECK (status IN ('pending', 'confirmed', 'completed', 'cancelled', 'no_show', 'accepted', 'rejected'))`);
        console.log('Migration successful: accepted and rejected statuses added.');
        process.exit(0);
    } catch (err) {
        console.error('Migration failed:', err);
        process.exit(1);
    }
}

migrate();
