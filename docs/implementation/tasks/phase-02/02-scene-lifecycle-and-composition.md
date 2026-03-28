# Task 02: Scene Lifecycle And Composition

## Goal

Implement `Scene` as the spec-defined, Composer-managed runtime boundary.

## Spec Anchors

- `docs/spec/ui-foundation-spec.md §6.4.2 Scene`
- `docs/spec/ui-foundation-spec.md §3A.6 Lifecycle Model`
- `docs/spec/ui-foundation-spec.md §3B.2 Composition Validity Rules`

## Scope

- Implement `lib/ui/scene/scene.lua`
- Scene construction
- Scene root and optional content region
- Creation, enter, leave, and destruction hook support
- Active versus inactive runtime participation

## Required Behavior

- A `Scene` owns a full-screen or stage-sized subtree by default.
- A `Scene` exposes creation, enter-before, enter-after, leave-before, leave-after, and destruction hooks.
- A `Scene` integrates with `Composer` and must not manage other scenes directly.
- A `Scene` receives active-scene logical input routed through the `Stage`/`Composer` runtime boundary into its subtree.
- Detached scene instances may exist during creation and registration flow, but they are not standalone valid runtime content outside `Composer` management.
- Inactive scenes receive no input events.

## Settled Spec Clarifications

- No public in-transition `"running"` enter or leave phase is part of the `Scene` contract.
- Activation and deactivation remain `Composer`-owned; scene-local visibility helpers, if they exist, stay internal.
- `Scene` does not create a second raw-input boundary beneath `Stage`.

## Non-Goals

- No scene-managed navigation.
- No overlay ownership in `Scene` itself.
- No separate public visibility contract beyond active/inactive `Composer` management.

## Acceptance Checks

- Activation fires enter-before then enter-after in the correct `Composer`-managed sequence.
- Deactivation fires leave-before then leave-after in the correct `Composer`-managed sequence.
- A `Scene` with no content remains valid and renders nothing.
- Hook errors are surfaced to `Composer` handling and do not leave activation state indeterminate.
