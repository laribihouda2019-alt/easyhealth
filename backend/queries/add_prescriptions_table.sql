CREATE TABLE IF NOT EXISTS public.prescriptions (
    id SERIAL PRIMARY KEY,
    doctor_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    patient_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    appointment_id INTEGER,
    medications JSONB NOT NULL,
    prescription_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    verification_code VARCHAR(255) UNIQUE NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS logo_url VARCHAR(255);
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS specialty VARCHAR(255);
