import { NextRequest, NextResponse } from 'next/server';
import { supabaseMultiUserService } from '@/lib/supabase/multi-user-service';

interface SynthesizeRequest {
  text: string;
  provider: 'elevenlabs' | 'sarvam';
  voiceId?: string;
  settings?: {
    rate?: number;
    pitch?: number;
    volume?: number;
  };
}

// POST /api/voice/synthesize - Synthesize speech using centralized API keys
export async function POST(request: NextRequest) {
  try {
    // Get current user for authentication
    const currentUser = await supabaseMultiUserService.getCurrentUser();
    if (!currentUser) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const body: SynthesizeRequest = await request.json();
    const { text, provider, voiceId, settings } = body;

    if (!text || text.length > 1000) {
      return NextResponse.json(
        { error: 'Text is required and must be less than 1000 characters' },
        { status: 400 }
      );
    }

    let audioBuffer: ArrayBuffer;

    switch (provider) {
      case 'elevenlabs':
        audioBuffer = await synthesizeElevenLabs(text, voiceId, settings);
        break;
      case 'sarvam':
        audioBuffer = await synthesizeSarvam(text, voiceId, settings);
        break;
      default:
        return NextResponse.json(
          { error: 'Invalid provider' },
          { status: 400 }
        );
    }

    // Track usage
    await trackVoiceUsage(currentUser, provider, text.length);

    // Return audio as base64
    const base64Audio = Buffer.from(audioBuffer).toString('base64');
    
    return NextResponse.json({
      audio: base64Audio,
      provider,
      voiceId
    });

  } catch (error) {
    console.error('Voice synthesis error:', error);
    return NextResponse.json(
      { error: error instanceof Error ? error.message : 'Synthesis failed' },
      { status: 500 }
    );
  }
}

async function synthesizeElevenLabs(
  text: string, 
  voiceId: string = 'EXAVITQu4vr4xnSDxMaL', 
  settings: any = {}
): Promise<ArrayBuffer> {
  const apiKey = process.env.ELEVENLABS_API_KEY;
  if (!apiKey) {
    throw new Error('ElevenLabs API key not configured');
  }

  const response = await fetch(`https://api.elevenlabs.io/v1/text-to-speech/${voiceId}`, {
    method: 'POST',
    headers: {
      'Accept': 'audio/mpeg',
      'Content-Type': 'application/json',
      'xi-api-key': apiKey
    },
    body: JSON.stringify({
      text,
      model_id: 'eleven_monolingual_v1',
      voice_settings: {
        stability: 0.5,
        similarity_boost: 0.5,
        style: 0.5,
        use_speaker_boost: true
      }
    })
  });

  if (!response.ok) {
    throw new Error(`ElevenLabs API error: ${response.status}`);
  }

  return await response.arrayBuffer();
}

async function synthesizeSarvam(
  text: string,
  voiceId: string = 'meera',
  settings: any = {}
): Promise<ArrayBuffer> {
  const apiKey = process.env.SARVAM_API_KEY;
  if (!apiKey) {
    throw new Error('Sarvam API key not configured');
  }

  const response = await fetch('https://api.sarvam.ai/text-to-speech', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'API-Subscription-Key': apiKey
    },
    body: JSON.stringify({
      inputs: [text],
      target_language_code: 'en-IN',
      speaker: voiceId,
      pitch: settings.pitch || 0,
      pace: settings.rate || 1.0,
      loudness: settings.volume || 1.0,
      speech_sample_rate: 22050,
      enable_preprocessing: true,
      model: 'bulbul:v1'
    })
  });

  if (!response.ok) {
    throw new Error(`Sarvam API error: ${response.status}`);
  }

  const data = await response.json();
  
  if (!data.audios || data.audios.length === 0) {
    throw new Error('No audio data received from Sarvam');
  }

  // Convert base64 to ArrayBuffer
  const audioBase64 = data.audios[0];
  const audioBuffer = Uint8Array.from(atob(audioBase64), c => c.charCodeAt(0));
  
  return audioBuffer.buffer;
}

async function trackVoiceUsage(userId: string, provider: string, textLength: number) {
  try {
    await supabaseMultiUserService.trackActivity('voice_synthesis', {
      provider,
      textLength,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.warn('Failed to track voice usage:', error);
  }
}