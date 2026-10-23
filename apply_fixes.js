const db = require('./backend/config/db');

async function applyFixes() {
    try {
        console.log('--- Adding metadata to medication_schedules ---');
        await db.query(`ALTER TABLE public.medication_schedules ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}'`);

        console.log('--- Creating anonymized_diagnoses ---');
        await db.query(`
      CREATE TABLE IF NOT EXISTS public.anonymized_diagnoses (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        pseudo_id TEXT NOT NULL,
        age_range TEXT,
        gender TEXT,
        country TEXT,
        city TEXT,
        primary_condition TEXT NOT NULL,
        symptoms JSONB DEFAULT '[]',
        outcome TEXT,
        source TEXT,
        metadata JSONB DEFAULT '{}',
        created_at TIMESTAMPTZ DEFAULT NOW()
      )
    `);

        // Insert some mock data into anonymized_diagnoses so statistics screen doesn't stay empty
        console.log('--- Seeding mock diagnoses ---');
        await db.query(`
      INSERT INTO public.anonymized_diagnoses (pseudo_id, age_range, primary_condition, created_at)
      SELECT 
        gen_random_uuid()::text, 
        (ARRAY['0-18', '19-35', '36-60', '60+'])[floor(random() * 4 + 1)],
        (ARRAY['Grippe', 'Diabète', 'Hypertension', 'Asthme', 'Allergies'])[floor(random() * 5 + 1)],
        NOW() - (random() * interval '30 days')
      FROM generate_series(1, 50)
      ON CONFLICT DO NOTHING;
    `);

        console.log('--- Database Fixes Applied Successfully ---');
        process.exit(0);
    } catch (err) {
        console.error('Migration Error:', err);
        process.exit(1);
    }
}

applyFixes();
