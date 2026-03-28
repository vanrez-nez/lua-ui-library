# Task 05: Phase 04 Demo And Acceptance

## Goal

Build a Phase 4 verification harness that demonstrates event propagation, target resolution, and cancellation behavior without inventing public API surface beyond what the current spec settles.

## Spec Anchors

- `docs/spec/ui-foundation-spec.md §7.1 Event Propagation`
- `docs/spec/ui-foundation-spec.md §7.2 Focus`
- `docs/spec/ui-foundation-spec.md §3E.3 Concurrent And Rapid Input Behavior`

## Scope

- Create or revise `test/phase4/`
- Capture/target/bubble logging
- preventDefault behavior
- overlay precedence and z-order target selection
- navigate/dismiss dispatch
- scroll and drag dispatch

## Screen Normalization

- The navigate/dismiss screen must not present `stage:requestFocus()` or any other specific imperative focus helper as spec-backed public API.
- Use a Phase 4-local focus anchor or internal test harness fixture instead.
- The hover demo, if present, must remain internal-state-driven and not rely on nonexistent public hover events.

## Non-Goals

- No text-input or focus-change event screen yet.
- No control-family contract assertions beyond dispatch plumbing.

## Acceptance Checks

- Capture, target, and bubble order is observable and stable.
- `preventDefault()` blocks default action without blocking propagation.
- Overlay targets win over base-scene targets in overlap regions.
- Dispatch failures do not corrupt the harness after they are caught with `pcall` where appropriate.
