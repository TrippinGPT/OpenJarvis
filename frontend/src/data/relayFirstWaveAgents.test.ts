import { describe, expect, it } from 'vitest';
import {
  buildRelayFirstWaveHandoff,
  deriveRelayFirstWaveRecommendation,
  resolveRelayFirstWaveModel,
} from './relayFirstWaveAgents';
import type { RelayRoutingGuidanceView, RelayStructuredMemory } from '../lib/relayMemory';

function createMemory(overrides: Partial<RelayStructuredMemory> = {}): RelayStructuredMemory {
  return {
    sessionId: 'test-session',
    currentLane: 'Relay cockpit',
    activeAgent: null,
    currentObjective: null,
    lastMeaningfulAction: 'Structured memory initialized.',
    nextSuggestedMove: 'Use Relay normally, then pin anything worth keeping.',
    recentStatusSummary: 'Relay memory is empty except for visible workspace notes.',
    pinnedNotes: [],
    activeLanePriorities: [],
    freezeNotes: [],
    machineEnvironmentNotes: [],
    currentBoundaries: [],
    expiresAt: null,
    clearedAt: null,
    updatedAt: 0,
    ...overrides,
  };
}

function createRouting(overrides: Partial<RelayRoutingGuidanceView> = {}): RelayRoutingGuidanceView {
  return {
    mode: 'handoff',
    targetAgentKey: 'dispatch',
    targetAgentName: 'Dispatch',
    summary: 'Suggested handoff: Dispatch.',
    reason: 'Default routing fallback.',
    basedOn: 'fallback routing',
    ...overrides,
  };
}

describe('deriveRelayFirstWaveRecommendation', () => {
  it('routes project-state summary asks to Recon', () => {
    const recommendation = deriveRelayFirstWaveRecommendation({
      taskDraft: 'Use the project-state summary prompt.',
      relayMemory: createMemory({
        nextSuggestedMove: 'Propose a safe fix for the local script flow.',
        recentStatusSummary: 'Patch handled the last startup fix.',
      }),
      broadRouting: createRouting({
        targetAgentKey: 'patch',
        targetAgentName: 'Patch',
      }),
    });

    expect(recommendation.key).toBe('recon');
    expect(recommendation.agent.name).toBe('Recon');
  });

  it('routes unclear ownership asks to Dispatch', () => {
    const recommendation = deriveRelayFirstWaveRecommendation({
      taskDraft: 'I am not sure who should handle this next.',
      relayMemory: createMemory(),
      broadRouting: createRouting(),
    });

    expect(recommendation.key).toBe('dispatch');
    expect(recommendation.agent.name).toBe('Dispatch');
  });

  it('routes build and fix asks to Patch', () => {
    const recommendation = deriveRelayFirstWaveRecommendation({
      taskDraft: 'Propose the smallest safe fix for this broken local script flow.',
      relayMemory: createMemory(),
      broadRouting: createRouting({
        targetAgentKey: 'recon',
        targetAgentName: 'Recon',
      }),
    });

    expect(recommendation.key).toBe('patch');
    expect(recommendation.agent.name).toBe('Patch');
  });
});

describe('resolveRelayFirstWaveModel', () => {
  it('keeps the preferred Patch model when it is installed', () => {
    const model = resolveRelayFirstWaveModel('patch', [
      'qwen3.5:9b',
      'qwen2.5-coder:14b',
    ]);

    expect(model).toBe('qwen2.5-coder:14b');
  });

  it('falls back to a compatible installed coder model for Patch', () => {
    const model = resolveRelayFirstWaveModel('patch', [
      'qwen3.5:9b',
      'qwen2.5-coder:latest',
    ]);

    expect(model).toBe('qwen2.5-coder:latest');
  });

  it('uses the provided fallback model when no Patch-specific model is installed', () => {
    const model = resolveRelayFirstWaveModel('patch', ['qwen3.5:9b'], 'qwen3.5:9b');

    expect(model).toBe('qwen3.5:9b');
  });
});

describe('buildRelayFirstWaveHandoff', () => {
  it('keeps Patch handoff propose-only while using the resolved model', () => {
    const handoff = buildRelayFirstWaveHandoff(
      'patch',
      'Propose the smallest safe fix for this startup script.',
      {
        models: ['qwen2.5-coder:latest'],
        fallbackModel: 'qwen3.5:9b',
      },
    );

    expect(handoff.model).toBe('qwen2.5-coder:latest');
    expect(handoff.message).toContain('Worker: Patch');
    expect(handoff.message).toContain('Model: qwen2.5-coder:latest');
    expect(handoff.message).toContain('Propose only.');
    expect(handoff.message).toContain('smallest safe fix');
    expect(handoff.message).toContain('Do not imply anything was already changed, applied, shipped, committed, tagged, or pushed.');
  });
});
