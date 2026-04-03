# Phase 03 Task Set

Authoritative sources for this task set:

- `docs/spec/ui-layout-spec.md`
- `docs/spec/ui-foundation-spec.md`

Implementation-plan input for this phase: `docs/implementation/phase-03-layout.md`.

Note: `docs/implementation/phase-03-foundation.md` does not exist in the repo. This task set reconciles the existing Phase 3 layout plan against the current foundation spec rather than treating the older implementation draft as normative.

Normalization rules for this phase:

- Treat `docs/spec/ui-layout-spec.md` as normative for layout families, spacing,
  and layout state.
- Treat `docs/spec/ui-foundation-spec.md` as normative for responsive rules,
  retained-tree ownership, and Stage/runtime behavior.
- Do not freeze a public measurement or breakpoint schema where the spec does not define one.
- Keep implementation-specific layout algorithms internal unless the spec clearly promotes them to contract surface.
- Prefer settled spec text and Trace note clarifications over older implementation-plan assumptions.

Key corrections applied to the original phase document:

- `Flow` must not gain extra public props such as `gapX` and `gapY`; its
  public surface remains the common layout props unless the spec changes.
- Layout families consume child margin only where the layout spec explicitly
  says they do, and non-layout parents leave child margin inert.
- Layout-family spacing uses non-negative finite `padding` and `gap`, while
  child `margin` remains finite and signed on spacing-owning child surfaces.
- `responsive` and inherited `breakpoints` are two public entry points into the same pre-measure responsive resolution step; supplying both on one node is invalid and must fail deterministically.
- Responsive-rule handling must not be narrowed to a viewport-only breakpoint list; the spec allows viewport size, orientation, safe area, and parent dimensions as dependencies.
- Equal-share `fill` allocation and similar measurement policies are implementation choices, not current spec commitments.
- `SafeAreaContainer` must derive from safe-area bounds, not just inset values.
- Percentage sizing resolves against the effective parent content region, including safe-area-derived content boxes.
- Defaults that are not named by the spec should not be documented as stable public defaults.

Task order:

1. `00-compliance-review.md`
2. `01-layout-contract-and-responsive-surface.md`
3. `02-stage-layout-pass-integration.md`
4. `03-stack-layout.md`
5. `04-row-and-column-layout.md`
6. `05-flow-layout.md`
7. `06-safe-area-container.md`
8. `07-demo-and-acceptance.md`
