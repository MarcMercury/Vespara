# Kult Phase 2 Technical Migration Plan

## Goal

Rename legacy technical identifiers (`vespara_*`, `package:vespara`, legacy deep links, and RPC names) to Kult-safe equivalents with minimal downtime and explicit rollback.

## Scope

- In scope: package name, deep link protocol, app/table/RPC aliases, edge function endpoint compatibility, CI/deploy config.
- Out of scope (Phase 2): UX copy (already completed), gameplay/business logic changes.

## Migration Principles

1. Additive-first: introduce new names before removing old names.
2. Backward compatible: support both old and new identifiers during transition.
3. Observable: every cutover step has logs/metrics and a rollback command.
4. Reversible: no destructive rename without stable alias period.

## Proposed Sequence

### Step 1 — App Identity Compatibility

- Keep package name as `vespara` until last step.
- Keep legacy imports working.
- Completed prep:
  - Auth redirect URL is now domain-agnostic in app code.
  - QR generation now emits `kult://connect/...`.

Rollback:

- Revert app commit only; no DB changes.

### Step 2 — Database Alias Layer (No Breaking Renames)

Create `kult_*` views/functions that map to existing `vespara_*` tables/RPCs.

Examples:

- `kult_events` view -> `vespara_events`
- `kult_event_rsvps` view -> `vespara_event_rsvps`
- `create_kult_group()` wrapper -> calls `create_vespara_group()`
- `leave_kult_group()` wrapper -> calls `leave_vespara_group()`
- `delete_kult_group()` wrapper -> calls `delete_vespara_group()`

Rollback:

- Drop only the new wrapper objects (`kult_*`) if needed.

### Step 3 — Dual-Read / Dual-Write in App

- Update providers to prefer `kult_*` endpoints/tables when present.
- Keep fallback to legacy `vespara_*` until production stabilization window is complete.
- Add telemetry on fallback usage.

Rollback:

- Feature flag to force legacy `vespara_*` path.

### Step 4 — Edge Functions and Links

- Keep old edge routes active.
- Add/keep compatibility handling for old domains and old deep links where needed.
- Ensure invite/vouch links resolve both old/new hostnames.

Rollback:

- Keep old routes and DNS records active during rollback window.

### Step 5 — Package Rename (Final Step)

- Rename `pubspec.yaml` package from `vespara` to `kult` only after DB/RPC cutover is stable.
- Update all `package:vespara/...` imports in one coordinated commit.

Rollback:

- Revert package-rename commit and restore lockfile.

### Step 6 — Decommission Legacy Identifiers

- After 1–2 release cycles with no legacy traffic:
  - Remove legacy wrappers/fallbacks.
  - Archive legacy migration notes.

Rollback:

- Recreate wrappers from migration scripts.

## SQL Change Checklist (Phase 2 Execution)

- [ ] Add `kult_*` compatibility views.
- [ ] Add `create_kult_group/leave_kult_group/delete_kult_group` wrappers.
- [ ] Add grants/RLS coverage for wrappers/views.
- [ ] Add migration verification queries.

## App Change Checklist (Phase 2 Execution)

- [ ] Add provider-level fallback from `kult_*` to `vespara_*`.
- [ ] Add logging for fallback hit count.
- [ ] Update tests for both paths.
- [ ] Update environment docs and release checklist.

## Verification Gates

- [ ] Auth flow works on deployed host domain and local host.
- [ ] Event CRUD works via new aliases.
- [ ] Group CRUD works via new wrappers.
- [ ] QR connect payload accepted in scanner flow.
- [ ] No increase in auth or DB error rates post-cutover.

## Rollback Triggers

- Elevated auth failures (>2x baseline).
- Group/event RPC error rate >1% sustained for 10+ minutes.
- Schema permission failures in production logs.

## Rollback Plan (Fast)

1. Disable `kult_*` feature flag in app.
2. Revert to legacy provider paths.
3. Keep wrappers/views in DB (non-breaking).
4. Re-run smoke tests.

## Owner Notes

- Runtime safety is prioritized over aggressive rename speed.
- Keep object rename operations (actual table/function renames) as a dedicated Phase 3, only after alias strategy has proven stable.
