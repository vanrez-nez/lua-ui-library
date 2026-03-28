# Task 01: Core Math And Geometry

## Goal

Establish the shared value types and normalization helpers required by the foundation runtime and primitive contracts.

## Spec Anchors

- `docs/spec/ui-foundation-spec.md §6.1.1 Container`
- `docs/spec/ui-foundation-spec.md §6.1.2 Drawable`
- `docs/spec/ui-foundation-spec.md Glossary: local space, world space, hit test, layout pass`

## Scope

- Implement `lib/ui/core/vec2.lua`
- Implement `lib/ui/core/matrix.lua`
- Implement `lib/ui/core/rectangle.lua`
- Implement `lib/ui/core/insets.lua`

## Deliverables

- Immutable or value-oriented vector operations needed for transform and geometry work
- Affine matrix composition, inversion, and point transform support
- Rectangle helpers for bounds, intersection, containment, and corner extraction
- Insets normalization for scalar, two-value, and four-edge inputs

## Required Constraints

- Matrix and rectangle behavior must be deterministic and side-effect free at the API boundary.
- Rectangle helpers must support clip and hit-test use cases, not just layout.
- Insets normalization must be shared by all future components that use padding or margin.

## Non-Goals

- `color.lua` and `easing.lua` are not acceptance blockers for spec compliance in this phase.
- No layout-family measurement helpers yet.
- No token resolution or theming behavior yet.

## Acceptance Checks

- Matrix inversion plus forward transform round-trips representative points within a small numeric tolerance.
- Rectangle intersection returns an empty or zero-area rectangle when regions do not overlap.
- Insets normalization produces a canonical `{ top, right, bottom, left }` shape for all accepted input forms.
