const db = require('./backend/config/db');

async function migrate() {
  try {
    console.log("Starting Database Schema Migration...");
    console.log("Checking and adding columns to public.profiles table...");

    const sqlQuery = `
      ALTER TABLE public.profiles 
      ADD COLUMN IF NOT EXISTS password TEXT,
      ADD COLUMN IF NOT EXISTS reset_token TEXT,
      ADD COLUMN IF NOT EXISTS reset_token_expires TIMESTAMP;
    `;

    await db.query(sqlQuery);
    console.log("Schema migration completed successfully!");
  } catch (error) {
    console.error("Migration failed with error:", error);
  } finally {
    process.exit();
  }
}

migrate();
