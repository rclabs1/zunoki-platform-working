-- Multi-Tenant Agent Marketplace Database Schema
-- Designed for: Free/Paid tiers, Revenue sharing, Admin approval, Multi-tenant isolation

-- ===============================
-- USER MANAGEMENT & SUBSCRIPTIONS
-- ===============================

-- User profiles with subscription tiers
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id text PRIMARY KEY, -- Auth user ID
    full_name text,
    email text UNIQUE,
    avatar_url text,
    subscription_tier text NOT NULL CHECK (subscription_tier IN ('free', 'paid', 'admin')) DEFAULT 'free',
    subscription_status text CHECK (subscription_status IN ('active', 'canceled', 'expired')) DEFAULT 'active',
    subscription_expires_at timestamp with time zone,
    stripe_customer_id text,
    total_earnings numeric DEFAULT 0, -- For revenue sharing
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- ===============================
-- AGENT TEMPLATES & MARKETPLACE
-- ===============================

-- Main agent templates table
CREATE TABLE IF NOT EXISTS public.agent_templates (
    id text PRIMARY KEY,
    name text NOT NULL,
    description text NOT NULL,
    category text NOT NULL,
    template_config jsonb NOT NULL,
    
    -- Ownership & Permissions
    created_by text NOT NULL REFERENCES public.user_profiles(id),
    visibility text NOT NULL CHECK (visibility IN ('private', 'public', 'system')) DEFAULT 'private',
    
    -- Marketplace Settings
    is_approved boolean DEFAULT false, -- Admin approval required
    approval_status text CHECK (approval_status IN ('pending', 'approved', 'rejected')) DEFAULT 'pending',
    approved_by text REFERENCES public.user_profiles(id),
    approved_at timestamp with time zone,
    rejection_reason text,
    
    -- Pricing & Monetization
    pricing_tier text NOT NULL CHECK (pricing_tier IN ('free', 'premium')) DEFAULT 'free',
    price numeric DEFAULT 0,
    revenue_share_enabled boolean DEFAULT true, -- Creator gets revenue share
    revenue_share_percentage numeric DEFAULT 70.0, -- 70% to creator, 30% to platform
    
    -- Licensing
    allows_modification boolean DEFAULT false, -- Can buyers modify?
    allows_commercial_use boolean DEFAULT true,
    
    -- Metrics
    usage_count integer DEFAULT 0,
    purchase_count integer DEFAULT 0,
    rating numeric DEFAULT 0,
    reviews_count integer DEFAULT 0,
    total_revenue numeric DEFAULT 0,
    
    -- Metadata
    tags text[] DEFAULT '{}',
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- ===============================
-- PURCHASES & SUBSCRIPTIONS
-- ===============================

-- Agent purchases/subscriptions
CREATE TABLE IF NOT EXISTS public.agent_purchases (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    buyer_id text NOT NULL REFERENCES public.user_profiles(id),
    template_id text NOT NULL REFERENCES public.agent_templates(id),
    creator_id text NOT NULL REFERENCES public.user_profiles(id), -- For revenue sharing
    
    -- Purchase Details
    purchase_type text NOT NULL CHECK (purchase_type IN ('one_time', 'monthly_subscription', 'free_access')),
    price_paid numeric NOT NULL DEFAULT 0,
    platform_fee numeric NOT NULL DEFAULT 0, -- 30% platform fee
    creator_earnings numeric NOT NULL DEFAULT 0, -- 70% to creator
    
    -- License & Usage
    license_type text NOT NULL CHECK (license_type IN ('personal', 'commercial')) DEFAULT 'personal',
    usage_limit integer, -- Monthly conversation limit
    usage_count integer DEFAULT 0,
    
    -- Subscription Management
    subscription_status text CHECK (subscription_status IN ('active', 'canceled', 'expired')) DEFAULT 'active',
    expires_at timestamp with time zone,
    auto_renewal boolean DEFAULT true,
    
    -- Timestamps
    purchased_at timestamp with time zone DEFAULT now(),
    canceled_at timestamp with time zone
);

-- ===============================
-- USER-CREATED AGENTS INSTANCES
-- ===============================

-- User's personal agent instances (created from templates)
CREATE TABLE IF NOT EXISTS public.user_agents (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id text NOT NULL REFERENCES public.user_profiles(id),
    template_id text NOT NULL REFERENCES public.agent_templates(id),
    purchase_id uuid REFERENCES public.agent_purchases(id),
    
    -- Customization
    name text NOT NULL,
    custom_config jsonb, -- User's customizations
    is_active boolean DEFAULT true,
    
    -- Usage Tracking
    conversations_handled integer DEFAULT 0,
    last_used_at timestamp with time zone,
    
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- ===============================
-- REVIEWS & RATINGS
-- ===============================

-- Template reviews
CREATE TABLE IF NOT EXISTS public.template_reviews (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    template_id text NOT NULL REFERENCES public.agent_templates(id),
    reviewer_id text NOT NULL REFERENCES public.user_profiles(id),
    purchase_id uuid REFERENCES public.agent_purchases(id), -- Only buyers can review
    
    rating integer NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment text,
    is_verified_purchase boolean DEFAULT false,
    
    created_at timestamp with time zone DEFAULT now(),
    
    UNIQUE(template_id, reviewer_id) -- One review per user per template
);

-- ===============================
-- REVENUE & ANALYTICS
-- ===============================

-- Revenue transactions for creators
CREATE TABLE IF NOT EXISTS public.revenue_transactions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id text NOT NULL REFERENCES public.user_profiles(id),
    purchase_id uuid NOT NULL REFERENCES public.agent_purchases(id),
    template_id text NOT NULL REFERENCES public.agent_templates(id),
    
    amount numeric NOT NULL,
    transaction_type text NOT NULL CHECK (transaction_type IN ('purchase', 'subscription', 'usage_fee')),
    platform_fee numeric NOT NULL,
    net_amount numeric NOT NULL,
    
    payout_status text CHECK (payout_status IN ('pending', 'paid', 'failed')) DEFAULT 'pending',
    payout_date timestamp with time zone,
    
    created_at timestamp with time zone DEFAULT now()
);

-- ===============================
-- INDEXES FOR PERFORMANCE
-- ===============================

-- User profiles
CREATE INDEX IF NOT EXISTS idx_user_profiles_subscription ON public.user_profiles(subscription_tier, subscription_status);

-- Agent templates - Marketplace queries
CREATE INDEX IF NOT EXISTS idx_templates_marketplace ON public.agent_templates(visibility, is_approved, pricing_tier);
CREATE INDEX IF NOT EXISTS idx_templates_category ON public.agent_templates(category, visibility, is_approved);
CREATE INDEX IF NOT EXISTS idx_templates_creator ON public.agent_templates(created_by, visibility);
CREATE INDEX IF NOT EXISTS idx_templates_rating ON public.agent_templates(rating DESC, reviews_count DESC);
CREATE INDEX IF NOT EXISTS idx_templates_popularity ON public.agent_templates(purchase_count DESC, usage_count DESC);

-- Purchases
CREATE INDEX IF NOT EXISTS idx_purchases_buyer ON public.agent_purchases(buyer_id, subscription_status);
CREATE INDEX IF NOT EXISTS idx_purchases_creator ON public.agent_purchases(creator_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_purchases_template ON public.agent_purchases(template_id, subscription_status);

-- User agents
CREATE INDEX IF NOT EXISTS idx_user_agents_user ON public.user_agents(user_id, is_active);
CREATE INDEX IF NOT EXISTS idx_user_agents_template ON public.user_agents(template_id);

-- Reviews
CREATE INDEX IF NOT EXISTS idx_reviews_template ON public.template_reviews(template_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_reviews_reviewer ON public.template_reviews(reviewer_id);

-- Revenue
CREATE INDEX IF NOT EXISTS idx_revenue_creator ON public.revenue_transactions(creator_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_revenue_payout ON public.revenue_transactions(payout_status, created_at);

-- ===============================
-- ROW LEVEL SECURITY (RLS)
-- ===============================

-- Enable RLS on all tables
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agent_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agent_purchases ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_agents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.template_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.revenue_transactions ENABLE ROW LEVEL SECURITY;

-- ===============================
-- RLS POLICIES - USER PROFILES
-- ===============================

CREATE POLICY "Users can view their own profile" ON public.user_profiles
    FOR SELECT USING (id = auth.uid()::text);

CREATE POLICY "Users can update their own profile" ON public.user_profiles
    FOR UPDATE USING (id = auth.uid()::text);

CREATE POLICY "Admins can view all profiles" ON public.user_profiles
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles 
            WHERE id = auth.uid()::text AND subscription_tier = 'admin'
        )
    );

-- ===============================
-- RLS POLICIES - AGENT TEMPLATES
-- ===============================

-- Everyone can view approved public templates
CREATE POLICY "Public approved templates viewable by all" ON public.agent_templates
    FOR SELECT USING (
        visibility = 'public' AND is_approved = true
        OR visibility = 'system' -- System templates always visible
    );

-- Users can view their own templates
CREATE POLICY "Users can view own templates" ON public.agent_templates
    FOR SELECT USING (created_by = auth.uid()::text);

-- Free users can only create private templates
CREATE POLICY "Free users create private templates" ON public.agent_templates
    FOR INSERT WITH CHECK (
        created_by = auth.uid()::text 
        AND (
            visibility = 'private' 
            OR (
                visibility = 'public' 
                AND EXISTS (
                    SELECT 1 FROM public.user_profiles 
                    WHERE id = auth.uid()::text 
                    AND subscription_tier IN ('paid', 'admin')
                )
            )
        )
    );

-- Users can update their own templates (if not approved yet)
CREATE POLICY "Users update own pending templates" ON public.agent_templates
    FOR UPDATE USING (
        created_by = auth.uid()::text 
        AND (approval_status = 'pending' OR visibility = 'private')
    );

-- Admins can view and manage all templates
CREATE POLICY "Admins manage all templates" ON public.agent_templates
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles 
            WHERE id = auth.uid()::text AND subscription_tier = 'admin'
        )
    );

