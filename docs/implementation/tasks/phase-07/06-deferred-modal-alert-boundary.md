# Task 06: Deferred Modal And Alert Boundary

## Goal

Keep Phase 07 scoped to the controls it actually implements, and explicitly defer `Modal` and `Alert` so they do not leak into the Phase 07 contract.

## Spec Anchors

- `docs/spec/ui-controls-spec.md:911-1066`
- `docs/spec/ui-controls-spec.md:1238-1240`

## Scope

- Record that `Modal` and `Alert` are part of the controls specification but not implemented by Phase 07
- Prevent Phase 07 tests, docs, or helpers from implying overlay-control coverage

## Required Behavior

- Phase 07 should not introduce overlay-layer APIs in the controls package just to cover missing controls early.
- Phase 07 should not freeze `Modal`/`Alert` behavior indirectly through the button, text-entry, or tabs implementations.

## Non-Goals

- No `Modal` implementation.
- No `Alert` implementation.
- No overlay-focus or backdrop-specific API stabilization.

## Acceptance Checks

- Phase 07 task documentation clearly states the deferred boundary.
- The phase 07 harness does not claim Modal/Alert coverage.
