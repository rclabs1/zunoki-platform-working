-- SAFE MARKETPLACE MIGRATION
-- This script extends existing tables without modifying any messaging/integration functionality
-- All changes are additive only - no data loss risk

-- ===============================
-- EXTEND EXISTING USERS TABLE
-- ===============================

-- Add marketplace-related fields to existing users table
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS total_earnings numeric DEFAULT 0;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS revenue_share_percentage numeric DEFAULT 70.0;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS stripe_customer_id text;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS payout_email text;

-- Add subscription expiry tracking
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS subscription_expires_at timestamp with time zone;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS subscription_renewed_at timestamp with time zone;

-- ===============================
-- EXTEND EXISTING AI_AGENT_TEMPLATES TABLE
-- ===============================

-- Add approval workflow fields
ALTER TABLE public.ai_agent_templates ADD COLUMN IF NOT EXISTS approval_status text DEFAULT 'approved' 
    CHECK (approval_status IN ('pending', 'approved', 'rejected'));
ALTER TABLE public.ai_agent_templates ADD COLUMN IF NOT EXISTS approved_by text;
ALTER TABLE public.ai_agent_templates ADD COLUMN IF NOT EXISTS approved_at timestamp with time zone;
ALTER TABLE public.ai_agent_templates ADD COLUMN IF NOT EXISTS rejection_reason text;

-- Add marketplace visibility and pricing
ALTER TABLE public.ai_agent_templates ADD COLUMN IF NOT EXISTS visibility text DEFAULT 'public' 
    CHECK (visibility IN ('private', 'public', 'system'));
ALTER TABLE public.ai_agent_templates ADD COLUMN IF NOT EXISTS pricing_tier text DEFAULT 'free' 
    CHECK (pricing_tier IN ('free', 'premium'));

-- Add revenue sharing
ALTER TABLE public.ai_agent_templates ADD COLUMN IF NOT EXISTS revenue_share_enabled boolean DEFAULT true;
ALTER TABLE public.ai_agent_templates ADD COLUMN IF NOT EXISTS creator_revenue_share numeric DEFAULT 70.0;

-- Add licensing options
ALTER TABLE public.ai_agent_templates ADD COLUMN IF NOT EXISTS allows_modification boolean DEFAULT false;
ALTER TABLE public.ai_agent_templates ADD COLUMN IF NOT EXISTS allows_commercial_use boolean DEFAULT true;

-- Add usage limits configuration
ALTER TABLE public.ai_agent_templates ADD COLUMN IF NOT EXISTS usage_limits jsonb DEFAULT '{"free": {"monthlyConversations": 40, "resetDate": "monthly"}, "paid": {"monthlyConversations": 500, "resetDate": "monthly"}}';

-- Add additional metrics
ALTER TABLE public.ai_agent_templates ADD COLUMN IF NOT EXISTS purchase_count integer DEFAULT 0;
ALTER TABLE public.ai_agent_templates ADD COLUMN IF NOT EXISTS total_revenue numeric DEFAULT 0;

-- ===============================
-- EXTEND EXISTING AGENTS TABLE (for user-created agents)
-- ===============================

-- Add template relationship (which template was this agent created from)
ALTER TABLE public.agents ADD COLUMN IF NOT EXISTS source_template_id uuid;
ALTER TABLE public.agents ADD COLUMN IF NOT EXISTS purchase_reference_id uuid;

-- Add usage tracking for subscription limits
ALTER TABLE public.agents ADD COLUMN IF NOT EXISTS monthly_usage_count integer DEFAULT 0;
ALTER TABLE public.agents ADD COLUMN IF NOT EXISTS usage_reset_date date DEFAULT CURRENT_DATE;
ALTER TABLE public.agents ADD COLUMN IF NOT EXISTS usage_limit integer DEFAULT 40; -- Free tier default

-- ===============================
-- CREATE NEW TABLES (MARKETPLACE-SPECIFIC)
-- ===============================

