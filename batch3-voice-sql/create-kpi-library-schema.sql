-- KPI Library Schema for Enhanced Maya Intelligence
-- Integrates with existing schema architecture and patterns

-- Core KPI Library Table
CREATE TABLE IF NOT EXISTS public.kpi_library (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  display_name text NOT NULL,
  description text,
  category text NOT NULL CHECK (category = ANY (ARRAY[
    'performance'::text, 
    'financial'::text, 
    'audience'::text, 
    'operational'::text,
    'conversion'::text,
    'engagement'::text
  ])),
  
  -- Data source configuration
  data_source_table text, -- e.g., 'campaign_metrics', 'whatsapp_messages'
  data_source_column text, -- e.g., 'metrics_data->roas', 'COUNT(*)'
  calculation_type text DEFAULT 'direct'::text CHECK (calculation_type = ANY (ARRAY[
    'direct'::text,      -- Direct column value
    'calculated'::text,  -- Custom formula
    'aggregated'::text,  -- SUM, AVG, COUNT, etc.
    'derived'::text      -- Complex multi-table calculation
  ])),
  
  -- Formula for calculated KPIs
  formula text, -- e.g., 'SUM(revenue) / SUM(spend)', 'COUNT(*) WHERE direction = "inbound"'
  
  -- Platform requirements
  required_platforms text[] DEFAULT '{}'::text[], -- ['google_ads', 'whatsapp', 'meta_ads']
  supported_platforms text[] DEFAULT '{}'::text[], -- Platforms this KPI can work with
  
  -- Display configuration
  format_type text DEFAULT 'number'::text CHECK (format_type = ANY (ARRAY[
    'number'::text,
    'currency'::text,
    'percentage'::text,
    'duration'::text,
    'ratio'::text
  ])),
  decimal_places integer DEFAULT 2,
  prefix text, -- '$', '%', etc.
  suffix text,
  
  -- Chart configuration
  default_chart_type text DEFAULT 'line'::text CHECK (default_chart_type = ANY (ARRAY[
    'line'::text,
    'bar'::text,
    'pie'::text,
    'doughnut'::text,
    'area'::text,
    'gauge'::text
  ])),
  chart_color text DEFAULT '#4285f4'::text,
  
  -- AI insights configuration
  insights_enabled boolean DEFAULT true,
  benchmark_value numeric, -- Industry benchmark for comparison
  benchmark_source text,   -- Where the benchmark comes from
  target_direction text DEFAULT 'higher'::text CHECK (target_direction = ANY (ARRAY[
    'higher'::text,  -- Higher values are better (ROAS, Revenue)
    'lower'::text,   -- Lower values are better (CPC, Response Time)
    'optimal'::text  -- Specific range is optimal
  ])),
  optimal_range_min numeric,
  optimal_range_max numeric,
  
  -- Alert configuration
  alert_enabled boolean DEFAULT false,
  alert_threshold_high numeric,
  alert_threshold_low numeric,
  alert_change_percentage numeric, -- Alert if changes by X%
  
  -- System vs Custom KPIs
  is_system boolean DEFAULT true,
  created_by text, -- user_id for custom KPIs
  
  -- Usage and popularity
  usage_count integer DEFAULT 0,
  popularity_score numeric DEFAULT 0,
  
  -- Metadata
  tags text[] DEFAULT '{}'::text[],
  icon text, -- Emoji or icon identifier
  help_text text,
  example_value text,
  
  -- Lifecycle
  is_active boolean DEFAULT true,
  version text DEFAULT '1.0'::text,
  deprecated_at timestamp with time zone,
  replacement_kpi_id uuid, -- Points to newer version
  
  created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT kpi_library_pkey PRIMARY KEY (id),
  CONSTRAINT kpi_library_unique_name UNIQUE (name),
  CONSTRAINT kpi_library_replacement_fkey FOREIGN KEY (replacement_kpi_id) REFERENCES public.kpi_library(id)
);

-- User's Dashboard KPI Instances
CREATE TABLE IF NOT EXISTS public.user_dashboard_kpis (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id text NOT NULL,
  kpi_id uuid NOT NULL,
  
  -- Dashboard positioning
  position_x integer DEFAULT 0,
  position_y integer DEFAULT 0,
  size_width integer DEFAULT 1, -- Grid units
  size_height integer DEFAULT 1,
  
  -- Custom overrides
  custom_name text, -- User's custom name for this KPI
  custom_target numeric, -- User's personal target
  custom_color text, -- User's preferred color
  
  -- Alert settings (overrides KPI defaults)
  alerts_enabled boolean DEFAULT false,
  alert_email boolean DEFAULT true,
  alert_threshold_high numeric,
  alert_threshold_low numeric,
  alert_change_percentage numeric,
  
  -- Data filtering
  date_range text DEFAULT '30d'::text CHECK (date_range = ANY (ARRAY[
    '7d'::text, '30d'::text, '90d'::text, '1y'::text, 'custom'::text
  ])),
  custom_date_start date,
  custom_date_end date,
  platform_filter text[], -- Filter to specific platforms
  
  -- Visibility and status
  is_visible boolean DEFAULT true,
  is_favorite boolean DEFAULT false,
  last_viewed_at timestamp with time zone,
  
  created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT user_dashboard_kpis_pkey PRIMARY KEY (id),
  CONSTRAINT user_dashboard_kpis_kpi_fkey FOREIGN KEY (kpi_id) REFERENCES public.kpi_library(id),
  CONSTRAINT user_dashboard_kpis_unique_user_kpi UNIQUE (user_id, kpi_id)
);

