const db = require('./config/db');

async function migrate() {
    try {
        console.log('Starting enum migration...');
        //Postgres ALTER TYPE ADD VALUE cannot run inside a transaction
        await db.query(`ALTER TYPE appointment_status ADD VALUE IF NOT EXISTS 'accepted'`);
        console.log('Added accepted');
        await db.query(`ALTER TYPE appointment_status ADD VALUE IF NOT EXISTS 'rejected'`);
        console.log('Added rejected');

        console.log('Migration successful.');
        process.exit(0);
    } catch (err) {
        console.error('Migration failed:', err);
        process.exit(1);
    }
}

migrate();
