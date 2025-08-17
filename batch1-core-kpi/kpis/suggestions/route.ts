import { NextRequest, NextResponse } from 'next/server';
import { supabase } from '@/lib/supabase/client';
import { supabaseMultiUserService } from '@/lib/supabase/multi-user-service';

export interface KPISuggestion {
  id: string;
  user_id: string;
  kpi_id: string;
  suggestion_reason: string;
  confidence_score: number;
  priority: number;
  current_value?: number;
  trend_direction?: 'up' | 'down' | 'stable';
  change_percentage?: number;
  benchmark_comparison?: string;
  user_action: 'pending' | 'accepted' | 'dismissed' | 'ignored';
  acted_at?: string;
  expires_at?: string;
  is_active: boolean;
  kpi: {
    id: string;
    name: string;
    display_name: string;
    description: string;
    category: string;
    icon: string;
    chart_color: string;
    benchmark_value?: number;
  };
}

// GET /api/kpis/suggestions - Get AI-powered KPI suggestions for user
export async function GET(request: NextRequest) {
  try {
    const currentUser = await supabaseMultiUserService.getCurrentUser();
    if (!currentUser) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { searchParams } = new URL(request.url);
    const active = searchParams.get('active') !== 'false';
    const limit = parseInt(searchParams.get('limit') || '10');

    let query = supabase
      .from('kpi_suggestions')
      .select(`
        *,
        kpi:kpi_library!inner(
          id,
          name,
          display_name,
          description,
          category,
          icon,
          chart_color,
          benchmark_value,
          help_text
        )
      `)
      .eq('user_id', currentUser)
      .order('priority', { ascending: false })
      .order('confidence_score', { ascending: false })
      .limit(limit);

    if (active) {
      query = query
        .eq('is_active', true)
        .eq('user_action', 'pending')
        .or('expires_at.is.null,expires_at.gt.now()');
    }

    const { data: suggestions, error } = await query;

    if (error) {
      console.error('Error fetching KPI suggestions:', error);
      return NextResponse.json({ error: 'Failed to fetch suggestions' }, { status: 500 });
    }

    return NextResponse.json({ suggestions });
  } catch (error) {
    console.error('KPI suggestions API error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}

// POST /api/kpis/suggestions - Generate new KPI suggestions based on user data
export async function POST(request: NextRequest) {
  try {
    const currentUser = await supabaseMultiUserService.getCurrentUser();
    if (!currentUser) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    // Get user's current dashboard KPIs
    const { data: existingKPIs } = await supabase
      .from('user_dashboard_kpis')
      .select('kpi_id')
      .eq('user_id', currentUser)
      .eq('is_visible', true);

    const existingKPIIds = existingKPIs?.map(k => k.kpi_id) || [];

    // Get user's connected platforms
    const userIntegrations = await supabaseMultiUserService.getUserIntegrations();
    const connectedPlatforms = userIntegrations.map(i => i.platform);

    // Get popular KPIs that user doesn't have yet
    const { data: popularKPIs } = await supabase
      .from('kpi_library')
      .select('*')
      .eq('is_active', true)
      .gte('popularity_score', 0.7)
      .not('id', 'in', `(${existingKPIIds.join(',')})`)
      .limit(5);

    // Get platform-specific KPIs for connected platforms
    const { data: platformKPIs } = await supabase
      .from('kpi_library')
      .select('*')
      .eq('is_active', true)
      .overlaps('supported_platforms', connectedPlatforms)
      .not('id', 'in', `(${existingKPIIds.join(',')})`)
      .limit(3);

    const suggestions = [];
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7); // Suggestions expire in 7 days

    // Add popular KPI suggestions
    for (const kpi of popularKPIs || []) {
      suggestions.push({
        user_id: currentUser,
        kpi_id: kpi.id,
        suggestion_reason: 'trending_kpi',
        confidence_score: 0.8,
        priority: 2,
        expires_at: expiresAt.toISOString(),
        user_action: 'pending',
        is_active: true
      });
    }

    // Add platform-specific suggestions
    for (const kpi of platformKPIs || []) {
      suggestions.push({
        user_id: currentUser,
        kpi_id: kpi.id,
        suggestion_reason: 'new_platform_connected',
        confidence_score: 0.9,
        priority: 3,
        expires_at: expiresAt.toISOString(),
        user_action: 'pending',
        is_active: true
      });
    }

    if (suggestions.length === 0) {
      return NextResponse.json({ 
        message: 'No new suggestions available',
        suggestions: []
      });
    }

    const { data: createdSuggestions, error } = await supabase
      .from('kpi_suggestions')
      .insert(suggestions)
      .select(`
        *,
        kpi:kpi_library!inner(
          id,
          name,
          display_name,
          description,
          category,
          icon,
          chart_color,
          benchmark_value
        )
      `);

    if (error) {
      console.error('Error creating KPI suggestions:', error);
      return NextResponse.json({ error: 'Failed to create suggestions' }, { status: 500 });
    }

    return NextResponse.json({ 
      message: `Generated ${createdSuggestions.length} new suggestions`,
      suggestions: createdSuggestions 
    }, { status: 201 });
  } catch (error) {
    console.error('KPI suggestions creation error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}