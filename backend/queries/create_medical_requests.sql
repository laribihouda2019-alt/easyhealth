-- Create medical_requests table for Social Security medical approval workflow
CREATE TABLE IF NOT EXISTS public.medical_requests (
    id SERIAL PRIMARY KEY,
    patient_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    request_type VARCHAR(50) NOT NULL, -- 'medicaments', 'prise_en_charge', 'appareillage'
    description TEXT,
    prescription_url TEXT,
    supporting_docs_url TEXT[], -- Array of URLs for scans, lab results, etc.
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    controller_id UUID REFERENCES public.profiles(id),
    controller_comment TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for patient performance
CREATE INDEX IF NOT EXISTS idx_medical_requests_patient ON public.medical_requests(patient_id);
-- Index for controller performance
CREATE INDEX IF NOT EXISTS idx_medical_requests_status ON public.medical_requests(status);
