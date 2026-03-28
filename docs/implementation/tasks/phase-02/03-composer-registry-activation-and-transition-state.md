# Task 03: Composer Registry, Activation, And Transition State

## Goal

Implement `Composer` as the authoritative owner of scene registration, activation, caching, and transition state.

## Spec Anchors

- `docs/spec/ui-foundation-spec.md §6.4.3 Composer`
- `docs/spec/ui-foundation-spec.md §3C.4 State Flow Within Composition`
- `docs/spec/ui-foundation-spec.md §3C.5 Consistency Guarantees`
- `docs/spec/ui-foundation-spec.md §3E.4 Transition Interruption`

## Scope

- Implement `lib/ui/scene/composer.lua`
- Scene registry by stable name
- Active scene tracking
- Transition-state ownership
- Scene caching policy
- Navigation entry point

## Required Behavior

- Composer owns one Stage and must not share stage ownership.
- Composer registers scenes by stable name and activates one scene at a time in the base scene layer.
- `gotoScene(target)` follows the Composer state machine from the foundation spec.
- When transition is disabled, navigation commits immediately with the documented enter-before/leave-before and enter-after/leave-after boundaries.
- When transition is enabled, transition state is initialized and later cleared only through the documented transition flow.

## Missing Detail Normalization

- Cache policy may exist, but exact cache eviction and persistence behavior are internal unless separately documented.
- Registration method names may exist in implementation, but the task should avoid freezing additional public API beyond the spec-backed navigation and registration concepts.
- Overlay management should remain scoped to Composer ownership of the overlay layer, not to a prematurely stabilized overlay-scene API.

## Non-Goals

- No modal or alert behavior yet.
- No control-layer focus trapping yet.
- No public transition catalog API commitment.

## Acceptance Checks

- Unknown scene names hard-fail deterministically.
- `gotoScene` to the currently active scene still performs full navigation lifecycle work.
- Navigating before any scene is active does not fire outgoing leave hooks.
- Composer never leaves more than one active base scene committed at stable state boundaries.
