'use client';

import { useState, useEffect } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Slider } from '@/components/ui/slider';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Volume2, Key, TestTube, Save, RefreshCw } from 'lucide-react';
import { mayaVoiceService, VoiceSettings, VoiceProvider, VoiceConfig } from '@/lib/voice-recognition';

interface MayaVoiceSettingsProps {
  isOpen: boolean;
  onClose: () => void;
}

export function MayaVoiceSettings({ isOpen, onClose }: MayaVoiceSettingsProps) {
  const [settings, setSettings] = useState<VoiceSettings>({
    provider: 'web',
    rate: 0.9,
    pitch: 1,
    volume: 1,
    usePersonalKey: false
  });
  const [isTesting, setIsTesting] = useState(false);
  const [providers, setProviders] = useState<any[]>([]);
  const [voiceConfig, setVoiceConfig] = useState<VoiceConfig | null>(null);

  useEffect(() => {
    if (isOpen) {
      loadCurrentSettings();
      loadProviders();
      loadVoiceConfig();
    }
  }, [isOpen]);

  const loadCurrentSettings = () => {
    const currentSettings = mayaVoiceService.getVoiceSettings();
    setSettings(currentSettings);
  };

  const loadProviders = () => {
    const availableProviders = mayaVoiceService.getAvailableProviders();
    setProviders(availableProviders);
  };

  const loadVoiceConfig = async () => {
    try {
      console.log('🔧 Loading voice config...');
      const config = await mayaVoiceService.loadVoiceConfig();
      console.log('🔧 Voice config loaded:', config);
      console.log('🔧 ElevenLabs available:', config?.elevenlabs?.available);
      console.log('🔧 Sarvam available:', config?.sarvam?.available);
      setVoiceConfig(config);
    } catch (error) {
      console.error('🔧 Failed to load voice config:', error);
      setVoiceConfig(null);
    }
  };

  const handleSettingChange = (key: keyof VoiceSettings, value: any) => {
    setSettings(prev => ({ ...prev, [key]: value }));
  };

  const handleSave = () => {
    mayaVoiceService.updateVoiceSettings(settings);
    onClose();
  };

  const handleTest = async () => {
    setIsTesting(true);
    try {
      // Apply settings temporarily for testing
      mayaVoiceService.updateVoiceSettings(settings);
      
      const testText = "Hello! I'm Zunoki., your AI marketing intelligence assistant. This is how I sound with your current voice settings.";
      await mayaVoiceService.speakResponse(testText);
    } catch (error) {
      console.error('Voice test failed:', error);
    } finally {
      setIsTesting(false);
    }
  };

  const handleReset = () => {
    setSettings({
      provider: 'web',
      rate: 0.9,
      pitch: 1,
      volume: 1
    });
  };

  const getVoiceOptions = () => {
    switch (settings.provider) {
      case 'elevenlabs':
        return [
          { id: 'EXAVITQu4vr4xnSDxMaL', name: 'Bella (Recommended)', category: 'Premade' },
          { id: 'ErXwobaYiN019PkySvjV', name: 'Antoni', category: 'Premade' },
          { id: 'pNInz6obpgDQGcFmaJgB', name: 'Adam', category: 'Premade' },
          { id: 'yoZ06aMxZJJ28mfd3POQ', name: 'Sam', category: 'Premade' }
        ];
      case 'sarvam':
        return [
          { id: 'meera', name: 'Meera (Recommended)', language: 'English (Indian)' },
          { id: 'aditi', name: 'Aditi', language: 'English (Indian)' },
          { id: 'amit', name: 'Amit', language: 'English (Indian)' },
          { id: 'arjun', name: 'Arjun', language: 'English (Indian)' }
        ];
      default:
        return [];
    }
  };

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-3">
            <Volume2 className="h-6 w-6 text-blue-600" />
            Zunoki. Voice Settings
          </DialogTitle>
        </DialogHeader>

        <div className="space-y-6">
          {/* Voice Provider Selection */}
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Voice Provider</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid gap-3">
                {providers.map((provider) => {
                  // Always allow selection - we'll handle availability in the backend
                  const isAvailable = true;
                  const isCentralized = provider.provider !== 'web' && 
                    ((provider.provider === 'elevenlabs' && voiceConfig?.elevenlabs.available) ||
                     (provider.provider === 'sarvam' && voiceConfig?.sarvam.available));
                  
                  const showProPlanBadge = provider.provider !== 'web' && !isCentralized;
                  
                  return (
                    <div
                      key={provider.provider}
                      className={`p-4 border rounded-lg cursor-pointer transition-all ${
                        settings.provider === provider.provider
                          ? 'border-blue-500 bg-blue-50'
                          : 'border-gray-200 hover:border-gray-300'
                      }`}
                      onClick={() => handleSettingChange('provider', provider.provider)}
                    >
                      <div className="flex items-center justify-between">
                        <div>
                          <div className="flex items-center gap-2">
                            <h4 className="font-medium">{provider.name}</h4>
                            {isCentralized && (
                              <Badge variant="secondary" className="text-xs">
                                Included
                              </Badge>
                            )}
                            {showProPlanBadge && (
                              <Badge variant="outline" className="text-xs">
                                Pro Plan Voice Provider
                              </Badge>
                            )}
                          </div>
                          <p className="text-sm text-gray-600">{provider.description}</p>
                          {isCentralized && (
                            <p className="text-xs text-blue-600 mt-1">
                              ✓ Ready to use with your plan
                            </p>
                          )}
                        </div>
                        {settings.provider === provider.provider && (
                          <Badge>Selected</Badge>
                        )}
                      </div>
                    </div>
                  );
                })}
              </div>
            </CardContent>
          </Card>

          {/* API Configuration for Premium Providers */}
          {(settings.provider === 'elevenlabs' || settings.provider === 'sarvam') && (
            <Card>
              <CardHeader>
                <CardTitle className="text-lg flex items-center gap-2">
                  <Key className="h-5 w-5" />
                  API Configuration
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                {/* Show centralized option if available */}
                {((settings.provider === 'elevenlabs' && voiceConfig?.elevenlabs.available) ||
                  (settings.provider === 'sarvam' && voiceConfig?.sarvam.available)) && (
                  <div className="p-3 bg-green-50 border border-green-200 rounded-lg">
                    <div className="flex items-center gap-2 mb-2">
                      <Badge variant="secondary">Recommended</Badge>
                      <span className="text-sm font-medium text-green-800">
                        Use Included API (Free with your plan)
                      </span>
                    </div>
                    <p className="text-xs text-green-700">
                      Premium voice technology included with your subscription. No setup required!
                    </p>
                  </div>
                )}

                {/* Personal API Key Option */}
                <div className="space-y-3">
                  <div className="flex items-center gap-2">
                    <input
                      type="checkbox"
                      id="usePersonalKey"
                      checked={settings.usePersonalKey || false}
                      onChange={(e) => handleSettingChange('usePersonalKey', e.target.checked)}
                      className="rounded"
                    />
                    <Label htmlFor="usePersonalKey" className="text-sm">
                      Use my personal premium voice API key
                    </Label>
                  </div>

                  {settings.usePersonalKey && (
                    <div>
                      <Label htmlFor="apiKey">
                        Your Premium Voice API Key
                      </Label>
                      <Input
                        id="apiKey"
                        type="password"
                        placeholder="Enter your personal premium voice API key"
                        value={settings.apiKey || ''}
                        onChange={(e) => handleSettingChange('apiKey', e.target.value)}
                      />
                      <p className="text-xs text-gray-500 mt-1">
                        {settings.provider === 'elevenlabs' 
                          ? 'Get your API key from elevenlabs.io' 
                          : 'Get your API key from sarvam.ai'}
                      </p>
                    </div>
                  )}
                </div>

                {getVoiceOptions().length > 0 && (
                  <div>
                    <Label htmlFor="voiceId">Voice Selection</Label>
                    <Select
                      value={settings.voiceId || ''}
                      onValueChange={(value) => handleSettingChange('voiceId', value)}
                    >
                      <SelectTrigger>
                        <SelectValue placeholder="Select a voice" />
                      </SelectTrigger>
                      <SelectContent>
                        {getVoiceOptions().map((voice) => (
                          <SelectItem key={voice.id} value={voice.id}>
                            {voice.name}
                            {voice.category && <Badge variant="outline" className="ml-2">{voice.category}</Badge>}
                            {voice.language && <span className="text-xs text-gray-500 ml-2">({voice.language})</span>}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>
                )}
              </CardContent>
            </Card>
          )}

          {/* Voice Parameters */}
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Voice Parameters</CardTitle>
            </CardHeader>
            <CardContent className="space-y-6">
              <div>
                <Label>Speech Rate: {settings.rate?.toFixed(1)}x</Label>
                <Slider
                  value={[settings.rate || 0.9]}
                  onValueChange={([value]) => handleSettingChange('rate', value)}
                  min={0.5}
                  max={2.0}
                  step={0.1}
                  className="mt-2"
                />
                <div className="flex justify-between text-xs text-gray-500 mt-1">
                  <span>Slow</span>
                  <span>Normal</span>
                  <span>Fast</span>
                </div>
              </div>

              <div>
                <Label>Pitch: {settings.pitch?.toFixed(1)}</Label>
                <Slider
                  value={[settings.pitch || 1]}
                  onValueChange={([value]) => handleSettingChange('pitch', value)}
                  min={0.5}
                  max={2.0}
                  step={0.1}
                  className="mt-2"
                />
                <div className="flex justify-between text-xs text-gray-500 mt-1">
                  <span>Low</span>
                  <span>Normal</span>
                  <span>High</span>
                </div>
              </div>

              <div>
                <Label>Volume: {Math.round((settings.volume || 1) * 100)}%</Label>
                <Slider
                  value={[settings.volume || 1]}
                  onValueChange={([value]) => handleSettingChange('volume', value)}
                  min={0.1}
                  max={1.0}
                  step={0.1}
                  className="mt-2"
                />
                <div className="flex justify-between text-xs text-gray-500 mt-1">
                  <span>Quiet</span>
                  <span>Normal</span>
                  <span>Loud</span>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Action Buttons */}
          <div className="flex gap-3">
            <Button
              onClick={handleTest}
              disabled={isTesting}
              variant="outline"
              className="flex-1"
            >
              {isTesting ? (
                <>
                  <RefreshCw className="h-4 w-4 mr-2 animate-spin" />
                  Testing...
                </>
              ) : (
                <>
                  <TestTube className="h-4 w-4 mr-2" />
                  Test Voice
                </>
              )}
            </Button>

            <Button
              onClick={handleReset}
              variant="outline"
            >
              <RefreshCw className="h-4 w-4 mr-2" />
              Reset
            </Button>

            <Button
              onClick={handleSave}
              className="flex-1"
            >
              <Save className="h-4 w-4 mr-2" />
              Save Settings
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}