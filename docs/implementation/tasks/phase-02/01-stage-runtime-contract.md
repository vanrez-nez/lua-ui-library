# Task 01: Stage Runtime Contract

## Goal

Implement `Stage` as the runtime root exactly within the boundary published in `docs/spec/ui-foundation-spec.md`.

## Spec Anchors

- `docs/spec/ui-foundation-spec.md §6.4.1 Stage`
- `docs/spec/ui-foundation-spec.md §3A.6 Lifecycle Model`
- `docs/spec/ui-foundation-spec.md §7.1 Event Propagation`

## Scope

- Finalize `lib/ui/scene/stage.lua`
- Enforce base scene and overlay layer ownership
- Update traversal entry
- Draw traversal entry
- Root input delivery boundary
- Viewport and safe-area synchronization

## Required Behavior

- `Stage` has no parent and only one instance may exist per application runtime.
- `Stage` owns exactly two logical layers: base scene layer and overlay layer.
- `Stage` reflects current viewport dimensions and exposes both full viewport bounds and safe area bounds as queryable rectangles.
- `Stage` keeps `safeAreaInsets` synchronized with the environment alongside the bounds-based safe-area view.
- Update traversal resolves dirty geometry, layout placeholders, world transforms, and queued state changes before returning.
- Draw traversal issues draw commands without performing state resolution.
- Raw host input enters only through `Stage`. Phase 02 may keep downstream routing shallower than later event phases, but the root intake boundary cannot be a documented no-op and cannot be duplicated beneath `Stage`.
- Event resolution precedence checks the overlay layer before the base scene layer.

## Settled Spec Clarifications

- The safe-area contract is bounds-based as well as inset-based; `safeAreaInsets` alone is insufficient.
- The Stage-owned raw-input boundary is already part of the published contract; later phases deepen dispatch mechanics without moving that boundary.
- A two-pass draw assertion is valid as enforcement of the runtime contract, but it does not replace the runtime contract itself.

## Non-Goals

- No full logical event propagation yet.
- No focus traversal yet.
- No control-family behavior yet.

## Acceptance Checks

- Overlay precedence is structural and independent of child `zIndex`.
- Viewport resize updates viewport dimensions, `safeAreaInsets`, and safe area bounds.
- Calling draw before a valid update in the same frame hard-fails deterministically.
- No scene or overlay path beneath `Stage` becomes a second raw-input intake boundary.
