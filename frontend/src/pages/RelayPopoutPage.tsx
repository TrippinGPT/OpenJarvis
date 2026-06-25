import { useEffect, useState, type CSSProperties, type ReactNode } from 'react';
import {
  Activity,
  ArrowLeft,
  Bot,
  CircleDot,
  ExternalLink,
  Link2,
  MessageSquare,
  Radio,
  ShieldCheck,
  Sparkles,
  ToggleLeft,
  ToggleRight,
  Volume2,
  PlayCircle,
} from 'lucide-react';
import { useNavigate } from 'react-router';
import {
  checkHealth,
  fetchOpenClawBridgeStatus,
  fetchRelayVoicePack,
  playRelayPlaceholderVoice,
  type RelayVoicePack,
} from '../lib/api';
import {
  readRelayPopoutActivity,
  RELAY_POPOUT_ACTIVITY_KEY,
  type RelayPopoutActivity,
} from '../lib/relayPopout';
import { useAppStore } from '../lib/store';

type BridgeState = 'checking' | 'connected' | 'fallback';

function formatActivityTime(timestamp: number): string {
  if (!timestamp) return '--:--:--';
  return new Date(timestamp).toLocaleTimeString([], {
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
  });
}

function HudPanel({
  children,
  className = '',
  cyan = false,
}: {
  children: ReactNode;
  className?: string;
  cyan?: boolean;
}) {
  return (
    <section
      className={`relay-popout-panel relative overflow-hidden ${className}`}
      style={{
        borderColor: cyan ? 'rgba(34, 211, 238, 0.24)' : 'rgba(168, 85, 247, 0.26)',
        background: cyan
          ? 'linear-gradient(145deg, rgba(5, 22, 32, 0.88), rgba(4, 8, 17, 0.94))'
          : 'linear-gradient(145deg, rgba(20, 10, 39, 0.88), rgba(4, 7, 16, 0.95))',
      }}
    >
      {children}
    </section>
  );
}

function MicroReadout({
  label,
  value,
  color = 'rgb(103, 232, 249)',
}: {
  label: string;
  value: string;
  color?: string;
}) {
  return (
    <div className="relay-popout-micro-panel">
      <div className="text-[6px] uppercase tracking-[0.22em]" style={{ color: 'rgba(148, 163, 184, 0.72)' }}>
        {label}
      </div>
      <div className="mt-1 truncate text-[8px] font-semibold uppercase tracking-[0.09em]" style={{ color }}>
        {value}
      </div>
      <div className="mt-1.5 h-px overflow-hidden" style={{ background: 'rgba(148, 163, 184, 0.10)' }}>
        <div
          className="h-full"
          style={{
            width: label === 'Safety' ? '100%' : '72%',
            background: `linear-gradient(90deg, ${color}, transparent)`,
          }}
        />
      </div>
    </div>
  );
}

function StatusRow({
  icon: Icon,
  label,
  detail,
  color,
}: {
  icon: typeof Activity;
  label: string;
  detail: string;
  color: string;
}) {
  return (
    <div className="flex min-w-0 items-center gap-2 py-1.5">
      <div
        className="flex h-5 w-5 shrink-0 items-center justify-center rounded"
        style={{
          color,
          border: `1px solid color-mix(in srgb, ${color} 22%, transparent)`,
          background: `color-mix(in srgb, ${color} 6%, transparent)`,
        }}
      >
        <Icon size={10} />
      </div>
      <div className="min-w-0 flex-1">
        <div className="truncate text-[8px] font-medium uppercase tracking-[0.1em]">{label}</div>
        <div className="truncate text-[7px]" style={{ color: 'rgba(148, 163, 184, 0.72)' }}>
          {detail}
        </div>
      </div>
      <span
        className="h-1.5 w-1.5 shrink-0 rounded-full"
        style={{ background: color, boxShadow: `0 0 8px ${color}` }}
      />
    </div>
  );
}

