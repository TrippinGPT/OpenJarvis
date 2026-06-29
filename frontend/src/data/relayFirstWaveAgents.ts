import { relayAgents, type RelayAgent, type RelayAgentKey } from './relayAgents';

/** First-wave runtime specialists for the Relay fork shell. */
export const RELAY_FIRST_WAVE_AGENT_KEYS = ['dispatch', 'recon', 'patch'] as const;

export type RelayFirstWaveAgentKey = (typeof RELAY_FIRST_WAVE_AGENT_KEYS)[number];

export const relayFirstWaveAgents: RelayAgent[] = RELAY_FIRST_WAVE_AGENT_KEYS.map(
  (key) => relayAgents.find((agent) => agent.key === key)!,
);

export const relayFirstWaveQuickGuide: Record<
  RelayFirstWaveAgentKey,
  { headline: string; whenToUse: string }
> = {
  dispatch: {
    headline: 'Routing and coordination',
    whenToUse: 'Unclear owner, triage, sequencing, or handoff planning',
  },
  recon: {
    headline: 'Research, summaries, and facts',
    whenToUse: 'Project state, sources, evidence, and context gathering',
  },
  patch: {
    headline: 'Build, fix, propose-only',
    whenToUse: 'Scripts, repo changes, validation plans — no auto-ship',
  },
};

export function isRelayFirstWaveAgentKey(value: string): value is RelayFirstWaveAgentKey {
  return (RELAY_FIRST_WAVE_AGENT_KEYS as readonly string[]).includes(value);
}

export function getRelayFirstWaveAgent(key: RelayAgentKey | string): RelayAgent | null {
  if (!isRelayFirstWaveAgentKey(key)) {
    return null;
  }
  return relayAgents.find((agent) => agent.key === key) ?? null;
}
