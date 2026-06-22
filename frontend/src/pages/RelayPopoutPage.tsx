import { useEffect, useMemo, useState } from 'react';
import { ArrowLeft, ExternalLink, MessageSquare, Radio, ShieldCheck, Sparkles } from 'lucide-react';
import { useNavigate } from 'react-router';
import { checkHealth } from '../lib/api';
import {
  readRelayPopoutActivity,
  RELAY_POPOUT_ACTIVITY_KEY,
  type RelayPopoutActivity,
} from '../lib/relayPopout';
import { useAppStore } from '../lib/store';

function formatActivityTime(timestamp: number): string {
  if (!timestamp) return 'Awaiting activity';
  return new Date(timestamp).toLocaleTimeString([], {
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
  });
}

export function RelayPopoutPage() {
  const navigate = useNavigate();
  const selectedModel = useAppStore((state) => state.selectedModel);
  const localStreamState = useAppStore((state) => state.streamState);
  const [backendOnline, setBackendOnline] = useState<boolean | null>(null);
  const [sharedActivity, setSharedActivity] = useState<RelayPopoutActivity | null>(() =>
    readRelayPopoutActivity(),
  );

  useEffect(() => {
    const refreshHealth = () => {
      checkHealth().then(setBackendOnline).catch(() => setBackendOnline(false));
    };
    refreshHealth();
    const interval = window.setInterval(refreshHealth, 30_000);
    return () => window.clearInterval(interval);
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

  const isResponding = localStreamState.isStreaming || Boolean(sharedActivity?.isResponding);
  const activePhase = localStreamState.isStreaming
    ? localStreamState.phase
    : sharedActivity?.phase || '';
  const currentModel = selectedModel || sharedActivity?.model || 'Loading local models...';
  const statusLabel = isResponding ? 'RELAY RESPONDING' : 'RELAY ONLINE';
  const recentStatus = useMemo(
    () => [
      {
        label: isResponding ? 'Response route active' : 'Companion window ready',
        detail: isResponding
          ? activePhase || 'Local inference in progress'
          : 'Standing by for a full-chat handoff',
        color: isResponding ? 'rgb(216, 180, 254)' : 'rgb(103, 232, 249)',
      },
      {
        label: 'Model link',
        detail: currentModel,
        color: 'rgb(196, 181, 253)',
      },
      {
        label: 'Safety boundary',
        detail: 'No shell, agent auto-run, voice, or OpenClaw execution',
        color: 'rgb(134, 239, 172)',
      },
    ],
    [activePhase, currentModel, isResponding],
  );

  return (
    <div
      className="relative min-h-screen overflow-hidden px-4 py-4"
      style={{
        color: 'var(--color-text)',
        background:
          'radial-gradient(circle at 50% 18%, rgba(126,34,206,0.20), transparent 35%), linear-gradient(180deg, #08070d 0%, #05070b 100%)',
      }}
    >
      <div className="hud-backdrop" aria-hidden="true" />
      <div
        className="pointer-events-none absolute -left-24 -top-28 h-72 w-72 rounded-full blur-3xl"
        style={{ background: 'rgba(126, 34, 206, 0.16)' }}
      />
      <div
        className="pointer-events-none absolute -right-28 top-1/3 h-64 w-64 rounded-full blur-3xl"
        style={{ background: 'rgba(8, 145, 178, 0.09)' }}
      />

      <main className="relative z-10 mx-auto flex min-h-[calc(100vh-2rem)] max-w-[460px] flex-col gap-3">
        <header
          className="rounded-2xl p-4"
          style={{
            border: '1px solid rgba(192, 132, 252, 0.24)',
            background: 'linear-gradient(145deg, rgba(24, 12, 40, 0.94), rgba(7, 9, 15, 0.96))',
            boxShadow: '0 20px 60px rgba(88, 28, 135, 0.18)',
          }}
        >
          <div className="flex items-start justify-between gap-3">
            <div className="flex items-center gap-3">
              <div
                className="flex h-10 w-10 items-center justify-center rounded-xl"
                style={{
                  color: 'rgb(216, 180, 254)',
                  background: 'rgba(168, 85, 247, 0.14)',
                  boxShadow: '0 0 24px rgba(168, 85, 247, 0.22)',
                }}
              >
                <Sparkles size={18} />
              </div>
              <div>
                <div className="text-sm font-semibold tracking-[0.2em]">TRIPPIN AI</div>
                <div
                  className="mt-1 text-[8px] font-semibold tracking-[0.3em]"
                  style={{ color: 'rgb(216, 180, 254)' }}
                >
                  BUILT DIFFERENT
                </div>
              </div>
            </div>
            <div
              className="inline-flex items-center gap-2 rounded-full px-2.5 py-1 text-[8px] uppercase tracking-[0.14em]"
              style={{
                color: backendOnline === false ? 'rgb(251, 191, 36)' : 'rgb(134, 239, 172)',
                border:
                  backendOnline === false
                    ? '1px solid rgba(251, 191, 36, 0.22)'
                    : '1px solid rgba(74, 222, 128, 0.20)',
                background:
                  backendOnline === false
                    ? 'rgba(251, 191, 36, 0.06)'
                    : 'rgba(74, 222, 128, 0.06)',
              }}
            >
              <span className="hud-heartbeat" />
              {backendOnline === null ? 'Checking' : backendOnline ? 'Online' : 'Offline'}
            </div>
          </div>

          <div className="mt-4">
            <div className="text-lg font-semibold tracking-[0.08em]">Smartmouth Relay</div>
            <p className="mt-1 text-xs" style={{ color: 'var(--color-text-secondary)' }}>
              Relay online. Try not to break anything heroic.
            </p>
          </div>
        </header>

        <section
          className="relative overflow-hidden rounded-2xl px-4 py-5"
          style={{
            border: isResponding
              ? '1px solid rgba(216, 180, 254, 0.42)'
              : '1px solid rgba(192, 132, 252, 0.20)',
            background: 'linear-gradient(145deg, rgba(18, 10, 31, 0.94), rgba(7, 10, 16, 0.97))',
            boxShadow: isResponding
              ? '0 0 54px rgba(168, 85, 247, 0.18)'
              : '0 18px 50px rgba(88, 28, 135, 0.10)',
          }}
        >
          <div
            className="pointer-events-none absolute inset-0 opacity-50"
            style={{
              backgroundImage:
                'linear-gradient(rgba(168,85,247,0.04) 1px, transparent 1px), linear-gradient(90deg, rgba(34,211,238,0.035) 1px, transparent 1px)',
              backgroundSize: '28px 28px',
              maskImage: 'radial-gradient(circle at center, black, transparent 72%)',
            }}
          />

          <div className="relative flex flex-col items-center">
            <div className={`relay-popout-orb ${isResponding ? 'relay-popout-orb-active' : ''}`}>
              <div className="relay-popout-ring relay-popout-ring-outer" />
              <div className="relay-popout-ring relay-popout-ring-inner" />
              <div className="relay-popout-core">
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
              className="mt-4 text-[10px] font-semibold uppercase tracking-[0.22em]"
              style={{ color: isResponding ? 'rgb(216, 180, 254)' : 'rgb(103, 232, 249)' }}
            >
              {statusLabel}
            </div>
            <div className="mt-1 text-[10px]" style={{ color: 'var(--color-text-tertiary)' }}>
              {isResponding
                ? activePhase || 'Routing local response'
                : `Last sync: ${formatActivityTime(sharedActivity?.updatedAt || 0)}`}
            </div>
          </div>
        </section>

        <section
          className="rounded-2xl p-4"
          style={{
            border: '1px solid rgba(34, 211, 238, 0.16)',
            background: 'linear-gradient(145deg, rgba(7, 18, 25, 0.90), rgba(8, 8, 14, 0.96))',
          }}
        >
          <div className="flex items-center gap-2">
            <Radio size={14} style={{ color: 'rgb(103, 232, 249)' }} />
            <h2 className="text-xs font-semibold uppercase tracking-[0.16em]">Recent Status</h2>
          </div>
          <div className="mt-3 space-y-2">
            {recentStatus.map((item) => (
              <div
                key={item.label}
                className="rounded-xl p-3"
                style={{
                  border: '1px solid rgba(255,255,255,0.06)',
                  background: 'rgba(255,255,255,0.025)',
                }}
              >
                <div className="flex items-center gap-2 text-[10px] font-medium">
                  <span
                    className="h-1.5 w-1.5 shrink-0 rounded-full"
                    style={{ background: item.color, boxShadow: `0 0 8px ${item.color}` }}
                  />
                  {item.label}
                </div>
                <div
                  className="mt-1 break-words text-[10px] leading-relaxed"
                  style={{ color: 'var(--color-text-tertiary)' }}
                >
                  {item.detail}
                </div>
              </div>
            ))}
          </div>
        </section>

        <section
          className="rounded-2xl p-4"
          style={{
            border: '1px solid rgba(192, 132, 252, 0.16)',
            background: 'rgba(13, 9, 21, 0.90)',
          }}
        >
          <div className="flex items-start gap-3">
            <ShieldCheck size={16} style={{ color: 'rgb(134, 239, 172)' }} />
            <div>
              <div className="text-xs font-medium">Relay companion window ready</div>
              <p className="mt-1 text-[10px] leading-relaxed" style={{ color: 'var(--color-text-tertiary)' }}>
                Chat stays in the full Relay workspace for this first companion release. This
                window provides model, health, and response-state visibility only.
              </p>
            </div>
          </div>
        </section>

        <footer className="mt-auto grid grid-cols-2 gap-2">
          <button
            type="button"
            onClick={() => navigate('/dashboard')}
            className="flex items-center justify-center gap-2 rounded-xl px-3 py-2.5 text-xs font-medium transition-colors"
            style={{
              color: 'rgb(103, 232, 249)',
              border: '1px solid rgba(34, 211, 238, 0.18)',
              background: 'rgba(34, 211, 238, 0.055)',
            }}
          >
            <ArrowLeft size={14} />
            Dashboard
          </button>
          <button
            type="button"
            onClick={() => navigate('/')}
            className="flex items-center justify-center gap-2 rounded-xl px-3 py-2.5 text-xs font-medium transition-colors"
            style={{
              color: 'rgb(216, 180, 254)',
              border: '1px solid rgba(192, 132, 252, 0.20)',
              background: 'rgba(168, 85, 247, 0.075)',
            }}
          >
            <MessageSquare size={14} />
            Full Chat
            <ExternalLink size={12} />
          </button>
        </footer>
      </main>
    </div>
  );
}
