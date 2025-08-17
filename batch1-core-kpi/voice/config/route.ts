import { NextRequest, NextResponse } from 'next/server';
import { supabaseMultiUserService } from '@/lib/supabase/multi-user-service';

// GET /api/voice/config - Get voice API configuration
export async function GET(request: NextRequest) {
  try {
    // Get current user for authentication
    const currentUser = await supabaseMultiUserService.getCurrentUser();
    if (!currentUser) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    // Check if centralized API keys are available
    const config = {
      elevenlabs: {
        available: !!process.env.ELEVENLABS_API_KEY,
        keySource: process.env.ELEVENLABS_API_KEY ? 'centralized' : null
      },
      sarvam: {
        available: !!process.env.SARVAM_API_KEY,
        keySource: process.env.SARVAM_API_KEY ? 'centralized' : null
      }
    };

    return NextResponse.json(config);
  } catch (error) {
    console.error('Error fetching voice config:', error);
    return NextResponse.json(
      { error: 'Failed to fetch voice configuration' },
      { status: 500 }
    );
  }
}