# Task 07: Phase 10 Demo And Acceptance

## Goal

Build the verification surface for graphics objects, motion integration, the newly implemented controls, and the retrofit work required by the current spec set.

## Spec Anchors

- `docs/spec/ui-controls-spec.md`
- `docs/spec/ui-graphics-spec.md`
- `docs/spec/ui-motion-spec.md`
- `docs/spec/ui-foundation-spec.md §3G Failure Semantics`
- `docs/spec/ui-foundation-spec.md §7.1.4 Anchored overlay placement`

## Scope

- Create or revise `test/phase10/`
- Graphics-object and `Image` verification
- Motion integration verification through documented motion surfaces only
- `Radio` / `RadioGroup`
- `Select` / `Option`
- `Notification`
- `Tooltip`
- Retrofit coverage for `Button`, `ProgressBar`, `Modal`, `Alert`, and `Tabs`
- Automated regression checks where practical

## Concrete Deliverables

- Add or update manual harness modules under `test/phase10/` with one screen per task family.
- Add focused automated specs for the new graphics objects, new controls, and retrofit behavior instead of relying only on one end-to-end harness.
- Keep any harness-only fixtures, fake adapters, or diagnostic helpers under `test/phase10/` or another clearly test-only location so they are not mistaken for public runtime API.

## Implementation Guidance

- Build test fixtures against the real public constructors and documented props, not against private registration helpers or direct mutation of internal state.
- Where test-only helper objects are needed, they should still follow the current `lib/cls` and shared utility conventions closely enough to exercise production behavior realistically.
- Reuse the shared assert/schema utilities in any test-side fake objects that need to validate inputs, especially for motion adapter and graphics-object edge cases.
- Prefer direct verification of published behavior: selected values, open state, placement fallback, clipped-region warnings, and overlay/focus effects. Do not couple tests to internal helper names or data structure layouts.
- Motion tests should verify the adapter boundary and target/property restrictions without locking the suite to one specific built-in timeline model.

## Screen Normalization

- Graphics screens must demonstrate full-texture and region-backed rendering without implying a public asset-loader contract.
- Motion screens must demonstrate motion through `motionPreset` / `motion` and documented phases, not through private helper APIs or framework-specific driver wiring.
- Control screens must validate published props, structure, and state behavior rather than constructor-centered shortcuts.
- Shader-driven motion, if demonstrated, must use documented shader-capable surfaces and documented motion properties only.
- Manual harness helpers may exist, but they remain test-only and must not be described as library API.

## Required Demo Screens

### Screen 1: Graphics Objects

- Demonstrate `Texture`, `Atlas`, `Sprite`, and `Image` as distinct first-class surfaces.
- Show a full-image render, a region-backed render, and a clipped out-of-bounds region request with warning visibility in the harness.
- Display intrinsic dimensions so region-relative behavior is inspectable.

### Screen 2: Radio Group

- Include at least three radios with one disabled option.
- Show roving focus, activation-driven selection, and the no-wrap-at-ends rule.
- Make the current group value and focused radio visible in the harness.

### Screen 3: Select

- Include both single-select and multi-select examples.
- Demonstrate placeholder rendering, summary rendering, popup open/close, and disabled options.
- Show modal and non-modal popup variants without presenting a public popup manager API.

### Screen 4: Notification And Tooltip

- Demonstrate notification stacking, explicit dismissal, and auto-dismiss timing.
- Demonstrate tooltip hover/focus/manual visibility and fallback placement near viewport edges.
- Show the current resolved placement and open state for inspection.

### Screen 5: Motion And Retrofits

- Demonstrate motion on at least:
  `ProgressBar.indicator`,
  `Tabs.indicator` or `Tabs.panel`,
  one overlay surface such as `Modal.surface` or `Alert.surface`,
  and one graphics-backed or shader-capable control surface such as `Button.border`.
- The screen must make the motion phase and current target surface visible in the harness log.

## Automated Verification Boundary

- Add or extend unit specs for:
  graphics-object validity and region behavior,
  radio-group registration and selection repair,
  select single/multiple value behavior,
  notification dismissal and stack behavior,
  tooltip fallback placement resolution,
  motion-surface targeting and interruption behavior where unit-testable.
- Coverage should remain centered on published behavior, not on internal helper-module shapes.

## Hard-Failure Demonstrations

- Demonstrate duplicate radio values as deterministic invalid configuration.
- Demonstrate duplicate select option values as deterministic invalid configuration.
- Demonstrate invalid motion-target or motion-property usage through guarded execution when practical so the harness remains usable afterward.
- Demonstrate non-positive graphics source-region size as deterministic failure.

## Acceptance Checks

- Graphics objects and `Image` match the current graphics spec surface.
- Motion integration works through the shared motion contract without implying a built-in animation engine API.
- The newly implemented controls match their published structure, props, and behavior.
- Previously implemented controls remain compliant after graphics and motion retrofits.
- The harness can demonstrate failure paths without leaving the app unusable afterward when guarded execution is appropriate.
- The verification surface is executable with the current codebase structure and does not depend on undocumented helper APIs.
