-- Seed KPI Library with Essential Marketing KPIs
-- Step 2 of the foundation-first approach

-- Clear existing data (for fresh seeding)
DELETE FROM public.kpi_library WHERE is_system = true;

-- Essential Performance KPIs
INSERT INTO public.kpi_library (
    name, display_name, description, category, 
    data_source_table, data_source_column, calculation_type, formula,
    required_platforms, supported_platforms,
    format_type, decimal_places, prefix, suffix,
    default_chart_type, chart_color,
    benchmark_value, benchmark_source, target_direction,
    is_system, tags, icon, help_text, example_value
) VALUES 

-- ROAS (Return on Ad Spend)
('roas', 'ROAS', 'Return on advertising spend - revenue generated per dollar spent', 'performance',
 'campaign_metrics', 'revenue / spend', 'calculated', 'SUM(revenue) / NULLIF(SUM(spend), 0)',
 ARRAY['google_ads', 'meta_ads'], ARRAY['google_ads', 'meta_ads', 'linkedin_ads'],
 'ratio', 2, '', 'x', 'line', '#10B981',
 4.0, 'Industry average', 'higher',
 true, ARRAY['revenue', 'advertising', 'performance'], '📈', 'Higher ROAS means better return on your ad investment', '4.2x'),

-- Cost Per Click
('cpc', 'CPC', 'Average cost per click across advertising campaigns', 'financial',
 'campaign_metrics', 'spend / clicks', 'calculated', 'SUM(spend) / NULLIF(SUM(clicks), 0)',
 ARRAY['google_ads', 'meta_ads'], ARRAY['google_ads', 'meta_ads', 'linkedin_ads'],
 'currency', 2, '$', '', 'bar', '#3B82F6',
 1.50, 'Platform benchmarks', 'lower',
 true, ARRAY['cost', 'advertising', 'efficiency'], '💰', 'Lower CPC means you pay less for each click', '$1.25'),

-- Click Through Rate
('ctr', 'CTR', 'Percentage of people who click on ads after seeing them', 'performance',
 'campaign_metrics', 'clicks / impressions * 100', 'calculated', '(SUM(clicks) / NULLIF(SUM(impressions), 0)) * 100',
 ARRAY['google_ads', 'meta_ads'], ARRAY['google_ads', 'meta_ads', 'linkedin_ads'],
 'percentage', 2, '', '%', 'line', '#8B5CF6',
 2.5, 'Industry average', 'higher',
 true, ARRAY['engagement', 'advertising', 'performance'], '🎯', 'Higher CTR indicates more engaging ads', '3.2%'),

-- Conversion Rate
('conversion_rate', 'Conversion Rate', 'Percentage of clicks that result in conversions', 'conversion',
 'campaign_metrics', 'conversions / clicks * 100', 'calculated', '(SUM(conversions) / NULLIF(SUM(clicks), 0)) * 100',
 ARRAY['google_ads', 'meta_ads'], ARRAY['google_ads', 'meta_ads', 'linkedin_ads'],
 'percentage', 2, '', '%', 'bar', '#F59E0B',
 2.0, 'E-commerce average', 'higher',
 true, ARRAY['conversion', 'sales', 'performance'], '🔄', 'Higher conversion rate means more sales per visitor', '2.8%'),

-- Cost Per Lead
('cpl', 'Cost Per Lead', 'Average cost to acquire one lead', 'financial',
 'campaign_metrics', 'spend / conversions', 'calculated', 'SUM(spend) / NULLIF(SUM(conversions), 0)',
 ARRAY['google_ads', 'linkedin_ads'], ARRAY['google_ads', 'meta_ads', 'linkedin_ads'],
 'currency', 2, '$', '', 'line', '#EF4444',
 25.0, 'Industry benchmark', 'lower',
 true, ARRAY['cost', 'leads', 'acquisition'], '🎯', 'Lower CPL means more efficient lead generation', '$18.50'),

-- Total Revenue
('total_revenue', 'Total Revenue', 'Total revenue generated across all campaigns', 'financial',
 'campaign_metrics', 'revenue', 'aggregated', 'SUM(revenue)',
 ARRAY[]::text[], ARRAY['google_ads', 'meta_ads', 'linkedin_ads'],
 'currency', 0, '$', '', 'area', '#059669',
 NULL, NULL, 'higher',
 true, ARRAY['revenue', 'financial', 'performance'], '💵', 'Total money earned from your marketing efforts', '$12,500'),

-- Total Spend
('total_spend', 'Total Ad Spend', 'Total amount spent on advertising', 'financial',
 'campaign_metrics', 'spend', 'aggregated', 'SUM(spend)',
 ARRAY[]::text[], ARRAY['google_ads', 'meta_ads', 'linkedin_ads'],
 'currency', 0, '$', '', 'bar', '#DC2626',
 NULL, NULL, 'lower',
 true, ARRAY['cost', 'budget', 'advertising'], '💸', 'Total advertising budget spent', '$3,200'),

