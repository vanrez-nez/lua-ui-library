# Phase 04 Task Set

Source implementation document used for this phase: `docs/implementation/phase-04-events.md`.

Normalization rules for this phase:

- Treat `docs/spec/ui-foundation-spec.md` as normative for event propagation, input translation, focus, and interaction state.
- Do not freeze a listener API surface or hover-state surface as stable public API unless the spec explicitly does so.
- Keep stage-level dispatch, propagation, and target resolution spec-shaped, even where the implementation needs internal helper structures.
- When the spec leaves a timing or helper-surface choice open, keep the choice internal rather than promoting it to contract surface.

Key corrections applied to the original phase document:

- Pointer activation must resolve to a single activation gesture per user action, not a double-fired press/release pair.
- Hit testing must respect effective visibility, clipping, and enabled participation, not only local flags.
- `hovered` and pointer-enter/leave notifications should be treated as internal interaction-state plumbing unless a later spec revision stabilizes them.
- The `test/phase4` harness must not depend on a future Phase 5 focus API.
- Listener method names and registration semantics are implementation details here, not a spec-promoted public API.

Unresolved spec gap carried into this phase:

- The spec defines propagation and event object contracts, but it does not name a concrete listener-registration method surface. Phase 4 can implement one, but it should remain provisional unless later documented in the spec.

Task order:

1. `00-compliance-review.md`
2. `01-event-object-and-stage-dispatch.md`
3. `02-target-resolution-and-propagation.md`
4. `03-hover-tracking-and-interaction-state.md`
5. `04-listener-surface-and-error-semantics.md`
6. `05-demo-and-acceptance.md`
