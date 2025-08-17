-- Create user_tokens table for OAuth tokens
CREATE TABLE IF NOT EXISTS user_tokens (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    platform TEXT NOT NULL,
    access_token TEXT NOT NULL,
    refresh_token TEXT,
    expires_at TIMESTAMP WITH TIME ZONE,
    scope TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, platform)
);

-- Create campaign_metrics table for storing campaign data
CREATE TABLE IF NOT EXISTS campaign_metrics (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    campaign_id TEXT NOT NULL,
    campaign_name TEXT NOT NULL,
    platform TEXT NOT NULL CHECK (platform IN ('google_ads', 'meta', 'youtube', 'dooh', 'ctv', 'marketplace')),
    status TEXT DEFAULT 'active',
    spend DECIMAL(10,2) DEFAULT 0,
    revenue DECIMAL(10,2) DEFAULT 0,
    impressions INTEGER DEFAULT 0,
    clicks INTEGER DEFAULT 0,
    conversions INTEGER DEFAULT 0,
    ctr DECIMAL(5,4) DEFAULT 0,
    cpc DECIMAL(10,2) DEFAULT 0,
    roas DECIMAL(10,2) DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, campaign_id, platform)
);

-- Create user_purchases table for marketplace transactions
CREATE TABLE IF NOT EXISTS user_purchases (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    item_id TEXT NOT NULL,
    item_type TEXT NOT NULL CHECK (item_type IN ('template', 'autopilot', 'segment', 'integration')),
    price DECIMAL(10,2) NOT NULL,
    details JSONB,
    purchased_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create automation_logs table for Maya's actions
CREATE TABLE IF NOT EXISTS automation_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    action TEXT NOT NULL,
    details JSONB NOT NULL,
    confirmed_by_user BOOLEAN DEFAULT FALSE,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create user_audience_insights table for storing audience data
CREATE TABLE IF NOT EXISTS user_audience_insights (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    platform TEXT NOT NULL,
    segment_name TEXT NOT NULL,
    segment_type TEXT,
    description TEXT,
    size BIGINT,
    data JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    date DATE NOT NULL DEFAULT CURRENT_DATE, -- New date column for historical data
    UNIQUE(user_id, platform, segment_name, date) -- Updated unique constraint
);

-- Create user_profiles table for storing user profile data
CREATE TABLE IF NOT EXISTS user_profiles (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT,
    company TEXT,
    bio TEXT,
    avatar_url TEXT,
    role TEXT DEFAULT 'user',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create brands table for marketplace brands
CREATE TABLE IF NOT EXISTS brands (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    logo_url TEXT,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security on all tables
ALTER TABLE user_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE campaign_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_purchases ENABLE ROW LEVEL SECURITY;
ALTER TABLE automation_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_audience_insights ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE brands ENABLE ROW LEVEL SECURITY;

-- Create a function to check if the current user is an admin
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  is_admin_user BOOLEAN;
BEGIN
  SELECT role = 'admin'
  INTO is_admin_user
  FROM user_profiles
  WHERE user_id = auth.uid(); -- auth.uid() returns UUID, no need for ::text cast here

  RETURN COALESCE(is_admin_user, FALSE);
END;
$$;

-- Grant execute permission on the function to authenticated users
GRANT EXECUTE ON FUNCTION is_admin() TO authenticated;

-- RLS Policies for user_profiles
-- 1. Admins can see all user profiles
DROP POLICY IF EXISTS "Admins can view all user profiles" ON user_profiles;
CREATE POLICY "Admins can view all user profiles" ON user_profiles
    FOR SELECT TO authenticated USING (is_admin());

-- 2. Users can view their own profile
DROP POLICY IF EXISTS "Users can view their own profile" ON user_profiles;
CREATE POLICY "Users can view their own profile" ON user_profiles
    FOR SELECT TO authenticated USING (user_id = auth.uid());

-- 3. Users can update their own profile
DROP POLICY IF EXISTS "Users can update their own profile" ON user_profiles;
CREATE POLICY "Users can update their own profile" ON user_profiles
    FOR UPDATE TO authenticated USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- 4. Admins can update any user profile (including roles)
DROP POLICY IF EXISTS "Admins can update any user profile" ON user_profiles;
CREATE POLICY "Admins can update any user profile" ON user_profiles
    FOR UPDATE TO authenticated USING (is_admin());

-- RLS Policies for brands
-- Allow authenticated users to read brands
DROP POLICY IF EXISTS "Allow authenticated users to read brands" ON brands;
CREATE POLICY "Allow authenticated users to read brands" ON brands
    FOR SELECT TO authenticated USING (true);

-- Allow admins to create brands
DROP POLICY IF EXISTS "Allow admins to create brands" ON brands;
CREATE POLICY "Allow admins to create brands" ON brands
    FOR INSERT TO authenticated WITH CHECK (is_admin());

-- Allow admins to update brands
DROP POLICY IF EXISTS "Allow admins to update brands" ON brands;
CREATE POLICY "Allow admins to update brands" ON brands
    FOR UPDATE TO authenticated USING (is_admin());

-- Allow admins to delete brands
DROP POLICY IF EXISTS "Allow admins to delete brands" ON brands;
CREATE POLICY "Allow admins to delete brands" ON brands
    FOR DELETE TO authenticated USING (is_admin());

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_user_tokens_user_id ON user_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_user_tokens_platform ON user_tokens(user_id, platform);
CREATE INDEX IF NOT EXISTS idx_campaign_metrics_user_id ON campaign_metrics(user_id);
CREATE INDEX IF NOT EXISTS idx_campaign_metrics_platform ON campaign_metrics(user_id, platform);
CREATE INDEX IF NOT EXISTS idx_campaign_metrics_updated_at ON campaign_metrics(updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_purchases_user_id ON user_purchases(user_id);
CREATE INDEX IF NOT EXISTS idx_automation_logs_user_id ON automation_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_automation_logs_timestamp ON automation_logs(user_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_user_audience_insights_user_id ON user_audience_insights(user_id);
CREATE INDEX IF NOT EXISTS idx_user_audience_insights_platform ON user_audience_insights(user_id, platform);
CREATE INDEX IF NOT EXISTS idx_user_audience_insights_date ON user_audience_insights(user_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_brands_name ON brands(name);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
DROP TRIGGER IF EXISTS update_user_tokens_updated_at ON user_tokens;
CREATE TRIGGER update_user_tokens_updated_at BEFORE UPDATE ON user_tokens
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_campaign_metrics_updated_at ON campaign_metrics;
CREATE TRIGGER update_campaign_metrics_updated_at BEFORE UPDATE ON campaign_metrics
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_user_audience_insights_updated_at ON user_audience_insights;
CREATE TRIGGER update_user_audience_insights_updated_at BEFORE UPDATE ON user_audience_insights
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON user_profiles;
CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON user_profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_brands_updated_at ON brands;
CREATE TRIGGER update_brands_updated_at BEFORE UPDATE ON brands
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert sample data for testing (optional)
-- This would be removed in production
INSERT INTO campaign_metrics (user_id, campaign_id, campaign_name, platform, spend, revenue, impressions, clicks, conversions) VALUES
('00000000-0000-0000-0000-000000000000', 'camp-001', 'google_ads', 'google_ads', 1500.00, 4500.00, 50000, 2500, 150),
('00000000-0000-0000-0000-000000000000', 'camp-002', 'Brand Awareness', 'meta', 800.00, 2400.00, 75000, 1800, 90),
('00000000-0000-0000-0000-000000000000', 'camp-003', 'Product Launch', 'ctv', 2000.00, 8000.00, 100000, 3200, 200);

-- Insert sample data for user_audience_insights (for demonstration)
-- IMPORTANT: Replace 'YOUR_TEST_USER_ID_HERE' with the actual user_id from your Firebase/NextAuth setup
INSERT INTO user_audience_insights (user_id, platform, segment_name, segment_type, description, size, data, date) VALUES
('00000000-0000-0000-0000-000000000000', 'google_ads', 'In-Market: Software Development', 'In-Market', 'Users actively researching software development products and services.', 1500000, '{"interest_id": "123", "category": "Software"}', CURRENT_DATE),
('00000000-0000-0000-0000-000000000000', 'google_ads', 'Custom Affinity: Tech Enthusiasts', 'Custom Affinity', 'Audience interested in technology news, gadgets, and innovation.', 2000000, '{"affinity_id": "456", "keywords": ["tech news", "gadgets"]}', CURRENT_DATE),
('00000000-0000-0000-0000-000000000000', 'meta', 'Custom Audience: Website Visitors (Last 30 Days)', 'Custom Audience', 'Users who visited the website in the last 30 days.', 850000, '{"source": "website", "lookback_window": 30}', CURRENT_DATE),
('00000000-0000-0000-0000-000000000000', 'meta', 'Lookalike Audience: High-Value Customers', 'Lookalike', 'Audience similar to your top 10% of high-value customers.', 1200000, '{"source_audience_id": "789", "similarity": "1%"}', CURRENT_DATE),
('00000000-0000-0000-0000-000000000000', 'google_analytics', 'GA4 Users: Age 25-34', 'Age Bracket', 'Active users on your site aged 25-34.', 300000, '{"age_group": "25-34"}', CURRENT_DATE),
('00000000-0000-0000-0000-000000000000', 'google_analytics', 'GA4 Users: Gender Female', 'Gender', 'Active female users on your site.', 400000, '{"gender": "female"}', CURRENT_DATE);

-- Function to set current user context (for RLS)
CREATE OR REPLACE FUNCTION set_current_user_id(user_id UUID)
RETURNS VOID AS $$
BEGIN
    PERFORM set_config('app.current_user_id', user_id::text, true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;
GRANT EXECUTE ON FUNCTION set_current_user_id(UUID) TO anon, authenticated;


-- =================================================================
-- Supabase Storage Setup for Brand Logos
-- =================================================================
-- The following steps need to be performed in your Supabase project dashboard.

-- 1. Create a new Storage Bucket:
--    - Go to the "Storage" section in your Supabase dashboard.
--    - Click on "New bucket".
--    - Enter "brand_logos" as the bucket name.
--    - Toggle "Public bucket" to ON.
--    - Click "Save".

-- 2. Set up Row Level Security (RLS) for the bucket:
--    - After creating the bucket, click on it and select "Policies".
--    - Create a new policy for SELECT access:
--      - Policy Name: "Allow public read access"
--      - Allowed operation: "SELECT"
--      - Target roles: "anon", "authenticated"
--      - USING expression: "true"
--    - Create a new policy for INSERT access:
--      - Policy Name: "Allow admins to upload"
--      - Allowed operation: "INSERT"
--      - Target roles: "authenticated"
--      - WITH CHECK expression: "is_admin()"
--    - Create a new policy for UPDATE access:
--      - Policy Name: "Allow admins to update"
--      - Allowed operation: "UPDATE"
--      - Target roles: "authenticated"
--      - USING expression: "is_admin()"
--    - Create a new policy for DELETE access:
--      - Policy Name: "Allow admins to delete"
--      - Allowed operation: "DELETE"
--      - Target roles: "authenticated"
--      - USING expression: "is_admin()"
-- =================================================================

-- Create user_workflows table for storing automation workflow definitions
CREATE TABLE IF NOT EXISTS user_workflows (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    status TEXT DEFAULT 'inactive' CHECK (status IN ('active', 'inactive', 'draft')),
    trigger_type TEXT NOT NULL CHECK (trigger_type IN ('schedule', 'performance', 'webhook', 'manual')),
    schedule_details JSONB, -- e.g., { "frequency": "daily", "time": "09:00" }
    performance_thresholds JSONB, -- e.g., { "metric": "CTR", "operator": "<", "value": 0.02 }
    last_run_at TIMESTAMP WITH TIME ZONE,
    execution_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security on user_workflows table
ALTER TABLE user_workflows ENABLE ROW LEVEL SECURITY;

-- RLS Policies for user_workflows
-- 1. Users can view their own workflows
DROP POLICY IF EXISTS "Users can view their own workflows" ON user_workflows;
CREATE POLICY "Users can view their own workflows" ON user_workflows
    FOR SELECT TO authenticated USING (user_id = auth.uid());

-- 2. Users can create their own workflows
DROP POLICY IF EXISTS "Users can create their own workflows" ON user_workflows;
CREATE POLICY "Users can create their own workflows" ON user_workflows
    FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());

-- 3. Users can update their own workflows
DROP POLICY IF EXISTS "Users can update their own workflows" ON user_workflows;
CREATE POLICY "Users can update their own workflows" ON user_workflows
    FOR UPDATE TO authenticated USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- 4. Users can delete their own workflows
DROP POLICY IF EXISTS "Users can delete their own workflows" ON user_workflows;
CREATE POLICY "Users can delete their own workflows" ON user_workflows
    FOR DELETE TO authenticated USING (user_id = auth.uid());

-- 5. Admins can view all workflows
DROP POLICY IF EXISTS "Admins can view all workflows" ON user_workflows;
CREATE POLICY "Admins can view all workflows" ON user_workflows
    FOR SELECT TO authenticated USING (is_admin());

-- 6. Admins can update any workflow
DROP POLICY IF EXISTS "Admins can update any workflow" ON user_workflows;
CREATE POLICY "Admins can update any workflow" ON user_workflows
    FOR UPDATE TO authenticated USING (is_admin());

-- 7. Admins can delete any workflow
DROP POLICY IF EXISTS "Admins can delete any workflow" ON user_workflows;
CREATE POLICY "Admins can delete any workflow" ON user_workflows
    FOR DELETE TO authenticated USING (is_admin());

-- Add index for user_id for better performance
CREATE INDEX IF NOT EXISTS idx_user_workflows_user_id ON user_workflows(user_id);

-- Add trigger to update updated_at timestamp
DROP TRIGGER IF EXISTS update_user_workflows_updated_at ON user_workflows;
CREATE TRIGGER update_user_workflows_updated_at BEFORE UPDATE ON user_workflows
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();