# Phase 02 Compliance Review

Source under review: `docs/implementation/phase-02-runtime.md`

This review records where the parent Phase 02 runtime draft diverges from the now-authoritative contract in `docs/spec/ui-foundation-spec.md`, including the trace-note clarifications now attached to the runtime family sections. These are settled task inputs, not open design gaps.

Primary findings, ordered by severity:

1. `Stage` is still described too narrowly in the parent draft.
   Source: `phase-02-runtime.md:24-43`
   Spec anchors: `ui-foundation-spec.md §6.4.1 Stage`, `ui-foundation-spec.md §7.1 Event Propagation`
   Settled spec direction:
   - `Stage` must expose both `safeAreaInsets` and safe area bounds; an insets-only surface is not compliant.
   - All raw host input enters through `Stage`; Phase 02 can stage downstream routing depth, but it cannot document a second raw-input intake path or a pure no-op root boundary.

2. `Scene` lifecycle is over-expanded beyond the stabilized public surface.
   Source: `phase-02-runtime.md:47-66`
   Spec anchor: `ui-foundation-spec.md §6.4.2 Scene`
   Settled spec direction:
   - Public lifecycle remains limited to creation, enter-before, enter-after, leave-before, leave-after, and destruction.
   - Public in-transition `"running"` phases are out of contract; any progress-time plumbing stays internal to runtime execution.

3. `Scene` activation is still framed too much around scene-local visibility control.
   Source: `phase-02-runtime.md:68-76`
   Spec anchor: `ui-foundation-spec.md §6.4.2 Scene`
   Settled spec direction:
   - Activation and deactivation are owned by `Composer`.
   - Scene-local `show()` / `hide()` helpers may exist internally, but they do not define a parallel public activation API and should not be tasked as such.

4. `Composer` transition sequencing must follow the published state machine exactly.
   Source: `phase-02-runtime.md:91-107`
   Spec anchors: `ui-foundation-spec.md §6.4.3 Composer`, `ui-foundation-spec.md §3E.4 Transition Interruption`
   Settled spec direction:
   - `gotoScene(...)` must follow the stable-state and transitioning-state flow from the spec.
   - Interrupted navigation must commit the current incoming scene as the stable scene, clear transition state, and then process the new request.
   - No intermediate scene may execute enter or leave hooks during the interruption edge case.

5. Transition helpers and overlay helpers are implementation detail unless the spec names them.
   Source: `phase-02-runtime.md:105-126`
   Spec anchor: `ui-foundation-spec.md §6.4.3 Composer`, `ui-foundation-spec.md §3F.2 API Surface Classification`
   Settled spec direction:
   - Built-in transition catalogs, `transitions.lua`, composition callback signatures, and canvas-pool mechanics remain internal.
   - Overlay-layer ownership is part of the runtime contract, but helper methods such as `showOverlay(...)` and `hideOverlay(...)` are not stabilized public API in this revision.

Secondary scoping notes:

- Scene caching remains within the `Composer` responsibility boundary, but cache policy details are still internal unless separately documented.
- The parent runtime plan remains useful for test-harness scenarios and sequencing examples, but Phase 02 task requirements should always defer to `docs/spec` when the two disagree.