-- Template purchases/subscriptions (extends existing marketplace_transactions)
CREATE TABLE IF NOT EXISTS public.template_purchases (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    buyer_id uuid NOT NULL REFERENCES public.users(id),
    template_id uuid NOT NULL REFERENCES public.ai_agent_templates(id),
    creator_id text, -- Template creator (from ai_agent_templates.creator_id)
    
    -- Purchase details
    purchase_type text NOT NULL CHECK (purchase_type IN ('one_time', 'monthly_subscription', 'free_access')) DEFAULT 'one_time',
    price_paid numeric NOT NULL DEFAULT 0,
    platform_fee numeric NOT NULL DEFAULT 0,
    creator_earnings numeric NOT NULL DEFAULT 0,
    
    -- Usage tracking
    usage_limit integer DEFAULT 40, -- Monthly conversation limit
    usage_count integer DEFAULT 0,
    usage_reset_date date DEFAULT CURRENT_DATE,
    
    -- Subscription management
    subscription_status text CHECK (subscription_status IN ('active', 'canceled', 'expired')) DEFAULT 'active',
    expires_at timestamp with time zone,
    auto_renewal boolean DEFAULT false,
    
    -- License
    license_type text NOT NULL CHECK (license_type IN ('personal', 'commercial')) DEFAULT 'personal',
    
    -- Timestamps
    purchased_at timestamp with time zone DEFAULT now(),
    canceled_at timestamp with time zone,
    
    UNIQUE(buyer_id, template_id) -- One active purchase per user per template
);

-- Template reviews (separate from agent_reviews)
CREATE TABLE IF NOT EXISTS public.template_reviews (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    template_id uuid NOT NULL REFERENCES public.ai_agent_templates(id),
    reviewer_id uuid NOT NULL REFERENCES public.users(id),
    purchase_id uuid REFERENCES public.template_purchases(id),
    
    rating integer NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment text,
    is_verified_purchase boolean DEFAULT false,
    
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    
    UNIQUE(template_id, reviewer_id) -- One review per user per template
);

-- Revenue transactions for creators
CREATE TABLE IF NOT EXISTS public.creator_revenue (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id text NOT NULL, -- From users table or ai_agent_templates.creator_id
    purchase_id uuid NOT NULL REFERENCES public.template_purchases(id),
    template_id uuid NOT NULL REFERENCES public.ai_agent_templates(id),
    
    -- Revenue details
    gross_amount numeric NOT NULL,
    platform_fee numeric NOT NULL,
    net_amount numeric NOT NULL,
    transaction_type text NOT NULL CHECK (transaction_type IN ('purchase', 'subscription', 'usage_fee')),
    
    -- Payout tracking
    payout_status text CHECK (payout_status IN ('pending', 'paid', 'failed')) DEFAULT 'pending',
    payout_date timestamp with time zone,
    payout_reference text, -- Stripe payout ID, etc.
    
    created_at timestamp with time zone DEFAULT now()
);

