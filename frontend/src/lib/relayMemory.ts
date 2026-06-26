export const RELAY_MEMORY_STORAGE_KEY = 'relay-structured-memory-v1';
export const RELAY_MEMORY_TRANSIENT_TTL_MS = 12 * 60 * 60 * 1000;

export interface RelayPinnedNote {
  id: string;
  text: string;
  pinnedAt: number;
}

export interface RelayStructuredMemory {
  sessionId: string;
  currentLane: string | null;
  activeAgent: string | null;
  currentObjective: string | null;
  lastMeaningfulAction: string | null;
  nextSuggestedMove: string | null;
  recentStatusSummary: string | null;
  pinnedNotes: RelayPinnedNote[];
  activeLanePriorities: string[];
  freezeNotes: string[];
  machineEnvironmentNotes: string[];
  currentBoundaries: string[];
  expiresAt: number | null;
  clearedAt: number | null;
  updatedAt: number;
}

export type RelayMemoryTransientUpdate = Partial<
  Pick<
    RelayStructuredMemory,
    | 'currentLane'
    | 'activeAgent'
    | 'currentObjective'
    | 'lastMeaningfulAction'
    | 'nextSuggestedMove'
    | 'recentStatusSummary'
  >
>;

const defaultActiveLanePriorities = [
  'Relay cockpit continuity',
  'Operator-visible memory only',
  'Structured memory before semantic memory',
];

const defaultFreezeNotes = [
  'Relay voice/UI lane is frozen as a stable placeholder milestone.',
];

const defaultMachineEnvironmentNotes = [
  'Local-first prototype on the main Windows build machine.',
  'Single-machine continuity only. No cross-machine sync.',
];

const defaultCurrentBoundaries = [
  'No browser shell execution.',
  'OpenClaw stays read-only.',
  'Transient memory expires unless it is pinned.',
];

function createSessionId(): string {
  if (typeof crypto !== 'undefined' && typeof crypto.randomUUID === 'function') {
    return crypto.randomUUID();
  }
  return `relay-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 8)}`;
}

export function createDefaultRelayMemory(now = Date.now()): RelayStructuredMemory {
  return {
    sessionId: createSessionId(),
    currentLane: 'Relay cockpit',
    activeAgent: null,
    currentObjective: null,
    lastMeaningfulAction: 'Structured memory initialized.',
    nextSuggestedMove: 'Use Relay normally, then pin anything worth keeping.',
    recentStatusSummary: 'Relay memory is empty except for visible workspace notes.',
    pinnedNotes: [],
    activeLanePriorities: [...defaultActiveLanePriorities],
    freezeNotes: [...defaultFreezeNotes],
    machineEnvironmentNotes: [...defaultMachineEnvironmentNotes],
    currentBoundaries: [...defaultCurrentBoundaries],
    expiresAt: now + RELAY_MEMORY_TRANSIENT_TTL_MS,
    clearedAt: null,
    updatedAt: now,
  };
}

function normalizeMemoryShape(
  candidate: Partial<RelayStructuredMemory> | null | undefined,
  now = Date.now(),
): RelayStructuredMemory {
  const base = createDefaultRelayMemory(now);
  if (!candidate) {
    return base;
  }
  return {
    ...base,
    ...candidate,
    sessionId: candidate.sessionId || base.sessionId,
    pinnedNotes: Array.isArray(candidate.pinnedNotes)
      ? candidate.pinnedNotes.filter((note): note is RelayPinnedNote =>
          !!note
          && typeof note.id === 'string'
          && typeof note.text === 'string'
          && typeof note.pinnedAt === 'number',
        )
      : base.pinnedNotes,
    activeLanePriorities: Array.isArray(candidate.activeLanePriorities)
      ? candidate.activeLanePriorities.filter((value): value is string => typeof value === 'string')
      : base.activeLanePriorities,
    freezeNotes: Array.isArray(candidate.freezeNotes)
      ? candidate.freezeNotes.filter((value): value is string => typeof value === 'string')
      : base.freezeNotes,
    machineEnvironmentNotes: Array.isArray(candidate.machineEnvironmentNotes)
      ? candidate.machineEnvironmentNotes.filter((value): value is string => typeof value === 'string')
      : base.machineEnvironmentNotes,
    currentBoundaries: Array.isArray(candidate.currentBoundaries)
      ? candidate.currentBoundaries.filter((value): value is string => typeof value === 'string')
      : base.currentBoundaries,
    updatedAt: typeof candidate.updatedAt === 'number' ? candidate.updatedAt : base.updatedAt,
    expiresAt: typeof candidate.expiresAt === 'number' || candidate.expiresAt === null
      ? candidate.expiresAt ?? null
      : base.expiresAt,
    clearedAt: typeof candidate.clearedAt === 'number' || candidate.clearedAt === null
      ? candidate.clearedAt ?? null
      : base.clearedAt,
  };
}