export function RelayPopoutPage() {
  const navigate = useNavigate();
  const selectedModel = useAppStore((state) => state.selectedModel);
  const localStreamState = useAppStore((state) => state.streamState);
  const relayPlaceholderVoiceEnabled = useAppStore((state) => state.settings.relayPlaceholderVoiceEnabled);
  const updateSettings = useAppStore((state) => state.updateSettings);
  const [backendOnline, setBackendOnline] = useState<boolean | null>(null);
  const [bridgeState, setBridgeState] = useState<BridgeState>('checking');
  const [sharedActivity, setSharedActivity] = useState<RelayPopoutActivity | null>(() =>
    readRelayPopoutActivity(),
  );
  const [voicePack, setVoicePack] = useState<RelayVoicePack | null>(null);
  const [voicePackError, setVoicePackError] = useState<string | null>(null);
  const [voicePlaybackState, setVoicePlaybackState] = useState<'idle' | 'playing' | 'error'>('idle');
  const [voicePlaybackNote, setVoicePlaybackNote] = useState<string>('Manual only');

  useEffect(() => {
    const refreshHealth = () => {
      checkHealth().then(setBackendOnline).catch(() => setBackendOnline(false));
    };
    refreshHealth();
    const interval = window.setInterval(refreshHealth, 30_000);
    return () => window.clearInterval(interval);
  }, []);

  useEffect(() => {
    let cancelled = false;
    fetchOpenClawBridgeStatus()
      .then(() => {
        if (!cancelled) setBridgeState('connected');
      })
      .catch(() => {
        if (!cancelled) setBridgeState('fallback');
      });
    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    const handleStorage = (event: StorageEvent) => {
      if (event.key !== RELAY_POPOUT_ACTIVITY_KEY || !event.newValue) return;
      try {
        setSharedActivity(JSON.parse(event.newValue) as RelayPopoutActivity);
      } catch {
        // Ignore malformed cross-window status and retain the last safe state.
      }
    };
    window.addEventListener('storage', handleStorage);
    return () => window.removeEventListener('storage', handleStorage);
  }, []);

  useEffect(() => {
    let cancelled = false;
    fetchRelayVoicePack()
      .then((pack) => {
        if (cancelled) return;
        setVoicePack(pack);
        setVoicePackError(pack.warning || null);
      })
      .catch((error) => {
        if (cancelled) return;
        setVoicePack(null);
        setVoicePackError(error instanceof Error ? error.message : 'Relay voice pack unavailable');
      });
    return () => {
      cancelled = true;
    };
  }, []);

  const isResponding = localStreamState.isStreaming || Boolean(sharedActivity?.isResponding);
  const activePhase = localStreamState.isStreaming
    ? localStreamState.phase
    : sharedActivity?.phase || '';
  const currentModel = selectedModel || sharedActivity?.model || 'Loading local models...';
  const meshState = isResponding ? 'Responding' : 'Stable';
  const systemState = backendOnline === false ? 'Offline' : backendOnline === null ? 'Checking' : 'Online';
  const bridgeLabel =
    bridgeState === 'connected' ? 'Connected' : bridgeState === 'fallback' ? 'Manifest' : 'Checking';
  const statusLabel = isResponding ? 'RELAY RESPONDING' : 'RELAY ONLINE';
  const lastSync = formatActivityTime(sharedActivity?.updatedAt || 0);
  const voiceStatusLabel = relayPlaceholderVoiceEnabled
    ? voicePlaybackState === 'playing'
      ? 'Playing'
      : voicePack?.synthesis_available
        ? 'Ready'
        : 'Unavailable'
    : 'Off';
  const voiceStyleLabel = voicePack?.active_placeholder_style || 'sarcastic_polish_04';
  const voiceLine = voicePack?.default_placeholder_text || 'Relax. I already fixed it.';

  const handleTogglePlaceholderVoice = () => {
    updateSettings({ relayPlaceholderVoiceEnabled: !relayPlaceholderVoiceEnabled });
    setVoicePlaybackNote('Manual only');
  };

  const handlePlayPlaceholderVoice = async () => {
    if (!relayPlaceholderVoiceEnabled || !voicePack?.synthesis_available || voicePlaybackState === 'playing') {
      return;
    }

    const text = voiceLine;
    setVoicePlaybackState('playing');
    setVoicePlaybackNote(text);

    try {
      const blob = await playRelayPlaceholderVoice(text);
      const objectUrl = URL.createObjectURL(blob);
      const audio = new Audio(objectUrl);
      audio.onended = () => {
        URL.revokeObjectURL(objectUrl);
        setVoicePlaybackState('idle');
      };
      audio.onerror = () => {
        URL.revokeObjectURL(objectUrl);
        setVoicePlaybackState('error');
        setVoicePlaybackNote('Playback failed');
      };
      await audio.play();
    } catch (error) {
      setVoicePlaybackState('error');
      setVoicePlaybackNote(error instanceof Error ? error.message : 'Playback failed');
    }
  };

  return (
    <div className="relay-popout-screen h-screen overflow-y-auto">
      <div className="relay-popout-grid" aria-hidden="true" />
      <div className="relay-popout-scanlines" aria-hidden="true" />
      <div className="relay-popout-screen-glow" aria-hidden="true" />

      <main className="relay-popout-layout relative z-10 mx-auto flex min-h-full flex-col gap-2.5 p-3">
        <HudPanel className="relay-popout-header px-3 py-2.5">
          <header className="flex items-center justify-between gap-3">
            <div className="flex min-w-0 items-center gap-2.5">
              <div className="relay-popout-brand-mark">
                <Sparkles size={14} />
              </div>
              <div className="min-w-0">
                <div className="text-[11px] font-semibold tracking-[0.2em]">TRIPPIN AI</div>
                <div className="mt-0.5 text-[6px] font-semibold tracking-[0.32em]" style={{ color: 'rgb(196, 181, 253)' }}>
                  BUILT DIFFERENT
                </div>
              </div>
            </div>

            <div className="min-w-0 flex-1 text-center">
              <div className="text-[9px] font-semibold uppercase tracking-[0.24em]" style={{ color: 'rgb(103, 232, 249)' }}>
                Relay Companion
              </div>
              <div className="mt-0.5 truncate font-mono text-[6px] uppercase tracking-[0.08em]" style={{ color: 'rgba(148, 163, 184, 0.75)' }}>
                <span className="relay-popout-mode-compact">Companion Mode</span>
                <span className="relay-popout-mode-wide">Monitor Mode</span>
                {' // '}Model // {currentModel}
              </div>
            </div>

            <div
              className="inline-flex shrink-0 items-center gap-1.5 rounded-sm px-2 py-1 text-[6px] font-semibold uppercase tracking-[0.12em]"
              style={{
                color: backendOnline === false ? 'rgb(251, 191, 36)' : 'rgb(134, 239, 172)',
                border:
                  backendOnline === false
                    ? '1px solid rgba(251, 191, 36, 0.24)'
                    : '1px solid rgba(74, 222, 128, 0.22)',
                background:
                  backendOnline === false
                    ? 'rgba(251, 191, 36, 0.06)'
                    : 'rgba(74, 222, 128, 0.055)',
              }}
            >
              <span className="hud-heartbeat" />
              {systemState}
            </div>
          </header>
        </HudPanel>

        <div className="relay-popout-telemetry-grid grid grid-cols-5 gap-1.5">
          {[
            ['SYS', systemState],
            ['BRIDGE', bridgeLabel],
            ['MESH', meshState],
            ['AGENTS', '7 / 7'],
            ['MODE', 'Read-only'],
          ].map(([label, value], index) => (
            <div
              key={label}
              className="relay-popout-telemetry-cell"
              style={{ '--telemetry-accent': index === 1 ? 'rgb(103, 232, 249)' : 'rgb(192, 132, 252)' } as CSSProperties}
            >
              <div>{label}</div>
              <strong>{value}</strong>
            </div>
          ))}
        </div>

        <HudPanel className={`relay-popout-main-hud ${isResponding ? 'relay-popout-main-hud-active' : ''}`}>
          <div className="relay-popout-hud-corners" aria-hidden="true" />
          <div className="relay-popout-hud-grid" aria-hidden="true" />
          <div className="relay-popout-hud-axis relay-popout-hud-axis-x" aria-hidden="true" />
          <div className="relay-popout-hud-axis relay-popout-hud-axis-y" aria-hidden="true" />

          <div className="relay-popout-hud-layout relative z-10 grid h-full grid-cols-[76px_minmax(0,1fr)_76px] items-center gap-2 px-2 py-3">
            <aside className="relay-popout-side-stack space-y-2">
              <MicroReadout label="Model" value={currentModel.replace(':latest', '')} color="rgb(196, 181, 253)" />
              <MicroReadout label="Bridge" value={bridgeLabel} />
              <MicroReadout label="Agents" value="7 / 7 Online" color="rgb(134, 239, 172)" />
            </aside>

            <div className="relay-popout-radar-column flex min-w-0 flex-col items-center">
              <div className={`relay-popout-radar ${isResponding ? 'relay-popout-radar-active' : ''}`}>
                <div className="relay-popout-radar-sweep" />
                <div className="relay-popout-radar-ring relay-popout-radar-ring-1" />
                <div className="relay-popout-radar-ring relay-popout-radar-ring-2" />
                <div className="relay-popout-radar-ring relay-popout-radar-ring-3" />
                <div className="relay-popout-radar-ticks" />
                <span className="relay-popout-radar-dot relay-popout-radar-dot-a" />
                <span className="relay-popout-radar-dot relay-popout-radar-dot-b" />
                <span className="relay-popout-radar-dot relay-popout-radar-dot-c" />
                <div className="relay-popout-radar-core">
                  <span>///</span>
                </div>
                {isResponding && (
                  <div className="relay-popout-wave" aria-label="Relay response activity">
                    {[0, 1, 2, 3, 4].map((bar) => (
                      <span key={bar} style={{ animationDelay: `${bar * 90}ms` }} />
                    ))}
                  </div>
                )}
              </div>

              <div
                className="mt-2 text-[8px] font-semibold uppercase tracking-[0.24em]"
                style={{ color: isResponding ? 'rgb(216, 180, 254)' : 'rgb(103, 232, 249)' }}
              >
                {statusLabel}
              </div>
              <div className="mt-1 max-w-full truncate font-mono text-[6px] uppercase tracking-[0.08em]" style={{ color: 'rgba(148, 163, 184, 0.70)' }}>
                {isResponding ? activePhase || 'Routing local response' : `Sync ${lastSync}`}
              </div>
            </div>

            <aside className="relay-popout-side-stack space-y-2">
              <MicroReadout label="Mesh" value={meshState} color={isResponding ? 'rgb(216, 180, 254)' : 'rgb(103, 232, 249)'} />
              <MicroReadout label="Safety" value="Read-only" color="rgb(134, 239, 172)" />
              <MicroReadout label="Link" value="Local" color="rgb(196, 181, 253)" />
            </aside>
          </div>
        </HudPanel>

        <div className="relay-popout-lower-grid grid grid-cols-[1.35fr_0.9fr] gap-2">
          <HudPanel className="relay-popout-status-panel px-3 py-2.5" cyan>
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-1.5">
                <Radio size={10} style={{ color: 'rgb(103, 232, 249)' }} />
                <h2 className="text-[7px] font-semibold uppercase tracking-[0.18em]">Recent Status</h2>
              </div>
              <span className="font-mono text-[6px]" style={{ color: 'rgba(148, 163, 184, 0.60)' }}>
                {lastSync}
              </span>
            </div>
            <div className="mt-1 divide-y" style={{ borderColor: 'rgba(148, 163, 184, 0.08)' }}>
              <StatusRow
                icon={CircleDot}
                label={isResponding ? 'Response route active' : 'Companion window ready'}
                detail={isResponding ? activePhase || 'Local inference in progress' : 'Waiting for Relay activity'}
                color={isResponding ? 'rgb(216, 180, 254)' : 'rgb(103, 232, 249)'}
              />
              <StatusRow
                icon={Link2}
                label={bridgeState === 'connected' ? 'Bridge linked' : 'Bridge manifest ready'}
                detail={bridgeState === 'connected' ? 'Read-only backend status connected' : 'Static safety manifest available'}
                color="rgb(103, 232, 249)"
              />
              <StatusRow
                icon={ShieldCheck}
                label="Safety boundary active"
                detail="No execution controls exposed"
                color="rgb(134, 239, 172)"
              />
            </div>
          </HudPanel>

          <HudPanel className="relay-popout-signal-panel px-3 py-2.5">
            <div className="flex items-center gap-1.5">
              <Activity size={10} style={{ color: 'rgb(192, 132, 252)' }} />
              <h2 className="text-[7px] font-semibold uppercase tracking-[0.18em]">Signal</h2>
            </div>
            <div className="relay-popout-signal mt-3" aria-hidden="true">
              {[7, 13, 9, 20, 14, 25, 11, 17, 8, 21, 12, 16].map((height, index) => (
                <span
                  key={`${height}-${index}`}
                  style={{
                    height: `${isResponding ? Math.min(28, height + 5) : height}px`,
                    animationDelay: `${index * 70}ms`,
                  }}
                />
              ))}
            </div>
            <div className="mt-3 flex items-center justify-between font-mono text-[6px] uppercase" style={{ color: 'rgba(148, 163, 184, 0.68)' }}>
              <span>{isResponding ? 'Active' : 'Standby'}</span>
              <span>Local</span>
            </div>
          </HudPanel>
        </div>

        <HudPanel className="relay-popout-command-panel px-3 py-2.5">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-1.5">
              <Bot size={10} style={{ color: 'rgb(196, 181, 253)' }} />
              <span className="text-[7px] font-semibold uppercase tracking-[0.18em]">Command Strip</span>
            </div>
            <span className="text-[6px] uppercase tracking-[0.14em]" style={{ color: 'rgb(134, 239, 172)' }}>
              Reference only
            </span>
          </div>
          <div className="mt-2 grid gap-0.5 font-mono text-[7px] leading-relaxed" style={{ color: 'rgba(165, 243, 252, 0.78)' }}>
            <div><span style={{ color: 'rgb(216, 180, 254)' }}>&gt;</span> relay --status</div>
            <div><span style={{ color: 'rgba(148, 163, 184, 0.70)' }}>System:</span> {systemState}</div>
            <div><span style={{ color: 'rgba(148, 163, 184, 0.70)' }}>Mesh:</span> {meshState}</div>
            <div><span style={{ color: 'rgba(148, 163, 184, 0.70)' }}>Mode:</span> Companion</div>
          </div>
        </HudPanel>

        <HudPanel className="relay-popout-voice-panel px-3 py-2.5" cyan>
          <div className="flex items-center justify-between gap-2">
            <div className="flex items-center gap-1.5">
              <Volume2 size={10} style={{ color: 'rgb(103, 232, 249)' }} />
              <h2 className="text-[7px] font-semibold uppercase tracking-[0.18em]">Placeholder Voice</h2>
            </div>
            <span className="text-[6px] uppercase tracking-[0.14em]" style={{ color: 'rgb(134, 239, 172)' }}>
              Manual only
            </span>
          </div>
          <div className="mt-2 grid gap-2">
            <div className="grid grid-cols-2 gap-2">
              <MicroReadout
                label="Voice"
                value={voicePack?.active_voice || 'af_bella'}
                color="rgb(216, 180, 254)"
              />
              <MicroReadout
                label="Mode"
                value={voicePack?.active_mode || 'sarcastic'}
                color="rgb(103, 232, 249)"
              />
            </div>
            <div className="grid grid-cols-3 gap-2">
              <MicroReadout label="Style" value={voiceStyleLabel} color="rgb(134, 239, 172)" />
              <MicroReadout label="State" value={voiceStatusLabel} color="rgb(103, 232, 249)" />
              <MicroReadout label="Config" value={voicePack?.manual_only ? 'Gated' : 'Open'} color="rgb(196, 181, 253)" />
            </div>
            <div className="rounded-sm border border-white/10 bg-black/25 px-2 py-1.5 text-[7px] leading-relaxed">
              <div className="font-semibold uppercase tracking-[0.14em]" style={{ color: 'rgb(216, 180, 254)' }}>
                {voicePack?.public_label || 'Relay Companion'}
              </div>
              <div className="mt-1 truncate" style={{ color: 'rgba(165, 243, 252, 0.84)' }}>
                {voiceLine}
              </div>
              <div className="mt-1 text-[6px] uppercase tracking-[0.12em]" style={{ color: 'rgba(148, 163, 184, 0.68)' }}>
                {voicePackError || 'Voice playback remains off until you toggle it on.'}
              </div>
            </div>
            <div className="grid grid-cols-[auto_auto_1fr] gap-2">
              <button
                type="button"
                onClick={handleTogglePlaceholderVoice}
                className="relay-popout-nav-button justify-center"
                style={{
                  color: relayPlaceholderVoiceEnabled ? 'rgb(134, 239, 172)' : 'rgb(216, 180, 254)',
                  borderColor: relayPlaceholderVoiceEnabled ? 'rgba(74, 222, 128, 0.24)' : 'rgba(192, 132, 252, 0.24)',
                }}
              >
                {relayPlaceholderVoiceEnabled ? <ToggleRight size={11} /> : <ToggleLeft size={11} />}
                {relayPlaceholderVoiceEnabled ? 'Voice On' : 'Voice Off'}
              </button>
              <button
                type="button"
                onClick={handlePlayPlaceholderVoice}
                disabled={!relayPlaceholderVoiceEnabled || !voicePack?.synthesis_available || voicePlaybackState === 'playing'}
                className="relay-popout-nav-button justify-center"
                style={{
                  color: !relayPlaceholderVoiceEnabled || !voicePack?.synthesis_available
                    ? 'rgba(148, 163, 184, 0.56)'
                    : 'rgb(103, 232, 249)',
                  borderColor: !relayPlaceholderVoiceEnabled || !voicePack?.synthesis_available
                    ? 'rgba(148, 163, 184, 0.16)'
                    : 'rgba(34, 211, 238, 0.24)',
                  opacity: !relayPlaceholderVoiceEnabled || !voicePack?.synthesis_available ? 0.6 : 1,
                }}
              >
                <PlayCircle size={11} />
                Play test line
              </button>
              <div className="min-w-0 text-[6px] uppercase tracking-[0.14em]" style={{ color: 'rgba(148, 163, 184, 0.72)' }}>
                <div className="truncate">Style: {voiceStyleLabel}</div>
                <div className="truncate">Line: {voicePlaybackNote}</div>
              </div>
            </div>
          </div>
        </HudPanel>

        <footer className="relay-popout-footer mt-auto grid grid-cols-2 gap-2">
          <button
            type="button"
            onClick={() => navigate('/dashboard')}
            className="relay-popout-nav-button"
            style={{ color: 'rgb(103, 232, 249)', borderColor: 'rgba(34, 211, 238, 0.22)' }}
          >
            <ArrowLeft size={11} />
            Dashboard
          </button>
          <button
            type="button"
            onClick={() => navigate('/')}
            className="relay-popout-nav-button"
            style={{ color: 'rgb(216, 180, 254)', borderColor: 'rgba(192, 132, 252, 0.22)' }}
          >
            <MessageSquare size={11} />
            Full Chat
            <ExternalLink size={9} />
          </button>
        </footer>
      </main>
    </div>
  );
}