-- User agent instances (created from purchased templates)
CREATE TABLE IF NOT EXISTS public.user_agent_instances (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES public.users(id),
    agent_id uuid NOT NULL REFERENCES public.agents(id),
    template_id uuid NOT NULL REFERENCES public.ai_agent_templates(id),
    purchase_id uuid NOT NULL REFERENCES public.template_purchases(id),
    
    -- Customizations
    custom_name text,
    custom_config jsonb, -- User's modifications
    is_active boolean DEFAULT true,
    
    -- Usage tracking
    conversations_this_month integer DEFAULT 0,
    last_reset_date date DEFAULT CURRENT_DATE,
    last_used_at timestamp with time zone,
    
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- ===============================
-- INDEXES FOR PERFORMANCE
-- ===============================

-- Template purchases
CREATE INDEX IF NOT EXISTS idx_template_purchases_buyer ON public.template_purchases(buyer_id, subscription_status);
CREATE INDEX IF NOT EXISTS idx_template_purchases_template ON public.template_purchases(template_id, subscription_status);
CREATE INDEX IF NOT EXISTS idx_template_purchases_creator ON public.template_purchases(creator_id, purchased_at DESC);

-- Template reviews
CREATE INDEX IF NOT EXISTS idx_template_reviews_template ON public.template_reviews(template_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_template_reviews_rating ON public.template_reviews(template_id, rating);

-- Creator revenue
CREATE INDEX IF NOT EXISTS idx_creator_revenue_creator ON public.creator_revenue(creator_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_creator_revenue_payout ON public.creator_revenue(payout_status, created_at);

-- User agent instances
CREATE INDEX IF NOT EXISTS idx_user_agent_instances_user ON public.user_agent_instances(user_id, is_active);
CREATE INDEX IF NOT EXISTS idx_user_agent_instances_template ON public.user_agent_instances(template_id);

-- Enhanced indexes for existing tables
CREATE INDEX IF NOT EXISTS idx_ai_agent_templates_marketplace ON public.ai_agent_templates(approval_status, visibility, pricing_tier);
CREATE INDEX IF NOT EXISTS idx_ai_agent_templates_creator_revenue ON public.ai_agent_templates(creator_id, total_revenue DESC);

-- ===============================
-- ROW LEVEL SECURITY (RLS)
-- ===============================

-- Enable RLS on new tables
ALTER TABLE public.template_purchases ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.template_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.creator_revenue ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_agent_instances ENABLE ROW LEVEL SECURITY;

-- ===============================
-- RLS POLICIES FOR NEW TABLES
-- ===============================

-- Template purchases policies
CREATE POLICY "Users view own template purchases" ON public.template_purchases
    FOR SELECT USING (buyer_id = auth.uid());

CREATE POLICY "Users create own template purchases" ON public.template_purchases
    FOR INSERT WITH CHECK (buyer_id = auth.uid());

CREATE POLICY "Creators view purchases of their templates" ON public.template_purchases
    FOR SELECT USING (
        creator_id = auth.uid()::text OR
        EXISTS (
            SELECT 1 FROM public.ai_agent_templates 
            WHERE id = template_purchases.template_id 
            AND creator_id = auth.uid()::text
        )
    );

-- Template reviews policies  
CREATE POLICY "Everyone can view template reviews" ON public.template_reviews
    FOR SELECT USING (true);

CREATE POLICY "Verified purchasers can create reviews" ON public.template_reviews
    FOR INSERT WITH CHECK (
        reviewer_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM public.template_purchases 
            WHERE buyer_id = auth.uid() 
            AND template_id = template_reviews.template_id
            AND subscription_status = 'active'
        )
    );

CREATE POLICY "Users can update own reviews" ON public.template_reviews
    FOR UPDATE USING (reviewer_id = auth.uid());

-- Creator revenue policies
CREATE POLICY "Creators view own revenue" ON public.creator_revenue
    FOR SELECT USING (creator_id = auth.uid()::text);

-- User agent instances policies
CREATE POLICY "Users manage own agent instances" ON public.user_agent_instances
    FOR ALL USING (user_id = auth.uid());

-- ===============================
-- FUNCTIONS & TRIGGERS
-- ===============================

-- Function to update template rating when review is added/updated
CREATE OR REPLACE FUNCTION public.update_template_rating_from_reviews()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Update rating and rating_count in ai_agent_templates
    UPDATE public.ai_agent_templates
    SET 
        rating = (
            SELECT COALESCE(AVG(rating), 0)
            FROM public.template_reviews
            WHERE template_id = NEW.template_id
        ),
        rating_count = (
            SELECT COUNT(*)
            FROM public.template_reviews
            WHERE template_id = NEW.template_id
        ),
        updated_at = now()
    WHERE id = NEW.template_id;
    
    RETURN NEW;
END;
$$;

-- Trigger for template rating updates
DROP TRIGGER IF EXISTS update_template_rating_on_review ON public.template_reviews;
CREATE TRIGGER update_template_rating_on_review
    AFTER INSERT OR UPDATE ON public.template_reviews
    FOR EACH ROW EXECUTE FUNCTION public.update_template_rating_from_reviews();

-- Function to create revenue transaction on template purchase
CREATE OR REPLACE FUNCTION public.create_template_revenue_transaction()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    template_creator text;
    revenue_share_pct numeric;
    creator_amount numeric;
    platform_amount numeric;
BEGIN
    -- Get template creator and revenue share percentage
    SELECT creator_id, COALESCE(creator_revenue_share, 70.0)
    INTO template_creator, revenue_share_pct
    FROM public.ai_agent_templates
    WHERE id = NEW.template_id;
    
    -- Calculate amounts (only if not free)
    IF NEW.price_paid > 0 THEN
        platform_amount = NEW.price_paid * (100 - revenue_share_pct) / 100;
        creator_amount = NEW.price_paid - platform_amount;
        
        -- Update purchase record with calculated amounts
        UPDATE public.template_purchases
        SET 
            platform_fee = platform_amount,
            creator_earnings = creator_amount
        WHERE id = NEW.id;
        
        -- Create revenue transaction for creator (if not system template)
        IF template_creator IS NOT NULL AND template_creator != 'system' THEN
            INSERT INTO public.creator_revenue (
                creator_id,
                purchase_id,
                template_id,
                gross_amount,
                platform_fee,
                net_amount,
                transaction_type
            ) VALUES (
                template_creator,
                NEW.id,
                NEW.template_id,
                NEW.price_paid,
                platform_amount,
                creator_amount,
                NEW.purchase_type
            );
            
            -- Update creator's total earnings in users table
            UPDATE public.users
            SET total_earnings = COALESCE(total_earnings, 0) + creator_amount
            WHERE id::text = template_creator OR email = template_creator;
        END IF;
    END IF;
    
    -- Update template metrics
    UPDATE public.ai_agent_templates
    SET 
        purchase_count = COALESCE(purchase_count, 0) + 1,
        downloads_count = COALESCE(downloads_count, 0) + 1,
        total_revenue = COALESCE(total_revenue, 0) + NEW.price_paid,
        updated_at = now()
    WHERE id = NEW.template_id;
    
    RETURN NEW;
END;
$$;

-- Trigger for revenue transaction creation
DROP TRIGGER IF EXISTS create_revenue_on_template_purchase ON public.template_purchases;
CREATE TRIGGER create_revenue_on_template_purchase
    AFTER INSERT ON public.template_purchases
    FOR EACH ROW EXECUTE FUNCTION public.create_template_revenue_transaction();

-- Function to reset monthly usage counts
CREATE OR REPLACE FUNCTION public.reset_monthly_usage()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Reset usage for template purchases
    UPDATE public.template_purchases
    SET 
        usage_count = 0,
        usage_reset_date = CURRENT_DATE
    WHERE usage_reset_date < CURRENT_DATE - INTERVAL '1 month';
    
    -- Reset usage for user agent instances
    UPDATE public.user_agent_instances
    SET 
        conversations_this_month = 0,
        last_reset_date = CURRENT_DATE
    WHERE last_reset_date < CURRENT_DATE - INTERVAL '1 month';
    
    -- Reset usage for agents
    UPDATE public.agents
    SET 
        monthly_usage_count = 0,
        usage_reset_date = CURRENT_DATE
    WHERE usage_reset_date < CURRENT_DATE - INTERVAL '1 month';
END;
$$;

-- ===============================
-- SUCCESS MESSAGE
-- ===============================

DO $$
BEGIN
    RAISE NOTICE 'Marketplace migration completed successfully!';
    RAISE NOTICE 'Added columns to existing tables: users, ai_agent_templates, agents';
    RAISE NOTICE 'Created new tables: template_purchases, template_reviews, creator_revenue, user_agent_instances';
    RAISE NOTICE 'All messaging/integration tables left untouched';
END $$;