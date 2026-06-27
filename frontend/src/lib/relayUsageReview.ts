import type { RelayStructuredMemory } from './relayMemory';

export const RELAY_USAGE_REVIEW_STORAGE_KEY = 'relay-usage-review-log-v1';
const RELAY_USAGE_REVIEW_LIMIT = 25;

export type RelayUsageReviewTone = 'strong' | 'mixed' | 'rough';
export type RelayUsageReviewArea = 'popout' | 'dashboard' | 'agents' | 'chat';

export interface RelayUsageReviewEntry {
  id: string;
  createdAt: number;
  tone: RelayUsageReviewTone;
  area: RelayUsageReviewArea;
  note: string;
  currentLane: string | null;
  activeAgent: string | null;
  currentObjective: string | null;
  nextSuggestedMove: string | null;
  recentStatusSummary: string | null;
  selectedModel: string | null;
}

export interface RelayUsageReviewDraft {
  tone: RelayUsageReviewTone;
  area: RelayUsageReviewArea;
  note: string;
}

export interface RelayUsageReviewContext {
  relayMemory: RelayStructuredMemory;
  selectedModel: string | null;
}

export interface RelayUsageReviewDigest {
  total: number;
  strongCount: number;
  mixedCount: number;
  roughCount: number;
  strongestArea: string;
  roughestArea: string;
  recurringAgent: string | null;
  recurringLane: string | null;
  tuningHint: string;
}

function createReviewId(): string {
  if (typeof crypto !== 'undefined' && typeof crypto.randomUUID === 'function') {
    return crypto.randomUUID();
  }
  return `review-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 8)}`;
}

function normalizeEntries(candidate: unknown): RelayUsageReviewEntry[] {
  if (!Array.isArray(candidate)) {
    return [];
  }
  return candidate.filter((entry): entry is RelayUsageReviewEntry => (
    !!entry
    && typeof entry === 'object'
    && typeof (entry as RelayUsageReviewEntry).id === 'string'
    && typeof (entry as RelayUsageReviewEntry).createdAt === 'number'
    && typeof (entry as RelayUsageReviewEntry).tone === 'string'
    && typeof (entry as RelayUsageReviewEntry).area === 'string'
    && typeof (entry as RelayUsageReviewEntry).note === 'string'
  ));
}

export function loadRelayUsageReviews(): RelayUsageReviewEntry[] {
  try {
    const raw = localStorage.getItem(RELAY_USAGE_REVIEW_STORAGE_KEY);
    if (!raw) return [];
    return normalizeEntries(JSON.parse(raw));
  } catch {
    return [];
  }
}

export function saveRelayUsageReviews(entries: RelayUsageReviewEntry[]): void {
  localStorage.setItem(RELAY_USAGE_REVIEW_STORAGE_KEY, JSON.stringify(entries.slice(0, RELAY_USAGE_REVIEW_LIMIT)));
}

export function addRelayUsageReviewEntry(
  entries: RelayUsageReviewEntry[],
  draft: RelayUsageReviewDraft,
  context: RelayUsageReviewContext,
  now = Date.now(),
): RelayUsageReviewEntry[] {
  const note = draft.note.trim();
  if (!note) {
    return entries;
  }
  const nextEntry: RelayUsageReviewEntry = {
    id: createReviewId(),
    createdAt: now,
    tone: draft.tone,
    area: draft.area,
    note,
    currentLane: context.relayMemory.currentLane,
    activeAgent: context.relayMemory.activeAgent,
    currentObjective: context.relayMemory.currentObjective,
    nextSuggestedMove: context.relayMemory.nextSuggestedMove,
    recentStatusSummary: context.relayMemory.recentStatusSummary,
    selectedModel: context.selectedModel,
  };
  return [nextEntry, ...entries].slice(0, RELAY_USAGE_REVIEW_LIMIT);
}

export function removeRelayUsageReviewEntry(
  entries: RelayUsageReviewEntry[],
  id: string,
): RelayUsageReviewEntry[] {
  return entries.filter((entry) => entry.id !== id);
}

export function clearRelayUsageReviews(): RelayUsageReviewEntry[] {
  return [];
}

export function formatRelayUsageReviewTime(timestamp: number): string {
  return new Date(timestamp).toLocaleString([], {
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
}

function countTopLabel(values: Array<string | null | undefined>): string | null {
  const counts = new Map<string, number>();
  for (const value of values) {
    const normalized = value?.trim();
    if (!normalized) continue;
    counts.set(normalized, (counts.get(normalized) || 0) + 1);
  }
  let best: string | null = null;
  let bestCount = 0;
  for (const [label, count] of counts.entries()) {
    if (count > bestCount) {
      best = label;
      bestCount = count;
    }
  }
  return best;
}

function countTopArea(entries: RelayUsageReviewEntry[]): string {
  const best = countTopLabel(entries.map((entry) => entry.area));
  return best || 'None';
}

export function deriveRelayUsageReviewDigest(entries: RelayUsageReviewEntry[]): RelayUsageReviewDigest {
  const recentEntries = entries.slice(0, 8);
  const strongEntries = recentEntries.filter((entry) => entry.tone === 'strong');
  const mixedEntries = recentEntries.filter((entry) => entry.tone === 'mixed');
  const roughEntries = recentEntries.filter((entry) => entry.tone === 'rough');

  const strongestArea = strongEntries.length ? countTopArea(strongEntries) : 'None yet';
  const roughestArea = roughEntries.length ? countTopArea(roughEntries) : 'None yet';
  const recurringAgent = countTopLabel(recentEntries.map((entry) => entry.activeAgent));
  const recurringLane = countTopLabel(recentEntries.map((entry) => entry.currentLane));

  let tuningHint = 'Save a few review entries before trying to tune the cockpit.';

  if (roughEntries.length >= 2) {
    tuningHint = `Recent rough reviews cluster around ${roughestArea.toLowerCase()}. That is the clearest next tuning target.`;
  } else if (mixedEntries.length >= 2 && recurringAgent) {
    tuningHint = `${recurringAgent} context is showing up repeatedly in mixed reviews. Tighten that flow before widening scope.`;
  } else if (strongEntries.length >= 2) {
    tuningHint = `Recent strong reviews are concentrated around ${strongestArea.toLowerCase()}. Keep that stable while fixing weaker spots.`;
  } else if (recurringLane) {
    tuningHint = `${recurringLane} is the most repeated recent lane. Use that context for the next polish pass.`;
  }

  return {
    total: entries.length,
    strongCount: strongEntries.length,
    mixedCount: mixedEntries.length,
    roughCount: roughEntries.length,
    strongestArea,
    roughestArea,
    recurringAgent,
    recurringLane,
    tuningHint,
  };
}
