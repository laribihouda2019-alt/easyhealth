-- ========================================================
-- EasyHealth - Public Health Trends
-- Table to store anonymous clinical observations
-- ========================================================

CREATE TABLE IF NOT EXISTS public.health_reports (
    id SERIAL PRIMARY KEY,
    region VARCHAR(100) NOT NULL, -- e.g., Oran, Senia, Bir El Djir
    symptom_summary TEXT NOT NULL,
    gender VARCHAR(20), -- Homme, Femme, Autre
    age_group VARCHAR(50), -- Enfant, Adolescent, Adulte, Senior
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_health_reports_region ON public.health_reports(region);
CREATE INDEX IF NOT EXISTS idx_health_reports_created_at ON public.health_reports(created_at);
