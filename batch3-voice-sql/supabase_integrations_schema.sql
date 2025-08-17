-- Integration credentials table for storing OAuth and API key credentials securely
CREATE TABLE IF NOT EXISTS integration_credentials (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    provider TEXT NOT NULL,
    encrypted_data TEXT NOT NULL, -- Encrypted JSON containing access tokens, refresh tokens, or API keys
    account_id TEXT, -- External account/project ID
    account_name TEXT, -- Human-readable account name
    provider_type TEXT NOT NULL CHECK (provider_type IN ('oauth', 'api_key')),
    is_active BOOLEAN DEFAULT TRUE,
    expires_at TIMESTAMP WITH TIME ZONE, -- For OAuth tokens
    last_synced_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, provider)
);

-- Integration sync logs for tracking data fetch operations
CREATE TABLE IF NOT EXISTS integration_sync_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    provider TEXT NOT NULL,
    sync_type TEXT NOT NULL, -- 'manual', 'scheduled', 'webhook'
    status TEXT NOT NULL CHECK (status IN ('started', 'completed', 'failed', 'partial')),
    records_fetched INTEGER DEFAULT 0,
    records_processed INTEGER DEFAULT 0,
    error_message TEXT,
    sync_duration_ms INTEGER,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    metadata JSONB -- Additional sync details
);

-- Platform audience data aggregated from integrations
CREATE TABLE IF NOT EXISTS platform_audience_data (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    platform TEXT NOT NULL,
    data_type TEXT NOT NULL, -- 'demographics', 'interests', 'behaviors', 'performance'
    segment_name TEXT,
    data JSONB NOT NULL,
    audience_size BIGINT,
    confidence_score DECIMAL(5,2), -- 0.00 to 100.00
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, platform, data_type, segment_name)
);

-- Maya Copilot context cache for storing transformed audience insights
CREATE TABLE IF NOT EXISTS maya_audience_context (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    context_data JSONB NOT NULL, -- Full AudienceContext object
    summary_text TEXT, -- Natural language summary for Copilot
    data_sources TEXT[], -- Array of connected platforms used
    total_reach BIGINT,
    confidence_score DECIMAL(5,2),
    expires_at TIMESTAMP WITH TIME ZONE, -- Context TTL (e.g., 1 hour)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for faster context retrieval
CREATE INDEX IF NOT EXISTS idx_maya_context_user_expires ON maya_audience_context(user_id, expires_at);

-- Cross-platform audience overlaps for deduplication insights
CREATE TABLE IF NOT EXISTS audience_overlaps (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    platform_a TEXT NOT NULL,
    platform_b TEXT NOT NULL,
    overlap_percentage DECIMAL(5,2),
    shared_characteristics JSONB,
    sample_size INTEGER,
    calculated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, platform_a, platform_b)
);

-- Integration webhooks for real-time data updates
CREATE TABLE IF NOT EXISTS integration_webhooks (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    provider TEXT NOT NULL,
    webhook_url TEXT NOT NULL,
    secret_key TEXT, -- For webhook verification
    event_types TEXT[], -- Array of subscribed events
    is_active BOOLEAN DEFAULT TRUE,
    last_triggered TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, provider)
);

-- Performance metrics aggregated across platforms
CREATE TABLE IF NOT EXISTS cross_platform_metrics (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    metric_name TEXT NOT NULL, -- 'cpc', 'ctr', 'roas', 'conversion_rate'
    platform TEXT NOT NULL,
    segment_name TEXT,
    metric_value DECIMAL(10,4),
    currency TEXT, -- For cost metrics
    time_period TEXT NOT NULL, -- '7d', '30d', '90d'
    measurement_date DATE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    INDEX(user_id, metric_name, time_period, measurement_date)
);

-- Enable Row Level Security
ALTER TABLE integration_credentials ENABLE ROW LEVEL SECURITY;
ALTER TABLE integration_sync_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE platform_audience_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE maya_audience_context ENABLE ROW LEVEL SECURITY;
ALTER TABLE audience_overlaps ENABLE ROW LEVEL SECURITY;
ALTER TABLE integration_webhooks ENABLE ROW LEVEL SECURITY;
ALTER TABLE cross_platform_metrics ENABLE ROW LEVEL SECURITY;

-- Row Level Security Policies
CREATE POLICY "Users can only access their own integration credentials" ON integration_credentials
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can only access their own sync logs" ON integration_sync_logs
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can only access their own platform data" ON platform_audience_data
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can only access their own context" ON maya_audience_context
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can only access their own overlaps" ON audience_overlaps
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can only access their own webhooks" ON integration_webhooks
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can only access their own metrics" ON cross_platform_metrics
    FOR ALL USING (auth.uid() = user_id);

