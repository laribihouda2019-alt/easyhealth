const db = require('./backend/config/db');
const fs = require('fs');
const path = require('path');

async function runSQL() {
  try {
    const sqlPath = path.join(__dirname, 'backend', 'queries', 'create_medical_requests.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');
    
    console.log('Running SQL migration...');
    await db.query(sql);
    console.log('Migration successful: medical_requests table created.');
    process.exit(0);
  } catch (err) {
    console.error('Migration failed:', err);
    process.exit(1);
  }
}

runSQL();
