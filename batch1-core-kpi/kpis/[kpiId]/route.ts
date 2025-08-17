import { NextRequest, NextResponse } from 'next/server';
import { supabase } from '@/lib/supabase/client';
import { supabaseMultiUserService } from '@/lib/supabase/multi-user-service';

// GET /api/kpis/[kpiId] - Get specific KPI details
export async function GET(
  request: NextRequest,
  { params }: { params: { kpiId: string } }
) {
  try {
    const currentUser = await supabaseMultiUserService.getCurrentUser();
    if (!currentUser) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { data: kpi, error } = await supabase
      .from('kpi_library')
      .select(`
        *,
        kpi_categories!inner(name, display_name, icon, color)
      `)
      .eq('id', params.kpiId)
      .eq('is_active', true)
      .single();

    if (error) {
      console.error('Error fetching KPI:', error);
      return NextResponse.json({ error: 'KPI not found' }, { status: 404 });
    }

    return NextResponse.json({ kpi });
  } catch (error) {
    console.error('KPI fetch error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}

// PUT /api/kpis/[kpiId] - Update KPI (only custom KPIs)
export async function PUT(
  request: NextRequest,
  { params }: { params: { kpiId: string } }
) {
  try {
    const currentUser = await supabaseMultiUserService.getCurrentUser();
    if (!currentUser) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const body = await request.json();

    // Check if this is a system KPI (cannot be modified)
    const { data: existingKPI, error: fetchError } = await supabase
      .from('kpi_library')
      .select('is_system, created_by')
      .eq('id', params.kpiId)
      .single();

    if (fetchError || !existingKPI) {
      return NextResponse.json({ error: 'KPI not found' }, { status: 404 });
    }

    if (existingKPI.is_system) {
      return NextResponse.json({ error: 'Cannot modify system KPIs' }, { status: 403 });
    }

    if (existingKPI.created_by !== currentUser) {
      return NextResponse.json({ error: 'Can only modify your own KPIs' }, { status: 403 });
    }

    const { data: kpi, error } = await supabase
      .from('kpi_library')
      .update({
        ...body,
        updated_at: new Date().toISOString()
      })
      .eq('id', params.kpiId)
      .select()
      .single();

    if (error) {
      console.error('Error updating KPI:', error);
      return NextResponse.json({ error: 'Failed to update KPI' }, { status: 500 });
    }

    return NextResponse.json({ kpi });
  } catch (error) {
    console.error('KPI update error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}

// DELETE /api/kpis/[kpiId] - Delete custom KPI
export async function DELETE(
  request: NextRequest,
  { params }: { params: { kpiId: string } }
) {
  try {
    const currentUser = await supabaseMultiUserService.getCurrentUser();
    if (!currentUser) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    // Check if this is a system KPI (cannot be deleted)
    const { data: existingKPI, error: fetchError } = await supabase
      .from('kpi_library')
      .select('is_system, created_by')
      .eq('id', params.kpiId)
      .single();

    if (fetchError || !existingKPI) {
      return NextResponse.json({ error: 'KPI not found' }, { status: 404 });
    }

    if (existingKPI.is_system) {
      return NextResponse.json({ error: 'Cannot delete system KPIs' }, { status: 403 });
    }

    if (existingKPI.created_by !== currentUser) {
      return NextResponse.json({ error: 'Can only delete your own KPIs' }, { status: 403 });
    }

    const { error } = await supabase
      .from('kpi_library')
      .update({ is_active: false, updated_at: new Date().toISOString() })
      .eq('id', params.kpiId);

    if (error) {
      console.error('Error deleting KPI:', error);
      return NextResponse.json({ error: 'Failed to delete KPI' }, { status: 500 });
    }

    return NextResponse.json({ success: true });
  } catch (error) {
    console.error('KPI deletion error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}