import { NextRequest, NextResponse } from 'next/server';
import { supabase } from '@/lib/supabase/client';
import { supabaseMultiUserService } from '@/lib/supabase/multi-user-service';

// GET /api/kpis/dashboard/[dashboardKpiId] - Get specific dashboard KPI
export async function GET(
  request: NextRequest,
  { params }: { params: { dashboardKpiId: string } }
) {
  try {
    const currentUser = await supabaseMultiUserService.getCurrentUser();
    if (!currentUser) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { data: dashboardKPI, error } = await supabase
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
          default_chart_type,
          chart_color,
          icon,
          tags
        )
      `)
      .eq('id', params.dashboardKpiId)
      .eq('user_id', currentUser)
      .single();

    if (error) {
      console.error('Error fetching dashboard KPI:', error);
      return NextResponse.json({ error: 'Dashboard KPI not found' }, { status: 404 });
    }

    // Update last viewed timestamp
    await supabase
      .from('user_dashboard_kpis')
      .update({ 
        last_viewed_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      })
      .eq('id', params.dashboardKpiId)
      .eq('user_id', currentUser);

    return NextResponse.json({ dashboardKPI });
  } catch (error) {
    console.error('Dashboard KPI fetch error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}

// PUT /api/kpis/dashboard/[dashboardKpiId] - Update dashboard KPI settings
export async function PUT(
  request: NextRequest,
  { params }: { params: { dashboardKpiId: string } }
) {
  try {
    const currentUser = await supabaseMultiUserService.getCurrentUser();
    if (!currentUser) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const body = await request.json();

    const { data: dashboardKPI, error } = await supabase
      .from('user_dashboard_kpis')
      .update({
        ...body,
        updated_at: new Date().toISOString()
      })
      .eq('id', params.dashboardKpiId)
      .eq('user_id', currentUser)
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
      console.error('Error updating dashboard KPI:', error);
      return NextResponse.json({ error: 'Failed to update dashboard KPI' }, { status: 500 });
    }

    return NextResponse.json({ dashboardKPI });
  } catch (error) {
    console.error('Dashboard KPI update error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}

// DELETE /api/kpis/dashboard/[dashboardKpiId] - Remove KPI from dashboard
export async function DELETE(
  request: NextRequest,
  { params }: { params: { dashboardKpiId: string } }
) {
  try {
    const currentUser = await supabaseMultiUserService.getCurrentUser();
    if (!currentUser) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { error } = await supabase
      .from('user_dashboard_kpis')
      .delete()
      .eq('id', params.dashboardKpiId)
      .eq('user_id', currentUser);

    if (error) {
      console.error('Error removing dashboard KPI:', error);
      return NextResponse.json({ error: 'Failed to remove dashboard KPI' }, { status: 500 });
    }

    return NextResponse.json({ success: true });
  } catch (error) {
    console.error('Dashboard KPI deletion error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}