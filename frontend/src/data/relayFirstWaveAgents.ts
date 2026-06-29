import { relayAgents, type RelayAgent, type RelayAgentKey } from './relayAgents';
import type { RelayRoutingGuidanceView, RelayStructuredMemory } from '../lib/relayMemory';

/** First-wave runtime specialists for the Relay fork shell. */
export const RELAY_FIRST_WAVE_AGENT_KEYS = ['dispatch', 'recon', 'patch'] as const;

export type RelayFirstWaveAgentKey = (typeof RELAY_FIRST_WAVE_AGENT_KEYS)[number];

export const relayFirstWaveAgents: RelayAgent[] = RELAY_FIRST_WAVE_AGENT_KEYS.map(
  (key) => relayAgents.find((agent) => agent.key === key)!,
);

export const relayFirstWaveQuickGuide: Record<
  RelayFirstWaveAgentKey,
  { headline: string; whenToUse: string; taskFit: string; scopeNote: string; actionLabel: string }
> = {
  dispatch: {
    headline: 'Routing and coordination',
    whenToUse: 'Unclear owner, triage, sequencing, or handoff planning',
    taskFit: 'Use Dispatch when the task is vague, multi-step, or needs the right owner selected first.',
    scopeNote: 'Dispatch keeps the first pass short: owner, why, next step.',
    actionLabel: 'Route with Dispatch',
  },
  recon: {
    headline: 'Research, summaries, and facts',
    whenToUse: 'Project state, sources, evidence, and context gathering',
    taskFit: 'Use Recon for repo/project summaries, source checks, context packs, and evidence-first answers.',
    scopeNote: 'Recon starts from local project context unless the user asks for external activity.',
    actionLabel: 'Ask Recon',
  },
  patch: {
    headline: 'Build, fix, propose-only',
    whenToUse: 'Scripts, repo changes, validation plans - no auto-ship',
    taskFit: 'Use Patch for build, fix, script, repo, and workflow-improvement tasks.',
    scopeNote: 'Patch proposes the smallest safe fix and validation path. It does not auto-commit, tag, or push.',
    actionLabel: 'Ask Patch',
  },
};

export interface RelayFirstWaveRecommendation {
  key: RelayFirstWaveAgentKey;
  agent: RelayAgent;
  reason: string;
  routingMode: RelayRoutingGuidanceView['mode'];
  actionLabel: string;
  taskFit: string;
  scopeNote: string;
}

export function isRelayFirstWaveAgentKey(value: string): value is RelayFirstWaveAgentKey {
  return (RELAY_FIRST_WAVE_AGENT_KEYS as readonly string[]).includes(value);
}

export function getRelayFirstWaveAgent(key: RelayAgentKey | string): RelayAgent | null {
  if (!isRelayFirstWaveAgentKey(key)) {
    return null;
  }
  return relayAgents.find((agent) => agent.key === key) ?? null;
}

function hasAny(text: string, terms: readonly string[]) {
  return terms.some((term) => text.includes(term));
}

function normalizeText(parts: Array<string | string[] | undefined | null>) {
  return parts
    .filter(Boolean)
    .flatMap((part) => (Array.isArray(part) ? part : [part]))
    .filter(Boolean)
    .join(' ')
    .toLowerCase()
    .replace(/\s+/g, ' ')
    .trim();
}

function detectFirstWaveKey(text: string): RelayFirstWaveAgentKey | null {
  if (
    hasAny(text, [
      'build',
      'fix',
      'script',
      'repo',
      'workflow',
      'frontend',
      'backend',
      'compile',
      'test',
      'patch',
      'bug',
      'validation',
      'powershell',
      'typescript',
      'python',
    ])
  ) {
    return 'patch';
  }

  if (
    hasAny(text, [
      'research',
      'summary',
      'summarize',
      'sources',
      'source',
      'facts',
      'fact',
      'evidence',
      'context',
      'project state',
      'current state',
      'docs',
      'document',
      'report',
      'intel',
    ])
  ) {
    return 'recon';
  }

  if (
    hasAny(text, [
      'route',
      'routing',
      'who should',
      'which agent',
      'not sure',
      'unclear',
      'coordinate',
      'plan',
      'triage',
      'breakdown',
      'owner',
      'handoff',
      'sequence',
      'next step',
    ])
  ) {
    return 'dispatch';
  }

  return null;
}

function mapBroadRouteToFirstWave(
  broadRoute: RelayRoutingGuidanceView,
  contextText: string,
): { key: RelayFirstWaveAgentKey; reasonPrefix: string } {
  if (isRelayFirstWaveAgentKey(broadRoute.targetAgentKey)) {
    return {
      key: broadRoute.targetAgentKey,
      reasonPrefix: broadRoute.mode === 'stay' ? 'Stay with the current first-wave owner.' : 'First-wave match found.',
    };
  }

  if (hasAny(contextText, ['preflight', 'readiness', 'launcher', 'health', 'restart', 'status'])) {
    return {
      key: 'dispatch',
      reasonPrefix:
        'This looks like shell/readiness territory, so Simple Mode starts with Dispatch to route the handoff cleanly.',
    };
  }

  if (hasAny(contextText, ['risk', 'safety', 'boundary', 'approve', 'reject', 'final review', 'hype', 'trend'])) {
    return {
      key: 'dispatch',
      reasonPrefix:
        'This may need a later specialist, but Simple Mode keeps the first pass with Dispatch until scope is explicit.',
    };
  }

  return {
    key: 'dispatch',
    reasonPrefix: 'The task does not name a clear worker yet, so Dispatch owns the first pass.',
  };
}

export function deriveRelayFirstWaveRecommendation({
  taskDraft,
  relayMemory,
  broadRouting,
}: {
  taskDraft: string;
  relayMemory: RelayStructuredMemory;
  broadRouting: RelayRoutingGuidanceView;
}): RelayFirstWaveRecommendation {
  const contextText = normalizeText([
    taskDraft,
    relayMemory.currentObjective,
    relayMemory.lastMeaningfulAction,
    relayMemory.nextSuggestedMove,
    relayMemory.recentStatusSummary,
    relayMemory.activeLanePriorities,
    relayMemory.currentBoundaries,
  ]);
  const explicitKey = detectFirstWaveKey(contextText);
  const mapped = explicitKey
    ? { key: explicitKey, reasonPrefix: 'The task language points to a first-wave owner.' }
    : mapBroadRouteToFirstWave(broadRouting, contextText);
  const agent = getRelayFirstWaveAgent(mapped.key) ?? relayFirstWaveAgents[0];
  const guide = relayFirstWaveQuickGuide[mapped.key];
  const activeAgent = relayMemory.activeAgent?.toLowerCase().trim();
  const isCurrentAgent = Boolean(activeAgent && activeAgent === agent.name.toLowerCase());
  const routingMode: RelayRoutingGuidanceView['mode'] = isCurrentAgent ? 'stay' : 'handoff';

  return {
    key: mapped.key,
    agent,
    reason: `${mapped.reasonPrefix} ${guide.taskFit}`,
    routingMode,
    actionLabel: isCurrentAgent ? `Stay with ${agent.name}` : guide.actionLabel,
    taskFit: guide.taskFit,
    scopeNote: guide.scopeNote,
  };
}
