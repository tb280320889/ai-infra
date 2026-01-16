# iTrustCircle - Agent Guidance

## Read this first (authoritative references)
- AI Handbook: `.ai/handbook/` (use this as the SOP; do not read `.ai/ai-infra/*` unless updating infra)
- Skills: `.claude/skills/` (linked from ai-infra)
- Rules: project root `.rules` (agent constraints)

## Non-negotiables
- Guardian Core reliability > UI. UI may crash; Guardian Core must keep running.
- Capacitor workflow is mandatory: `web build -> cap sync -> run/open`.
- Never hand-edit generated/copied web assets under `android/` or `ios/` (e.g. `android/app/src/main/assets/public`). Always rebuild web then sync.
-- WIP=1: Only work on ONE task card at a time. Do not start a second task until the current one is accepted.
- No cross-layer refactors in one change. If changes touch more than one layer (UI(Web), Plugin(Bridge), Native(Android)), split into multiple task cards and separate PRs.

## Directory boundaries
- Web UI: `apps/mobile/src/` (SvelteKit)
- Capacitor config + web output: `apps/mobile/capacitor.config.*`, `apps/mobile/build/`
- Android native + Guardian runtime: `apps/mobile/android/`
- (Future) iOS: `apps/mobile/ios/`
- Infra sources (do not edit from project work): `.ai/ai-infra/`

## Commands (prefer running from repo root)
- Web dev: `cd apps/mobile && pnpm dev`
- Web build: `cd apps/mobile && pnpm build`
- Sync native: `cd apps/mobile && pnpm exec cap sync`
- Android run (CLI): `cd apps/mobile && pnpm exec cap run android`
- Android open (Studio): `cd apps/mobile && pnpm exec cap open android`

## Output expectations (every change request)
When making changes, always include:
1) Files to change (paths)
2) What changes (bullets)
3) Risks (bullets)
4) How to test (commands + manual steps)
5) Rollback (how to revert)

## Acceptance (MVP)
- BLE disconnect triggers countdown; if not cancelled -> AlertEvent queued and sent to Tower.
- Weak/No network: queue persists and flushes on recovery.
- Tower stores to SQLite and sends Email successfully.
- Diagnostics exports recent logs + config summary.
