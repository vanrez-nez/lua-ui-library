# Phase 06 Task Set

Primary authority for this task set: `docs/spec/ui-foundation-spec.md` and, where `TextArea` integration is relevant, `docs/spec/ui-controls-spec.md`.

Parent planning context: `docs/implementation/phase-06-scroll.md`.
Use the parent phase document as historical implementation draft only. When it conflicts with `docs/spec`, the spec wins.

Normalization rules for this phase:

- Treat `docs/spec/ui-foundation-spec.md` as normative for `ScrollableContainer`.
- Treat the `ScrollableContainer` trace notes as settled clarifications of the public contract, not as open gaps.
- Keep the public surface limited to the spec-backed props and anatomy: `scrollXEnabled`, `scrollYEnabled`, `momentum`, `momentumDecay`, `overscroll`, `scrollStep`, `showScrollbars`, and the required `root` / `viewport` / `content` / `scrollbars` roles.
- Do not freeze consumer attachment helper names, exact momentum curves, scrollbar geometry, key-mapping tables, or other internal mechanics unless the spec explicitly does so.
- The scroll container must remain spec-shaped for later `TextArea` integration, but that integration should not leak new public scroll APIs into the foundation contract.

Key corrections applied to the original phase document:

- `addContent` and `getContentContainer` are not stabilized as public APIs by the spec.
- `ui.navigate`-based scroll translation is not a spec-backed public contract.
- Exact overscroll damping, inertial thresholds, and velocity-buffer details are implementation choices, not public contract.
- Scrollbars are an optional `scrollbars` role whose geometry, hit regions, and drag policy remain internal unless separately standardized; the task set must not freeze the older draft's non-interactive-only assumption.
- `ScrollableContainer` must still obey the spec’s requirement to support touch, wheel, keyboard, and programmatic scrolling, and to remain valid when empty or when both axes are disabled.
- The required `content` subtree is settled public structure, while the consumer-facing mechanics used to populate it remain intentionally unspecified at the foundation level.

Task order:

1. `00-compliance-review.md`
2. `01-scrollable-container-surface-and-roles.md`
3. `02-content-extent-and-offset-state.md`
4. `03-input-routing-and-nested-consumption.md`
5. `04-clipping-and-scrollbar-visuals.md`
6. `05-textarea-integration-boundary.md`
7. `06-demo-and-acceptance.md`
