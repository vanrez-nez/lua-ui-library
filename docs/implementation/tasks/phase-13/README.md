# Phase 13 Task Set

Source implementation document for this phase:

- `docs/implementation/phase-13-styling-renderer.md`

Authority rules for this phase:

- `docs/spec/ui-styling-spec.md` §6 is authoritative for background source selection priority, color-backed and gradient-backed rendering, image-backed placement, and opacity composition.
- `docs/spec/ui-styling-spec.md` §7 is authoritative for border geometry (center-aligned), per-side widths, and line style contract.
- `docs/spec/ui-styling-spec.md` §8 is authoritative for corner radius overflow protection and the proportional scale-down rule.
- `docs/spec/ui-styling-spec.md` §9 is authoritative for shadow geometry, outer versus inset distinction, blur approach, and clipping requirement.
- `docs/spec/ui-styling-spec.md` §11A is authoritative for the paint order: outer shadow → background → border → inset shadow.
- `docs/spec/ui-styling-spec.md` §5.2 is authoritative for the alpha composition formula: `colorAlpha * opacity`.

Settled decisions that control this task set:

- `Styling.draw(props, bounds, graphics)` is the single public entry point. The module is stateless per call — no persistent state is kept between frames.
- All color inputs in `props` have already been resolved through `Color.resolve` by Phase 12 schema validation or Phase 14 resolution. The renderer does not call `Color.resolve` again — it reads `{ r, g, b, a }` tables directly.
- Background source selection follows strict priority: `backgroundImage` first, then `backgroundGradient`, then `backgroundColor`. Only the first present source is painted. The others are ignored, not an error.
- The `lerp` scalar function from `reference/color.lua` must be ported for gradient vertex interpolation as a plain local function operating in `[0, 1]` space. The reference module must not be imported or required.
- Corner radius overflow protection is computed once per `Styling.draw` call and the resolved (possibly scaled) radii are used for all subsequent painting steps.
- Canvas pool from `lib/ui/render/canvas_pool.lua` is used for shadow blur — no new canvas is allocated per frame.
- Border geometry is center-aligned on the styled bounds. Half of each side's width paints inward, half outward. This does not affect layout or hit-testing.
- Inset shadow clipping is enforced via a stencil or scissor pass. Blur falloff must not bleed outside the node interior.
- Phase 12 must be complete (all 29 properties in schema) before acceptance testing this phase is meaningful. Phase 11 (`Color.resolve`) must be complete before this phase is implemented.

Implementation conventions for every task in this phase:

- All graphics calls go through the `graphics` adapter parameter — do not call `love.graphics.*` directly. The adapter wraps LÖVE calls.
- Save and restore graphics state around any operation that changes line style, line join, miter limit, blend mode, color, or stencil settings.
- Use `lib/ui/utils/assert.lua` and `lib/ui/utils/types.lua` for argument guards in `Styling.draw`.
- No layout or measurement side-effects from any paint call.

Task order:

1. `00-compliance-review.md`
2. `01-module-structure-and-paint-order.md`
3. `02-corner-radius-resolution.md`
4. `03-background-color-paint.md`
5. `04-background-gradient-paint.md`
6. `05-background-image-paint.md`
7. `06-border-paint.md`
8. `07-shadow-paint.md`
9. `08-acceptance.md`
