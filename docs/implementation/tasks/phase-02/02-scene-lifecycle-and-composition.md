# Task 02: Scene Lifecycle And Composition

## Goal

Implement `Scene` as a Composer-managed runtime boundary without adding extra public lifecycle phases.

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

- A Scene owns a screen-level subtree by default.
- A Scene exposes creation, enter-before, enter-after, leave-before, leave-after, and destruction hooks.
- A Scene is valid only when registered with and managed by Composer in the Stage base scene layer.
- Active scenes receive runtime participation appropriate to the Stage traversal; inactive scenes do not receive input forwarding.

## Missing Detail Normalization

- Do not define `show()` and `hide()` as the primary public activation API.
- Do not expose `"running"` enter/leave phases publicly.
- Detached Scene instances may exist during creation and registration flow, but the task must preserve the spec rule that detached scenes are not standalone valid runtime content.

## Non-Goals

- No scene-managed navigation.
- No overlay ownership in Scene itself.
- No separate public visibility contract beyond active/inactive Composer management.

## Acceptance Checks

- Activation fires enter-before then enter-after in the correct Composer-managed sequence.
- Deactivation fires leave-before then leave-after in the correct Composer-managed sequence.
- A Scene with no content remains valid and renders nothing.
- Hook errors are surfaced to Composer handling rather than leaving partial activation state behind.
