# Phase 04 Task Set

Authority order for this task set:

1. `docs/spec/ui-foundation-spec.md`
2. `docs/implementation/phase-04-events.md`

Normalization rules for this phase:

- Treat `docs/spec/ui-foundation-spec.md` as normative for event propagation, input translation, focus, and interaction state.
- Do not freeze a listener API surface or hover-state surface as stable public API unless the spec explicitly does so.
- Keep stage-level dispatch, propagation, and target resolution spec-shaped, even where the implementation needs internal helper structures.
- When the spec leaves a timing or helper-surface choice open, keep the choice internal rather than promoting it to contract surface.

Settled consolidation points from the current spec and trace notes:

- Pointer activation must resolve to a single public `ui.activate` dispatch per gesture.
- Hit testing must respect effective visibility, enabled participation, ancestor clipping, and overlay precedence.
- Hover ownership and pointer-entry/exit bookkeeping are explicitly internal derived state in this revision.
- Explicit focus requests are part of the behavioral focus contract, but no specific public helper such as `stage:requestFocus()` is standardized here.
- Listener method names and registration helpers remain internal implementation detail; the spec stabilizes propagation semantics, not one registration API surface.

Task order:

1. `00-compliance-review.md`
2. `01-event-object-and-stage-dispatch.md`
3. `02-target-resolution-and-propagation.md`
4. `03-hover-tracking-and-interaction-state.md`
5. `04-listener-surface-and-error-semantics.md`
6. `05-demo-and-acceptance.md`
