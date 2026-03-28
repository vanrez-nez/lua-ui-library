# Task 06: Stage Root, Viewport, And Two-Pass Traversal

## Goal

Implement `Stage` as the runtime root with its required layers, traversal entry points, and root-owned environment data.

## Spec Anchors

- `docs/spec/ui-foundation-spec.md §6.4.1 Stage`
- `docs/spec/ui-foundation-spec.md §3A.6 Lifecycle Model`
- `docs/spec/ui-foundation-spec.md §3D Interaction Model`

## Scope

- Implement `lib/ui/scene/stage.lua`
- Create required `base scene layer` and `overlay layer`
- Expose viewport dimensions
- Expose safe-area insets and queryable safe-area bounds
- Provide update traversal and draw traversal entry points
- Provide a root input-delivery surface

## Required Behavior

- `Stage` has no parent.
- `Stage` owns exactly two logical layers: base scene and overlay.
- Overlay traversal precedence is structural, not derived from child `zIndex`.
- Update traversal resolves dirty geometry, layout placeholders, and world transforms so the tree is internally consistent before draw.
- Draw traversal issues draw commands and performs no state resolution.

## Missing Detail Normalization

- The phase draft's `getSafeArea()` insets-only shape is insufficient on its own. This task must define both:
  - safe-area insets storage
  - a query for safe-area bounds derived from viewport minus insets
- Even before Phase 4 event propagation, `Stage` must expose a root input entry point so later input work plugs into an existing spec-shaped boundary.
- Two-pass enforcement may remain a hard failure, but it must be framed as runtime contract enforcement rather than as a public component feature.

## Non-Goals

- No `Scene` or `Composer` lifecycle orchestration yet.
- No full logical event dispatch yet.
- No focus traversal yet.

## Acceptance Checks

- `Stage` initializes with required base and overlay layers.
- Overlay draw and hit-resolution precedence is consistent regardless of child `zIndex`.
- Viewport resize updates dimensions, safe-area insets, and safe-area bounds.
- Calling draw without a prior successful update in the same frame raises the documented two-pass violation.
