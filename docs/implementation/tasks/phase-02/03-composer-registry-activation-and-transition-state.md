# Task 03: Composer Registry, Activation, And Transition State

## Goal

Implement `Composer` as the authoritative owner of scene registration, activation, caching, transition state, and runtime routing into the active subtree.

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

- `Composer` owns one `Stage` and must not share stage ownership.
- `Composer` registers scenes by stable name and activates one scene at a time in the base scene layer.
- `Composer` owns the active overlay layer above the base scene layer, while keeping overlay helper mechanics internal unless separately documented.
- `gotoScene(target)` follows the `Composer` state machine from the foundation spec.
- When transition is disabled, navigation commits immediately with the documented lifecycle boundaries.
- When transition is enabled, transition state is initialized, advanced, and cleared only through the documented transition flow.
- `Composer` forwards root input into the active runtime subtree without creating a second raw-input intake boundary.

## Settled Spec Clarifications

- Cache policy may exist, but exact cache eviction and persistence rules remain internal unless separately documented.
- `gotoScene` to the currently active scene is still a full navigation request, not a no-op.
- When no scene has been activated yet, navigation fires no outgoing leave hooks.
- Overlay ownership is required runtime behavior, but helper names such as `showOverlay(...)` or `hideOverlay(...)` are not stabilized public API in this revision.

## Non-Goals

- No modal or alert behavior yet.
- No control-layer focus trapping yet.
- No public transition catalog API commitment.

## Acceptance Checks

- Unknown scene names hard-fail deterministically.
- `gotoScene` to the currently active scene still performs full navigation lifecycle work.
- Navigating before any scene is active does not fire outgoing leave hooks.
- `Composer` never leaves more than one active base scene committed at stable state boundaries.
