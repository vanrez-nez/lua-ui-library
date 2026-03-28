# Phase 06 Task Set

Source implementation document used for this phase: `docs/implementation/phase-06-scroll.md`.

Normalization rules for this phase:

- Treat `docs/spec/ui-foundation-spec.md` as normative for `ScrollableContainer`.
- Keep the public surface limited to the spec-backed props and anatomy: `scrollXEnabled`, `scrollYEnabled`, `momentum`, `momentumDecay`, `overscroll`, `scrollStep`, `showScrollbars`, and the required `root` / `viewport` / `content` / `scrollbars` roles.
- Do not freeze consumer child APIs, exact momentum curves, scrollbar geometry, or keyboard key mappings unless the spec explicitly does so.
- The scroll container must remain spec-shaped for later `TextArea` integration, but that integration should not leak new public scroll APIs into the foundation contract.

Key corrections applied to the original phase document:

- `addContent` and `getContentContainer` are not stabilized as public APIs by the spec.
- `ui.navigate`-based scroll translation is not a spec-backed public contract.
- Exact overscroll damping, inertial thresholds, and velocity-buffer details are implementation choices, not public contract.
- Scrollbars are optional structural/visual children, but their exact geometry and interaction treatment should stay internal unless separately standardized.
- `ScrollableContainer` must still obey the spec’s requirement to support touch, wheel, keyboard, and programmatic scrolling, and to remain valid when empty or when both axes are disabled.

Unresolved spec gap carried into this phase:

- The foundation spec defines the `ScrollableContainer` anatomy and props, but it does not define a public consumer API for attaching content to the internal `content` subtree. The implementation may need an internal attachment boundary, but that boundary should not be frozen into public API names unless the spec is updated.

Task order:

1. `00-compliance-review.md`
2. `01-scrollable-container-surface-and-roles.md`
3. `02-content-extent-and-offset-state.md`
4. `03-input-routing-and-nested-consumption.md`
5. `04-clipping-and-scrollbar-visuals.md`
6. `05-textarea-integration-boundary.md`
7. `06-demo-and-acceptance.md`