-- ===============================
-- RLS POLICIES - PURCHASES
-- ===============================

-- Users can view their own purchases
CREATE POLICY "Users view own purchases" ON public.agent_purchases
    FOR SELECT USING (buyer_id = auth.uid()::text);

-- Users can make purchases
CREATE POLICY "Users make purchases" ON public.agent_purchases
    FOR INSERT WITH CHECK (buyer_id = auth.uid()::text);

-- Creators can view purchases of their templates
CREATE POLICY "Creators view template purchases" ON public.agent_purchases
    FOR SELECT USING (creator_id = auth.uid()::text);

-- Admins can view all purchases
CREATE POLICY "Admins view all purchases" ON public.agent_purchases
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles 
            WHERE id = auth.uid()::text AND subscription_tier = 'admin'
        )
    );

-- ===============================
-- RLS POLICIES - USER AGENTS
-- ===============================

-- Users can manage their own agent instances
CREATE POLICY "Users manage own agents" ON public.user_agents
    FOR ALL USING (user_id = auth.uid()::text);

-- ===============================
-- RLS POLICIES - REVIEWS
-- ===============================

-- Everyone can view reviews
CREATE POLICY "Reviews viewable by all" ON public.template_reviews
    FOR SELECT USING (true);

-- Only verified purchasers can create reviews
CREATE POLICY "Purchasers can review" ON public.template_reviews
    FOR INSERT WITH CHECK (
        reviewer_id = auth.uid()::text
        AND EXISTS (
            SELECT 1 FROM public.agent_purchases 
            WHERE buyer_id = auth.uid()::text 
            AND template_id = template_reviews.template_id
        )
    );