-- Impressions
('total_impressions', 'Impressions', 'Total number of times ads were displayed', 'audience',
 'campaign_metrics', 'impressions', 'aggregated', 'SUM(impressions)',
 ARRAY[]::text[], ARRAY['google_ads', 'meta_ads', 'linkedin_ads'],
 'number', 0, '', '', 'area', '#6366F1',
 NULL, NULL, 'higher',
 true, ARRAY['reach', 'visibility', 'awareness'], '👁️', 'How many times your ads were shown', '145,230'),

-- Total Clicks
('total_clicks', 'Total Clicks', 'Total number of clicks across all campaigns', 'engagement',
 'campaign_metrics', 'clicks', 'aggregated', 'SUM(clicks)',
 ARRAY[]::text[], ARRAY['google_ads', 'meta_ads', 'linkedin_ads'],
 'number', 0, '', '', 'bar', '#0891B2',
 NULL, NULL, 'higher',
 true, ARRAY['engagement', 'traffic', 'clicks'], '👆', 'Total clicks on your advertisements', '4,672'),

-- Average Response Time (for messaging platforms)
('avg_response_time', 'Avg Response Time', 'Average time to respond to customer messages', 'operational',
 'unified_messages', 'EXTRACT(EPOCH FROM (timestamp - created_at)) / 60', 'calculated', 'AVG(EXTRACT(EPOCH FROM (timestamp - created_at)) / 60) WHERE direction = ''inbound''',
 ARRAY['whatsapp', 'telegram'], ARRAY['whatsapp', 'telegram', 'gmail', 'instagram', 'facebook', 'slack', 'discord', 'sms'],
 'duration', 1, '', ' min', 'gauge', '#14B8A6',
 15.0, 'Customer service best practice', 'lower',
 true, ARRAY['response', 'customer_service', 'messaging'], '⏱️', 'Faster response times improve customer satisfaction', '8.5 min'),

-- Message Volume
('message_volume', 'Message Volume', 'Total number of messages received across platforms', 'engagement',
 'unified_messages', 'COUNT(*)', 'aggregated', 'COUNT(*)',
 ARRAY[]::text[], ARRAY['whatsapp', 'telegram', 'gmail', 'instagram', 'facebook', 'slack', 'discord', 'youtube', 'tiktok', 'sms', 'website_chat'],
 'number', 0, '', '', 'line', '#7C3AED',
 NULL, NULL, 'higher',
 true, ARRAY['volume', 'engagement', 'messaging'], '💬', 'Total customer interactions via messaging', '1,247'),

-- Inbound Message Volume
('inbound_messages', 'Inbound Messages', 'Number of messages received from customers', 'engagement',
 'unified_messages', 'COUNT(*) WHERE direction = ''inbound''', 'aggregated', 'COUNT(*) WHERE direction = ''inbound''',
 ARRAY[]::text[], ARRAY['whatsapp', 'telegram', 'gmail', 'instagram', 'facebook', 'slack', 'discord', 'youtube', 'tiktok', 'sms', 'website_chat'],
 'number', 0, '', '', 'bar', '#059669',
 NULL, NULL, 'higher',
 true, ARRAY['inbound', 'customer', 'messaging'], '📥', 'Messages from customers requiring response', '856'),

-- Outbound Message Volume
('outbound_messages', 'Outbound Messages', 'Number of messages sent to customers', 'engagement',
 'unified_messages', 'COUNT(*) WHERE direction = ''outbound''', 'aggregated', 'COUNT(*) WHERE direction = ''outbound''',
 ARRAY[]::text[], ARRAY['whatsapp', 'telegram', 'gmail', 'instagram', 'facebook', 'slack', 'discord', 'youtube', 'tiktok', 'sms', 'website_chat'],
 'number', 0, '', '', 'bar', '#3B82F6',
 NULL, NULL, 'higher',
 true, ARRAY['outbound', 'response', 'messaging'], '📤', 'Messages sent to customers in response', '943'),

-- Response Rate
('response_rate', 'Response Rate', 'Percentage of inbound messages that received a response', 'operational',
 'unified_messages', '(outbound_count / inbound_count) * 100', 'calculated', '(COUNT(*) FILTER (WHERE direction = ''outbound'') / NULLIF(COUNT(*) FILTER (WHERE direction = ''inbound''), 0)) * 100',
 ARRAY[]::text[], ARRAY['whatsapp', 'telegram', 'gmail', 'instagram', 'facebook', 'slack', 'discord', 'youtube', 'tiktok', 'sms', 'website_chat'],
 'percentage', 1, '', '%', 'gauge', '#F59E0B',
 95.0, 'Customer service benchmark', 'higher',
 true, ARRAY['response', 'service', 'messaging'], '↩️', 'Higher response rate indicates better customer service', '87.3%'),

