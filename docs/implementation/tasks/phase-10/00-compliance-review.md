# Phase 10 Compliance Review

Source under review: published spec set only

Task-set authority:

- `docs/spec/ui-foundation-spec.md` is authoritative for retained runtime boundaries, visual contracts, render effects, anchored-overlay placement, and failure semantics.
- `docs/spec/ui-controls-spec.md` is authoritative for control identity, structure, props, state, and interaction behavior.
- `docs/spec/ui-graphics-spec.md` is authoritative for `Texture`, `Atlas`, `Sprite`, and `Image`.
- `docs/spec/ui-motion-spec.md` is authoritative for motion surfaces, motion properties, motion descriptors, motion adapters, and easing inputs.

Primary findings, ordered by severity:

1. The current implementation phases do not cover the published graphics-object surface.
   Spec anchors: `ui-graphics-spec.md §4 Scope And Domain`, `ui-graphics-spec.md §4A Graphics Object Classification And Identity`
   Problem: Phase 08 implemented texture-, atlas-, quad-, and nine-slice-aware theming internals, but there is no task set yet for first-class `Texture`, `Atlas`, `Sprite`, or `Image`.
   Required normalization: create explicit tasks for graphics-object construction, validation, region behavior, and retained `Image` rendering.

2. Motion is now a first-class spec domain, but existing tasks still assume control-local animation wording.
   Spec anchors: `ui-motion-spec.md §4 Scope And Domain`, `ui-motion-spec.md §4D Motion Descriptor Contract`, `ui-controls-spec.md §6.15 Notification`, `ui-controls-spec.md §6.16 Tooltip`
   Problem: the current task history predates `ui-motion-spec.md`, and `Notification` was implemented on its older per-control timing/easing surface. The published spec now requires shared `motionPreset` / `motion` semantics for motion-relevant controls.
   Required normalization: add a motion-integration task and a retrofit task for earlier controls that are now motion-aware.

3. Several published controls still have no implementation phase coverage.
   Spec anchors: `ui-controls-spec.md §6.4 Radio`, `ui-controls-spec.md §6.5 RadioGroup`, `ui-controls-spec.md §6.9 Option`, `ui-controls-spec.md §6.10 Select`, `ui-controls-spec.md §6.15 Notification`, `ui-controls-spec.md §6.16 Tooltip`, `ui-controls-spec.md §6.7 Slider`, `ui-controls-spec.md §6.8 ProgressBar`
   Problem: these controls were added to the spec after the earlier control phases and have no dedicated task set.
   Required normalization: add explicit implementation tasks for the unimplemented controls and include any related registration, popup, overlay, and motion behavior needed by their contracts.

4. Graphics and motion revisions create mandatory retrofit work for controls that were already implemented.
   Spec anchors: `ui-controls-spec.md §6.13 Modal`, `ui-controls-spec.md §6.14 Alert`, `ui-controls-spec.md §6.17 Tabs`, `ui-controls-spec.md §8.2 Control Visual Surfaces`, `ui-motion-spec.md §4I Family Adoption Matrix`
   Problem: previously implemented controls now participate in the published motion surface or in graphics-backed rendering scenarios that were not part of their original task phases.
   Required normalization: include a retrofit task for `Button`, `Modal`, `Alert`, `Tabs`, and any other earlier controls whose visual or motion contract changed.

5. Demo and acceptance coverage needs a broader scope than earlier phases.
   Spec anchors: `ui-graphics-spec.md`, `ui-motion-spec.md`, `ui-controls-spec.md`
   Problem: there is no existing harness that demonstrates graphics objects, image region rendering, popup/overlay motion integration, radio/select interaction, and the new control retrofits together.
   Required normalization: add a phase-level manual harness and regression scope that proves the spec-backed surfaces without turning test helpers into public API.

Secondary scoping notes:

- Motion adapters may be internal for this phase, but the implementation must preserve the external-adapter boundary required by the motion spec.
- Shader-driven motion may be demonstrated in tests or harnesses, but only through documented motion properties on documented visual surfaces.
- The graphics-object phase should not invent a public asset loader or a public animation player; those remain out of scope.

Implementation normalization for the whole phase:

- All new spec-owned objects should use the existing `lib/cls` inheritance model and follow the constructor/new helper pattern already used across `lib/ui`.
- Prop validation and default extraction should reuse `lib/ui/utils/schema.lua` plus the shared assert/type helpers, not handwritten parallel validation systems.
- New controls and retained primitives should extend the nearest existing base (`Container`, `Drawable`, or another control) and should add public props through merged schema tables or `_allowed_public_keys` in the same style as `Modal` and `Alert`.
- The phase deliverables should name concrete module targets and helper boundaries so an implementer can build directly against the current codebase layout instead of inferring architecture from the specs alone.
