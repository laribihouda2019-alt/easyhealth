const { query } = require('./backend/config/db');

async function check() {
    try {
        const tables = ['medication_schedules', 'messages', 'real_appointments', 'medication_reminders'];
        for (const table of tables) {
            const res = await query('SELECT column_name, data_type FROM information_schema.columns WHERE table_name = $1', [table]);
            console.log(`\nColumns in ${table}:`);
            res.rows.forEach(r => console.log(`- ${r.column_name} (${r.data_type})`));
        }
    } catch (e) {
        console.error(e);
    } finally {
        process.exit();
    }
}

check();
