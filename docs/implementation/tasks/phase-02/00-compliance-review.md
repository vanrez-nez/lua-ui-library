# Phase 02 Compliance Review

Source under review: `docs/implementation/phase-02-runtime.md`

Primary findings, ordered by severity:

1. `Scene` lifecycle is over-specified beyond the foundation spec.
   Source: `phase-02-runtime.md:55-66`
   Spec anchor: `ui-foundation-spec.md §6.4.2 Scene`
   Problem: the phase doc introduces `onEnter("running")` and `onLeave("running")` as public lifecycle phases. The spec stabilizes creation, enter-before, enter-after, leave-before, leave-after, and destruction hooks, but not a public running-phase hook.
   Required normalization: do not introduce a public running-phase lifecycle API. If transition-progress callbacks are needed internally, keep them internal to Composer transition execution.

2. `Scene` public surface is expanded with `show()` and `hide()` semantics that are not rooted in the spec.
   Source: `phase-02-runtime.md:68-71`
   Spec anchors: `ui-foundation-spec.md §6.4.2 Scene`, `ui-foundation-spec.md §3B.2 Composition Validity Rules`
   Problem: the spec defines Scene activation and deactivation through `Composer`, not through scene-local visibility APIs. It also marks detached scenes invalid outside Composer management.
   Required normalization: keep activation/deactivation under Composer ownership. Scene visibility may be an internal runtime effect of active/inactive state, but it should not become the primary public contract.

3. `Stage.deliverInput` as a no-op conflicts with the phase claim of runtime compliance.
   Source: `phase-02-runtime.md:37-38`
   Spec anchor: `ui-foundation-spec.md §6.4.1 Stage`
   Problem: `Stage` must provide the root input delivery entry point and translate delivered raw input into logical intents before dispatch. A placeholder surface is acceptable in an earlier phase, but a documented no-op is not compliant with the full Stage contract.
   Required normalization: either limit the phase claim to partial runtime compliance, or implement an actual root input path boundary with deterministic forwarding behavior that later event phases deepen.

4. Transition and lifecycle sequencing are partially off-spec.
   Source: `phase-02-runtime.md:94-103`
   Spec anchors: `ui-foundation-spec.md §6.4.3 Composer`, `ui-foundation-spec.md §3E.4 Transition Interruption`
   Problems:
   - the draft inserts `running` lifecycle phases that the spec does not name
   - interruption handling says the interrupted outgoing scene gets `onLeave("after")` immediately, but the spec's stronger rule is that interrupted navigation must complete the leave lifecycle for the outgoing scene and the enter lifecycle for the final incoming scene, with no intermediate scene executing enter or leave hooks
   Required normalization: implement interruption exactly from the Composer state machine and behavioral edge cases, without inventing additional public lifecycle phases.

5. `lib/ui/scene/transitions.lua` is under-labeled as public surface.
   Source: `phase-02-runtime.md:111-126`
   Spec anchor: `ui-foundation-spec.md §3F.2 API Surface Classification`
   Problem: the spec requires transition support, but it does not stabilize built-in transition names, transition table shapes, canvas arguments, or a `transitions.lua` module API.
   Required normalization: built-in transitions and render-composition helpers may exist, but they must be explicitly treated as internal implementation detail unless later promoted into the documented API surface.

Secondary scoping notes:

- Scene caching is consistent with the Composer responsibility boundary, but the cache policy details are not public API unless documented separately.
- Overlay support belongs to Composer and Stage ownership, but `showOverlay(name, options)` / `hideOverlay(name)` should be scoped as internal or deferred unless a spec-backed overlay API is written.
