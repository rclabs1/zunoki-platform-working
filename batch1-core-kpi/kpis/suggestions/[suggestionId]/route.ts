import { NextRequest, NextResponse } from 'next/server';
import { supabase } from '@/lib/supabase/client';
import { supabaseMultiUserService } from '@/lib/supabase/multi-user-service';

// PUT /api/kpis/suggestions/[suggestionId] - Accept or dismiss a KPI suggestion
export async function PUT(
  request: NextRequest,
  { params }: { params: { suggestionId: string } }
) {
  try {
    const currentUser = await supabaseMultiUserService.getCurrentUser();
    if (!currentUser) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const body = await request.json();
    const { action } = body; // 'accepted', 'dismissed', 'ignored'

    if (!['accepted', 'dismissed', 'ignored'].includes(action)) {
      return NextResponse.json({ 
        error: 'Invalid action. Must be: accepted, dismissed, or ignored' 
      }, { status: 400 });
    }

    // Get the suggestion to ensure it belongs to the user
    const { data: suggestion, error: fetchError } = await supabase
      .from('kpi_suggestions')
      .select('*, kpi:kpi_library!inner(id, name, display_name)')
      .eq('id', params.suggestionId)
      .eq('user_id', currentUser)
      .single();

    if (fetchError || !suggestion) {
      return NextResponse.json({ error: 'Suggestion not found' }, { status: 404 });
    }

    // Update the suggestion
    const { data: updatedSuggestion, error } = await supabase
      .from('kpi_suggestions')
      .update({
        user_action: action,
        acted_at: new Date().toISOString(),
        is_active: action === 'accepted' // Keep active if accepted for tracking
      })
      .eq('id', params.suggestionId)
      .eq('user_id', currentUser)
      .select(`
        *,
        kpi:kpi_library!inner(
          id,
          name,
          display_name,
          description,
          category,
          icon,
          chart_color
        )
      `)
      .single();

    if (error) {
      console.error('Error updating suggestion:', error);
      return NextResponse.json({ error: 'Failed to update suggestion' }, { status: 500 });
    }

    // If accepted, add the KPI to user's dashboard
    if (action === 'accepted') {
      try {
        const { error: dashboardError } = await supabase
          .from('user_dashboard_kpis')
          .insert([
            {
              user_id: currentUser,
              kpi_id: suggestion.kpi_id,
              position_x: 0,
              position_y: 0,
              size_width: 1,
              size_height: 1,
              date_range: '30d',
              is_visible: true,
              is_favorite: false,
              alerts_enabled: false,
              alert_email: true
            }
          ]);

        if (dashboardError && dashboardError.code !== '23505') { // Ignore duplicate errors
          console.error('Error adding KPI to dashboard:', dashboardError);
        }
      } catch (dashboardError) {
        console.warn('Could not add KPI to dashboard automatically:', dashboardError);
      }
    }

    return NextResponse.json({ 
      suggestion: updatedSuggestion,
      message: action === 'accepted' 
        ? 'KPI suggestion accepted and added to dashboard'
        : `KPI suggestion ${action}`
    });
  } catch (error) {
    console.error('Suggestion update error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}

// DELETE /api/kpis/suggestions/[suggestionId] - Delete a suggestion
export async function DELETE(
  request: NextRequest,
  { params }: { params: { suggestionId: string } }
) {
  try {
    const currentUser = await supabaseMultiUserService.getCurrentUser();
    if (!currentUser) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { error } = await supabase
      .from('kpi_suggestions')
      .delete()
      .eq('id', params.suggestionId)
      .eq('user_id', currentUser);

    if (error) {
      console.error('Error deleting suggestion:', error);
      return NextResponse.json({ error: 'Failed to delete suggestion' }, { status: 500 });
    }

    return NextResponse.json({ success: true });
  } catch (error) {
    console.error('Suggestion deletion error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}