# Task 06: Retrofit Existing Controls For Motion And Graphics

## Goal

Refactor previously implemented controls and render paths so they comply with the current graphics and motion specs without widening the published public API.

## Spec Anchors

- `docs/spec/ui-controls-spec.md §6.2 Button`
- `docs/spec/ui-controls-spec.md §6.7 Slider`
- `docs/spec/ui-controls-spec.md §6.8 ProgressBar`
- `docs/spec/ui-controls-spec.md §6.13 Modal`
- `docs/spec/ui-controls-spec.md §6.14 Alert`
- `docs/spec/ui-controls-spec.md §6.17 Tabs`
- `docs/spec/ui-controls-spec.md §8.2 Control Visual Surfaces`
- `docs/spec/ui-foundation-spec.md §8.10 Graphics Asset Interoperability Contract`
- `docs/spec/ui-motion-spec.md §4C Motion Property Model`
- `docs/spec/ui-motion-spec.md §4I Family Adoption Matrix`

## Scope

- Retrofit `Button` part rendering and motion-capable visual surfaces
- Retrofit `Slider` and `ProgressBar` to the current motion-aware surface
- Retrofit `Modal`, `Alert`, and `Tabs` to the published motion surface
- Normalize any graphics-backed rendering to the published `Texture` / `Sprite` / shader-capable-surface language where applicable
- Remove any remaining ad hoc or superseded control-local animation props

## Implementation Guidance

- Read the current implementations first and patch them in place. This task is a retrofit, not a rewrite of working controls into a new architecture.
- Preserve the existing `lib/cls` inheritance tree and constructor signatures unless the spec now requires a surface change.
- Reuse `lib/ui/utils/schema.lua` and existing `_allowed_public_keys` / merged-schema patterns when replacing legacy animation props with `motionPreset` and `motion`.
- When graphics-backed rendering is introduced or normalized, route it through the graphics objects from Task 01 instead of control-local texture conventions.
- Keep new helper code internal and narrowly scoped. Avoid adding public utility methods on controls just to simplify the retrofit implementation.
- Validate every changed control against both its original behavioral contract and the new graphics/motion requirements so regressions in focus, controlled state, or overlay ownership are caught immediately.

## Required Behavior

- `Button` remains skinnable through the stable part surface and may participate in documented motion on those surfaces.
- `ProgressBar` supports motion phases `value` and `indeterminate` through the shared motion contract.
- `Modal` and `Alert` support `motionPreset` / `motion` through their documented `backdrop` and `surface` parts.
- `Tabs` supports value-related motion through its documented `indicator` and `panel` surfaces.
- Shader-driven motion, when present, is limited to documented shader-capable surfaces and documented motion properties.
- Existing behavior remains controlled by the latest published spec rather than by earlier task-phase wording.

## Settled Boundaries

- Do not invent a built-in animation engine or preset catalog as public API in this task.
- Do not allow motion to mutate focus ownership, registration, or structural validity.
- Keep any graphics or motion helper-module shapes internal unless the spec explicitly stabilizes them.

## Non-Goals

- No new control families beyond those already covered by this phase.
- No undocumented whole-tree animation API.
- No public shader-uniform free-for-all outside documented motion properties.

## Acceptance Checks

- Previously implemented controls continue to satisfy their original behavioral contracts after the retrofit.
- Shared motion props replace any superseded control-local animation surfaces.
- Graphics-backed and shader-capable render paths respect the current graphics and motion boundaries.
- The retrofit does not widen the public API beyond the published specs.
- Retrofitted modules continue to follow the current class/schema conventions already present in `lib/ui`.
