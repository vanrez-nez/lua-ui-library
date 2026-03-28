# Phase 05 Compliance Review

Source under review: `docs/implementation/phase-05-focus.md`

Primary findings, ordered by severity:

1. Phase 5 stabilizes generic focus-related `Container` props that the spec does not define.
   Source: `phase-05-focus.md:27-33`, `phase-05-focus.md:128-132`
   Spec anchors: `ui-foundation-spec.md §6.1.1 Props and API surface`, `ui-foundation-spec.md §7.2 Focus`, `ui-foundation-spec.md §7.2.5 Focus and overlays`
   Problems:
   - `focusScope = true` is presented as a generic `Container` property, but the spec only says Stage defines the root focus scope and some component/runtime primitives may define nested scopes
   - `trapFocus = true` is presented as a generic `Container` property, but the spec only stabilizes trap behavior in the context of overlays
   - `pointerFocusCoupling` is introduced as a new `Container` property, while the spec says coupling must be defined by the component contract
   Required normalization: keep focus-scope, trap, and pointer-coupling mechanics internal or component-specific; do not freeze them as generic foundation props in Phase 5.

2. The phase doc overcommits a public imperative focus API.
   Source: `phase-05-focus.md:70-76`
   Spec anchors: `ui-foundation-spec.md §7.2 Focus`, `ui-foundation-spec.md §3F.2 API Surface Classification`
   Problem: the spec requires explicit focus request support, but it does not stabilize a `stage:requestFocus(node)` public method. Imperative handles are explicitly not a standardized public surface in this revision.
   Required normalization: implement the runtime boundary internally, but avoid presenting a new stable imperative method as part of the public API unless the spec later names it.

3. The focus-trap model is broader than the spec and tied to a generic container abstraction.
   Source: `phase-05-focus.md:91-107`
   Spec anchors: `ui-foundation-spec.md §7.2.1 Focus scopes`, `ui-foundation-spec.md §7.2.5 Focus and overlays`, `ui-foundation-spec.md §6.4.2 Scene`
   Problems:
   - the phase doc activates traps on any `Container` with `trapFocus = true` and `focusScope = true`
   - the spec only names overlay focus trapping and names `Modal` and `Alert` as nested focus-scope examples
   - the phase doc adds Stage behavior for swallowing `ui.navigate` and pointer activation outside the trap, which is a detailed runtime policy not stabilized as a generic container contract
   Required normalization: keep the focus-trap implementation ready for overlays, but do not stabilize generic container-level trap behavior as public foundation API.

4. The `focused` indicator is treated as a mutable draw-time field on nodes rather than as derived focus ownership state.
   Source: `phase-05-focus.md:17-24`, `phase-05-focus.md:122-124`
   Spec anchors: `ui-foundation-spec.md §3C.6 Derived State`, `ui-foundation-spec.md §7.2 Focus`
   Problem: the phase doc describes Stage setting `focused = true` on the node before draw and resetting it after. The spec only stabilizes effective focus ownership as derived state; it does not stabilize a node-local mutable `focused` property surface.
   Required normalization: keep `focused` as derived rendering state or internal draw context, not as a durable node property surface.

Secondary scoping notes:

- The sequential and directional traversal algorithms are broadly aligned with the spec, but their exact implementation should remain internal where the spec does not define a strict helper surface.
- The test harness can demonstrate focus-change logging, but it should not imply a public `requestFocus` API if that method is kept internal.
