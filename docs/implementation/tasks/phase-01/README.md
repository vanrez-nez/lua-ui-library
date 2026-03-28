# Phase 01 Task Set

This task set consolidates Phase 01 against the authoritative spec set in `docs/spec`.

`docs/spec/ui-foundation-spec.md` is the source of truth for public behavior and surface area. `docs/implementation/phase-01-foundation.md` is retained as planning context only; where the draft and the spec differ, the spec wins.

Consolidation rules for this phase:

- Treat `docs/spec/ui-foundation-spec.md` as normative for all public component and runtime surfaces.
- Do not narrow a stable spec surface just because a later phase deepens its implementation.
- Do not add new public props or defaults unless the spec names them.
- Keep later-phase systems out of scope unless Phase 1 needs a stable placeholder surface to stay spec-shaped.

Settled spec clarifications carried into this task set:

- `Container.width` and `Container.height` keep the full accepted domain from `§6.1.1`; the `Trace note` there closes the earlier draft ambiguity.
- `focusScope` and `trapFocus` are not introduced as public `Container` props in Phase 1.
- `visible = false` changes rendering and direct-target participation, but does not detach the node from retained-tree geometry or descendant-state resolution while attached.
- Effective targeting is ancestor-aware: visibility, clipping, and enabled participation all constrain direct targets.
- Degenerate clip bounds produce an empty effective clip region, not a no-op clip.
- `Drawable` may derive focused rendering state internally, but that state is not a durable public node property.
- `Stage` must expose viewport bounds, safe-area insets, safe-area bounds, the root input entry point, and the root focus-scope boundary even before later interaction systems are fully implemented.

Task order:

1. `00-compliance-review.md`
2. `01-core-math-and-geometry.md`
3. `02-container-tree-and-surface.md`
4. `03-container-transform-and-dirty-state.md`
5. `04-container-order-clipping-hit-testing.md`
6. `05-drawable-content-box-and-visual-surface.md`
7. `06-stage-root-and-two-pass-traversal.md`
8. `07-phase-01-demo-and-acceptance.md`
