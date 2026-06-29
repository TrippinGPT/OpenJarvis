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

export interface RelayFirstWaveHandoff {
  agentKey: RelayFirstWaveAgentKey;
  agentName: string;
  model: string;
  task: string;
  message: string;
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

function countMatches(text: string, terms: readonly string[]) {
  return terms.reduce((count, term) => count + (text.includes(term) ? 1 : 0), 0);
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

const RECON_STRONG_PHRASES = [
  'project-state',
  'project state',
  'current state',
  'summary prompt',
  'project-state summary',
  'summarize my current project state',
  'summarize repo status',
  'repo status',
  'repo state',
  'current project state',
  'what does the project currently look like',
  'gather facts',
  'compare these options',
] as const;

const RECON_TERMS = [
  'research',
  'summary',
  'summarize',
  'sources',
  'source',
  'facts',
  'fact',
  'evidence',
  'context',
  'docs',
  'document',
  'report',
  'intel',
] as const;

const PATCH_STRONG_PHRASES = [
  'safe change',
  'propose a safe change',
  'safe fix',
  'smallest safe fix',
  'improve this file',
  'improve this workflow',
  'repo change',
  'broken script',
  'validation plan',
] as const;

const PATCH_TERMS = [
  'build',
  'fix',
  'script',
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
  'file',
  'refactor',
  'implement',
  'change',
] as const;

const DISPATCH_STRONG_PHRASES = [
  'who should handle this',
  'what should handle this',
  'what should i do next',
  'not sure who should',
  'not sure what should',
  'which agent',
  'route this',
  'route this task',
  'help me route this',
] as const;

const DISPATCH_TERMS = [
  'route',
  'routing',
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
] as const;

function scoreFirstWaveIntent(text: string) {
  const reconStrong = countMatches(text, RECON_STRONG_PHRASES);
  const patchStrong = countMatches(text, PATCH_STRONG_PHRASES);
  const dispatchStrong = countMatches(text, DISPATCH_STRONG_PHRASES);
  const reconTerms = countMatches(text, RECON_TERMS);
  const patchTerms = countMatches(text, PATCH_TERMS);
  const dispatchTerms = countMatches(text, DISPATCH_TERMS);

  return {
    recon: reconStrong * 4 + reconTerms,
    patch: patchStrong * 4 + patchTerms,
    dispatch: dispatchStrong * 4 + dispatchTerms,
  };
}

function detectFirstWaveKey(text: string): RelayFirstWaveAgentKey | null {
  const scores = scoreFirstWaveIntent(text);
  const topScore = Math.max(scores.recon, scores.patch, scores.dispatch);
  if (topScore <= 0) {
    return null;
  }

  if (scores.recon > 0 && scores.recon >= scores.patch && scores.recon >= scores.dispatch) {
    return 'recon';
  }

  if (scores.patch > 0 && scores.patch > scores.recon && scores.patch >= scores.dispatch) {
    return 'patch';
  }

  if (scores.dispatch > 0) {
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
    relayMemory.currentObjective,
    relayMemory.lastMeaningfulAction,
    relayMemory.nextSuggestedMove,
    relayMemory.recentStatusSummary,
    relayMemory.activeLanePriorities,
    relayMemory.currentBoundaries,
  ]);
  const taskText = normalizeText([taskDraft]);
  const explicitTaskKey = detectFirstWaveKey(taskText);
  const explicitContextKey = explicitTaskKey ? null : detectFirstWaveKey(contextText);
  const mapped = explicitTaskKey
    ? { key: explicitTaskKey, reasonPrefix: 'The task language points to a first-wave owner.' }
    : explicitContextKey
      ? { key: explicitContextKey, reasonPrefix: 'The saved context points to a first-wave owner.' }
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

export function buildRelayFirstWaveHandoff(
  agentKey: RelayFirstWaveAgentKey,
  task: string,
): RelayFirstWaveHandoff {
  const agent = getRelayFirstWaveAgent(agentKey) ?? relayFirstWaveAgents[0];
  const cleanTask = task.replace(/\s+/g, ' ').trim();
  const modelByAgent: Record<RelayFirstWaveAgentKey, string> = {
    dispatch: 'qwen3.5:9b',
    recon: 'qwen3.5:9b',
    patch: 'qwen2.5-coder:14b',
  };

  const instructions: Record<RelayFirstWaveAgentKey, string> = {
    dispatch:
      [
        'Stay inside Dispatch.',
        'Route only.',
        'Do not answer like a generic assistant.',
        'Do not invent departments, teams, enterprise roles, or new agents.',
        'Return exactly:',
        'Owner: <Dispatch | Recon | Patch>',
        'Why: <one short sentence>',
        'Next: <one short next step or 2-3 short ordered steps>',
      ].join(' '),
    recon:
      [
        'Stay inside Recon.',
        'Use local repo, project, docs, config, scripts, and visible app context first.',
        'Do not drift to Jira, GitHub activity, workplace history, or unrelated connected context unless the user explicitly asked for it.',
        'If local evidence is missing, say what is missing instead of padding.',
        'Keep the answer concise.',
        'Return in this shape when helpful:',
        'Known:',
        'Missing:',
        'Answer:',
      ].join(' '),
    patch:
      [
        'Stay inside Patch.',
        'Propose only.',
        'Prefer the smallest safe fix first.',
        'Keep scope narrow unless the user explicitly asks for a broad rewrite.',
        'Do not imply anything was already changed, applied, shipped, committed, tagged, or pushed.',
        'Return in this shape:',
        'Proposed fix:',
        'Files:',
        'Validation:',
        'Risks:',
      ].join(' '),
  };

  return {
    agentKey,
    agentName: agent.name,
    model: modelByAgent[agentKey],
    task: cleanTask,
    message: [
      'Relay first-wave handoff.',
      `Worker: ${agent.name}`,
      `Model: ${modelByAgent[agentKey]}`,
      'Scope: First-wave only. Do not switch to Hermes or later agents unless the operator explicitly asks for that.',
      `Task: ${cleanTask}`,
      `Instructions: ${instructions[agentKey]}`,
    ].join('\n'),
  };
}
