import { NextRequest, NextResponse } from 'next/server';
import { supabase } from '@/lib/supabase/client';
import { supabaseMultiUserService } from '@/lib/supabase/multi-user-service';

// GET /api/kpis/categories - Fetch all KPI categories
export async function GET(request: NextRequest) {
  try {
    // Categories are public - no auth needed

    const { data: categories, error } = await supabase
      .from('kpi_categories')
      .select('*')
      .eq('is_active', true)
      .order('sort_order', { ascending: true });

    if (error) {
      console.error('Error fetching KPI categories:', error);
      return NextResponse.json({ error: 'Failed to fetch categories' }, { status: 500 });
    }

    return NextResponse.json({ categories });
  } catch (error) {
    console.error('KPI categories API error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}