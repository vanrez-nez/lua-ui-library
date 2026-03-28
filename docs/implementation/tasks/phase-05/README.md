# Phase 05 Task Set

Authoritative sources for this phase:

- `docs/spec/ui-foundation-spec.md`
- `docs/implementation/phase-05-focus.md`

Authority rule:

- Treat `docs/spec/ui-foundation-spec.md` as authoritative whenever it is more specific than or narrower than `docs/implementation/phase-05-focus.md`.
- Use `docs/implementation/phase-05-focus.md` as implementation planning context, not as a source of new public API.

Consolidation rules for this phase:

- Treat `docs/spec/ui-foundation-spec.md` as normative for focus ownership, traversal, focus restoration, and `ui.focus.change`.
- Preserve behavioral commitments that the spec now settles, especially the boundaries clarified by the Phase 05 trace notes.
- Do not stabilize new generic `Container` props or imperative handles just because the phase plan uses them as implementation hooks.
- Keep runtime bookkeeping, helper APIs, and internal metadata internal unless a component or runtime contract explicitly names them.

Settled normalization points carried through the task set:

- Nested focus scopes are standardized behavior, but the generic marker schema is intentionally not standardized at the foundation level.
- Explicit focus request support is standardized behavior, but no public `Stage` method name is standardized in this revision.
- Overlay focus trapping and restoration are standardized behavior, but a generic `Container` trap contract is not.
- Pointer-focus coupling is standardized as component behavior, not as a generic foundation prop.
- Any transient `focused` render flag remains internal derived state unless a later component contract exposes it.

Trace note consolidations reflected here:

- The scope-marker boundary in `§7.2.1` prevents Phase 05 from treating `focusScope` as a generic foundation prop.
- The explicit-request boundary in `§3D.4` prevents Phase 05 from documenting `requestFocus(...)` as stable public API.
- The overlay-trapping boundary in `§7.2.5` prevents Phase 05 from generalizing `trapFocus` into a generic foundation contract.
- The coupling-surface boundary in `§7.2.6` prevents Phase 05 from treating `pointerFocusCoupling` as a generic `Container` prop.
- The derived-state clarification in `§3C.6` keeps `focused` in the internal rendering layer rather than the public node state surface.

Task order:

1. `00-compliance-review.md`
2. `01-focus-state-and-scope-contract.md`
3. `02-focus-traversal-and-acquisition.md`
4. `03-focus-trapping-and-restoration.md`
5. `04-focused-indicator-and-cleanup.md`
6. `05-demo-and-acceptance.md`
