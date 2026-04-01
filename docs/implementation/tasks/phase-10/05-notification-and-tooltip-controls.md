# Task 05: Notification And Tooltip Controls

## Goal

Implement the published non-modal overlay family for transient status and anchored descriptive content, aligned to the current control and motion specs.

## Spec Anchors

- `docs/spec/ui-controls-spec.md §6.15 Notification`
- `docs/spec/ui-controls-spec.md §6.16 Tooltip`
- `docs/spec/ui-foundation-spec.md §7.1.4 Anchored overlay placement`
- `docs/spec/ui-foundation-spec.md §7.2.5 Focus and overlays`
- `docs/spec/ui-motion-spec.md §4I Family Adoption Matrix`

## Scope

- `lib/ui/controls/notification.lua`
- `lib/ui/controls/tooltip.lua`
- Overlay-layer mounting for non-modal surfaces
- Notification dismissal timing and stacking
- Tooltip trigger association and fallback placement
- Shared motion-surface adoption for notification enter/exit/reflow and tooltip open/close/placement
- Overlay hit-testing and non-focus-trapping behavior

## Implementation Guidance

- Implement both controls with the existing `lib/cls` inheritance model and extend the nearest retained node base instead of introducing standalone manager-style modules as the public API.
- Reuse the overlay-mounting and focus-contract patterns already present in `Modal`; `Notification` and `Tooltip` should adapt those patterns to their non-modal contracts rather than inventing unrelated overlay lifecycle code.
- Reuse `lib/ui/utils/schema.lua`, `assert.lua`, and `types.lua` for validating `open`, `onOpenChange`, `closeMethod`, `duration`, placement props, trigger mode, and other public fields.
- Keep timer, stacking, hover observation, placement resolution bookkeeping, and overlay attachment internal. None of those helper objects should become public phase deliverables.
- `Tooltip` should preserve the split between the ordinary-scene trigger subtree and the overlay-mounted surface subtree. Do not model it as a free-floating notification variant.
- `Notification` close-button behavior should remain an owned optional region inside the control contract, not a requirement that consumers supply interactive descendants in `content`.
- Motion support must be wired through the shared motion contract from Task 02, with old per-control animation props explicitly treated as obsolete.

## Required Behavior

- `Notification` uses `closeMethod`, `duration`, `stackable`, `edge`, `align`, and `safeAreaAware` exactly as published.
- `Notification.duration` remains dismissal timing only.
- `Tooltip` coordinates one ordinary-scene trigger subtree with one overlay-mounted tooltip surface.
- Tooltip placement honors preferred placement first and falls back to stay as visible as possible within the effective visible region.
- Neither control traps focus or blocks interaction outside its visible hit region.
- Nested interactive descendants inside notification or tooltip content remain unsupported in this revision.
- Motion support for both controls flows through `motionPreset` / `motion`.

## Settled Boundaries

- Do not reintroduce per-control animation props such as `Notification.easing`.
- Do not add a public overlay host, queue manager, or tooltip registry API.
- Do not turn tooltip visibility into an imperative-only API; negotiated `open` remains authoritative.

## Non-Goals

- No modal notification or tooltip behavior.
- No interactive action-region expansion inside tooltip content.
- No public overlay registry API.

## Acceptance Checks

- Notification stacking and overlap behavior match `stackable`.
- Tooltip stays associated with its trigger and falls back away from clipping when possible.
- Neither control moves focus on open.
- Motion surfaces and phases align to the shared motion contract rather than ad hoc local animation props.
- Overlay lifecycle and validation follow the same base conventions already used by `Modal` and the shared utility modules.
