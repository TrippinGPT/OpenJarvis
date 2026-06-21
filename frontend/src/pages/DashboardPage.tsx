import { useEffect, useState, type ReactNode } from 'react';
import {
  Activity,
  Bot,
  Check,
  Copy,
  Cpu,
  FolderKanban,
  GitBranch,
  Link2,
  Network,
  Radio,
  ShieldCheck,
  Sparkles,
  Terminal,
  Zap,
} from 'lucide-react';
import { useNavigate } from 'react-router';
import relayProjectLanes from '../data/relayProjectLanes.json';
import {
  fetchOpenClawBridgeStatus,
  type OpenClawBridgeStatus,
} from '../lib/api';
import { useAppStore } from '../lib/store';

const agents = [
  { name: 'Dispatch', role: 'Coordinator', status: 'Online', x: 50, y: 14 },
  { name: 'Recon', role: 'Research Intel', status: 'Scanning', x: 17, y: 32 },
  { name: 'Patch', role: 'Engineering', status: 'Ready', x: 83, y: 32 },
  { name: 'Redline', role: 'Risk Analyst', status: 'Monitoring', x: 14, y: 65 },
  { name: 'Racket', role: 'Narrative Hunter', status: 'Hunting', x: 38, y: 76 },
  { name: 'Hermes', role: 'Local Scout', status: 'Standing by', x: 62, y: 76 },
  { name: 'Veto', role: 'Review Gate', status: 'Clear', x: 86, y: 65 },
] as const;

type AgentRouteTarget = Lowercase<(typeof agents)[number]['name']>;

const agentDetails: Record<
  AgentRouteTarget,
  {
    purpose: string;
    boundary: string;
    nextAction: string;
  }
> = {
  dispatch: {
    purpose: 'Routes requests and coordinates specialist agents.',
    boundary: 'Coordination only. No destructive actions.',
    nextAction: 'Review the request and choose the safest specialist route.',
  },
  recon: {
    purpose: 'Scans sources, gathers context, and supports research/reporting.',
    boundary: 'Research only. Verify sources before publishing.',
    nextAction: 'Define the research question and list the sources that need verification.',
  },
  patch: {
    purpose: 'Build, fix, test, and repo workflow support.',
    boundary: 'No destructive file operations without explicit approval.',
    nextAction: 'Identify the smallest safe code change and its validation command.',
  },
  redline: {
    purpose: 'Checks safety, scope, boundaries, and operational risk.',
    boundary: 'Does not approve live financial actions.',
    nextAction: 'Review the proposed action for scope, safety, and approval requirements.',
  },
  racket: {
    purpose: 'Tracks hype, trend language, narrative shifts, and signal patterns.',
    boundary: 'Reporting only. No predictions or guaranteed outcomes.',
    nextAction: 'Summarize the current narrative signals without forecasting outcomes.',
  },
  hermes: {
    purpose: 'Local preflight, readiness checks, launcher/logging support.',
    boundary:
      'No registry edits, overclocking, risky service changes, or destructive cleanup.',
    nextAction: 'Run a read-only local readiness check and report blockers.',
  },
  veto: {
    purpose: 'Final review, cleanup, approval/rejection, and incident quality control.',
    boundary: 'Review only unless user explicitly approves next action.',
    nextAction: 'Perform a final review and return an approve, revise, or reject recommendation.',
  },
};

const meshNodeAccents = [
  { color: 'rgb(192, 132, 252)', glow: 'rgba(168, 85, 247, 0.46)' },
  { color: 'rgb(103, 232, 249)', glow: 'rgba(34, 211, 238, 0.42)' },
  { color: 'rgb(74, 222, 128)', glow: 'rgba(74, 222, 128, 0.38)' },
] as const;

const quickCommands = [
  {
    name: 'Start full stack',
    purpose: 'Launch the Relay backend and frontend together.',
    command:
      'powershell -ExecutionPolicy Bypass -File D:\\AI\\TRIPPIN_AI_RELAY\\scripts\\start_relay_stack.ps1',
  },
  {
    name: 'Backend only',
    purpose: 'Start the local Relay API server.',
    command: 'cd D:\\AI\\TRIPPIN_AI_RELAY\nuv run relay serve',
  },
  {
    name: 'Frontend only',
    purpose: 'Start the Vite development server.',
    command: 'cd D:\\AI\\TRIPPIN_AI_RELAY\\frontend\nnpm run dev',
  },
  {
    name: 'Build frontend',
    purpose: 'Create a production frontend build.',
    command: 'cd D:\\AI\\TRIPPIN_AI_RELAY\\frontend\nnpm run build',
  },
  {
    name: 'Git status',
    purpose: 'Check the working tree for local changes.',
    command: 'cd D:\\AI\\TRIPPIN_AI_RELAY\ngit status --short',
  },
  {
    name: 'Recent commits',
    purpose: 'Review the latest Relay commit history.',
    command: 'cd D:\\AI\\TRIPPIN_AI_RELAY\ngit --no-pager log --oneline -8',
  },
  {
    name: 'Run doctor',
    purpose: 'Check the local Relay environment.',
    command: 'cd D:\\AI\\TRIPPIN_AI_RELAY\nuv run relay doctor',
  },
  {
    name: 'Open quick docs',
    purpose: 'Open the practical command reference.',
    command: 'D:\\AI\\TRIPPIN_AI_RELAY\\docs\\RELAY_QUICK_COMMANDS.md',
  },
] as const;

function Panel({
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
      className={`relative overflow-hidden rounded-2xl ${className}`}
      style={{
        border: cyan
          ? '1px solid rgba(34, 211, 238, 0.20)'
          : '1px solid rgba(192, 132, 252, 0.20)',
        background: cyan
          ? 'linear-gradient(145deg, rgba(6, 18, 25, 0.95), rgba(10, 8, 18, 0.97))'
          : 'linear-gradient(145deg, rgba(18, 10, 31, 0.94), rgba(7, 7, 12, 0.98))',
        boxShadow: cyan
          ? '0 18px 60px rgba(8, 145, 178, 0.07)'
          : '0 18px 60px rgba(126, 34, 206, 0.09)',
      }}
    >
      <div
        className="pointer-events-none absolute inset-x-0 top-0 h-px"
        style={{
          background: cyan
            ? 'linear-gradient(90deg, transparent, rgba(103, 232, 249, 0.55), transparent)'
            : 'linear-gradient(90deg, transparent, rgba(216, 180, 254, 0.55), transparent)',
        }}
      />
      {children}
    </section>
  );
}

function SectionTitle({
  icon: Icon,
  eyebrow,
  title,
  description,
  cyan = false,
}: {
  icon: typeof Activity;
  eyebrow: string;
  title: string;
  description?: string;
  cyan?: boolean;
}) {
  return (
    <div className="flex items-start gap-3">
      <div
        className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl"
        style={{
          color: cyan ? 'rgb(103, 232, 249)' : 'var(--color-accent-hover)',
          border: cyan
            ? '1px solid rgba(34, 211, 238, 0.24)'
            : '1px solid rgba(192, 132, 252, 0.24)',
          background: cyan ? 'rgba(34, 211, 238, 0.08)' : 'rgba(168, 85, 247, 0.10)',
        }}
      >
        <Icon size={17} />
      </div>
      <div>
        <div
          className="text-[10px] font-medium uppercase tracking-[0.24em]"
          style={{ color: cyan ? 'rgb(103, 232, 249)' : 'var(--color-accent-hover)' }}
        >
          {eyebrow}
        </div>
        <h2 className="mt-1 text-base font-semibold" style={{ color: 'var(--color-text)' }}>
          {title}
        </h2>
        {description && (
          <p className="mt-1 text-xs leading-relaxed" style={{ color: 'var(--color-text-secondary)' }}>
            {description}
          </p>
        )}
      </div>
    </div>
  );
}

