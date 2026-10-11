-- ==============================================================================
-- SUPABASE BACKEND SCHEMA FOR INSURANCE APP
-- ==============================================================================
-- Run this script in your Supabase SQL Editor:
-- https://supabase.com/dashboard/project/xpdtgngkkjihmconczuy/sql
-- ==============================================================================

-- 1. Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==============================================================================
-- 2. PROFILES TABLE (Linked to auth.users)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT,
    full_name TEXT,
    role TEXT DEFAULT 'agent',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Trigger to create profile automatically on auth signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1))
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ==============================================================================
-- 3. POLICIES TABLE (Customers, Vehicles & Policies)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.policies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    customer_name TEXT NOT NULL,
    care_of TEXT NOT NULL,
    phone TEXT,
    brand TEXT NOT NULL,
    model TEXT NOT NULL,
    year TEXT,
    registration TEXT NOT NULL,
    vehicle_note TEXT,
    insurance_provider TEXT NOT NULL,
    provider_code TEXT,
    policy_type TEXT NOT NULL,
    start_date TIMESTAMPTZ NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    start_date_string TEXT,
    expires_at_string TEXT,
    note TEXT,
    idv TEXT,
    status TEXT DEFAULT 'active',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes for lightning fast queries
CREATE INDEX IF NOT EXISTS idx_policies_expires_at ON public.policies (expires_at);
CREATE INDEX IF NOT EXISTS idx_policies_start_date ON public.policies (start_date);
CREATE INDEX IF NOT EXISTS idx_policies_registration ON public.policies (registration);
CREATE INDEX IF NOT EXISTS idx_policies_customer_name ON public.policies (customer_name);
CREATE INDEX IF NOT EXISTS idx_policies_user_id ON public.policies (user_id);

