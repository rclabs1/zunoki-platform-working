import { NextRequest, NextResponse } from 'next/server';
import { supabase } from '@/lib/supabase/client';
import { supabaseMultiUserService } from '@/lib/supabase/multi-user-service';

export interface KPI {
  id: string;
  name: string;
  display_name: string;
  description: string;
  category: string;
  data_source_table: string;
  data_source_column: string;
  calculation_type: 'direct' | 'calculated' | 'aggregated' | 'derived';
  formula: string;
  required_platforms: string[];
  supported_platforms: string[];
  format_type: 'number' | 'currency' | 'percentage' | 'duration' | 'ratio';
  decimal_places: number;
  prefix: string;
  suffix: string;
  default_chart_type: 'line' | 'bar' | 'pie' | 'doughnut' | 'area' | 'gauge';
  chart_color: string;
  benchmark_value: number;
  benchmark_source: string;
  target_direction: 'higher' | 'lower' | 'optimal';
  is_system: boolean;
  tags: string[];
  icon: string;
  help_text: string;
  example_value: string;
  usage_count: number;
  popularity_score: number;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface KPICategory {
  id: string;
  name: string;
  display_name: string;
  description: string;
  icon: string;
  color: string;
  sort_order: number;
  is_active: boolean;
}

// GET /api/kpis - Fetch KPIs with optional filtering
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const category = searchParams.get('category');
    const platform = searchParams.get('platform');
    const search = searchParams.get('search');
    const popular = searchParams.get('popular') === 'true';
    const limit = parseInt(searchParams.get('limit') || '50');

    // System KPIs are public - no auth needed for browsing
    // Auth only needed for user-specific dashboard operations

    // Build query
    let query = supabase
      .from('kpi_library')
      .select(`
        *,
        kpi_categories!inner(name, display_name, icon, color)
      `)
      .eq('is_active', true)
      .order('popularity_score', { ascending: false })
      .limit(limit);

    // Apply filters
    if (category) {
      query = query.eq('category', category);
    }

    if (platform) {
      query = query.contains('supported_platforms', [platform]);
    }

    if (search) {
      query = query.or(`display_name.ilike.%${search}%,description.ilike.%${search}%,tags.cs.{${search}}`);
    }

    if (popular) {
      query = query.gte('popularity_score', 0.7);
    }

    const { data: kpis, error } = await query;

    if (error) {
      console.error('Error fetching KPIs:', error);
      return NextResponse.json({ error: 'Failed to fetch KPIs' }, { status: 500 });
    }

    return NextResponse.json({ kpis });
  } catch (error) {
    console.error('KPI API error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}

// POST /api/kpis - Create custom KPI
export async function POST(request: NextRequest) {
  try {
    const currentUser = await supabaseMultiUserService.getCurrentUser();
    if (!currentUser) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const body = await request.json();
    const {
      name,
      display_name,
      description,
      category,
      data_source_table,
      data_source_column,
      calculation_type,
      formula,
      supported_platforms,
      format_type,
      decimal_places,
      prefix,
      suffix,
      chart_color,
      tags
    } = body;

    // Validate required fields
    if (!name || !display_name || !category || !data_source_table) {
      return NextResponse.json({ 
        error: 'Missing required fields: name, display_name, category, data_source_table' 
      }, { status: 400 });
    }

    const { data: kpi, error } = await supabase
      .from('kpi_library')
      .insert([
        {
          name,
          display_name,
          description,
          category,
          data_source_table,
          data_source_column,
          calculation_type: calculation_type || 'direct',
          formula,
          required_platforms: [],
          supported_platforms: supported_platforms || [],
          format_type: format_type || 'number',
          decimal_places: decimal_places || 2,
          prefix: prefix || '',
          suffix: suffix || '',
          default_chart_type: 'line',
          chart_color: chart_color || '#3B82F6',
          is_system: false,
          created_by: currentUser,
          tags: tags || [],
          is_active: true,
          usage_count: 0,
          popularity_score: 0
        }
      ])
      .select()
      .single();

    if (error) {
      console.error('Error creating KPI:', error);
      return NextResponse.json({ error: 'Failed to create KPI' }, { status: 500 });
    }

    return NextResponse.json({ kpi }, { status: 201 });
  } catch (error) {
    console.error('KPI creation error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}