const db = require('./config/db');

async function checkSchema() {
    try {
        const res = await db.query(`
            SELECT conname, pg_get_constraintdef(oid) as def
            FROM pg_constraint
            WHERE conrelid = 'medication_orders'::regclass AND contype = 'c';
        `);
        console.log('Constraints for medication_orders:');
        res.rows.forEach(row => {
            console.log(`${row.conname}: ${row.def}`);
        });
        process.exit(0);
    } catch (err) {
        console.error('Error checking schema:', err);
        process.exit(1);
    }
}

checkSchema();
