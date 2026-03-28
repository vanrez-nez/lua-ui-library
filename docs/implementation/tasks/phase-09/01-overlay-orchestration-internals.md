# Task 01: Overlay Orchestration Internals

## Goal

Implement Composer-owned overlay mounting behavior for Modal and Alert without freezing a public overlay registry API.

## Spec Anchors

- `docs/spec/ui-foundation-spec.md §6.4.3 Composer`
- `docs/spec/ui-foundation-spec.md §7.2.5 Focus and overlays`
- `docs/spec/ui-controls-spec.md §6.7 Modal`
- `docs/spec/ui-controls-spec.md §6.8 Alert`

## Scope

- Composer overlay mounting internals
- Overlay-layer ordering support
- Focus-trap bookkeeping for overlays
- Overlay lifecycle sequencing

## Required Behavior

- Overlay content mounts in the Stage overlay layer, not in the base scene layer.
- Overlay stacking is supported for nested Modal flows, but the implementation may keep its registry internal.
- Focus restoration records the previously focused node when `trapFocus = true` overlays become active.
- Overlay dismissal and restoration must preserve the spec’s focus-scope rules.

## Public API Boundary

- Do not stabilize `showOverlay` / `hideOverlay` as public API unless the specification is amended.
- Do not expose overlay zIndex allocation rules as public contract.
- Keep transition-progress callbacks and overlay sequencing internal.

## Non-Goals

- No new scene lifecycle phases.
- No public overlay registry schema.
- No modal-specific prop surface in this task.

## Acceptance Checks

- Nested overlays can be mounted and restored without breaking focus scope ownership.
- Overlay removal restores focus according to the spec when enabled.
- The implementation can change registry internals without forcing a public API break.
