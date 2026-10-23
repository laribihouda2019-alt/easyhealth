const db = require('./config/db');

async function migrate() {
    try {
        console.log('Starting migration for medication_orders status...');
        
        //Drop old constraint
        await db.query(`ALTER TABLE medication_orders DROP CONSTRAINT IF EXISTS medication_orders_status_check`);
        
        //Add new constraint with additional statuses
        await db.query(`ALTER TABLE medication_orders ADD CONSTRAINT medication_orders_status_check CHECK (status IN ('pending', 'accepted', 'prepared', 'shipping', 'delivered', 'cancelled', 'paid', 'payment_failed'))`);
        
        console.log('Migration successful: "accepted", "prepared", and "payment_failed" statuses added to medication_orders.');
        process.exit(0);
    } catch (err) {
        console.error('Migration failed:', err);
        process.exit(1);
    }
}

migrate();
