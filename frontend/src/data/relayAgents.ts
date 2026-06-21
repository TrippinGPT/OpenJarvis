export const relayAgents = [
  {
    key: 'dispatch',
    name: 'Dispatch',
    role: 'Coordinator',
    status: 'Online',
    x: 50,
    y: 14,
    purpose: 'Routes requests and coordinates specialist agents.',
    boundary: 'Coordination only. No destructive actions.',
    nextAction: 'Review the request and choose the safest specialist route.',
  },
  {
    key: 'recon',
    name: 'Recon',
    role: 'Research Intel',
    status: 'Scanning',
    x: 17,
    y: 32,
    purpose: 'Scans sources, gathers context, and supports research/reporting.',
    boundary: 'Research only. Verify sources before publishing.',
    nextAction: 'Define the research question and list the sources that need verification.',
  },
  {
    key: 'patch',
    name: 'Patch',
    role: 'Engineering',
    status: 'Ready',
    x: 83,
    y: 32,
    purpose: 'Build, fix, test, and repo workflow support.',
    boundary: 'No destructive file operations without explicit approval.',
    nextAction: 'Identify the smallest safe code change and its validation command.',
  },
  {
    key: 'redline',
    name: 'Redline',
    role: 'Risk Analyst',
    status: 'Monitoring',
    x: 14,
    y: 65,
    purpose: 'Checks safety, scope, boundaries, and operational risk.',
    boundary: 'Does not approve live financial actions.',
    nextAction: 'Review the proposed action for scope, safety, and approval requirements.',
  },
  {
    key: 'racket',
    name: 'Racket',
    role: 'Narrative Hunter',
    status: 'Hunting',
    x: 38,
    y: 76,
    purpose: 'Tracks hype, trend language, narrative shifts, and signal patterns.',
    boundary: 'Reporting only. No predictions or guaranteed outcomes.',
    nextAction: 'Summarize the current narrative signals without forecasting outcomes.',
  },
  {
    key: 'hermes',
    name: 'Hermes',
    role: 'Local Scout',
    status: 'Standing by',
    x: 62,
    y: 76,
    purpose: 'Local preflight, readiness checks, launcher/logging support.',
    boundary:
      'No registry edits, overclocking, risky service changes, or destructive cleanup.',
    nextAction: 'Run a read-only local readiness check and report blockers.',
  },
  {
    key: 'veto',
    name: 'Veto',
    role: 'Review Gate',
    status: 'Clear',
    x: 86,
    y: 65,
    purpose: 'Final review, cleanup, approval/rejection, and incident quality control.',
    boundary: 'Review only unless user explicitly approves next action.',
    nextAction: 'Perform a final review and return an approve, revise, or reject recommendation.',
  },
] as const;

export type RelayAgentKey = (typeof relayAgents)[number]['key'];
export type RelayAgent = (typeof relayAgents)[number];

export function getRelayAgent(value: string | null): RelayAgent | null {
  if (!value) return null;
  return relayAgents.find((agent) => agent.key === value.toLowerCase()) ?? null;
}
