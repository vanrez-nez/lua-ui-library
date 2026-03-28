# Phase 03 Task Set

Source implementation document used for this phase: `docs/implementation/phase-03-layout.md`.

Note: `docs/implementation/phase-03-foundation.md` does not exist in the repo. This task set normalizes the existing Phase 3 layout document against the authoritative spec set in `docs/spec`.

Normalization rules for this phase:

- Treat `docs/spec/ui-foundation-spec.md` as normative for all layout families, layout state, and responsive rules.
- Do not freeze a public measurement or breakpoint schema where the spec does not define one.
- Keep implementation-specific layout algorithms internal unless the spec clearly promotes them to contract surface.
- When the spec itself is underspecified or internally inconsistent, capture the gap explicitly and avoid turning one interpretation into stable API by accident.

Key corrections applied to the original phase document:

- `Flow` must not gain extra public props such as `gapX` and `gapY`; its public surface remains the common layout props unless the spec changes.
- Responsive-rule handling must not be narrowed to a viewport-only breakpoint list with a fixed schema.
- Equal-share `fill` allocation and similar measurement policies are implementation choices, not current spec commitments.
- `SafeAreaContainer` must derive from safe-area bounds, not just inset values.
- Defaults that are not named by the spec should not be documented as stable public defaults.

Unresolved spec gap carried into this phase:

- The foundation spec names `breakpoints` on `Container` and `responsive` in layout common props without defining the exact relationship or public data shape. Phase 3 implementation may need an internal normalization layer, but it must not freeze a public schema beyond what the spec says.

Task order:

1. `00-compliance-review.md`
2. `01-layout-contract-and-responsive-surface.md`
3. `02-stage-layout-pass-integration.md`
4. `03-stack-layout.md`
5. `04-row-and-column-layout.md`
6. `05-flow-layout.md`
7. `06-safe-area-container.md`
8. `07-demo-and-acceptance.md`
