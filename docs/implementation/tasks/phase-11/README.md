# Phase 11 Task Set

Source implementation document for this phase:

- `docs/implementation/phase-11-color-input.md`

Authority rules for this phase:

- `docs/spec/ui-styling-spec.md` §5.3 and §5.4 are authoritative for all accepted color input forms, conversion rules, and failure semantics.
- No color form may be accepted that is not explicitly listed in those sections.
- No color form that is listed may be silently ignored or coerced into a nearby valid value — all failure paths are deterministic hard failures.

Settled decisions that control this task set:

- The canonical output of `Color.resolve` is always `{ r, g, b, a }` with all components in `[0, 1]`.
- The `reference/color.lua` module must not be imported. Its class structure and 0-255 space are incompatible. The `lerp` arithmetic and `is_color` validation pattern may be ported as plain functions adapted to `[0, 1]` space.
- The reference implements HSV conversion, not HSL. HSL→RGB must be written from scratch — adapting the HSV algorithm would produce incorrect colors.
- 0-255 detection fires when any component exceeds `1`. Once triggered, all components must be integers and all must be `≤ 255`. A non-integer alongside a component `> 1` is a mixed-scale hard failure.
- Named color catalog is exactly the nine values listed in the spec. No additions.
- Hue wraps for any finite value. Saturation, lightness, and alpha outside `[0, 1]` are hard failures.

Implementation conventions for every task in this phase:

- `Color.resolve` is a pure function with no side effects. No module-level state.
- All validation errors use `error(msg, 2)` with a descriptive message identifying the input and the rule violated.
- Do not introduce a color class, metatable, or object wrapper. The output is a plain sequential table.
- Reuse `lib/ui/utils/assert.lua` and `lib/ui/utils/types.lua` for argument guards where applicable.
- Unit-testable: every code path in `Color.resolve` must be reachable by passing a single input value.

Task order:

1. `00-compliance-review.md`
2. `01-numeric-rgba-and-range-detection.md`
3. `02-hex-and-named-colors.md`
4. `03-hsl-conversion.md`
5. `04-integration-and-acceptance.md`