export function clearRelayTransientMemory(
  memory: RelayStructuredMemory,
  now = Date.now(),
): RelayStructuredMemory {
  return {
    ...memory,
    currentLane: 'Relay cockpit',
    activeAgent: null,
    currentObjective: null,
    lastMeaningfulAction: 'Transient Relay memory cleared.',
    nextSuggestedMove: 'Start a fresh action or pin a note you still need.',
    recentStatusSummary: 'Transient continuity was reset. Pinned notes remain visible.',
    expiresAt: null,
    clearedAt: now,
    updatedAt: now,
  };
}

export function pruneExpiredRelayMemory(
  memory: RelayStructuredMemory,
  now = Date.now(),
): RelayStructuredMemory {
  if (!memory.expiresAt || memory.expiresAt > now) {
    return memory;
  }
  return {
    ...clearRelayTransientMemory(memory, now),
    lastMeaningfulAction: 'Transient Relay memory expired.',
    nextSuggestedMove: 'Review pinned notes or start a fresh action.',
    recentStatusSummary: 'Only pinned and workspace memory remain after expiry.',
  };
}

export function loadRelayMemory(): RelayStructuredMemory {
  try {
    const raw = localStorage.getItem(RELAY_MEMORY_STORAGE_KEY);
    const parsed = raw ? (JSON.parse(raw) as Partial<RelayStructuredMemory>) : null;
    const hydrated = pruneExpiredRelayMemory(normalizeMemoryShape(parsed));
    saveRelayMemory(hydrated);
    return hydrated;
  } catch {
    const fallback = createDefaultRelayMemory();
    saveRelayMemory(fallback);
    return fallback;
  }
}

export function saveRelayMemory(memory: RelayStructuredMemory): void {
  localStorage.setItem(RELAY_MEMORY_STORAGE_KEY, JSON.stringify(memory));
}

export function updateRelayTransientMemory(
  memory: RelayStructuredMemory,
  updates: RelayMemoryTransientUpdate,
  now = Date.now(),
): RelayStructuredMemory {
  return {
    ...memory,
    ...updates,
    expiresAt: now + RELAY_MEMORY_TRANSIENT_TTL_MS,
    clearedAt: null,
    updatedAt: now,
  };
}

export function addRelayPinnedNote(
  memory: RelayStructuredMemory,
  noteText: string,
  now = Date.now(),
): RelayStructuredMemory {
  const text = noteText.trim();
  if (!text) {
    return memory;
  }
  const nextNote: RelayPinnedNote = {
    id: `${now.toString(36)}-${Math.random().toString(36).slice(2, 7)}`,
    text,
    pinnedAt: now,
  };
  return {
    ...memory,
    pinnedNotes: [nextNote, ...memory.pinnedNotes],
    updatedAt: now,
  };
}

export function removeRelayPinnedNote(
  memory: RelayStructuredMemory,
  noteId: string,
  now = Date.now(),
): RelayStructuredMemory {
  return {
    ...memory,
    pinnedNotes: memory.pinnedNotes.filter((note) => note.id !== noteId),
    updatedAt: now,
  };
}

export function clearAllRelayMemory(now = Date.now()): RelayStructuredMemory {
  const reset = createDefaultRelayMemory(now);
  return {
    ...reset,
    clearedAt: now,
    lastMeaningfulAction: 'Relay memory cleared.',
    nextSuggestedMove: 'Start a fresh session and pin only what matters.',
    recentStatusSummary: 'Relay memory was fully reset by the operator.',
  };
}

export function summarizeRelayMemoryText(text: string, maxLength = 180): string {
  const compact = text.replace(/\s+/g, ' ').trim();
  if (compact.length <= maxLength) {
    return compact;
  }
  return `${compact.slice(0, maxLength - 1).trimEnd()}…`;
}

export function formatRelayMemoryTime(timestamp: number | null): string {
  if (!timestamp) return 'Not set';
  return new Date(timestamp).toLocaleString([], {
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
}
