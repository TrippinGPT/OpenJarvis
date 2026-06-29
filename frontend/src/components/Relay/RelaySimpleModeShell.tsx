import { type ReactNode } from 'react';
import { ArrowRight, Compass, Target, UserRound } from 'lucide-react';
import {
  relayFirstWaveAgents,
  relayFirstWaveQuickGuide,
  type RelayFirstWaveAgentKey,
} from '../../data/relayFirstWaveAgents';
import type { RelayAgent } from '../../data/relayAgents';
import type { RelayNextMoveView, RelayRoutingGuidanceView } from '../../lib/relayMemory';
import type { RelayStructuredMemory } from '../../lib/relayMemory';

export interface RelaySimpleModeShellProps {
  taskDraft: string;
  onTaskDraftChange: (value: string) => void;
  onSaveFocus: () => void;
  onClearTask: () => void;
  recommendedAgent: RelayAgent;
  agentReason: string;
  agentTaskFit: string;
  firstWaveScopeNote: string;
  routingMode: RelayRoutingGuidanceView['mode'];
  nextMove: RelayNextMoveView;
  agentActionLabel: string;
  onUseRecommendedAgent: () => void;
  onOpenAgent: (agentKey: RelayFirstWaveAgentKey) => void;
  onShowAdvanced: () => void;
  relayMemory: RelayStructuredMemory;
}

function SimpleSection({
  icon: Icon,
  title,
  hint,
  children,
}: {
  icon: typeof Target;
  title: string;
  hint: string;
  children: ReactNode;
}) {
  return (
    <section className="relay-simple-section rounded-lg border border-white/10 bg-black/20 px-3 py-3">
      <div className="flex items-start gap-2">
        <div
          className="mt-0.5 flex h-6 w-6 shrink-0 items-center justify-center rounded-md"
          style={{
            color: 'rgb(103, 232, 249)',
            border: '1px solid rgba(34, 211, 238, 0.18)',
            background: 'rgba(34, 211, 238, 0.06)',
          }}
        >
          <Icon size={12} />
        </div>
        <div className="min-w-0 flex-1">
          <h2 className="text-[10px] font-semibold tracking-wide text-cyan-100">{title}</h2>
          <p className="mt-0.5 text-[9px] leading-relaxed text-slate-400">{hint}</p>
          <div className="mt-2.5">{children}</div>
        </div>
      </div>
    </section>
  );
}

