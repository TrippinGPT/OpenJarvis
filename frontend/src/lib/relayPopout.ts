export const RELAY_POPOUT_ACTIVITY_KEY = 'relay-popout-activity-v1';

export interface RelayPopoutActivity {
  isResponding: boolean;
  phase: string;
  model: string;
  updatedAt: number;
}

export function readRelayPopoutActivity(): RelayPopoutActivity | null {
  try {
    const raw = localStorage.getItem(RELAY_POPOUT_ACTIVITY_KEY);
    return raw ? (JSON.parse(raw) as RelayPopoutActivity) : null;
  } catch {
    return null;
  }
}

export function writeRelayPopoutActivity(activity: RelayPopoutActivity): void {
  try {
    localStorage.setItem(RELAY_POPOUT_ACTIVITY_KEY, JSON.stringify(activity));
  } catch {
    // The companion remains usable in idle mode when storage is unavailable.
  }
}
