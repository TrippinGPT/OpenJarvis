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
import relayProjectLanes from '../data/relayProjectLanes.json';
import {
  fetchOpenClawBridgeStatus,
  type OpenClawBridgeStatus,
} from '../lib/api';

const agents = [
  { name: 'Dispatch', role: 'Coordinator', status: 'Online', x: 50, y: 14 },
  { name: 'Recon', role: 'Research Intel', status: 'Scanning', x: 17, y: 32 },
  { name: 'Patch', role: 'Engineering', status: 'Ready', x: 83, y: 32 },
  { name: 'Redline', role: 'Risk Analyst', status: 'Monitoring', x: 14, y: 65 },
  { name: 'Racket', role: 'Narrative Hunter', status: 'Hunting', x: 38, y: 76 },
  { name: 'Hermes', role: 'Local Scout', status: 'Standing by', x: 62, y: 76 },
  { name: 'Veto', role: 'Review Gate', status: 'Clear', x: 86, y: 65 },
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
  const [copiedCommand, setCopiedCommand] = useState<string | null>(null);
  const [bridgeStatus, setBridgeStatus] = useState<OpenClawBridgeStatus | null>(null);
  const [bridgeBackendState, setBridgeBackendState] = useState<
    'loading' | 'connected' | 'fallback'
  >('loading');
  const now = new Date();
  const stamp = now.toISOString().replace('T', ' ').slice(0, 19) + ' UTC';
  const bridgeData = bridgeStatus ?? relayProjectLanes;
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
          <Panel className="min-h-[620px]">
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
            <div className="relative z-10 flex items-start justify-between gap-4 px-5 pt-5">
              <SectionTitle
                icon={Network}
                eyebrow="System Overview"
                title="Agent Network"
                description="Live command routing topology"
              />
              <div
                className="hidden items-center gap-2 rounded-lg px-3 py-2 text-[10px] uppercase tracking-[0.16em] sm:flex"
                style={{
                  color: 'rgb(134, 239, 172)',
                  border: '1px solid rgba(74, 222, 128, 0.18)',
                  background: 'rgba(74, 222, 128, 0.05)',
                }}
              >
                <Radio size={12} />
                Mesh Stable
              </div>
            </div>

            <svg
              className="absolute inset-0 h-full w-full"
              viewBox="0 0 100 100"
              preserveAspectRatio="none"
            >
              {agents.map((agent) => (
                <line
                  key={agent.name}
                  x1="50"
                  y1="50"
                  x2={agent.x}
                  y2={agent.y}
                  stroke="var(--color-accent)"
                  strokeOpacity="0.28"
                  strokeWidth="0.22"
                />
              ))}
              <circle cx="50" cy="50" r="15" fill="none" stroke="var(--color-accent)" strokeOpacity="0.24" strokeWidth="0.2" />
              <circle cx="50" cy="50" r="23" fill="none" stroke="rgb(103,232,249)" strokeOpacity="0.08" strokeWidth="0.16" />
            </svg>

            <div
              className="absolute left-1/2 top-[50%] flex h-44 w-44 items-center justify-center rounded-full text-center sm:h-52 sm:w-52"
              style={{
                transform: 'translate(-50%, -50%)',
                border: '1px solid rgba(192, 132, 252, 0.48)',
                background:
                  'radial-gradient(circle, rgba(168, 85, 247, 0.30), rgba(12, 6, 24, 0.90) 62%, rgba(5, 5, 8, 0.97))',
                boxShadow:
                  '0 0 72px rgba(168, 85, 247, 0.28), inset 0 0 42px rgba(192, 132, 252, 0.13)',
              }}
            >
              <div>
                <div
                  className="mb-2 text-[10px] uppercase tracking-[0.4em]"
                  style={{ color: 'var(--color-accent-hover)' }}
                >
                  Relay
                </div>
                <div className="text-xl font-semibold tracking-wide" style={{ color: 'var(--color-text)' }}>
                  CORE
                </div>
                <div className="mt-2 px-5 text-[10px]" style={{ color: 'var(--color-text-secondary)' }}>
                  Intelligent routing switchboard
                </div>
              </div>
            </div>

            {agents.map((agent) => (
              <div
                key={agent.name}
                className={`absolute ${
                  agent.y >= 60 ? 'w-28 sm:w-32 md:w-36' : 'w-32 sm:w-36'
                } rounded-xl px-3 py-2.5`}
                style={{
                  left: `${agent.x}%`,
                  top: `${agent.y}%`,
                  transform: 'translate(-50%, -50%)',
                  border: '1px solid rgba(192, 132, 252, 0.22)',
                  background: 'rgba(7, 7, 12, 0.88)',
                  backdropFilter: 'blur(14px)',
                  boxShadow: '0 0 20px rgba(168, 85, 247, 0.10)',
                }}
              >
                <div className="flex items-center justify-between gap-2">
                  <div className="truncate text-xs font-semibold" style={{ color: 'var(--color-text)' }}>
                    {agent.name}
                  </div>
                  <span
                    className="h-1.5 w-1.5 shrink-0 rounded-full"
                    style={{
                      background: 'rgb(74, 222, 128)',
                      boxShadow: '0 0 8px rgba(74,222,128,0.75)',
                    }}
                  />
                </div>
                <div className="mt-1 truncate text-[10px]" style={{ color: 'var(--color-accent-hover)' }}>
                  {agent.role}
                </div>
                <div className="mt-1.5 truncate text-[9px]" style={{ color: 'var(--color-text-secondary)' }}>
                  {agent.status}
                </div>
              </div>
            ))}

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

