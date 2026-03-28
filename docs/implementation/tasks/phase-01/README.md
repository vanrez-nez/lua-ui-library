# Phase 01 Task Set

This task set normalizes Phase 1 against the authoritative spec set in `docs/spec`.

Normalization rules for this phase:

- Treat `docs/spec/ui-foundation-spec.md` as normative for all public component and runtime surfaces.
- Do not narrow a stable spec surface just because a later phase deepens its implementation.
- Do not add new public props or defaults unless the spec names them.
- Keep later-phase systems out of scope unless Phase 1 needs a stable placeholder surface to stay spec-shaped.

Key corrections applied to the original phase document:

- `Container.width` and `Container.height` remain the full spec surface, not a Phase-1-only numeric API.
- `focusScope` and `trapFocus` are not introduced as public `Container` props in Phase 1.
- `visible = false` is not treated as a blanket escape from retained-tree consistency work during update traversal.
- Disabled targeting and clipping behavior are aligned to the foundation spec rather than the earlier draft wording.
- `Stage` must expose viewport bounds, safe-area insets, safe-area bounds, and a root input entry point, even before full event propagation ships.

Task order:

1. `00-compliance-review.md`
2. `01-core-math-and-geometry.md`
3. `02-container-tree-and-surface.md`
4. `03-container-transform-and-dirty-state.md`
5. `04-container-order-clipping-hit-testing.md`
6. `05-drawable-content-box-and-visual-surface.md`
7. `06-stage-root-and-two-pass-traversal.md`
8. `07-phase-01-demo-and-acceptance.md`
