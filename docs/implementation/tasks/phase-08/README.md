# Phase 08 Task Set

Source implementation document used for this phase: `docs/implementation/phase-08-theming.md`.

Authority rules for this phase:

- Treat `docs/spec/ui-foundation-spec.md` and `docs/spec/ui-controls-spec.md` as authoritative over the older phase implementation draft wherever they differ.
- Use `docs/implementation/phase-08-theming.md` only as historical implementation intent and task-sequencing context.
- Keep render helpers such as nine-slice and canvas pooling internal unless the spec stabilizes them as public API.
- Do not invent new public token families or visual-role taxonomies when the spec does not define them.
- Preserve the stable token naming schema and the documented part/property bindings only.

Settled spec clarifications that control this task set:

- The spec defines 13 token classes, not 12.
- `Text` theming is rooted in the single stable `content` part, and `textVariant` is the spec-backed way to vary presentation without stabilizing semantic role names such as `heading`, `body`, or `caption`.
- Focus styling must be rendered through documented parts and stateful variants, not through a new undocumented focus-indicator token family.
- Documented slots and regions are public structure, but they do not imply stable builder or helper APIs unless a control section names one explicitly.
- Canvas isolation and nine-slice mechanics are implementation details that must respect the spec, but their helper-module shapes are not public API.
- Library default-token coverage may be broad internally, but only documented component-part-property bindings and documented fallback inputs are stable public contract.

Task order:

1. `00-compliance-review.md`
2. `01-theme-token-model-and-surface.md`
3. `02-control-part-skins-and-state-variants.md`
4. `03-nineslice-and-canvas-isolation-internals.md`
5. `04-default-token-table-and-acceptance.md`