-- ==============================================================================
-- 4. RENEWALS TABLE (Policy Renewal History)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.renewals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    policy_id UUID REFERENCES public.policies(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    policy_number TEXT,
    customer_name TEXT,
    ncb_applied TEXT,
    had_claim_last_year BOOLEAN DEFAULT false,
    new_idv TEXT,
    coverage_type TEXT,
    od_premium NUMERIC,
    tp_premium NUMERIC,
    add_on_premium NUMERIC,
    ncb_discount NUMERIC,
    gst NUMERIC,
    total_premium NUMERIC,
    renewal_start_date TIMESTAMPTZ,
    payment_mode TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_renewals_policy_id ON public.renewals (policy_id);
CREATE INDEX IF NOT EXISTS idx_renewals_created_at ON public.renewals (created_at);

-- ==============================================================================
-- 5. CLAIMS TABLE (Insurance Claims)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.claims (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    policy_number TEXT NOT NULL,
    claim_type TEXT NOT NULL,
    incident_date TIMESTAMPTZ NOT NULL,
    incident_time TEXT,
    location TEXT NOT NULL,
    description TEXT,
    estimated_loss TEXT,
    fir_number TEXT,
    third_party_involved BOOLEAN DEFAULT false,
    injuries_reported BOOLEAN DEFAULT false,
    contact_phone TEXT,
    preferred_garage TEXT,
    documents JSONB DEFAULT '[]'::jsonb,
    status TEXT DEFAULT 'Pending',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_claims_policy_number ON public.claims (policy_number);
CREATE INDEX IF NOT EXISTS idx_claims_status ON public.claims (status);

-- ==============================================================================
-- 6. ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================
-- Enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.policies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.renewals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.claims ENABLE ROW LEVEL SECURITY;

-- Permissive policies for authenticated users and anon demo access
-- (Adjust to strict user_id = auth.uid() if you want multi-tenant data isolation)
CREATE POLICY "Allow read profiles" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Allow update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Policies table policies
CREATE POLICY "Allow select policies" ON public.policies FOR SELECT USING (true);
CREATE POLICY "Allow insert policies" ON public.policies FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow update policies" ON public.policies FOR UPDATE USING (true);
CREATE POLICY "Allow delete policies" ON public.policies FOR DELETE USING (true);

-- Renewals table policies
CREATE POLICY "Allow select renewals" ON public.renewals FOR SELECT USING (true);
CREATE POLICY "Allow insert renewals" ON public.renewals FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow update renewals" ON public.renewals FOR UPDATE USING (true);

-- Claims table policies
CREATE POLICY "Allow select claims" ON public.claims FOR SELECT USING (true);
CREATE POLICY "Allow insert claims" ON public.claims FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow update claims" ON public.claims FOR UPDATE USING (true);
CREATE POLICY "Allow delete claims" ON public.claims FOR DELETE USING (true);

-- ==============================================================================
-- 7. INITIAL SAMPLE DATA (Ready-to-use sample records)
-- ==============================================================================
INSERT INTO public.policies (
    customer_name,
    care_of,
    phone,
    brand,
    model,
    year,
    registration,
    vehicle_note,
    insurance_provider,
    provider_code,
    policy_type,
    start_date,
    expires_at,
    start_date_string,
    expires_at_string,
    note
) VALUES
(
    'Rahul Menon',
    'Suresh Menon',
    '9876543210',
    'Toyota',
    'Innova',
    '2022',
    'KL-07-AB-1234',
    'Own',
    'New India Insurance',
    'NI-4421',
    'Comprehensive',
    NOW() - INTERVAL '362 days',
    NOW() + INTERVAL '3 days',
    to_char(NOW() - INTERVAL '362 days', 'DD/MM/YYYY'),
    to_char(NOW() + INTERVAL '3 days', 'DD/MM/YYYY'),
    'Expires in 3 days. Customer prefers reminder call before renewal.'
),
(
    'Sara Thomas',
    'Thomas Mathew',
    '9876543211',
    'Maruti',
    'Swift',
    '2021',
    'KL-09-CD-4521',
    'Own',
    'National Insurance',
    'NAT-8812',
    'Third Party',
    NOW() - INTERVAL '353 days',
    NOW() + INTERVAL '12 days',
    to_char(NOW() - INTERVAL '353 days', 'DD/MM/YYYY'),
    to_char(NOW() + INTERVAL '12 days', 'DD/MM/YYYY'),
    'Upcoming renewal in 12 days.'
),
(
    'Anil Kumar',
    'Gopal Kumar',
    '9876543212',
    'Hyundai',
    'Creta',
    '2023',
    'KL-05-EF-7788',
    'Own',
    'IFFCO Tokio General Insurance',
    'IFF-2309',
    'Comprehensive',
    NOW() - INTERVAL '15 days',
    NOW() + INTERVAL '350 days',
    to_char(NOW() - INTERVAL '15 days', 'DD/MM/YYYY'),
    to_char(NOW() + INTERVAL '350 days', 'DD/MM/YYYY'),
    'Renewed recently. Active policy.'
),
(
    'Priya Nair',
    'Mohan Nair',
    '9876543213',
    'Honda',
    'City',
    '2020',
    'KL-11-GH-9012',
    'Lease',
    'Oriental Insurance',
    'ORI-1928',
    'Third Party',
    NOW() - INTERVAL '380 days',
    NOW() - INTERVAL '15 days',
    to_char(NOW() - INTERVAL '380 days', 'DD/MM/YYYY'),
    to_char(NOW() - INTERVAL '15 days', 'DD/MM/YYYY'),
    'Lapsed 15 days ago. Follow up required.'
),
(
    'Mohammed Riyas',
    'Abdulla',
    '9876543214',
    'Tata',
    'Nexon',
    '2022',
    'KL-10-XY-3344',
    'Own',
    'New India Insurance',
    'NI-7712',
    'Full Cover',
    NOW() - INTERVAL '364 days',
    NOW() + INTERVAL '1 day',
    to_char(NOW() - INTERVAL '364 days', 'DD/MM/YYYY'),
    to_char(NOW() + INTERVAL '1 day', 'DD/MM/YYYY'),
    'Urgent renewal tomorrow!'
)
ON CONFLICT DO NOTHING;