-- Bot vs Human Messages
('bot_automation_rate', 'Bot Automation Rate', 'Percentage of messages handled by bots vs humans', 'operational',
 'unified_messages', '(bot_messages / total_messages) * 100', 'calculated', '(COUNT(*) FILTER (WHERE is_from_bot = true) / NULLIF(COUNT(*), 0)) * 100',
 ARRAY[]::text[], ARRAY['whatsapp', 'telegram', 'gmail', 'instagram', 'facebook', 'slack', 'discord'],
 'percentage', 1, '', '%', 'pie', '#8B5CF6',
 30.0, 'Industry automation average', 'optimal',
 true, ARRAY['automation', 'bot', 'efficiency'], '🤖', 'Balance between automation and human touch', '42.1%'),

-- Platform Message Distribution
('whatsapp_volume', 'WhatsApp Messages', 'Total WhatsApp messages', 'engagement',
 'whatsapp_messages', 'COUNT(*)', 'aggregated', 'COUNT(*)',
 ARRAY['whatsapp'], ARRAY['whatsapp'],
 'number', 0, '', '', 'bar', '#25D366',
 NULL, NULL, 'higher',
 true, ARRAY['whatsapp', 'messaging', 'platform'], '📱', 'WhatsApp message volume', '524'),

-- Telegram Volume
('telegram_volume', 'Telegram Messages', 'Total Telegram messages', 'engagement',
 'telegram_messages', 'COUNT(*)', 'aggregated', 'COUNT(*)',
 ARRAY['telegram'], ARRAY['telegram'],
 'number', 0, '', '', 'bar', '#0088CC',
 NULL, NULL, 'higher',
 true, ARRAY['telegram', 'messaging', 'platform'], '✈️', 'Telegram message volume', '312'),

-- Gmail Volume
('gmail_volume', 'Gmail Messages', 'Total Gmail messages', 'engagement',
 'gmail_messages', 'COUNT(*)', 'aggregated', 'COUNT(*)',
 ARRAY['gmail'], ARRAY['gmail'],
 'number', 0, '', '', 'bar', '#EA4335',
 NULL, NULL, 'higher',
 true, ARRAY['gmail', 'email', 'platform'], '📧', 'Gmail message volume', '189'),

-- Active Conversations
('active_conversations', 'Active Conversations', 'Number of ongoing customer conversations', 'engagement',
 'crm_conversations', 'COUNT(*) WHERE status = ''active''', 'aggregated', 'COUNT(*) WHERE status = ''active''',
 ARRAY[]::text[], ARRAY['whatsapp', 'telegram', 'gmail', 'instagram', 'facebook', 'slack', 'discord', 'sms'],
 'number', 0, '', '', 'gauge', '#10B981',
 NULL, NULL, 'higher',
 true, ARRAY['conversations', 'active', 'crm'], '💬', 'Number of ongoing customer conversations', '47'),

-- Conversation Resolution Rate
('conversation_resolution_rate', 'Resolution Rate', 'Percentage of conversations successfully resolved', 'operational',
 'crm_conversations', '(resolved / total) * 100', 'calculated', '(COUNT(*) FILTER (WHERE status = ''resolved'') / NULLIF(COUNT(*), 0)) * 100',
 ARRAY[]::text[], ARRAY['whatsapp', 'telegram', 'gmail', 'instagram', 'facebook', 'slack', 'discord', 'sms'],
 'percentage', 1, '', '%', 'gauge', '#059669',
 85.0, 'Customer service benchmark', 'higher',
 true, ARRAY['resolution', 'service', 'crm'], '✅', 'Higher resolution rate indicates better problem solving', '78.9%'),

-- New Customer Contacts
('new_contacts', 'New Contacts', 'Number of new customers contacted in the last 30 days', 'audience',
 'crm_contacts', 'COUNT(*) WHERE created_at >= NOW() - INTERVAL ''30 days''', 'aggregated', 'COUNT(*) WHERE created_at >= NOW() - INTERVAL ''30 days''',
 ARRAY[]::text[], ARRAY['whatsapp', 'telegram', 'gmail', 'instagram', 'facebook', 'slack', 'discord', 'sms'],
 'number', 0, '', '', 'line', '#8B5CF6',
 NULL, NULL, 'higher',
 true, ARRAY['contacts', 'acquisition', 'crm'], '👋', 'New customer contacts acquired recently', '34'),

-- Customer Lifetime Value
('customer_ltv', 'Customer LTV', 'Average lifetime value per customer', 'financial',
 'crm_contacts', 'total_spent', 'calculated', 'AVG(total_spent) WHERE total_spent > 0',
 ARRAY[]::text[], ARRAY['whatsapp', 'telegram', 'gmail', 'instagram', 'facebook'],
 'currency', 2, '$', '', 'bar', '#DC2626',
 150.0, 'E-commerce average', 'higher',
 true, ARRAY['ltv', 'revenue', 'customers'], '💎', 'Average value each customer brings over time', '$127.45'),

