# Relay/OpenClaw Integration Plan

Trippin AI Relay is the cockpit. OpenClaw is the engine that owns the real workflows and project lanes. The repositories stay separate for now.

## Delivery stages

- **v0.7:** Read-only lane manifest and bridge status checker only.
- **v0.8:** Add a read-only OpenClaw status display in Relay.
- **v0.9:** Read dashboard project-lane cards from the bridge manifest.
- **v1.0:** Consider approved, allowlisted launcher and preflight actions after explicit user approval.

## Safety boundaries

- SignalForge is research and reporting only. It must not provide investment advice, buy/sell recommendations, financial predictions, guaranteed outcomes, or real-money execution.
- PaperForge is simulated education only. It must not connect wallets, use private keys, perform swaps, or handle real funds.
- The bridge may inspect declared paths and run documented read-only status commands. It must not run lane workflows or make cross-repository changes.

## Required restrictions

- Do not run `jarvis self-update` on Relay.
- Do not merge OpenClaw into Relay.
- Do not modify `D:\AI\OPENCLAW` from this bridge without explicit user approval.