-- Users can update their own reviews
CREATE POLICY "Users update own reviews" ON public.template_reviews
    FOR UPDATE USING (reviewer_id = auth.uid()::text);

-- ===============================
-- RLS POLICIES - REVENUE
-- ===============================

-- Creators can view their own revenue
CREATE POLICY "Creators view own revenue" ON public.revenue_transactions
    FOR SELECT USING (creator_id = auth.uid()::text);

-- Admins can view all revenue
CREATE POLICY "Admins view all revenue" ON public.revenue_transactions
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles 
            WHERE id = auth.uid()::text AND subscription_tier = 'admin'
        )
    );

-- ===============================
-- FUNCTIONS & TRIGGERS
-- ===============================

-- Update timestamps
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

-- Create triggers
CREATE TRIGGER handle_user_profiles_updated_at
    BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER handle_agent_templates_updated_at
    BEFORE UPDATE ON public.agent_templates
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER handle_user_agents_updated_at
    BEFORE UPDATE ON public.user_agents
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Function to update template ratings
CREATE OR REPLACE FUNCTION public.update_template_rating()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE public.agent_templates
    SET 
        rating = (
            SELECT COALESCE(AVG(rating), 0)
            FROM public.template_reviews
            WHERE template_id = NEW.template_id
        ),
        reviews_count = (
            SELECT COUNT(*)
            FROM public.template_reviews
            WHERE template_id = NEW.template_id
        ),
        updated_at = now()
    WHERE id = NEW.template_id;
    
    RETURN NEW;
