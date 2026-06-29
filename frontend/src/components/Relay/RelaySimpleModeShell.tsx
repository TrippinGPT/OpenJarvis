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
      <header className="rounded-xl border border-cyan-500/15 bg-cyan-950/15 px-4 py-3 shadow-[0_0_30px_rgba(34,211,238,0.06)]">
        <div className="flex items-start justify-between gap-3">
          <div className="min-w-0">
            <div className="text-[9px] font-semibold uppercase tracking-[0.22em] text-cyan-200">
              Relay assistant shell
            </div>
            <h1 className="mt-1 text-[18px] font-semibold tracking-tight text-cyan-50">
              Tell Relay the job. It picks the first worker.
            </h1>
            <p className="mt-1 max-w-[56ch] text-[10px] leading-relaxed text-cyan-100/72">
              Simple Mode is the front door: task, owner, next move. Memory, routing internals, review logs, and voice
              controls stay in Advanced.
            </p>
          </div>
          <button
            type="button"
            onClick={onShowAdvanced}
            className="relay-popout-nav-button shrink-0 justify-center whitespace-nowrap px-2.5 py-1.5 text-[9px]"
            style={{ color: 'rgb(216, 180, 254)', borderColor: 'rgba(192, 132, 252, 0.24)' }}
          >
            Advanced
          </button>
        </div>
      </header>

      <section className="grid gap-3 lg:grid-cols-[minmax(0,1.35fr)_minmax(220px,0.65fr)]">
        <div className="rounded-xl border border-white/10 bg-black/25 p-4">
          <div className="flex items-start gap-3">
            <div
              className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg"
              style={{
                color: 'rgb(103, 232, 249)',
                border: '1px solid rgba(34, 211, 238, 0.18)',
                background: 'rgba(34, 211, 238, 0.07)',
              }}
            >
              <Target size={15} />
            </div>
            <div className="min-w-0 flex-1">
              <div className="text-[10px] font-semibold uppercase tracking-[0.14em] text-cyan-100">
                Main task
              </div>
              <p className="mt-1 text-[9px] leading-relaxed text-slate-400">
                Type the outcome, question, repo issue, or decision you want handled. Keep it plain.
              </p>
            </div>
          </div>

          <textarea
            value={taskDraft}
            onChange={(event) => onTaskDraftChange(event.target.value)}
            rows={6}
            placeholder="Example: Check the Relay startup flow, propose the smallest safe fix, and keep OpenClaw untouched."
            className="mt-4 w-full rounded-lg border border-cyan-400/15 bg-black/35 px-3 py-3 text-[12px] leading-relaxed outline-none focus:border-cyan-300/40"
            style={{ color: 'rgba(226, 232, 240, 0.94)', resize: 'vertical' }}
          />

          <div className="mt-3 flex flex-wrap items-center justify-between gap-2">
            <div className="flex flex-wrap gap-2">
              <button
                type="button"
                onClick={onSaveFocus}
                disabled={!hasTaskDraft}
                className="relay-popout-nav-button justify-center px-3 py-2 text-[10px]"
                style={{
                  color: hasTaskDraft ? 'rgb(103, 232, 249)' : 'rgba(148, 163, 184, 0.56)',
                  borderColor: hasTaskDraft ? 'rgba(34, 211, 238, 0.24)' : 'rgba(148, 163, 184, 0.16)',
                  opacity: hasTaskDraft ? 1 : 0.6,
                }}
              >
                Save focus
              </button>
              <button
                type="button"
                onClick={onClearTask}
                disabled={!hasTaskDraft}
                className="relay-popout-nav-button justify-center px-3 py-2 text-[10px]"
                style={{
                  color: hasTaskDraft ? 'rgb(251, 191, 36)' : 'rgba(148, 163, 184, 0.56)',
                  borderColor: hasTaskDraft ? 'rgba(251, 191, 36, 0.20)' : 'rgba(148, 163, 184, 0.16)',
                  opacity: hasTaskDraft ? 1 : 0.6,
                }}
              >
                Clear
              </button>
            </div>
            <div className="text-[8px] uppercase tracking-[0.14em] text-slate-500">
              First wave: Dispatch / Recon / Patch
            </div>
          </div>
        </div>

        <aside className="rounded-xl border border-violet-400/15 bg-black/25 p-4">
          <div className="flex items-center justify-between gap-2">
            <div className="flex items-center gap-2">
              <div
                className="flex h-7 w-7 shrink-0 items-center justify-center rounded-lg"
                style={{
                  color: 'rgb(216, 180, 254)',
                  border: '1px solid rgba(192, 132, 252, 0.20)',
                  background: 'rgba(168, 85, 247, 0.08)',
                }}
              >
                <UserRound size={14} />
              </div>
              <div>
                <div className="text-[8px] font-semibold uppercase tracking-[0.16em] text-slate-500">
                  Current worker
                </div>
                <div className="text-[14px] font-semibold text-violet-100">{recommendedAgent.name}</div>
              </div>
            </div>
            <span
              className="rounded-md border px-2 py-1 text-[8px] font-medium uppercase tracking-wide"
              style={{
                color: 'rgb(134, 239, 172)',
                borderColor: 'rgba(74, 222, 128, 0.22)',
                background: 'rgba(74, 222, 128, 0.06)',
              }}
            >
              {routingMode === 'stay' ? 'Current fit' : 'Recommended'}
            </span>
          </div>

          <p className="mt-3 text-[10px] leading-relaxed text-cyan-50/82">{recommendedAgent.roleSentence}</p>

          <div className="mt-3 rounded-lg border border-white/8 bg-black/20 px-3 py-2.5">
            <div className="text-[8px] font-medium uppercase tracking-wide text-slate-500">Why this worker</div>
            <p className="mt-1.5 text-[9px] leading-relaxed text-cyan-50/80">{agentReason}</p>
          </div>

          <button
            type="button"
            onClick={onUseRecommendedAgent}
            className="relay-popout-nav-button mt-3 w-full justify-center px-3 py-2 text-[10px]"
            style={{ color: 'rgb(134, 239, 172)', borderColor: 'rgba(74, 222, 128, 0.24)' }}
          >
            {agentActionLabel}
            <ArrowRight size={12} />
          </button>
        </aside>
      </section>

      <section className="rounded-xl border border-cyan-400/12 bg-black/20 px-4 py-3">
        <div className="flex items-start gap-3">
          <div
            className="flex h-7 w-7 shrink-0 items-center justify-center rounded-lg"
            style={{
              color: 'rgb(103, 232, 249)',
              border: '1px solid rgba(34, 211, 238, 0.18)',
              background: 'rgba(34, 211, 238, 0.06)',
            }}
          >
            <Compass size={13} />
          </div>
          <div className="min-w-0 flex-1">
            <div className="text-[9px] font-semibold uppercase tracking-[0.16em] text-cyan-100">
              Next action
            </div>
            <p className="mt-1 text-[11px] leading-relaxed text-cyan-50/90">{nextMove.move}</p>
            <p className="mt-1.5 text-[8px] uppercase tracking-[0.12em] text-slate-500">
              Based on {nextMove.basedOn}. This is guidance, not automation.
            </p>
          </div>
        </div>
      </section>

      <details className="rounded-xl border border-white/10 bg-black/15 px-4 py-3">
        <summary className="cursor-pointer text-[10px] font-semibold uppercase tracking-[0.16em] text-violet-200">
          Show first-wave map
        </summary>
        <div className="mt-3 grid gap-2 sm:grid-cols-3">
          {relayFirstWaveAgents.map((agent) => {
            const guide = relayFirstWaveQuickGuide[agent.key as RelayFirstWaveAgentKey];
            const isRecommended = agent.key === recommendedAgent.key;
            return (
              <button
                key={agent.key}
                type="button"
                onClick={() => onOpenAgent(agent.key as RelayFirstWaveAgentKey)}
                className="rounded-lg border px-3 py-2.5 text-left transition hover:border-cyan-400/25 hover:bg-black/30"
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
        <div className="mt-3 grid gap-2 sm:grid-cols-2">
          <div className="rounded-lg border border-white/8 bg-black/20 px-3 py-2.5">
            <div className="text-[8px] font-medium uppercase tracking-wide text-slate-500">Task fit</div>
            <p className="mt-1 text-[9px] leading-relaxed text-cyan-50/80">{agentTaskFit}</p>
          </div>
          <div className="rounded-lg border border-white/8 bg-black/20 px-3 py-2.5">
            <div className="text-[8px] font-medium uppercase tracking-wide text-slate-500">Boundary</div>
            <p className="mt-1 text-[9px] leading-relaxed text-cyan-50/80">{firstWaveScopeNote}</p>
          </div>
        </div>
      </details>

      {(objective || relayMemory.recentStatusSummary) && (
        <details className="rounded-xl border border-white/8 bg-black/10 px-4 py-3">
          <summary className="cursor-pointer text-[10px] font-semibold uppercase tracking-[0.16em] text-slate-300">
            Show current context
          </summary>
          <div className="mt-2 text-[9px] leading-relaxed text-slate-300">
            {objective ? (
              <div>
                <span className="font-medium text-slate-400">Current focus:</span> {objective}
              </div>
            ) : null}
            {relayMemory.recentStatusSummary ? <div className="mt-1">{relayMemory.recentStatusSummary}</div> : null}
          </div>
        </details>
      )}
    </div>
  );
}
