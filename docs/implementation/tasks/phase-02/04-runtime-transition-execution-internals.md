# Task 04: Runtime Transition Execution Internals

## Goal

Implement the mechanics needed to render and interrupt scene transitions while keeping helper modules and low-level transition plumbing internal unless the spec names them.

## Spec Anchors

- `docs/spec/ui-foundation-spec.md §6.4.3 Composer`
- `docs/spec/ui-foundation-spec.md §3E.4 Transition Interruption`
- `docs/spec/ui-foundation-spec.md §3F.2 API Surface Classification`

## Scope

- Transition progress tracking
- Visual transition composition
- Transition interruption handling
- Optional helper modules such as transition catalogs or canvas-pool support

## Internal-Only Boundary

- `lib/ui/scene/transitions.lua` may exist, but its module shape, built-in names, and composition callback signatures are internal implementation detail.
- Canvas pooling or offscreen composition helpers may exist, but they are internal runtime support, not spec-backed public API in this phase.
- If easing helpers are reused here, they remain shared utilities, not new runtime API surface.
- Overlay transition helpers or stacking registries, if introduced, remain internal unless a later spec revision documents them.

## Required Behavior

- Transition completion follows the `Composer` state machine exactly: fire outgoing leave-after, remove outgoing, fire incoming enter-after, set current scene, clear transition state.
- Interruption follows the exact published rule: cancel the active visual transition, commit the current incoming scene as stable, clear transition state, then process the new request from that stable state.
- No intermediate scene may execute enter or leave hooks when the interrupted-transition edge case forbids it.
- Internal transition helpers may evolve later without forcing a public API break in Phase 02.

## Non-Goals

- No public promise about built-in transition names such as `fade` or `slideLeft`.
- No public promise about canvas arguments or low-level render callback shape.

## Acceptance Checks

- A second navigation request during transition resolves to the final incoming scene without leaving intermediate lifecycle residue.
- Transition state is absent outside the transitioning state.
- Internal transition helpers can change later without forcing a public API break.
