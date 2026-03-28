# Task 01: Stage Runtime Contract

## Goal

Implement `Stage` as the runtime root with the full runtime boundary required by the foundation spec.

## Spec Anchors

- `docs/spec/ui-foundation-spec.md §6.4.1 Stage`
- `docs/spec/ui-foundation-spec.md §3A.6 Lifecycle Model`
- `docs/spec/ui-foundation-spec.md §3D Interaction Model`

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
- Update traversal resolves dirty geometry, layout placeholders, world transforms, and queued state changes before returning.
- Draw traversal issues draw commands without performing state resolution.
- Root input delivery is a real runtime boundary, even if Phase 4 later deepens dispatch and propagation.
- Event resolution precedence checks overlay layer before base scene layer.

## Missing Detail Normalization

- `getSafeArea()` insets-only is insufficient; Stage must also expose safe-area bounds as a queryable rectangle.
- If raw input cannot yet flow through the full propagation system, the Stage task must still define deterministic intake and forwarding behavior rather than a no-op contract.
- Two-pass assertion behavior is allowed, but it is enforcement of the runtime contract, not a substitute for the runtime contract itself.

## Non-Goals

- No full logical event propagation yet.
- No focus traversal yet.
- No control-family behavior yet.

## Acceptance Checks

- Overlay precedence is structural and independent of child `zIndex`.
- Viewport resize updates viewport dimensions, safe-area insets, and safe-area bounds.
- Calling draw before a valid update in the same frame hard-fails deterministically.