-- Customer Retention Rate
('customer_retention', 'Retention Rate', 'Percentage of customers who made repeat purchases', 'conversion',
 'crm_contacts', '(repeat_customers / total_customers) * 100', 'calculated', '(COUNT(*) FILTER (WHERE total_orders > 1) / NULLIF(COUNT(*) FILTER (WHERE total_orders > 0), 0)) * 100',
 ARRAY[]::text[], ARRAY['whatsapp', 'telegram', 'gmail', 'instagram', 'facebook'],
 'percentage', 1, '', '%', 'gauge', '#7C2D12',
 40.0, 'Retail benchmark', 'higher',
 true, ARRAY['retention', 'customers', 'loyalty'], '🔄', 'Higher retention means more loyal customers', '35.7%'),

-- Customer Satisfaction Score
('satisfaction_score', 'Satisfaction Score', 'Average customer satisfaction rating', 'engagement',
 'whatsapp_messages', 'satisfaction_rating', 'calculated', 'AVG(satisfaction_rating)',
 ARRAY[]::text[], ARRAY['whatsapp', 'telegram'],
 'number', 1, '', '/5', 'gauge', '#F97316',
 4.0, 'Service industry standard', 'higher',
 true, ARRAY['satisfaction', 'quality', 'customer_service'], '⭐', 'Higher scores indicate better customer experience', '4.3/5'),

-- Lead Quality Score
('lead_quality', 'Lead Quality', 'Percentage of leads that convert to customers', 'conversion',
 'campaign_metrics', 'qualified_leads / total_leads * 100', 'calculated', '(qualified_leads / NULLIF(total_leads, 0)) * 100',
 ARRAY[]::text[], ARRAY['google_ads', 'linkedin_ads', 'meta_ads'],
 'percentage', 1, '', '%', 'pie', '#84CC16',
 25.0, 'B2B average', 'higher',
 true, ARRAY['quality', 'leads', 'conversion'], '🏆', 'Higher quality leads are more likely to become customers', '32.1%'),

-- Cost Per Acquisition
('cpa', 'CPA', 'Average cost to acquire one customer', 'financial',
 'campaign_metrics', 'spend / customers_acquired', 'calculated', 'SUM(spend) / NULLIF(SUM(customers_acquired), 0)',
 ARRAY[]::text[], ARRAY['google_ads', 'meta_ads', 'linkedin_ads'],
 'currency', 2, '$', '', 'line', '#BE185D',
 50.0, 'Industry average', 'lower',
 true, ARRAY['acquisition', 'cost', 'customers'], '🎯', 'Lower CPA means more efficient customer acquisition', '$42.30');

-- Insert KPI Categories for better organization (with conflict handling)
INSERT INTO public.kpi_categories (name, display_name, description, icon, color, sort_order) VALUES
('performance', 'Performance', 'Key performance indicators for campaign effectiveness', '📊', '#3B82F6', 1),
('financial', 'Financial', 'Revenue, costs, and profitability metrics', '💰', '#059669', 2),
('audience', 'Audience', 'Reach, impressions, and audience engagement metrics', '👥', '#6366F1', 3),
('operational', 'Operational', 'Response times, efficiency, and service quality metrics', '⚙️', '#64748B', 4),
('conversion', 'Conversion', 'Lead generation, sales, and conversion tracking', '🔄', '#F59E0B', 5),
('engagement', 'Engagement', 'Customer interaction and satisfaction metrics', '💬', '#7C3AED', 6)
ON CONFLICT (name) DO UPDATE SET
    display_name = EXCLUDED.display_name,
    description = EXCLUDED.description,
    icon = EXCLUDED.icon,
    color = EXCLUDED.color,
    sort_order = EXCLUDED.sort_order;

-- Update usage count and popularity for commonly used KPIs
UPDATE public.kpi_library SET 
    usage_count = 100, 
    popularity_score = 0.95 
WHERE name IN ('roas', 'cpc', 'ctr', 'conversion_rate');

UPDATE public.kpi_library SET 
    usage_count = 80, 
    popularity_score = 0.85 
WHERE name IN ('cpl', 'total_revenue', 'total_spend');

UPDATE public.kpi_library SET 
    usage_count = 60, 
    popularity_score = 0.75 
WHERE name IN ('total_impressions', 'total_clicks', 'avg_response_time');

UPDATE public.kpi_library SET 
    usage_count = 40, 
    popularity_score = 0.65 
WHERE name IN ('message_volume', 'satisfaction_score', 'lead_quality', 'cpa');