export function DashboardPage() {
  const navigate = useNavigate();
  const [copiedCommand, setCopiedCommand] = useState<string | null>(null);
  const [bridgeStatus, setBridgeStatus] = useState<OpenClawBridgeStatus | null>(null);
  const [previewUntil, setPreviewUntil] = useState(0);
  const [routePreview, setRoutePreview] = useState<{
    target: AgentRouteTarget | null;
    until: number;
  }>({ target: null, until: 0 });
  const [selectedAgent, setSelectedAgent] = useState<AgentRouteTarget>('dispatch');
  const [activityClock, setActivityClock] = useState(() => Date.now());
  const [bridgeBackendState, setBridgeBackendState] = useState<
    'loading' | 'connected' | 'fallback'
  >('loading');
  const isRelayResponding = useAppStore((state) => state.streamState.isStreaming);
  const relayStreamPhase = useAppStore((state) => state.streamState.phase);
  const relayActivityUntil = useAppStore((state) => state.relayActivityUntil);
  const isRelayActivityHeld = activityClock < relayActivityUntil;
  const isPreviewActive = activityClock < previewUntil;
  const isRoutePreviewActive =
    routePreview.target !== null && activityClock < routePreview.until;
  const isGlobalMeshActive =
    isRelayResponding || isRelayActivityHeld || isPreviewActive;
  const isRelayMeshActive = isGlobalMeshActive || isRoutePreviewActive;
  const isRelayRouting =
    isRelayResponding &&
    /research|search|agent thinking|calling/i.test(relayStreamPhase);
  const relayActivityState = isRoutePreviewActive
    ? 'route-preview'
    : isRelayRouting
    ? 'routing'
    : isRelayResponding
      ? 'responding'
      : isPreviewActive
        ? 'preview'
        : isRelayActivityHeld
          ? 'responding'
          : 'idle';
  const relayActivityLabel =
    relayActivityState === 'route-preview'
      ? `Routing to ${routePreview.target?.toUpperCase()}`
      : relayActivityState === 'routing'
      ? 'Relay Routing'
      : relayActivityState === 'responding'
        ? 'Relay Responding'
        : relayActivityState === 'preview'
          ? 'Relay Routing Preview'
          : 'Mesh Stable';
  const now = new Date();
  const stamp = now.toISOString().replace('T', ' ').slice(0, 19) + ' UTC';
  const bridgeData = bridgeStatus ?? relayProjectLanes;
  const selectedAgentSummary =
    agents.find((agent) => agent.name.toLowerCase() === selectedAgent) ?? agents[0];
  const selectedAgentDetails = agentDetails[selectedAgent];
  const selectedAgentAccent =
    meshNodeAccents[
      Math.max(
        0,
        agents.findIndex((agent) => agent.name.toLowerCase() === selectedAgent),
      ) % meshNodeAccents.length
    ];
  const safeReferences = Array.from(
    new Set(bridgeData.lanes.flatMap((lane) => lane.safe_commands)),
  ).slice(0, 5);

  useEffect(() => {
    let cancelled = false;

    fetchOpenClawBridgeStatus()
      .then((status) => {
        if (cancelled) return;
        setBridgeStatus(status);
        setBridgeBackendState('connected');
      })
      .catch(() => {
        if (cancelled) return;
        setBridgeBackendState('fallback');
      });

    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    const currentTime = Date.now();
    const nextExpiry = [relayActivityUntil, previewUntil, routePreview.until]
      .filter((expiry) => expiry > currentTime)
      .sort((a, b) => a - b)[0];

    if (!nextExpiry) return;

    const timeout = window.setTimeout(() => {
      const expiredAt = Date.now();
      setActivityClock(expiredAt);
      setRoutePreview((current) =>
        current.until <= expiredAt ? { target: null, until: 0 } : current,
      );
    }, nextExpiry - currentTime + 25);

    return () => window.clearTimeout(timeout);
  }, [relayActivityUntil, previewUntil, routePreview.until, activityClock]);

  useEffect(() => {
    if (isRelayResponding && previewUntil > 0) {
      setPreviewUntil(0);
    }
  }, [isRelayResponding, previewUntil]);

  const previewActiveMesh = () => {
    const currentTime = Date.now();
    setActivityClock(currentTime);
    setPreviewUntil(currentTime + 8000);
  };

  const previewAgentRoute = (target: AgentRouteTarget | null) => {
    const currentTime = Date.now();
    setActivityClock(currentTime);
    if (target) setSelectedAgent(target);
    setRoutePreview({
      target,
      until: target ? currentTime + 6000 : 0,
    });
  };

  const copyCommand = async (name: string, command: string) => {
    try {
      await navigator.clipboard.writeText(command);
      setCopiedCommand(name);
      window.setTimeout(() => {
        setCopiedCommand((current) => (current === name ? null : current));
      }, 1600);
    } catch {
      setCopiedCommand(null);
    }
  };

  return (
    <div
      className="relative flex-1 overflow-y-auto px-4 py-5 sm:px-6 lg:px-8 lg:py-7"
      style={{ background: '#050508' }}
    >
      <style>{`
        @keyframes relay-core-breathe {
          0%, 100% {
            filter: brightness(0.94);
            box-shadow:
              0 0 24px rgba(168, 85, 247, 0.34),
              0 0 66px rgba(126, 34, 206, 0.20),
              inset 0 0 28px rgba(192, 132, 252, 0.14);
          }
          50% {
            filter: brightness(1.08);
            box-shadow:
              0 0 34px rgba(192, 132, 252, 0.52),
              0 0 94px rgba(126, 34, 206, 0.34),
              inset 0 0 38px rgba(103, 232, 249, 0.16);
          }
        }

        @keyframes relay-core-respond {
          0%, 100% {
            filter: brightness(1);
            box-shadow:
              0 0 34px rgba(192, 132, 252, 0.52),
              0 0 92px rgba(126, 34, 206, 0.32),
              inset 0 0 34px rgba(103, 232, 249, 0.14);
          }
          50% {
            filter: brightness(1.24);
            box-shadow:
              0 0 48px rgba(216, 180, 254, 0.72),
              0 0 124px rgba(126, 34, 206, 0.48),
              inset 0 0 46px rgba(103, 232, 249, 0.25);
          }
        }

        @keyframes relay-orbit-clockwise {
          from { transform: rotate(0deg); }
          to { transform: rotate(360deg); }
        }

        @keyframes relay-orbit-counter {
          from { transform: rotate(360deg); }
          to { transform: rotate(0deg); }
        }

        @keyframes relay-link-travel {
          from { stroke-dashoffset: 0; }
          to { stroke-dashoffset: -10.4; }
        }

        @keyframes relay-link-breathe {
          0%, 100% { opacity: 0.38; }
          50% { opacity: 0.9; }
        }

        @keyframes relay-point-pulse {
          0%, 100% { opacity: 0.5; transform: scale(0.82); }
          50% { opacity: 1; transform: scale(1.22); }
        }

        @keyframes relay-glyph-pulse {
          0%, 100% { opacity: 0.82; transform: scale(0.96); }
          50% { opacity: 1; transform: scale(1.04); }
        }

        @keyframes relay-equalizer {
          0%, 100% { transform: scaleY(0.34); opacity: 0.46; }
          50% { transform: scaleY(0.92); opacity: 0.92; }
        }

        @keyframes relay-status-scan {
          0% { background-position: 180% 0; }
          100% { background-position: -180% 0; }
        }

        .relay-core-shell {
          animation: relay-core-breathe 4.8s ease-in-out infinite;
        }

        .relay-mesh--responding .relay-core-shell {
          animation: relay-core-respond 1.35s ease-in-out infinite;
        }

        .relay-mesh--route-preview .relay-core-shell {
          animation: relay-core-respond 1.55s ease-in-out infinite;
        }

        .relay-orbit {
          transform-box: view-box;
          transform-origin: 50px 50px;
        }

        .relay-orbit--clockwise {
          animation: relay-orbit-clockwise 34s linear infinite;
        }

        .relay-orbit--counter {
          animation: relay-orbit-counter 42s linear infinite;
        }

        .relay-core-orbit {
          transform-box: border-box;
          transform-origin: center;
        }

        .relay-mesh--responding .relay-orbit--clockwise {
          animation-duration: 12s;
        }

        .relay-mesh--responding .relay-orbit--counter {
          animation-duration: 16s;
        }

        .relay-link-trace {
          animation: relay-link-travel 4.4s linear infinite;
        }

        .relay-link-glow {
          animation: relay-link-breathe 3.4s ease-in-out infinite;
        }

        .relay-mesh--responding .relay-link-trace {
          animation-duration: 1.15s;
          stroke-opacity: 0.84;
        }

        .relay-mesh--responding .relay-link-glow {
          animation-duration: 1.1s;
        }

        .relay-mesh--route-preview .relay-route-link--muted {
          animation-duration: 4.8s !important;
          opacity: 0.16;
        }

        .relay-route-link--selected.relay-link-glow {
          animation-duration: 0.7s !important;
          opacity: 1;
          stroke-opacity: 0.82;
          stroke-width: 1.16;
        }

        .relay-route-link--selected.relay-link-trace {
          animation-duration: 0.68s !important;
          opacity: 1;
          stroke-opacity: 1;
          stroke-width: 0.34;
        }

        .relay-connection-point,
        .relay-agent-dot,
        .relay-core-port {
          transform-box: fill-box;
          transform-origin: center;
          animation: relay-point-pulse 2.8s ease-in-out infinite;
        }

        .relay-mesh--responding .relay-connection-point,
        .relay-mesh--responding .relay-agent-dot,
        .relay-mesh--responding .relay-core-port {
          animation-duration: 1s;
        }

        .relay-mesh--route-preview .relay-route-point--muted,
        .relay-mesh--route-preview .relay-route-dot--muted {
          animation-duration: 2.8s !important;
          opacity: 0.38;
        }

        .relay-mesh--route-preview .relay-route-point--selected,
        .relay-mesh--route-preview .relay-route-dot--selected {
          animation-duration: 0.65s !important;
          opacity: 1;
          filter: brightness(1.45);
        }

        .relay-agent-node:hover {
          filter: brightness(1.14);
        }

        .relay-agent-node:focus-visible {
          outline: 1px solid rgba(103, 232, 249, 0.72);
          outline-offset: 3px;
        }

        .relay-core-glyph {
          animation: relay-glyph-pulse 3.2s ease-in-out infinite;
        }

        .relay-mesh--responding .relay-core-glyph {
          animation-duration: 0.9s;
        }

        .relay-equalizer-bar {
          transform-origin: center bottom;
          animation: relay-equalizer 2.6s ease-in-out infinite;
        }

        .relay-mesh--responding .relay-equalizer-bar {
          animation-duration: 0.72s;
        }

        .relay-response-label {
          background-image: linear-gradient(
            90deg,
            rgba(103, 232, 249, 0.52),
            rgba(216, 180, 254, 0.96),
            rgba(103, 232, 249, 0.52)
          );
          background-size: 220% 100%;
          animation: relay-status-scan 2.6s linear infinite;
        }

        @media (prefers-reduced-motion: reduce) {
          .relay-core-shell,
          .relay-orbit,
          .relay-core-orbit,
          .relay-link-trace,
          .relay-link-glow,
          .relay-route-link--selected,
          .relay-connection-point,
          .relay-agent-dot,
          .relay-core-port,
          .relay-core-glyph,
          .relay-equalizer-bar,
          .relay-response-label {
            animation: none !important;
          }
        }
      `}</style>
      <div
        className="pointer-events-none fixed inset-0 opacity-50"
        style={{
          backgroundImage:
            'linear-gradient(rgba(168,85,247,0.025) 1px, transparent 1px), linear-gradient(90deg, rgba(168,85,247,0.025) 1px, transparent 1px)',
          backgroundSize: '42px 42px',
          maskImage: 'linear-gradient(to bottom, black, transparent 78%)',
        }}
      />
      <div
        className="pointer-events-none fixed -left-40 -top-48 h-[520px] w-[520px] rounded-full blur-3xl"
        style={{ background: 'rgba(126, 34, 206, 0.12)' }}
      />
      <div
        className="pointer-events-none fixed -right-40 top-1/3 h-[440px] w-[440px] rounded-full blur-3xl"
        style={{ background: 'rgba(8, 145, 178, 0.07)' }}
      />

      <div className="relative mx-auto max-w-[1480px]">
        <header className="mb-5 grid gap-4 xl:grid-cols-[230px_minmax(0,1fr)_auto] xl:items-center">
          <div
            className="rounded-2xl px-5 py-4"
            style={{
              border: '1px solid rgba(192, 132, 252, 0.24)',
              background:
                'linear-gradient(135deg, rgba(168,85,247,0.14), rgba(8,8,13,0.78))',
              boxShadow: 'inset 0 0 30px rgba(168,85,247,0.06)',
            }}
          >
            <div className="flex items-center gap-3">
              <div
                className="flex h-10 w-10 items-center justify-center rounded-xl"
                style={{
                  color: 'var(--color-accent-hover)',
                  background: 'rgba(168,85,247,0.16)',
                  boxShadow: '0 0 24px rgba(168,85,247,0.22)',
                }}
              >
                <Sparkles size={19} />
              </div>
              <div>
                <div
                  className="text-sm font-semibold tracking-[0.22em]"
                  style={{ color: 'var(--color-text)' }}
                >
                  TRIPPIN AI
                </div>
                <div
                  className="mt-1 text-[9px] font-semibold tracking-[0.32em]"
                  style={{ color: 'var(--color-accent-hover)' }}
                >
                  BUILT DIFFERENT
                </div>
              </div>
            </div>
          </div>

          <div className="min-w-0 px-1">
            <div className="flex flex-wrap items-center gap-3">
              <h1
                className="text-3xl font-semibold tracking-[0.18em] sm:text-4xl"
                style={{ color: 'var(--color-text)' }}
              >
                RELAY
              </h1>
              <span
                className="inline-flex items-center gap-2 rounded-full px-3 py-1 text-[10px] font-medium uppercase tracking-[0.18em]"
                style={{
                  color: 'rgb(134, 239, 172)',
                  border: '1px solid rgba(74, 222, 128, 0.22)',
                  background: 'rgba(74, 222, 128, 0.07)',
                }}
              >
                <span
                  className="h-1.5 w-1.5 rounded-full"
                  style={{
                    background: 'rgb(74, 222, 128)',
                    boxShadow: '0 0 10px rgb(74, 222, 128)',
                  }}
                />
                Online
              </span>
            </div>
            <p className="mt-1 text-sm" style={{ color: 'var(--color-text-secondary)' }}>
              Relay AI Command Assistant
            </p>
          </div>

          <div className="flex flex-wrap gap-2 xl:justify-end">
            <div
              className="rounded-xl px-3 py-2 text-[11px]"
              style={{
                color:
                  bridgeBackendState === 'connected'
                    ? 'rgb(103, 232, 249)'
                    : 'var(--color-text-secondary)',
                border: '1px solid rgba(34, 211, 238, 0.18)',
                background: 'rgba(34, 211, 238, 0.05)',
              }}
            >
              <span className="mr-2 opacity-60">BRIDGE</span>
              {bridgeBackendState === 'connected'
                ? 'CONNECTED'
                : bridgeBackendState === 'fallback'
                  ? 'MANIFEST FALLBACK'
                  : 'CHECKING'}
            </div>
            <div
              className="rounded-xl px-3 py-2 font-mono text-[11px]"
              style={{
                color: 'var(--color-text-tertiary)',
                border: '1px solid var(--color-border)',
                background: 'rgba(255,255,255,0.025)',
              }}
            >
              {stamp}
            </div>
          </div>
        </header>

        <div className="mb-5 grid grid-cols-2 gap-3 lg:grid-cols-4">
          {[
            {
              icon: Bot,
              label: 'Agent Mesh',
              value: '7 / 7 Online',
              detail: 'All specialists responsive',
              color: 'rgb(216, 180, 254)',
            },
            {
              icon: Link2,
              label: 'OpenClaw Bridge',
              value: bridgeBackendState === 'connected' ? 'Connected' : 'Read-only',
              detail: bridgeStatus?.openclaw_git_branch || 'Manifest fallback ready',
              color: 'rgb(103, 232, 249)',
            },
            {
              icon: FolderKanban,
              label: 'Project Lanes',
              value: `${bridgeData.lanes.length} Active`,
              detail: 'Scoped workflow boundaries',
              color: 'rgb(196, 181, 253)',
            },
            {
              icon: ShieldCheck,
              label: 'Safety Mode',
              value: 'Read-only',
              detail: 'No workflow execution',
              color: 'rgb(134, 239, 172)',
            },
          ].map(({ icon: Icon, label, value, detail, color }) => (
            <div
              key={label}
              className="rounded-2xl p-4"
              style={{
                border: '1px solid rgba(255,255,255,0.07)',
                background: 'linear-gradient(145deg, rgba(255,255,255,0.035), rgba(8,8,13,0.62))',
              }}
            >
              <div className="flex items-center justify-between gap-3">
                <div className="text-[10px] uppercase tracking-[0.18em]" style={{ color: 'var(--color-text-tertiary)' }}>
                  {label}
                </div>
                <Icon size={15} style={{ color }} />
              </div>
              <div className="mt-2 text-sm font-semibold" style={{ color: 'var(--color-text)' }}>
                {value}
              </div>
              <div className="mt-1 truncate text-[10px]" style={{ color: 'var(--color-text-secondary)' }}>
                {detail}
              </div>
            </div>
          ))}
        </div>

        <div className="grid grid-cols-1 gap-5 xl:grid-cols-[minmax(0,1.55fr)_minmax(300px,0.65fr)]">
          <Panel
            className={`min-h-[640px] relay-mesh ${
              isGlobalMeshActive ? 'relay-mesh--responding' : ''
            } ${
              isRoutePreviewActive ? 'relay-mesh--route-preview' : ''
            }`}
          >
            <div
              className="sr-only"
              aria-live="polite"
              data-relay-activity={relayActivityState}
              data-preview-active={isPreviewActive}
              data-route-preview={isRoutePreviewActive ? routePreview.target : undefined}
            >
              {relayActivityLabel}
            </div>
            <div className="absolute inset-0 opacity-40">
              <div
                className="absolute inset-0"
                style={{
                  backgroundImage:
                    'linear-gradient(rgba(255,255,255,0.035) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,0.035) 1px, transparent 1px)',
                  backgroundSize: '36px 36px',
                }}
              />
            </div>
            <div
              className="pointer-events-none absolute inset-0"
              style={{
                background:
                  'radial-gradient(circle at 50% 50%, rgba(126, 34, 206, 0.16), transparent 34%), radial-gradient(circle at 52% 48%, rgba(34, 211, 238, 0.07), transparent 22%)',
              }}
            />
            <div className="relative z-10 flex items-start justify-between gap-4 px-5 pt-5">
              <SectionTitle
                icon={Network}
                eyebrow="System Overview"
                title="Agent Network"
                description="Live command routing topology"
              />
              <div className="flex max-w-[260px] flex-col items-end gap-2">
                <div
                  className="hidden items-center gap-2 rounded-lg px-3 py-2 text-[10px] uppercase tracking-[0.16em] sm:flex"
                  style={{
                    color: isRelayMeshActive ? 'rgb(103, 232, 249)' : 'rgb(134, 239, 172)',
                    border: isRelayMeshActive
                      ? '1px solid rgba(34, 211, 238, 0.26)'
                      : '1px solid rgba(74, 222, 128, 0.18)',
                    background: isRelayMeshActive
                      ? 'rgba(34, 211, 238, 0.07)'
                      : 'rgba(74, 222, 128, 0.05)',
                  }}
                >
                  <Radio size={12} />
                  {relayActivityLabel}
                </div>
                <div className="flex flex-wrap justify-end gap-2">
                  <button
                    type="button"
                    onClick={previewActiveMesh}
                    disabled={isRelayResponding}
                    aria-pressed={isPreviewActive}
                    className="rounded-lg px-2.5 py-1.5 text-[9px] font-medium uppercase tracking-[0.12em] transition-opacity disabled:cursor-not-allowed disabled:opacity-40"
                    style={{
                      color: isPreviewActive
                        ? 'rgb(233, 213, 255)'
                        : 'var(--color-text-secondary)',
                      border: isPreviewActive
                        ? '1px solid rgba(192, 132, 252, 0.38)'
                        : '1px solid rgba(255,255,255,0.08)',
                      background: isPreviewActive
                        ? 'rgba(168, 85, 247, 0.12)'
                        : 'rgba(255,255,255,0.025)',
                      boxShadow: isPreviewActive
                        ? '0 0 18px rgba(168, 85, 247, 0.16)'
                        : 'none',
                    }}
                    title="Run an eight-second visual preview. No command or request is sent."
                  >
                    Preview Active Mesh
                  </button>
                  <label className="sr-only" htmlFor="relay-route-preview">
                    Preview an agent route
                  </label>
                  <select
                    id="relay-route-preview"
                    value={isRoutePreviewActive ? routePreview.target ?? '' : ''}
                    onChange={(event) =>
                      previewAgentRoute(
                        event.target.value
                          ? (event.target.value as AgentRouteTarget)
                          : null,
                      )
                    }
                    className="cursor-pointer rounded-lg px-2.5 py-1.5 text-[9px] font-medium uppercase tracking-[0.1em] outline-none"
                    style={{
                      color: isRoutePreviewActive
                        ? 'rgb(103, 232, 249)'
                        : 'var(--color-text-secondary)',
                      border: isRoutePreviewActive
                        ? '1px solid rgba(34, 211, 238, 0.36)'
                        : '1px solid rgba(255,255,255,0.08)',
                      background: isRoutePreviewActive
                        ? 'rgba(34, 211, 238, 0.10)'
                        : 'rgb(13, 12, 20)',
                      boxShadow: isRoutePreviewActive
                        ? '0 0 18px rgba(34, 211, 238, 0.13)'
                        : 'none',
                    }}
                    title="Highlight one agent route for six seconds. Visual preview only."
                  >
                    <option value="">Route Preview</option>
                    {agents.map((agent) => (
                      <option key={agent.name} value={agent.name.toLowerCase()}>
                        {agent.name}
                      </option>
                    ))}
                  </select>
                </div>
              </div>
            </div>

            <svg
              className="pointer-events-none absolute inset-0 h-full w-full"
              viewBox="0 0 100 100"
              preserveAspectRatio="none"
            >
              <defs>
                <radialGradient id="relay-mesh-halo">
                  <stop offset="0%" stopColor="rgb(168, 85, 247)" stopOpacity="0.18" />
                  <stop offset="48%" stopColor="rgb(126, 34, 206)" stopOpacity="0.06" />
                  <stop offset="100%" stopColor="rgb(34, 211, 238)" stopOpacity="0" />
                </radialGradient>
                <linearGradient id="relay-crosshair" x1="0" y1="0" x2="1" y2="1">
                  <stop offset="0%" stopColor="rgb(103, 232, 249)" stopOpacity="0" />
                  <stop offset="50%" stopColor="rgb(192, 132, 252)" stopOpacity="0.28" />
                  <stop offset="100%" stopColor="rgb(103, 232, 249)" stopOpacity="0" />
                </linearGradient>
                <filter id="relay-link-glow" x="-20%" y="-20%" width="140%" height="140%">
                  <feGaussianBlur stdDeviation="0.65" />
                </filter>
              </defs>

              <circle cx="50" cy="50" r="32" fill="url(#relay-mesh-halo)" />
              <line x1="18" y1="50" x2="82" y2="50" stroke="url(#relay-crosshair)" strokeWidth="0.16" />
              <line x1="50" y1="19" x2="50" y2="81" stroke="url(#relay-crosshair)" strokeWidth="0.16" />
              <line x1="28" y1="28" x2="72" y2="72" stroke="url(#relay-crosshair)" strokeWidth="0.1" />
              <line x1="72" y1="28" x2="28" y2="72" stroke="url(#relay-crosshair)" strokeWidth="0.1" />

              {[10, 17, 25, 31].map((radius, index) => (
                <circle
                  key={radius}
                  className={`relay-orbit ${
                    index % 2 === 0 ? 'relay-orbit--clockwise' : 'relay-orbit--counter'
                  }`}
                  cx="50"
                  cy="50"
                  r={radius}
                  fill="none"
                  stroke={index % 2 === 0 ? 'rgb(192, 132, 252)' : 'rgb(103, 232, 249)'}
                  strokeOpacity={index === 0 ? 0.32 : 0.1}
                  strokeWidth={index === 0 ? 0.24 : 0.14}
                  strokeDasharray={index > 1 ? '1.1 1.7' : undefined}
                />
              ))}

              {agents.map((agent, index) => {
                const accent = meshNodeAccents[index % meshNodeAccents.length];
                const pulseX = 50 + (agent.x - 50) * 0.62;
                const pulseY = 50 + (agent.y - 50) * 0.62;
                const agentRoute = agent.name.toLowerCase() as AgentRouteTarget;
                const isSelectedRoute =
                  isRoutePreviewActive && routePreview.target === agentRoute;
                const routeLinkClass = isRoutePreviewActive
                  ? isSelectedRoute
                    ? 'relay-route-link--selected'
                    : 'relay-route-link--muted'
                  : '';
                const routePointClass = isRoutePreviewActive
                  ? isSelectedRoute
                    ? 'relay-route-point--selected'
                    : 'relay-route-point--muted'
                  : '';

                return (
                  <g key={agent.name}>
                    <line
                      className={`relay-link-glow ${routeLinkClass}`}
                      x1="50"
                      y1="50"
                      x2={agent.x}
                      y2={agent.y}
                      stroke={accent.color}
                      strokeOpacity="0.19"
                      strokeWidth="0.72"
                      filter="url(#relay-link-glow)"
                    />
                    <line
                      className={`relay-link-trace ${routeLinkClass}`}
                      x1="50"
                      y1="50"
                      x2={agent.x}
                      y2={agent.y}
                      stroke={accent.color}
                      strokeOpacity="0.54"
                      strokeWidth="0.16"
                      strokeDasharray="1.15 1.45"
                    />
                    <circle
                      className={`relay-connection-point ${routePointClass}`}
                      cx={pulseX}
                      cy={pulseY}
                      r="0.48"
                      fill={accent.color}
                      fillOpacity="0.86"
                      style={{ animationDelay: `${index * -0.34}s` }}
                    />
                    <circle
                      cx={pulseX}
                      cy={pulseY}
                      r="1.15"
                      fill="none"
                      stroke={accent.color}
                      strokeOpacity="0.22"
                      strokeWidth="0.13"
                    />
                  </g>
                );
              })}
            </svg>

            <div
              className="absolute left-1/2 top-[50%] flex h-36 w-36 items-center justify-center rounded-full text-center sm:h-40 sm:w-40"
              style={{
                transform: 'translate(-50%, -50%)',
              }}
            >
              <div
                className="relay-core-shell absolute inset-0 rounded-full"
                style={{
                  border: '1px solid rgba(192, 132, 252, 0.58)',
                  background:
                    'radial-gradient(circle, rgba(192, 132, 252, 0.24), rgba(18, 7, 35, 0.94) 55%, rgba(5, 5, 10, 0.99) 76%)',
                }}
              />
              <div
                className="relay-core-orbit relay-orbit--clockwise absolute inset-2 rounded-full"
                style={{
                  border: '1px dashed rgba(103, 232, 249, 0.26)',
                  transform: 'rotate(22deg)',
                }}
              />
              <div
                className="relay-core-orbit relay-orbit--counter absolute inset-5 rounded-full"
                style={{
                  border: '1px solid rgba(192, 132, 252, 0.28)',
                  boxShadow: 'inset 0 0 18px rgba(34, 211, 238, 0.08)',
                }}
              />
              {[
                'left-1/2 top-0 -translate-x-1/2 -translate-y-1/2',
                'bottom-0 left-1/2 -translate-x-1/2 translate-y-1/2',
                'left-0 top-1/2 -translate-x-1/2 -translate-y-1/2',
                'right-0 top-1/2 translate-x-1/2 -translate-y-1/2',
              ].map((position) => (
                <span
                  key={position}
                  className={`relay-core-port absolute h-1.5 w-1.5 rounded-full ${position}`}
                  style={{
                    background: 'rgb(103, 232, 249)',
                    boxShadow: '0 0 10px rgba(34, 211, 238, 0.9)',
                  }}
                />
              ))}
              <div className="relative z-10">
                <div
                  className="relay-core-glyph font-mono text-2xl font-semibold tracking-[0.18em]"
                  style={{
                    color: 'rgb(233, 213, 255)',
                    textShadow:
                      '0 0 8px rgba(216, 180, 254, 0.9), 0 0 22px rgba(168, 85, 247, 0.75)',
                  }}
                >
                  ///
                </div>
                <div
                  className="mt-2 text-[9px] font-medium uppercase tracking-[0.36em]"
                  style={{ color: 'rgb(216, 180, 254)' }}
                >
                  Relay
                </div>
                <div className="mt-2 flex h-3 items-end justify-center gap-0.5" aria-hidden="true">
                  {[0.45, 0.8, 1, 0.66, 0.38].map((height, index) => (
                    <span
                      key={height}
                      className="relay-equalizer-bar block w-0.5 rounded-full"
                      style={{
                        height: `${height * 100}%`,
                        background:
                          index % 2 === 0 ? 'rgb(192, 132, 252)' : 'rgb(103, 232, 249)',
                        boxShadow:
                          index % 2 === 0
                            ? '0 0 7px rgba(168, 85, 247, 0.78)'
                            : '0 0 7px rgba(34, 211, 238, 0.72)',
                        animationDelay: `${index * -0.22}s`,
                      }}
                    />
                  ))}
                </div>
                <div
                  className={`mt-1.5 text-[8px] uppercase tracking-[0.16em] ${
                    isRelayMeshActive
                      ? 'relay-response-label bg-clip-text text-transparent'
                      : ''
                  }`}
                  style={{
                    color: isRelayMeshActive ? undefined : 'rgba(103, 232, 249, 0.72)',
                  }}
                >
                  {relayActivityState === 'routing'
                    ? 'Routing'
                    : relayActivityState === 'responding'
                      ? 'Responding'
                      : relayActivityState === 'preview'
                        ? 'Routing Preview'
                        : relayActivityState === 'route-preview'
                          ? `To ${routePreview.target?.toUpperCase()}`
                      : 'Switchboard'}
                </div>
              </div>
            </div>

            {agents.map((agent, index) => {
              const accent = meshNodeAccents[index % meshNodeAccents.length];
              const agentRoute = agent.name.toLowerCase() as AgentRouteTarget;
              const isSelectedRoute =
                isRoutePreviewActive && routePreview.target === agentRoute;
              const isMutedRoute =
                isRoutePreviewActive && routePreview.target !== agentRoute;
              const isSelectedAgent = selectedAgent === agentRoute;

              return (
                <button
                  type="button"
                  key={agent.name}
                  onClick={() => previewAgentRoute(agentRoute)}
                  aria-pressed={isSelectedRoute}
                  aria-label={`Preview route to ${agent.name}`}
                  className={`absolute ${
                    agent.y >= 60 ? 'w-28 sm:w-32 md:w-36' : 'w-32 sm:w-36'
                  } relay-agent-node cursor-pointer rounded-xl px-2.5 py-2 text-left transition-[opacity,box-shadow,border-color,filter] duration-300`}
                  style={{
                    left: `${agent.x}%`,
                    top: `${agent.y}%`,
                    transform: 'translate(-50%, -50%)',
                    border: `1px solid ${accent.color
                      .replace('rgb', 'rgba')
                      .replace(
                        ')',
                        isSelectedRoute
                          ? ', 0.76)'
                          : isSelectedAgent
                            ? ', 0.42)'
                            : ', 0.26)',
                      )}`,
                    background:
                      'linear-gradient(135deg, rgba(15, 10, 25, 0.95), rgba(5, 8, 13, 0.92))',
                    backdropFilter: 'blur(14px)',
                    boxShadow: isSelectedRoute
                      ? `0 0 22px ${accent.glow}, 0 0 48px ${accent.glow.replace(
                          /0\.\d+\)/,
                          '0.18)',
                        )}, inset 0 0 22px ${accent.glow.replace(/0\.\d+\)/, '0.12)')}`
                      : isSelectedAgent
                        ? `0 0 24px ${accent.glow.replace(
                            /0\.\d+\)/,
                            '0.18)',
                          )}, inset 0 0 18px rgba(255,255,255,0.025)`
                      : `0 0 20px ${accent.glow.replace(
                          /0\.\d+\)/,
                          '0.12)',
                        )}, inset 0 0 18px rgba(255,255,255,0.018)`,
                    opacity: isMutedRoute ? 0.58 : 1,
                  }}
                >
                  <div className="flex items-center gap-2">
                    <div
                      className="flex h-6 w-6 shrink-0 items-center justify-center rounded-md text-[8px] font-semibold"
                      style={{
                        color: accent.color,
                        border: `1px solid ${accent.color.replace('rgb', 'rgba').replace(')', ', 0.24)')}`,
                        background: accent.glow.replace(/0\.\d+\)/, '0.08)'),
                        boxShadow: `0 0 12px ${accent.glow.replace(/0\.\d+\)/, '0.10)')}`,
                      }}
                    >
                      {agent.name.slice(0, 2).toUpperCase()}
                    </div>
                    <div className="min-w-0 flex-1">
                      <div className="flex items-center justify-between gap-2">
                        <div
                          className="truncate text-[11px] font-medium"
                          style={{ color: 'var(--color-text)' }}
                        >
                          {agent.name}
                        </div>
                        <span
                          className={`relay-agent-dot h-1.5 w-1.5 shrink-0 rounded-full ${
                            isRoutePreviewActive
                              ? isSelectedRoute
                                ? 'relay-route-dot--selected'
                                : 'relay-route-dot--muted'
                              : ''
                          }`}
                          style={{
                            background: accent.color,
                            boxShadow: isSelectedRoute
                              ? `0 0 10px ${accent.glow}, 0 0 20px ${accent.glow}`
                              : `0 0 8px ${accent.glow}`,
                            animationDelay: `${index * -0.28}s`,
                          }}
                        />
                      </div>
                      <div
                        className="mt-0.5 truncate text-[9px]"
                        style={{ color: 'var(--color-text-secondary)' }}
                      >
                        {agent.role}
                      </div>
                    </div>
                  </div>
                  <div
                    className="mt-1.5 flex items-center gap-1.5 border-t pt-1 text-[8px] uppercase tracking-[0.12em]"
                    style={{
                      color: accent.color,
                      borderColor: 'rgba(255,255,255,0.05)',
                    }}
                  >
                    <span className="h-px w-3" style={{ background: accent.color, opacity: 0.5 }} />
                    {agent.status}
                  </div>
                </button>
              );
            })}

            <div
              className="absolute bottom-4 left-4 right-4 flex flex-wrap items-center justify-center gap-x-3 gap-y-1 rounded-xl px-4 py-2.5 text-[9px] uppercase tracking-[0.12em] sm:justify-between"
              style={{
                border: '1px solid rgba(192, 132, 252, 0.15)',
                background: 'rgba(0, 0, 0, 0.38)',
                color: 'var(--color-text-secondary)',
              }}
            >
              <span>Signal In</span>
              <span style={{ color: 'var(--color-accent)' }}>&rarr;</span>
              <span>Relay Routes</span>
              <span style={{ color: 'var(--color-accent)' }}>&rarr;</span>
              <span>OpenClaw Executes</span>
              <span style={{ color: 'var(--color-accent)' }}>&rarr;</span>
              <span>Work Out</span>
            </div>
          </Panel>

          <Panel className="p-5">
            <div className="mb-4 flex items-start justify-between gap-3">
              <SectionTitle
                icon={Activity}
                eyebrow="Operations"
                title="Agent Status"
                description="Specialist availability and current posture"
                cyan
              />
              <div className="text-right">
                <div className="text-lg font-semibold" style={{ color: 'rgb(134, 239, 172)' }}>
                  7/7
                </div>
                <div className="text-[9px] uppercase tracking-[0.18em]" style={{ color: 'var(--color-text-tertiary)' }}>
                  Online
                </div>
              </div>
            </div>
            <div className="flex flex-col gap-2">
              {agents.map((agent, index) => (
                <div
                  key={agent.name}
                  className="group flex items-center gap-3 rounded-xl px-3 py-3"
                  style={{
                    border: '1px solid rgba(255,255,255,0.065)',
                    background:
                      index === 0
                        ? 'linear-gradient(90deg, rgba(168,85,247,0.11), rgba(255,255,255,0.02))'
                        : 'rgba(255,255,255,0.022)',
                  }}
                >
                  <div
                    className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg text-[10px] font-semibold"
                    style={{
                      color: index === 0 ? 'var(--color-accent-hover)' : 'rgb(103, 232, 249)',
                      border: '1px solid rgba(255,255,255,0.08)',
                      background: 'rgba(0,0,0,0.24)',
                    }}
                  >
                    {agent.name.slice(0, 2).toUpperCase()}
                  </div>
                  <div className="min-w-0 flex-1">
                    <div className="flex items-center justify-between gap-2">
                      <div className="truncate text-xs font-semibold" style={{ color: 'var(--color-text)' }}>
                        {agent.name}
                      </div>
                      <div
                        className="shrink-0 text-[9px] uppercase tracking-[0.12em]"
                        style={{ color: 'rgb(134, 239, 172)' }}
                      >
                        {agent.status}
                      </div>
                    </div>
                    <div className="mt-1 truncate text-[10px]" style={{ color: 'var(--color-text-secondary)' }}>
                      {agent.role}
                    </div>
                  </div>
                </div>
              ))}
            </div>
            <div
              className="mt-4 rounded-xl px-3 py-3 text-[10px] leading-relaxed"
              style={{
                color: 'var(--color-text-secondary)',
                border: '1px solid rgba(34,211,238,0.12)',
                background: 'rgba(34,211,238,0.035)',
              }}
            >
              Dispatch coordinates the mesh. Veto remains the final review gate before work leaves
              the command center.
            </div>
          </Panel>
        </div>

        <Panel className="mt-5 p-5 md:p-6">
          <div className="flex flex-col gap-5 lg:flex-row lg:items-start lg:justify-between">
            <div className="flex items-start gap-3">
              <div
                className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl text-xs font-semibold"
                style={{
                  color: selectedAgentAccent.color,
                  border: `1px solid ${selectedAgentAccent.color
                    .replace('rgb', 'rgba')
                    .replace(')', ', 0.34)')}`,
                  background: selectedAgentAccent.glow.replace(/0\.\d+\)/, '0.10)'),
                  boxShadow: `0 0 20px ${selectedAgentAccent.glow.replace(
                    /0\.\d+\)/,
                    '0.13)',
                  )}`,
                }}
              >
                {selectedAgentSummary.name.slice(0, 2).toUpperCase()}
              </div>
              <div>
                <div
                  className="text-[9px] font-medium uppercase tracking-[0.22em]"
                  style={{ color: selectedAgentAccent.color }}
                >
                  Selected Agent
                </div>
                <div className="mt-1 flex flex-wrap items-center gap-2">
                  <h3 className="text-base font-semibold" style={{ color: 'var(--color-text)' }}>
                    {selectedAgentSummary.name}
                  </h3>
                  <span
                    className="rounded-full px-2 py-0.5 text-[8px] uppercase tracking-[0.12em]"
                    style={{
                      color: 'rgb(134, 239, 172)',
                      border: '1px solid rgba(74, 222, 128, 0.18)',
                      background: 'rgba(74, 222, 128, 0.05)',
                    }}
                  >
                    {selectedAgentSummary.status}
                  </span>
                </div>
                <div className="mt-1 text-[11px]" style={{ color: 'var(--color-text-secondary)' }}>
                  {selectedAgentSummary.role}
                </div>
              </div>
            </div>
            <div className="flex flex-wrap gap-2">
              <button
                type="button"
                onClick={() => previewAgentRoute(selectedAgent)}
                className="rounded-lg px-3 py-2 text-[9px] font-medium uppercase tracking-[0.12em]"
                style={{
                  color: 'rgb(103, 232, 249)',
                  border: '1px solid rgba(34, 211, 238, 0.22)',
                  background: 'rgba(34, 211, 238, 0.06)',
                }}
              >
                Preview Route
              </button>
              <button
                type="button"
                onClick={() => navigate('/agents')}
                className="rounded-lg px-3 py-2 text-[9px] font-medium uppercase tracking-[0.12em]"
                style={{
                  color: 'var(--color-accent-hover)',
                  border: '1px solid rgba(192, 132, 252, 0.22)',
                  background: 'rgba(168, 85, 247, 0.07)',
                }}
              >
                Open Agents Tab
              </button>
            </div>
          </div>

          <div className="mt-5 grid gap-3 md:grid-cols-2 xl:grid-cols-3">
            {[
              {
                label: 'Purpose',
                value: selectedAgentDetails.purpose,
              },
              {
                label: 'Safe boundary',
                value: selectedAgentDetails.boundary,
              },
            ].map((detail) => (
              <div
                key={detail.label}
                className="rounded-xl p-3.5"
                style={{
                  border: '1px solid rgba(255,255,255,0.065)',
                  background: 'rgba(255,255,255,0.022)',
                }}
              >
                <div
                  className="text-[9px] uppercase tracking-[0.16em]"
                  style={{ color: 'var(--color-text-tertiary)' }}
                >
                  {detail.label}
                </div>
                <div
                  className="mt-2 text-[11px] leading-relaxed"
                  style={{ color: 'var(--color-text-secondary)' }}
                >
                  {detail.value}
                </div>
              </div>
            ))}
            <div
              className="rounded-xl p-3.5 md:col-span-2 xl:col-span-1"
              style={{
                border: '1px solid rgba(34, 211, 238, 0.12)',
                background: 'rgba(34, 211, 238, 0.035)',
              }}
            >
              <div className="flex items-start justify-between gap-3">
                <div>
                  <div
                    className="text-[9px] uppercase tracking-[0.16em]"
                    style={{ color: 'rgb(103, 232, 249)' }}
                  >
                    Suggested next action
                  </div>
                  <div
                    className="mt-2 text-[11px] leading-relaxed"
                    style={{ color: 'var(--color-text-secondary)' }}
                  >
                    {selectedAgentDetails.nextAction}
                  </div>
                </div>
                <button
                  type="button"
                  onClick={() =>
                    copyCommand(
                      `agent-${selectedAgent}`,
                      selectedAgentDetails.nextAction,
                    )
                  }
                  className="flex shrink-0 items-center gap-1.5 rounded-lg px-2 py-1.5 text-[8px] uppercase tracking-[0.1em]"
                  style={{
                    color:
                      copiedCommand === `agent-${selectedAgent}`
                        ? 'rgb(134, 239, 172)'
                        : 'rgb(103, 232, 249)',
                    border: '1px solid rgba(34, 211, 238, 0.16)',
                    background: 'rgba(0,0,0,0.24)',
                  }}
                  title="Copy reference text"
                >
                  {copiedCommand === `agent-${selectedAgent}` ? (
                    <Check size={11} />
                  ) : (
                    <Copy size={11} />
                  )}
                  {copiedCommand === `agent-${selectedAgent}` ? 'Copied' : 'Copy'}
                </button>
              </div>
            </div>
          </div>
        </Panel>

        <Panel className="mt-5 p-5 md:p-6" cyan>
          <div className="mb-5 flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
            <SectionTitle
              icon={Link2}
              eyebrow="Engine Link"
              title="OpenClaw Bridge Status"
              description="Live read-only integration state with manifest fallback"
              cyan
            />
            <div
              className="flex items-center gap-2 self-start rounded-xl px-3 py-2 text-[10px] uppercase tracking-[0.12em]"
              style={{
                color:
                  bridgeBackendState === 'connected'
                    ? 'rgb(103, 232, 249)'
                    : 'var(--color-text-secondary)',
                border: '1px solid rgba(34, 211, 238, 0.18)',
                background: 'rgba(34, 211, 238, 0.05)',
              }}
            >
              <ShieldCheck size={13} />
              {bridgeBackendState === 'connected'
                ? 'Backend Connected'
                : bridgeBackendState === 'fallback'
                  ? 'Manifest Fallback'
                  : 'Checking Bridge'}
            </div>
          </div>

          <div className="grid gap-4 xl:grid-cols-[0.72fr_1.28fr]">
            <div className="grid content-start gap-3 sm:grid-cols-2 xl:grid-cols-1">
              {[
                { label: 'OpenClaw root', value: bridgeData.openclaw_root, icon: Cpu },
                { label: 'Integration mode', value: bridgeData.integration_mode, icon: Link2 },
                {
                  label: 'Live branch',
                  value: bridgeStatus?.openclaw_git_branch || 'Unavailable',
                  icon: GitBranch,
                },
                {
                  label: 'Working tree',
                  value: bridgeStatus
                    ? bridgeStatus.openclaw_git_status_short.length === 0
                      ? 'Clean'
                      : `${bridgeStatus.openclaw_git_status_short.length} change line(s)`
                    : 'Manifest only',
                  icon: Activity,
                },
              ].map(({ label, value, icon: Icon }) => (
                <div
                  key={label}
                  className="rounded-xl p-3"
                  style={{
                    border: '1px solid rgba(34,211,238,0.13)',
                    background: 'rgba(34,211,238,0.03)',
                  }}
                >
                  <div className="flex items-center gap-2">
                    <Icon size={13} style={{ color: 'rgb(103,232,249)' }} />
                    <div className="text-[9px] uppercase tracking-[0.16em]" style={{ color: 'var(--color-text-tertiary)' }}>
                      {label}
                    </div>
                  </div>
                  <div className="mt-2 break-all font-mono text-[11px]" style={{ color: 'var(--color-text)' }}>
                    {value}
                  </div>
                </div>
              ))}
              <div
                className="rounded-xl p-3 sm:col-span-2 xl:col-span-1"
                style={{
                  border: '1px solid rgba(74,222,128,0.16)',
                  background: 'rgba(74,222,128,0.035)',
                }}
              >
                <div className="flex items-center gap-2 text-[9px] uppercase tracking-[0.16em]" style={{ color: 'rgb(134,239,172)' }}>
                  <ShieldCheck size={13} />
                  Safety Mode
                </div>
                <div className="mt-2 text-[11px]" style={{ color: 'var(--color-text)' }}>
                  Read-only / no workflow execution
                </div>
              </div>
              {bridgeStatus?.warning && (
                <div
                  className="rounded-xl p-3 text-[10px] sm:col-span-2 xl:col-span-1"
                  style={{
                    color: 'rgb(253,224,71)',
                    border: '1px solid rgba(253,224,71,0.18)',
                    background: 'rgba(253,224,71,0.04)',
                  }}
                >
                  {bridgeStatus.warning}
                </div>
              )}
            </div>

            <div>
              <div className="mb-3 flex items-center justify-between gap-3">
                <div>
                  <div className="text-[10px] uppercase tracking-[0.2em]" style={{ color: 'rgb(103,232,249)' }}>
                    Active Projects
                  </div>
                  <div className="mt-1 text-sm font-semibold" style={{ color: 'var(--color-text)' }}>
                    OpenClaw Project Lanes
                  </div>
                </div>
                <div className="text-[10px]" style={{ color: 'var(--color-text-tertiary)' }}>
                  {bridgeData.lanes.length} lanes declared
                </div>
              </div>
              <div className="grid gap-3 md:grid-cols-2">
                {bridgeData.lanes.map((lane) => (
                  <article
                    key={lane.name}
                    className="rounded-xl p-4"
                    style={{
                      border: '1px solid rgba(192,132,252,0.16)',
                      background: 'rgba(8,8,13,0.55)',
                    }}
                  >
                    <div className="flex items-start justify-between gap-3">
                      <div>
                        <h3 className="text-xs font-semibold" style={{ color: 'var(--color-text)' }}>
                          {lane.name}
                        </h3>
                        <p className="mt-1 text-[10px] leading-relaxed" style={{ color: 'var(--color-text-secondary)' }}>
                          {lane.purpose}
                        </p>
                      </div>
                      <span
                        className="shrink-0 rounded-md px-2 py-1 text-[8px] uppercase tracking-[0.12em]"
                        style={{
                          color: 'var(--color-accent-hover)',
                          background: 'rgba(168,85,247,0.09)',
                        }}
                      >
                        {lane.status.replace('_', ' ')}
                      </span>
                    </div>
                    <div
                      className="mt-3 rounded-lg px-3 py-2 text-[9px] leading-relaxed"
                      style={{
                        color: 'rgb(253,224,71)',
                        border: '1px solid rgba(253,224,71,0.10)',
                        background: 'rgba(253,224,71,0.025)',
                      }}
                    >
                      {lane.boundary}
                    </div>
                    <code className="mt-3 block break-all text-[9px]" style={{ color: 'rgb(103,232,249)' }}>
                      {lane.openclaw_path}
                    </code>
                    <div className="mt-3 flex flex-col gap-1.5">
                      {lane.safe_commands.map((command, index) => {
                        const copyKey = `bridge-${lane.name}-${index}`;
                        const copied = copiedCommand === copyKey;
                        return (
                          <div
                            key={command}
                            className="flex items-center gap-2 rounded-lg px-2.5 py-2"
                            style={{
                              border: '1px solid rgba(255,255,255,0.055)',
                              background: 'rgba(0,0,0,0.25)',
                            }}
                          >
                            <code className="min-w-0 flex-1 break-all text-[9px]" style={{ color: 'var(--color-text-secondary)' }}>
                              {command}
                            </code>
                            <button
                              type="button"
                              onClick={() => copyCommand(copyKey, command)}
                              className="shrink-0 cursor-pointer rounded-md p-1.5"
                              style={{
                                color: copied ? 'var(--color-accent-hover)' : 'var(--color-text-tertiary)',
                                background: copied ? 'rgba(168,85,247,0.12)' : 'rgba(255,255,255,0.035)',
                              }}
                              aria-label={`Copy ${lane.name} command reference`}
                              title={copied ? 'Copied' : 'Copy reference'}
                            >
                              {copied ? <Check size={12} /> : <Copy size={12} />}
                            </button>
                          </div>
                        );
                      })}
                    </div>
                  </article>
                ))}
              </div>
            </div>
          </div>
        </Panel>

        <div className="mt-5 grid gap-5 xl:grid-cols-[minmax(0,1.45fr)_minmax(300px,0.55fr)]">
          <Panel className="p-5 md:p-6">
            <div className="mb-5 flex items-start justify-between gap-3">
              <SectionTitle
                icon={Zap}
                eyebrow="Operator Controls"
                title="Relay Quick Commands"
                description="Copy-safe references for local operation"
              />
              <div
                className="hidden rounded-lg px-3 py-2 text-[9px] uppercase tracking-[0.16em] sm:block"
                style={{
                  color: 'var(--color-text-tertiary)',
                  border: '1px solid rgba(255,255,255,0.06)',
                  background: 'rgba(255,255,255,0.025)',
                }}
              >
                Copy Only
              </div>
            </div>
            <div className="grid gap-2.5 md:grid-cols-2">
              {quickCommands.map((item) => {
                const copied = copiedCommand === item.name;
                return (
                  <article
                    key={item.name}
                    className="flex min-w-0 items-start gap-3 rounded-xl p-3"
                    style={{
                      border: '1px solid rgba(255,255,255,0.065)',
                      background: 'rgba(255,255,255,0.022)',
                    }}
                  >
                    <div
                      className="mt-0.5 flex h-8 w-8 shrink-0 items-center justify-center rounded-lg"
                      style={{
                        color: 'var(--color-accent-hover)',
                        background: 'rgba(168,85,247,0.09)',
                      }}
                    >
                      <Terminal size={14} />
                    </div>
                    <div className="min-w-0 flex-1">
                      <div className="flex items-start justify-between gap-2">
                        <div>
                          <h3 className="text-[11px] font-semibold" style={{ color: 'var(--color-text)' }}>
                            {item.name}
                          </h3>
                          <p className="mt-1 text-[9px]" style={{ color: 'var(--color-text-secondary)' }}>
                            {item.purpose}
                          </p>
                        </div>
                        <button
                          type="button"
                          onClick={() => copyCommand(item.name, item.command)}
                          className="shrink-0 cursor-pointer rounded-md p-1.5"
                          style={{
                            color: copied ? 'var(--color-accent-hover)' : 'var(--color-text-tertiary)',
                            background: copied ? 'rgba(168,85,247,0.13)' : 'rgba(255,255,255,0.035)',
                          }}
                          aria-label={`Copy ${item.name} command`}
                          title={copied ? 'Copied' : 'Copy command'}
                        >
                          {copied ? <Check size={13} /> : <Copy size={13} />}
                        </button>
                      </div>
                      <pre
                        className="mt-2 overflow-x-auto whitespace-pre-wrap break-words rounded-lg px-2.5 py-2 text-[9px] leading-relaxed"
                        style={{
                          color: 'var(--color-accent-hover)',
                          background: 'rgba(0,0,0,0.30)',
                        }}
                      >
                        <code>{item.command}</code>
                      </pre>
                    </div>
                  </article>
                );
              })}
            </div>
          </Panel>

          <Panel className="p-5" cyan>
            <SectionTitle
              icon={Terminal}
              eyebrow="Safe Reference"
              title="Command Terminal"
              description="Visual reference only — execution disabled"
              cyan
            />
            <div
              className="mt-5 overflow-hidden rounded-xl font-mono text-[10px]"
              style={{
                border: '1px solid rgba(34,211,238,0.16)',
                background: 'rgba(0,0,0,0.48)',
              }}
            >
              <div
                className="flex items-center gap-2 border-b px-3 py-2"
                style={{ borderColor: 'rgba(34,211,238,0.10)' }}
              >
                <span className="h-2 w-2 rounded-full" style={{ background: '#fb7185' }} />
                <span className="h-2 w-2 rounded-full" style={{ background: '#facc15' }} />
                <span className="h-2 w-2 rounded-full" style={{ background: '#4ade80' }} />
                <span className="ml-2 text-[8px] uppercase tracking-[0.16em]" style={{ color: 'var(--color-text-tertiary)' }}>
                  relay-reference
                </span>
              </div>
              <div className="p-4">
                <div style={{ color: 'rgb(103,232,249)' }}>
                  $ relay bridge status
                </div>
                <div className="mt-1" style={{ color: 'rgb(134,239,172)' }}>
                  connected :: read_only_bridge
                </div>
                <div className="mt-4 space-y-3">
                  {safeReferences.map((command, index) => {
                    const key = `terminal-${index}`;
                    const copied = copiedCommand === key;
                    return (
                      <div key={command} className="flex items-start gap-2">
                        <span style={{ color: 'var(--color-accent)' }}>&gt;</span>
                        <code className="min-w-0 flex-1 break-all" style={{ color: 'var(--color-text-secondary)' }}>
                          {command}
                        </code>
                        <button
                          type="button"
                          onClick={() => copyCommand(key, command)}
                          className="shrink-0 cursor-pointer rounded p-1"
                          style={{ color: copied ? 'rgb(103,232,249)' : 'var(--color-text-tertiary)' }}
                          aria-label="Copy safe command reference"
                          title={copied ? 'Copied' : 'Copy reference'}
                        >
                          {copied ? <Check size={11} /> : <Copy size={11} />}
                        </button>
                      </div>
                    );
                  })}
                </div>
                <div className="mt-5 border-t pt-3 text-[9px]" style={{ color: 'rgb(253,224,71)', borderColor: 'rgba(255,255,255,0.06)' }}>
                  EXECUTION LOCKED — COPY / REFERENCE MODE
                </div>
              </div>
            </div>
            {bridgeStatus?.openclaw_recent_commits?.length ? (
              <div className="mt-4">
                <div className="mb-2 text-[9px] uppercase tracking-[0.16em]" style={{ color: 'var(--color-text-tertiary)' }}>
                  Recent Engine Activity
                </div>
                <div className="space-y-1.5">
                  {bridgeStatus.openclaw_recent_commits.slice(0, 3).map((commit) => (
                    <div
                      key={commit}
                      className="truncate rounded-lg px-2.5 py-2 font-mono text-[9px]"
                      style={{ color: 'var(--color-text-secondary)', background: 'rgba(255,255,255,0.022)' }}
                    >
                      {commit}
                    </div>
                  ))}
                </div>
              </div>
            ) : null}
          </Panel>
        </div>

        <div
          className="mt-5 flex flex-col gap-2 rounded-xl px-4 py-3 text-[9px] uppercase tracking-[0.14em] sm:flex-row sm:items-center sm:justify-between"
          style={{
            color: 'var(--color-text-tertiary)',
            border: '1px solid rgba(255,255,255,0.05)',
            background: 'rgba(255,255,255,0.018)',
          }}
        >
          <span>Relay cockpit // OpenClaw engine</span>
          <span>Read-only bridge // No workflow execution</span>
        </div>
      </div>
    </div>
  );
}

