# Phase 08 Task Set

Source implementation document used for this phase: `docs/implementation/phase-08-theming.md`.

Normalization rules for this phase:

- Treat `docs/spec/ui-foundation-spec.md` and `docs/spec/ui-controls-spec.md` as normative for visual surfaces, token naming, render-skin behavior, and stateful variant resolution.
- Keep render helpers such as nine-slice and canvas pooling internal unless the spec stabilizes them as public API.
- Do not invent new public token families or visual-role taxonomies when the spec does not define them.
- Preserve the stable token naming schema and the documented part/property bindings only.

Key corrections applied to the original phase document:

- The spec defines 13 token classes, not 12.
- `Text` does not gain new stable content roles such as body, heading, or caption in this revision.
- Focus styling must be rooted in documented visual surfaces and stable token bindings, not a new undocumented token family.
- Canvas isolation and nine-slice mechanics are implementation details that must respect the spec, but their helper-module shapes are not public API.
- Default token coverage should only stabilize bindings that are actually documented by the component specs.

Task order:

1. `00-compliance-review.md`
2. `01-theme-token-model-and-surface.md`
3. `02-control-part-skins-and-state-variants.md`
4. `03-nineslice-and-canvas-isolation-internals.md`
5. `04-default-token-table-and-acceptance.md`
