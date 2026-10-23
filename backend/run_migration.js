const db = require('./config/db');
const fs = require('fs');
const path = require('path');

async function runMigration() {
    try {
        const sqlFile = process.argv[2] || 'queries/order_tables.sql';
        const sqlPath = path.join(__dirname, sqlFile);
        
        if (!fs.existsSync(sqlPath)) {
            console.error(`SQL file not found: ${sqlPath}`);
            process.exit(1);
        }

        const sql = fs.readFileSync(sqlPath, 'utf8');
        
        console.log(`Running migration: ${sqlFile}...`);
        await db.query(sql);
        console.log('Migration completed successfully!');
        process.exit(0);
    } catch (err) {
        console.error('Migration failed:', err);
        process.exit(1);
    }
}

runMigration();
