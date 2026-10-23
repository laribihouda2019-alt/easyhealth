const db = require('../config/db');

async function run() {
  try {
    console.log('Creating system_notifications table...');
    await db.query(`
      CREATE TABLE IF NOT EXISTS public.system_notifications (
        id SERIAL PRIMARY KEY,
        user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
        title VARCHAR(255) NOT NULL,
        message TEXT NOT NULL,
        type VARCHAR(50) NOT NULL,
        related_id VARCHAR(100),
        is_read BOOLEAN DEFAULT false,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      );
      
      CREATE INDEX IF NOT EXISTS idx_sys_notif_user_id ON public.system_notifications(user_id);
    `);
    console.log('Successfully created system_notifications table.');
    process.exit(0);
  } catch (error) {
    console.error('Error creating table:', error);
    process.exit(1);
  }
}

run();
