-- ========================================================
-- EasyHealth - Social Security (Sécurité Sociale) Migration
-- ========================================================

-- 1. Create the Social Security Requests table
CREATE TABLE IF NOT EXISTS public.social_security_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    status VARCHAR(50) DEFAULT 'En cours' CHECK (status IN ('En cours', 'Acceptée', 'Rejetée')),
    document_urls TEXT[] NOT NULL, -- Array of file paths/URLs
    notes TEXT,
    rejection_reason TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Add index for faster lookups by patient
CREATE INDEX IF NOT EXISTS idx_ss_requests_patient_id ON public.social_security_requests(patient_id);

-- 3. Add index for status filtering (useful for the agent dashboard)
CREATE INDEX IF NOT EXISTS idx_ss_requests_status ON public.social_security_requests(status);

-- 4. Function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 5. Trigger to automatically update updated_at
CREATE TRIGGER update_ss_requests_modtime
    BEFORE UPDATE ON public.social_security_requests
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
