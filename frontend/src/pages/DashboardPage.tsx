import { useState } from 'react';
import { Check, Copy, Terminal } from 'lucide-react';

const agents = [
  { name: 'Dispatch', role: 'Coordinator', status: 'Routing jobs', x: 50, y: 10 },
  { name: 'Recon', role: 'Research Intel', status: 'Scanning sources', x: 18, y: 32 },
  { name: 'Patch', role: 'Engineering', status: 'Ready for builds', x: 82, y: 32 },
  { name: 'Redline', role: 'Risk Analyst', status: 'Checking limits', x: 22, y: 72 },
  { name: 'Racket', role: 'Narrative Hunter', status: 'Watching signals', x: 38, y: 82 },
  { name: 'Hermes', role: 'Local Scout', status: 'Standing by', x: 62, y: 82 },
  { name: 'Veto', role: 'Review Gate', status: 'Approval queue clear', x: 78, y: 72 },
] as const;

const lanes = [
  { name: 'SignalForge', state: 'Intel reports', note: 'Market and trend reporting lane' },
  { name: 'VisualForge', state: 'Creative pipeline', note: 'Cover art and asset generation' },
  { name: 'PaperForge', state: 'Simulation lab', note: 'Paper trading and education workflows' },
  { name: 'SlapDesk', state: 'Music workflow', note: 'FL Studio to Pro Tools project assist' },
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

export function DashboardPage() {
  const [copiedCommand, setCopiedCommand] = useState<string | null>(null);
  const now = new Date();
  const stamp = now.toISOString().replace('T', ' ').slice(0, 19) + ' UTC';

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
    <div className="flex-1 overflow-y-auto px-6 py-8">
      <div className="max-w-6xl mx-auto">
        <header className="mb-6">
          <div className="flex flex-col gap-3 md:flex-row md:items-end md:justify-between">
            <div>
              <div
                className="text-xs tracking-[0.35em] uppercase mb-2"
                style={{ color: 'var(--color-accent)' }}
              >
                Trippin AI Relay
              </div>
              <h1 className="text-2xl font-semibold" style={{ color: 'var(--color-text)' }}>
                Agent Network View
              </h1>
              <p className="text-sm mt-2 max-w-2xl" style={{ color: 'var(--color-text-secondary)' }}>
                Relay is the data switchboard between the user, OpenClaw Core, and the specialist agents.
                Signal in. Work out.
              </p>
            </div>

            <div className="flex flex-col gap-2 md:items-end">
              <div
                className="text-xs px-3 py-2 rounded-lg"
                style={{
                  color: 'var(--color-accent-hover)',
                  border: '1px solid rgba(192, 132, 252, 0.28)',
                  background: 'rgba(168, 85, 247, 0.10)',
                }}
              >
                Powered by OpenClaw Core
              </div>
              <div
                className="text-xs px-3 py-2 rounded-lg"
                style={{
                  color: 'var(--color-text-tertiary)',
                  border: '1px solid var(--color-border)',
                  background: 'var(--color-bg-secondary)',
                }}
              >
                {stamp}
              </div>
            </div>
          </div>
        </header>

        <div className="grid grid-cols-1 xl:grid-cols-[1.4fr_0.8fr] gap-5">
          <section
            className="relative min-h-[560px] rounded-2xl overflow-hidden"
            style={{
              border: '1px solid var(--color-border)',
              background:
                'radial-gradient(circle at 50% 50%, rgba(168, 85, 247, 0.24), transparent 24%), radial-gradient(circle at 20% 20%, rgba(34, 211, 238, 0.10), transparent 22%), linear-gradient(135deg, rgba(5, 5, 8, 0.98), rgba(22, 10, 38, 0.94))',
              boxShadow: '0 0 45px rgba(168, 85, 247, 0.12)',
            }}
          >
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

            <svg className="absolute inset-0 w-full h-full" viewBox="0 0 100 100" preserveAspectRatio="none">
              {agents.map((agent) => (
                <line
                  key={agent.name}
                  x1="50"
                  y1="50"
                  x2={agent.x}
                  y2={agent.y}
                  stroke="var(--color-accent)"
                  strokeOpacity="0.34"
                  strokeWidth="0.28"
                />
              ))}
              <circle cx="50" cy="50" r="17" fill="none" stroke="var(--color-accent)" strokeOpacity="0.22" strokeWidth="0.22" />
              <circle cx="50" cy="50" r="25" fill="none" stroke="var(--color-accent-hover)" strokeOpacity="0.12" strokeWidth="0.18" />
            </svg>

            <div
              className="absolute left-1/2 top-1/2 w-56 h-56 rounded-full flex items-center justify-center text-center"
              style={{
                transform: 'translate(-50%, -50%)',
                border: '1px solid rgba(192, 132, 252, 0.48)',
                background:
                  'radial-gradient(circle, rgba(168, 85, 247, 0.30), rgba(12, 6, 24, 0.88) 62%, rgba(5, 5, 8, 0.94))',
                boxShadow: '0 0 80px rgba(168, 85, 247, 0.34), inset 0 0 45px rgba(192, 132, 252, 0.15)',
              }}
            >
              <div>
                <div
                  className="text-xs tracking-[0.4em] uppercase mb-2"
                  style={{ color: 'var(--color-accent-hover)' }}
                >
                  Relay
                </div>
                <div className="text-xl font-semibold" style={{ color: 'var(--color-text)' }}>
                  Switchboard
                </div>
                <div className="text-xs mt-2 px-6" style={{ color: 'var(--color-text-secondary)' }}>
                  Routes requests into coordinated OpenClaw work
                </div>
              </div>
            </div>

            {agents.map((agent) => (
              <div
                key={agent.name}
                className="absolute w-44 rounded-xl p-3"
                style={{
                  left: `${agent.x}%`,
                  top: `${agent.y}%`,
                  transform: 'translate(-50%, -50%)',
                  border: '1px solid rgba(192, 132, 252, 0.28)',
                  background: 'rgba(8, 8, 13, 0.78)',
                  backdropFilter: 'blur(16px)',
                  boxShadow: '0 0 24px rgba(168, 85, 247, 0.12)',
                }}
              >
                <div className="flex items-center justify-between gap-2">
                  <div className="font-semibold text-sm" style={{ color: 'var(--color-text)' }}>
                    {agent.name}
                  </div>
                  <span
                    className="w-2 h-2 rounded-full"
                    style={{ background: 'var(--color-accent)', boxShadow: '0 0 12px var(--color-accent)' }}
                  />
                </div>
                <div className="text-xs mt-1" style={{ color: 'var(--color-accent-hover)' }}>
                  {agent.role}
                </div>
                <div className="text-[11px] mt-2" style={{ color: 'var(--color-text-secondary)' }}>
                  {agent.status}
                </div>
              </div>
            ))}

            <div
              className="absolute bottom-4 left-4 right-4 rounded-xl px-4 py-3 text-xs flex items-center justify-between gap-3"
              style={{
                border: '1px solid rgba(192, 132, 252, 0.20)',
                background: 'rgba(0, 0, 0, 0.30)',
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
          </section>

          <aside className="flex flex-col gap-4">
            <section
              className="rounded-2xl p-5"
              style={{
                border: '1px solid var(--color-border)',
                background: 'var(--color-bg-secondary)',
              }}
            >
              <div className="text-sm font-semibold mb-1" style={{ color: 'var(--color-text)' }}>
                Active Project Lanes
              </div>
              <p className="text-xs mb-4" style={{ color: 'var(--color-text-secondary)' }}>
                Visual placeholders for workflows Relay will route into.
              </p>

              <div className="flex flex-col gap-3">
                {lanes.map((lane) => (
                  <div
                    key={lane.name}
                    className="rounded-xl p-3"
                    style={{
                      border: '1px solid var(--color-border)',
                      background: 'rgba(255,255,255,0.03)',
                    }}
                  >
                    <div className="flex items-center justify-between">
                      <div className="font-medium text-sm" style={{ color: 'var(--color-text)' }}>
                        {lane.name}
                      </div>
                      <div className="text-[11px]" style={{ color: 'var(--color-accent)' }}>
                        {lane.state}
                      </div>
                    </div>
                    <div className="text-xs mt-1" style={{ color: 'var(--color-text-secondary)' }}>
                      {lane.note}
                    </div>
                  </div>
                ))}
              </div>
            </section>

            <section
              className="rounded-2xl p-5"
              style={{
                border: '1px solid var(--color-border)',
                background: 'var(--color-bg-secondary)',
              }}
            >
              <div className="text-sm font-semibold" style={{ color: 'var(--color-text)' }}>
                Relay Definition
              </div>
              <p className="text-xs mt-2 leading-relaxed" style={{ color: 'var(--color-text-secondary)' }}>
                Electrical relay logic applied to data and projects: a low-power user signal activates
                a higher-power coordinated workflow. Relay routes the work. OpenClaw Core executes the system.
              </p>
            </section>
          </aside>
        </div>

        <section
          className="rounded-2xl p-5 md:p-6 mt-5"
          style={{
            border: '1px solid rgba(192, 132, 252, 0.28)',
            background:
              'linear-gradient(135deg, rgba(17, 9, 29, 0.96), rgba(8, 8, 13, 0.98))',
            boxShadow: '0 0 36px rgba(168, 85, 247, 0.10)',
          }}
        >
          <div className="flex items-start gap-3 mb-5">
            <div
              className="w-9 h-9 rounded-lg flex items-center justify-center shrink-0"
              style={{
                color: 'var(--color-accent-hover)',
                border: '1px solid rgba(192, 132, 252, 0.30)',
                background: 'rgba(168, 85, 247, 0.12)',
              }}
            >
              <Terminal size={17} />
            </div>
            <div>
              <h2 className="text-base font-semibold" style={{ color: 'var(--color-text)' }}>
                Relay Quick Commands
              </h2>
              <p className="text-xs mt-1" style={{ color: 'var(--color-text-secondary)' }}>
                Copy-safe operator references. Commands are never executed by the dashboard.
              </p>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-3">
            {quickCommands.map((item) => {
              const copied = copiedCommand === item.name;

              return (
                <article
                  key={item.name}
                  className="rounded-xl p-4 min-w-0 flex flex-col"
                  style={{
                    border: '1px solid var(--color-border)',
                    background: 'rgba(255, 255, 255, 0.025)',
                  }}
                >
                  <div className="flex items-start justify-between gap-3">
                    <div>
                      <h3 className="text-sm font-medium" style={{ color: 'var(--color-text)' }}>
                        {item.name}
                      </h3>
                      <p
                        className="text-[11px] mt-1 leading-relaxed"
                        style={{ color: 'var(--color-text-secondary)' }}
                      >
                        {item.purpose}
                      </p>
                    </div>
                    <button
                      type="button"
                      onClick={() => copyCommand(item.name, item.command)}
                      className="rounded-md p-1.5 shrink-0 transition-colors cursor-pointer"
                      style={{
                        color: copied ? 'var(--color-accent-hover)' : 'var(--color-text-tertiary)',
                        border: '1px solid var(--color-border)',
                        background: copied
                          ? 'rgba(168, 85, 247, 0.14)'
                          : 'var(--color-bg-secondary)',
                      }}
                      aria-label={`Copy ${item.name} command`}
                      title={copied ? 'Copied' : 'Copy command'}
                    >
                      {copied ? <Check size={14} /> : <Copy size={14} />}
                    </button>
                  </div>

                  <pre
                    className="text-[11px] leading-relaxed whitespace-pre-wrap break-words mt-4 rounded-lg p-3 overflow-x-auto flex-1"
                    style={{
                      color: 'var(--color-accent-hover)',
                      border: '1px solid rgba(192, 132, 252, 0.16)',
                      background: 'rgba(0, 0, 0, 0.32)',
                    }}
                  >
                    <code>{item.command}</code>
                  </pre>
                </article>
              );
            })}
          </div>
        </section>
      </div>
    </div>
  );
}