END;
$$;

-- Trigger to update ratings when reviews are added/updated
CREATE TRIGGER update_template_rating_on_review
    AFTER INSERT OR UPDATE ON public.template_reviews
    FOR EACH ROW EXECUTE FUNCTION public.update_template_rating();

-- Function to create revenue transaction on purchase
CREATE OR REPLACE FUNCTION public.create_revenue_transaction()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    template_creator text;
    revenue_share_pct numeric;
    creator_amount numeric;
    platform_amount numeric;
BEGIN
    -- Get template creator and revenue share percentage
    SELECT created_by, COALESCE(revenue_share_percentage, 70.0)
    INTO template_creator, revenue_share_pct
    FROM public.agent_templates
    WHERE id = NEW.template_id;
    
    -- Calculate amounts
    platform_amount = NEW.price_paid * (100 - revenue_share_pct) / 100;
    creator_amount = NEW.price_paid - platform_amount;
    
    -- Update purchase record
    UPDATE public.agent_purchases
    SET 
        platform_fee = platform_amount,
        creator_earnings = creator_amount
    WHERE id = NEW.id;
    
    -- Create revenue transaction for creator (if not free)
    IF NEW.price_paid > 0 AND template_creator != 'system' THEN
        INSERT INTO public.revenue_transactions (
            creator_id,
            purchase_id,
            template_id,
            amount,
            transaction_type,
            platform_fee,
            net_amount
        ) VALUES (
            template_creator,
            NEW.id,
            NEW.template_id,
            NEW.price_paid,
            NEW.purchase_type,
            platform_amount,
            creator_amount
        );
        
        -- Update creator's total earnings
        UPDATE public.user_profiles
        SET total_earnings = total_earnings + creator_amount
        WHERE id = template_creator;
    END IF;
    
    -- Update template purchase count
    UPDATE public.agent_templates
    SET 
        purchase_count = purchase_count + 1,
        total_revenue = total_revenue + NEW.price_paid,
        updated_at = now()
    WHERE id = NEW.template_id;
    
    RETURN NEW;
END;
$$;

-- Trigger to create revenue transactions
CREATE TRIGGER create_revenue_on_purchase
    AFTER INSERT ON public.agent_purchases
    FOR EACH ROW EXECUTE FUNCTION public.create_revenue_transaction();

-- ===============================
-- DEFAULT DATA
-- ===============================

-- Insert system user for seeding
INSERT INTO public.user_profiles (id, full_name, email, subscription_tier) 
VALUES ('system', 'Admolabs System', 'system@admolabs.com', 'admin')
ON CONFLICT (id) DO UPDATE SET
    full_name = EXCLUDED.full_name,
    email = EXCLUDED.email,
    subscription_tier = EXCLUDED.subscription_tier,
    updated_at = now();