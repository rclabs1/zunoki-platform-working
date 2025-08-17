import { NextRequest, NextResponse } from 'next/server';
import { supabase } from '@/lib/supabase/client';
import { supabaseMultiUserService } from '@/lib/supabase/multi-user-service';

export interface UserDashboardKPI {
  id: string;
  user_id: string;
  kpi_id: string;
  position_x: number;
  position_y: number;
  size_width: number;
  size_height: number;
  custom_name?: string;
  custom_target?: number;
  custom_color?: string;
  alerts_enabled: boolean;
  alert_email: boolean;
  alert_threshold_high?: number;
  alert_threshold_low?: number;
  alert_change_percentage?: number;
  date_range: '7d' | '30d' | '90d' | '1y' | 'custom';
  custom_date_start?: string;
  custom_date_end?: string;
  platform_filter?: string[];
  is_visible: boolean;
  is_favorite: boolean;
  last_viewed_at?: string;
  created_at: string;
  updated_at: string;
  // Joined from kpi_library
  kpi: {
    id: string;
    name: string;
    display_name: string;
    description: string;
    category: string;
    format_type: string;
    default_chart_type: string;
    chart_color: string;
    icon: string;
    tags: string[];
  };
}

// GET /api/kpis/dashboard - Get user's dashboard KPIs
export async function GET(request: NextRequest) {
  try {
    const currentUser = await supabaseMultiUserService.getCurrentUser();
    if (!currentUser) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { searchParams } = new URL(request.url);
    const visible = searchParams.get('visible') !== 'false';
    const favorites = searchParams.get('favorites') === 'true';

    let query = supabase
      .from('user_dashboard_kpis')
      .select(`
        *,
        kpi:kpi_library!inner(
          id,
          name,
          display_name,
          description,
          category,
          format_type,
          decimal_places,
          prefix,
          suffix,
          default_chart_type,
          chart_color,
          icon,
          tags,
          help_text
        )
      `)
      .eq('user_id', currentUser)
      .order('position_y', { ascending: true })
      .order('position_x', { ascending: true });

    if (visible) {
      query = query.eq('is_visible', true);
    }

    if (favorites) {
      query = query.eq('is_favorite', true);
    }

    const { data: dashboardKPIs, error } = await query;

    if (error) {
      console.error('Error fetching dashboard KPIs:', error);
      return NextResponse.json({ error: 'Failed to fetch dashboard KPIs' }, { status: 500 });
    }

    return NextResponse.json({ dashboardKPIs });
  } catch (error) {
    console.error('Dashboard KPIs API error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}

// POST /api/kpis/dashboard - Add KPI to user's dashboard
export async function POST(request: NextRequest) {
  try {
    const currentUser = await supabaseMultiUserService.getCurrentUser();
    if (!currentUser) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const body = await request.json();
    const {
      kpi_id,
      position_x = 0,
      position_y = 0,
      size_width = 1,
      size_height = 1,
      custom_name,
      custom_target,
      custom_color,
      date_range = '30d',
      platform_filter,
      is_favorite = false
    } = body;

    if (!kpi_id) {
      return NextResponse.json({ error: 'kpi_id is required' }, { status: 400 });
    }

    // Check if KPI exists and is active
    const { data: kpiExists, error: kpiError } = await supabase
      .from('kpi_library')
      .select('id')
      .eq('id', kpi_id)
      .eq('is_active', true)
      .single();

    if (kpiError || !kpiExists) {
      return NextResponse.json({ error: 'KPI not found or inactive' }, { status: 404 });
    }

    const { data: dashboardKPI, error } = await supabase
      .from('user_dashboard_kpis')
      .insert([
        {
          user_id: currentUser,
          kpi_id,
          position_x,
          position_y,
          size_width,
          size_height,
          custom_name,
          custom_target,
          custom_color,
          date_range,
          platform_filter,
          is_visible: true,
          is_favorite,
          alerts_enabled: false,
          alert_email: true
        }
      ])
      .select(`
        *,
        kpi:kpi_library!inner(
          id,
          name,
          display_name,
          description,
          category,
          format_type,
          default_chart_type,
          chart_color,
          icon,
          tags
        )
      `)
      .single();

    if (error) {
      if (error.code === '23505') {
        return NextResponse.json({ error: 'KPI already exists on dashboard' }, { status: 409 });
      }
      console.error('Error adding KPI to dashboard:', error);
      return NextResponse.json({ error: 'Failed to add KPI to dashboard' }, { status: 500 });
    }

    return NextResponse.json({ dashboardKPI }, { status: 201 });
  } catch (error) {
    console.error('Dashboard KPI creation error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}