export function RelaySimpleModeShell({
  taskDraft,
  onTaskDraftChange,
  onSaveFocus,
  onClearTask,
  recommendedAgent,
  agentReason,
  agentTaskFit,
  firstWaveScopeNote,
  routingMode,
  nextMove,
  agentActionLabel,
  onUseRecommendedAgent,
  onOpenAgent,
  onShowAdvanced,
  relayMemory,
}: RelaySimpleModeShellProps) {
  const objective = relayMemory.currentObjective?.trim();
  const hasTaskDraft = Boolean(taskDraft.trim());

  return (
    <div className="relay-simple-shell grid gap-3">
      <header className="flex items-start justify-between gap-3 rounded-lg border border-cyan-500/15 bg-cyan-950/20 px-3 py-2.5">
        <div className="min-w-0">
          <div className="text-[10px] font-semibold uppercase tracking-[0.14em] text-cyan-200">
            Simple Mode
          </div>
          <p className="mt-1 text-[9px] leading-relaxed text-cyan-100/80">
            One task, one first-wave specialist, one next move. Advanced panels stay available when you need them.
          </p>
        </div>
        <button
          type="button"
          onClick={onShowAdvanced}
          className="relay-popout-nav-button shrink-0 justify-center whitespace-nowrap px-2.5 py-1.5 text-[9px]"
          style={{ color: 'rgb(216, 180, 254)', borderColor: 'rgba(192, 132, 252, 0.24)' }}
        >
          Show advanced
        </button>
      </header>

      <SimpleSection
        icon={Target}
        title="What do I type here?"
        hint="Describe the outcome, repo, or question in plain language."
      >
        <textarea
          value={taskDraft}
          onChange={(event) => onTaskDraftChange(event.target.value)}
          rows={3}
          placeholder="Example: Summarize the Relay fork state, route the next build step, and keep OpenClaw read-only."
          className="w-full rounded-md border border-white/10 bg-black/30 px-2.5 py-2 text-[10px] leading-relaxed outline-none focus:border-cyan-400/30"
          style={{ color: 'rgba(226, 232, 240, 0.92)', resize: 'vertical' }}
        />
        <div className="mt-2 flex flex-wrap gap-2">
          <button
            type="button"
            onClick={onSaveFocus}
            disabled={!hasTaskDraft}
            className="relay-popout-nav-button justify-center text-[9px]"
            style={{
              color: hasTaskDraft ? 'rgb(103, 232, 249)' : 'rgba(148, 163, 184, 0.56)',
              borderColor: hasTaskDraft ? 'rgba(34, 211, 238, 0.24)' : 'rgba(148, 163, 184, 0.16)',
              opacity: hasTaskDraft ? 1 : 0.6,
            }}
          >
            Save task focus
          </button>
          <button
            type="button"
            onClick={onClearTask}
            disabled={!hasTaskDraft}
            className="relay-popout-nav-button justify-center text-[9px]"
            style={{
              color: hasTaskDraft ? 'rgb(251, 191, 36)' : 'rgba(148, 163, 184, 0.56)',
              borderColor: hasTaskDraft ? 'rgba(251, 191, 36, 0.20)' : 'rgba(148, 163, 184, 0.16)',
              opacity: hasTaskDraft ? 1 : 0.6,
            }}
          >
            Clear
          </button>
        </div>
      </SimpleSection>

      <SimpleSection
        icon={UserRound}
        title="Who gets this first?"
        hint="Simple Mode keeps normal flow inside Dispatch, Recon, and Patch."
      >
        <div className="rounded-md border border-white/10 bg-black/25 px-2.5 py-2.5">
          <div className="flex items-start justify-between gap-3">
            <div className="min-w-0">
              <div className="text-[11px] font-semibold text-violet-200">{recommendedAgent.name}</div>
              <div className="mt-0.5 text-[9px] text-slate-300">{recommendedAgent.role}</div>
              <p className="mt-2 text-[9px] leading-relaxed text-cyan-50/85">{recommendedAgent.roleSentence}</p>
            </div>
            <span
              className="shrink-0 rounded-md border px-2 py-1 text-[8px] font-medium uppercase tracking-wide"
              style={{
                color: 'rgb(134, 239, 172)',
                borderColor: 'rgba(74, 222, 128, 0.22)',
                background: 'rgba(74, 222, 128, 0.06)',
              }}
            >
              {routingMode === 'stay' ? 'Current fit' : 'Best next fit'}
            </span>
          </div>
          <div className="mt-3 rounded-md border border-white/8 bg-black/20 px-2 py-2">
            <div className="text-[8px] font-medium uppercase tracking-wide text-slate-500">Why this fits</div>
            <p className="mt-1 text-[9px] leading-relaxed text-cyan-50/85">{agentReason}</p>
          </div>
          <div className="mt-2 grid gap-2 sm:grid-cols-2">
            <div className="rounded-md border border-white/8 bg-black/20 px-2 py-2">
              <div className="text-[8px] font-medium uppercase tracking-wide text-slate-500">Task fit</div>
              <p className="mt-1 text-[9px] leading-relaxed text-cyan-50/80">{agentTaskFit}</p>
            </div>
            <div className="rounded-md border border-white/8 bg-black/20 px-2 py-2">
              <div className="text-[8px] font-medium uppercase tracking-wide text-slate-500">Boundary</div>
              <p className="mt-1 text-[9px] leading-relaxed text-cyan-50/80">{firstWaveScopeNote}</p>
            </div>
          </div>
          <button
            type="button"
            onClick={onUseRecommendedAgent}
            className="relay-popout-nav-button mt-3 w-full justify-center text-[9px]"
            style={{ color: 'rgb(134, 239, 172)', borderColor: 'rgba(74, 222, 128, 0.24)' }}
          >
            {agentActionLabel}
            <ArrowRight size={11} />
          </button>
        </div>
      </SimpleSection>

      <SimpleSection
        icon={Compass}
        title="What should I do next?"
        hint="Deterministic guidance from visible Relay memory - not hidden orchestration."
      >
        <div className="rounded-md border border-white/10 bg-black/25 px-2.5 py-2.5">
          <p className="text-[10px] leading-relaxed text-cyan-50/90">{nextMove.move}</p>
          <p className="mt-2 text-[8px] uppercase tracking-wide text-slate-500">Based on {nextMove.basedOn}</p>
        </div>
      </SimpleSection>

      <section className="relay-simple-section rounded-lg border border-white/10 bg-black/20 px-3 py-3">
        <div className="text-[10px] font-semibold tracking-wide text-violet-200">First-wave team</div>
        <p className="mt-0.5 text-[9px] text-slate-400">
          Dispatch routes, Recon verifies, Patch proposes fixes. Other roster agents stay parked in Simple Mode.
        </p>
        <div className="mt-3 grid gap-2 sm:grid-cols-3">
          {relayFirstWaveAgents.map((agent) => {
            const guide = relayFirstWaveQuickGuide[agent.key as RelayFirstWaveAgentKey];
            const isRecommended = agent.key === recommendedAgent.key;
            return (
              <button
                key={agent.key}
                type="button"
                onClick={() => onOpenAgent(agent.key as RelayFirstWaveAgentKey)}
                className="rounded-md border px-2.5 py-2 text-left transition hover:border-cyan-400/25 hover:bg-black/30"
                style={{
                  borderColor: isRecommended ? 'rgba(34, 211, 238, 0.28)' : 'rgba(255, 255, 255, 0.10)',
                  background: isRecommended ? 'rgba(34, 211, 238, 0.05)' : 'rgba(0, 0, 0, 0.20)',
                }}
              >
                <div className="text-[10px] font-semibold text-violet-200">{agent.name}</div>
                <div className="mt-1 text-[9px] font-medium text-cyan-100/85">{guide.headline}</div>
                <div className="mt-1.5 text-[8px] leading-relaxed text-slate-400">{guide.whenToUse}</div>
              </button>
            );
          })}
        </div>
      </section>

      {(objective || relayMemory.recentStatusSummary) && (
        <div className="rounded-lg border border-white/8 bg-black/15 px-3 py-2 text-[9px] leading-relaxed text-slate-300">
          {objective ? (
            <div>
              <span className="font-medium text-slate-400">Current focus:</span> {objective}
            </div>
          ) : null}
          {!objective && relayMemory.recentStatusSummary ? (
            <div>{relayMemory.recentStatusSummary}</div>
          ) : null}
        </div>
      )}
    </div>
  );
}
