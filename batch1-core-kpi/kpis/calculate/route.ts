import { NextRequest, NextResponse } from 'next/server';
import { supabaseMultiUserService } from '@/lib/supabase/multi-user-service';
import { KPICalculationService } from '@/lib/services/kpi-calculation-service';

// GET /api/kpis/calculate?kpis=roas,cpc,message_volume
export async function GET(request: NextRequest) {
  try {
    const currentUser = await supabaseMultiUserService.getCurrentUser();
    if (!currentUser) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { searchParams } = new URL(request.url);
    const kpisParam = searchParams.get('kpis');
    
    if (!kpisParam) {
      return NextResponse.json({ error: 'kpis parameter required' }, { status: 400 });
    }

    const kpiNames = kpisParam.split(',').map(name => name.trim());
    const calculatedKPIs = await KPICalculationService.calculateUserDashboardKPIs(
      currentUser, 
      kpiNames
    );

    return NextResponse.json({ 
      user_id: currentUser,
      kpis: calculatedKPIs,
      calculated_at: new Date().toISOString()
    });
  } catch (error) {
    console.error('KPI calculation error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}

// POST /api/kpis/calculate - Calculate specific KPI
export async function POST(request: NextRequest) {
  try {
    const currentUser = await supabaseMultiUserService.getCurrentUser();
    if (!currentUser) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { kpi_name } = await request.json();
    
    if (!kpi_name) {
      return NextResponse.json({ error: 'kpi_name required' }, { status: 400 });
    }

    const calculatedKPI = await KPICalculationService.calculateKPIValue(
      kpi_name, 
      currentUser
    );

    if (!calculatedKPI) {
      return NextResponse.json({ error: 'KPI calculation failed' }, { status: 404 });
    }

    return NextResponse.json({ 
      user_id: currentUser,
      kpi: calculatedKPI,
      calculated_at: new Date().toISOString()
    });
  } catch (error) {
    console.error('KPI calculation error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}