-- Functions for data management
CREATE OR REPLACE FUNCTION cleanup_expired_context()
RETURNS void AS $$
BEGIN
    DELETE FROM maya_audience_context 
    WHERE expires_at < NOW();
END;
$$ LANGUAGE plpgsql;

-- Function to update audience context
CREATE OR REPLACE FUNCTION update_audience_context(
    p_user_id UUID,
    p_context_data JSONB,
    p_summary_text TEXT,
    p_data_sources TEXT[],
    p_total_reach BIGINT,
    p_confidence_score DECIMAL(5,2),
    p_ttl_hours INTEGER DEFAULT 1
)
RETURNS UUID AS $$
DECLARE
    context_id UUID;
BEGIN
    INSERT INTO maya_audience_context (
        user_id,
        context_data,
        summary_text,
        data_sources,
        total_reach,
        confidence_score,
        expires_at
    ) VALUES (
        p_user_id,
        p_context_data,
        p_summary_text,
        p_data_sources,
        p_total_reach,
        p_confidence_score,
        NOW() + INTERVAL '1 hour' * p_ttl_hours
    )
    ON CONFLICT (user_id) 
    DO UPDATE SET
        context_data = EXCLUDED.context_data,
        summary_text = EXCLUDED.summary_text,
        data_sources = EXCLUDED.data_sources,
        total_reach = EXCLUDED.total_reach,
        confidence_score = EXCLUDED.confidence_score,
        expires_at = EXCLUDED.expires_at,
        updated_at = NOW()
    RETURNING id INTO context_id;
    
    RETURN context_id;
END;
$$ LANGUAGE plpgsql;

-- Function to log integration sync
CREATE OR REPLACE FUNCTION log_integration_sync(
    p_user_id UUID,
    p_provider TEXT,
    p_sync_type TEXT,
    p_status TEXT,
    p_records_fetched INTEGER DEFAULT 0,
    p_records_processed INTEGER DEFAULT 0,
    p_error_message TEXT DEFAULT NULL,
    p_sync_duration_ms INTEGER DEFAULT NULL,
    p_metadata JSONB DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    log_id UUID;
BEGIN
    INSERT INTO integration_sync_logs (
        user_id,
        provider,
        sync_type,
        status,
        records_fetched,
        records_processed,
        error_message,
        sync_duration_ms,
        completed_at,
        metadata
    ) VALUES (
        p_user_id,
        p_provider,
        p_sync_type,
        p_status,
        p_records_fetched,
        p_records_processed,
        p_error_message,
        p_sync_duration_ms,
        CASE WHEN p_status IN ('completed', 'failed', 'partial') THEN NOW() ELSE NULL END,
        p_metadata
    )
    RETURNING id INTO log_id;
    
    RETURN log_id;
END;
$$ LANGUAGE plpgsql;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_integration_credentials_user_provider ON integration_credentials(user_id, provider);
CREATE INDEX IF NOT EXISTS idx_integration_credentials_expires ON integration_credentials(expires_at) WHERE expires_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_sync_logs_user_provider ON integration_sync_logs(user_id, provider, started_at);
CREATE INDEX IF NOT EXISTS idx_platform_data_user_platform ON platform_audience_data(user_id, platform, data_type);
CREATE INDEX IF NOT EXISTS idx_audience_overlaps_user ON audience_overlaps(user_id, platform_a, platform_b);
CREATE INDEX IF NOT EXISTS idx_webhooks_provider_active ON integration_webhooks(provider, is_active);

-- Create a view for active integrations summary
CREATE OR REPLACE VIEW user_integrations_summary AS
SELECT 
    ic.user_id,
    ic.provider,
    ic.provider_type,
    ic.is_active,
    ic.account_name,
    ic.last_synced_at,
    ic.created_at,
    CASE 
        WHEN ic.expires_at IS NOT NULL AND ic.expires_at < NOW() THEN 'expired'
        WHEN ic.is_active THEN 'active'
        ELSE 'inactive'
    END as status,
    COALESCE(recent_sync.last_sync_status, 'never') as last_sync_status
FROM integration_credentials ic
LEFT JOIN (
    SELECT DISTINCT ON (user_id, provider) 
        user_id, 
        provider, 
        status as last_sync_status
    FROM integration_sync_logs 
    ORDER BY user_id, provider, started_at DESC
) recent_sync ON ic.user_id = recent_sync.user_id AND ic.provider = recent_sync.provider;

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO authenticated;