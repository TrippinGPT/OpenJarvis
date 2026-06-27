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
