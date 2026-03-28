# Phase 05 Task Set

Source implementation document used for this phase: `docs/implementation/phase-05-focus.md`.

Normalization rules for this phase:

- Treat `docs/spec/ui-foundation-spec.md` as normative for focus ownership, traversal, focus restoration, and `ui.focus.change`.
- Do not stabilize new generic `Container` props just because the phase doc uses them as implementation hooks.
- Keep traversal, restoration, and trap bookkeeping internal unless the spec explicitly names a public surface.
- When the spec is underspecified, capture the gap explicitly and avoid turning one implementation choice into stable API.

Key corrections applied to the original phase document:

- `focusScope`, `trapFocus`, and `pointerFocusCoupling` are not stabilized as generic `Container` props in the foundation spec.
- `requestFocus(node)` is an implementation boundary, not a spec-stabilized public imperative API.
- Focus trapping is spec-backed for overlays, but the generic activation mechanics used to support it should remain internal until a component contract names them.
- The `focused` indicator should be treated as derived state tied to focus ownership, not as durable node-local public state.

Unresolved spec gap carried into this phase:

- The spec stabilizes focus behavior but does not define a generic public property schema for focus scopes or pointer-focus coupling on `Container`. Phase 5 should implement the runtime model without freezing those hooks as stable foundation props.

Task order:

1. `00-compliance-review.md`
2. `01-focus-state-and-scope-contract.md`
3. `02-focus-traversal-and-acquisition.md`
4. `03-focus-trapping-and-restoration.md`
5. `04-focused-indicator-and-cleanup.md`
6. `05-demo-and-acceptance.md`
