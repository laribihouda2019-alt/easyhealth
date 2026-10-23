-- ========================================================
-- EasyHealth - PGAdmin Migration Script (V3 Updates)
-- Purpose: Adds Lab Services, Pharmacy Items, Test Results
-- ========================================================

-- 1. Doctor Profile Updates
-- Ensure consultation_fee exists (if not already present)
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS consultation_fee DECIMAL(10,2);

-- 2. Laboratory Services (Pricing Table)
CREATE TABLE IF NOT EXISTS public.lab_services (
    id SERIAL PRIMARY KEY,
    lab_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    test_name VARCHAR(255) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    is_available BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_lab_services_lab_id ON public.lab_services(lab_id);

-- 3. Pharmacy Items (Medications & Prices)
CREATE TABLE IF NOT EXISTS public.pharmacy_items (
    id SERIAL PRIMARY KEY,
    pharmacy_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    med_name VARCHAR(255) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    is_available BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_pharmacy_items_pharmacy_id ON public.pharmacy_items(pharmacy_id);

-- 4. Test Results (Linked to lab_requests)
-- This assumes public.lab_requests table already exists
CREATE TABLE IF NOT EXISTS public.test_results (
    id SERIAL PRIMARY KEY,
    request_id UUID REFERENCES public.lab_requests(id) ON DELETE CASCADE,
    file_path TEXT NOT NULL,
    status VARCHAR(50) DEFAULT 'Pending' CHECK (status IN ('Pending', 'Ready')),
    uploaded_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Note regarding Messages Table:
-- The messages table should already have `sender_id UUID REFERENCES public.profiles(id)`
-- and `recipient_id UUID REFERENCES public.profiles(id)`. 
-- Since `profiles` stores Patients, Doctors, Labs, and Pharmacies, 
-- the foreign keys are automatically polymorphic for all user roles.