-- KPI Historical Values for Trend Analysis
CREATE TABLE IF NOT EXISTS public.kpi_historical_values (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id text NOT NULL,
  kpi_id uuid NOT NULL,
  
  -- Time period
  date date NOT NULL,
  period_type text DEFAULT 'daily'::text CHECK (period_type = ANY (ARRAY[
    'hourly'::text, 'daily'::text, 'weekly'::text, 'monthly'::text
  ])),
  
  -- Values
  value numeric NOT NULL,
  previous_value numeric, -- For change calculation
  change_amount numeric,
  change_percentage numeric,
  
  -- Context
  platform_breakdown jsonb DEFAULT '{}'::jsonb, -- Values per platform
  metadata jsonb DEFAULT '{}'::jsonb, -- Additional context
  
  -- Data quality
  confidence_score numeric DEFAULT 1.0 CHECK (confidence_score >= 0 AND confidence_score <= 1),
  data_completeness numeric DEFAULT 1.0, -- Percentage of expected data available
  
  created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT kpi_historical_values_pkey PRIMARY KEY (id),
  CONSTRAINT kpi_historical_values_kpi_fkey FOREIGN KEY (kpi_id) REFERENCES public.kpi_library(id),
  CONSTRAINT kpi_historical_values_unique_user_kpi_date UNIQUE (user_id, kpi_id, date, period_type)
);

-- KPI Categories for Organization
CREATE TABLE IF NOT EXISTS public.kpi_categories (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  name text NOT NULL UNIQUE,
  display_name text NOT NULL,
  description text,
  icon text,
  color text DEFAULT '#6B7280'::text,
  sort_order integer DEFAULT 0,
  is_active boolean DEFAULT true,
  
  created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT kpi_categories_pkey PRIMARY KEY (id)
);

-- Smart KPI Suggestions for Users
CREATE TABLE IF NOT EXISTS public.kpi_suggestions (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id text NOT NULL,
  kpi_id uuid NOT NULL,
  
  -- Suggestion context
  suggestion_reason text NOT NULL, -- 'trending_down', 'missing_metric', 'new_platform_connected'
  confidence_score numeric DEFAULT 0.5 CHECK (confidence_score >= 0 AND confidence_score <= 1),
  priority integer DEFAULT 0, -- Higher = more important
  
  -- Supporting data
  current_value numeric,
  trend_direction text CHECK (trend_direction = ANY (ARRAY['up'::text, 'down'::text, 'stable'::text])),
  change_percentage numeric,
  benchmark_comparison text, -- 'above_benchmark', 'below_benchmark'
  
  -- User interaction
  shown_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  user_action text CHECK (user_action = ANY (ARRAY['pending'::text, 'accepted'::text, 'dismissed'::text, 'ignored'::text])),
  acted_at timestamp with time zone,
  
  -- Lifecycle
  expires_at timestamp with time zone,
  is_active boolean DEFAULT true,
  
  CONSTRAINT kpi_suggestions_pkey PRIMARY KEY (id),
  CONSTRAINT kpi_suggestions_kpi_fkey FOREIGN KEY (kpi_id) REFERENCES public.kpi_library(id)
);

-- Indexes for Performance
CREATE INDEX IF NOT EXISTS idx_kpi_library_category ON public.kpi_library(category);
CREATE INDEX IF NOT EXISTS idx_kpi_library_platforms ON public.kpi_library USING GIN (required_platforms);
CREATE INDEX IF NOT EXISTS idx_kpi_library_active ON public.kpi_library(is_active);
CREATE INDEX IF NOT EXISTS idx_user_dashboard_kpis_user ON public.user_dashboard_kpis(user_id);
CREATE INDEX IF NOT EXISTS idx_kpi_historical_values_user_date ON public.kpi_historical_values(user_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_kpi_suggestions_user_active ON public.kpi_suggestions(user_id, is_active);

-- Comments for Documentation
COMMENT ON TABLE public.kpi_library IS 'Master library of all available KPIs for Maya Intelligence';
COMMENT ON TABLE public.user_dashboard_kpis IS 'Users personal KPI dashboard configurations';
COMMENT ON TABLE public.kpi_historical_values IS 'Historical KPI values for trend analysis and charts';
COMMENT ON TABLE public.kpi_suggestions IS 'AI-powered KPI suggestions for users based on their data and behavior';

-- Grant permissions (adjust based on your RLS setup)
-- Note: You'll need to add RLS policies based on your existing patterns