# Phase 05 Compliance Review

Task-set authority:

- Authoritative spec: `docs/spec/ui-foundation-spec.md`
- Planning context: `docs/implementation/phase-05-focus.md`
- This review records the consolidated Phase 05 position after the focus-related trace-note clarifications in the spec.

Consolidated findings:

1. Nested focus scopes are part of the settled behavior contract, but a generic `Container` scope marker is still not public API.
   Implementation reading:
   - Phase 05 should implement Stage-owned active-scope behavior and bounded traversal.
   - If the runtime uses metadata such as `focusScope` internally, that remains an internal encoding choice unless a later component contract exposes it.
   Spec basis:
   - `ui-foundation-spec.md §7.2.1 Focus scopes`
   - `ui-foundation-spec.md §3D.4 Focus Model`

2. Explicit focus request support is settled behavior, but no public imperative method surface is standardized.
   Implementation reading:
   - Phase 05 must support explicit consumer-requested focus movement.
   - Test harnesses or runtime plumbing may call internal helpers, but task docs must not present a public `requestFocus(...)` method as part of the stable API.
   Spec basis:
   - `ui-foundation-spec.md §7.2`
   - `ui-foundation-spec.md §3D.4 Focus Model`
   - `ui-foundation-spec.md §3F.2 API Surface Classification`

3. Focus trapping and restoration are settled for overlays, not as a generic foundation trap contract.
   Implementation reading:
   - Phase 05 should implement the runtime stack and restoration behavior needed for overlay scopes.
   - Generic `Container` trap flags remain internal implementation detail unless a later component or runtime contract documents them.
   Spec basis:
   - `ui-foundation-spec.md §7.2.5 Focus and overlays`
   - `ui-foundation-spec.md §3D.4 Focus Model`

4. Pointer-focus coupling is settled as a component-behavior decision, not as a generic prop schema.
   Implementation reading:
   - Phase 05 should support focus changes on pointer activation where the relevant component contract allows it.
   - Any runtime metadata used to encode timing such as before-action or after-action coupling remains internal unless documented by a component contract.
   Spec basis:
   - `ui-foundation-spec.md §7.2.2 Focus acquisition rules`
   - `ui-foundation-spec.md §7.2.6 Pointer and focus coupling`

5. Focused rendering remains derived state, not durable public node state.
   Implementation reading:
   - Phase 05 may render a default visible focus indicator.
   - Any transient `focused` flag or equivalent render hint must remain internal derived state tied to current focus ownership.
   Spec basis:
   - `ui-foundation-spec.md §3C.6 Derived State`
   - `ui-foundation-spec.md §7.2 Focus`

Residual implementation guidance:

- The parent phase plan remains useful for algorithms, bookkeeping, and demo coverage where it does not widen the public contract.
- The task docs in this directory should treat phase-plan prop names such as `focusScope`, `trapFocus`, and `pointerFocusCoupling` as implementation vocabulary only, not as settled foundation API.
