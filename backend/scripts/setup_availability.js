const db = require('../config/db');

async function setupAvailability() {
  try {
    console.log('--- Setting up Availability Slots Table ---');

    //create availability_slots table
    await db.query(`
      CREATE TABLE IF NOT EXISTS public.availability_slots (
        id SERIAL PRIMARY KEY,
        doctor_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
        start_time TIMESTAMPTZ NOT NULL,
        end_time TIMESTAMPTZ NOT NULL,
        status VARCHAR(20) DEFAULT 'available' CHECK (status IN ('available', 'booked')),
        created_at TIMESTAMPTZ DEFAULT NOW(),
        updated_at TIMESTAMPTZ DEFAULT NOW()
      );
    `);
    console.log(' Table availability_slots created or already exists.');

    //add slot_id to real_appointments
    await db.query(`
      ALTER TABLE public.real_appointments 
      ADD COLUMN IF NOT EXISTS slot_id INTEGER REFERENCES public.availability_slots(id) ON DELETE SET NULL;
    `);
    console.log(' Column slot_id added to real_appointments or already exists.');

    console.log('--- Setup Complete ---');
  } catch (err) {
    console.error(' Error setting up availability:', err);
  } finally {
    process.exit();
  }
}

setupAvailability();
