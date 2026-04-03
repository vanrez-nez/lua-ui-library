# Phase 12 Task Set

Source implementation document for this phase:

- `docs/implementation/phase-12-styling-schema.md`

Authority rules for this phase:

- `docs/spec/ui-styling-spec.md` §5.3 and §5.4 are authoritative for accepted color input forms — all color-typed properties must pass through `Color.resolve` at validation time.
- `docs/spec/ui-styling-spec.md` §6 is authoritative for background property definitions, accepted value shapes, and the single-source rule.
- `docs/spec/ui-styling-spec.md` §7 is authoritative for border property definitions, the width model, the paint model, and the line contract.
- `docs/spec/ui-styling-spec.md` §8 is authoritative for corner radius definitions and the overflow-protection requirement.
- `docs/spec/ui-styling-spec.md` §9 is authoritative for shadow property definitions.
- `docs/spec/ui-styling-spec.md` §13 is authoritative for all failure semantics — every hard-failure case documented there is mandatory.
- `docs/spec/ui-styling-spec.md` §5.5 is authoritative for the accepted source types for `backgroundImage` — only `Texture` and `Sprite` are valid; `Image` is explicitly not valid.

Settled decisions that control this task set:

- All new properties are optional at the schema level. A nil value is valid for every property in this phase — it signals "not set at the instance level" and falls through to skin, token, or library default during Phase 14 resolution.
- No shorthand aliases are introduced in this phase. There is no `borderWidth` covering all four sides, no `cornerRadius` covering all four corners, no `background` group. The spec defines flat properties only.
- Color validation runs at assignment time via `Color.resolve`. The resolved form is stored, not the raw input. This means downstream rendering never needs to re-normalize color inputs.
- The schema does not validate that only one background source is set. That is a rendering concern belonging to Phase 13 source selection. Setting both `backgroundColor` and `backgroundGradient` is not a schema error.
- `backgroundGradient` validation is structural: the table must have the correct shape, `kind` must be `"linear"`, `direction` must be a documented value, and `colors` must contain at least two valid color inputs. Structural violations are hard failures.
- `backgroundImage` accepts only `Texture` or `Sprite` instances as defined in `docs/spec/ui-graphics-spec.md`. Passing an `Image` component instance is a hard failure.
- `borderMiterLimit` is nil by default and is only validated when present. When present it must be numeric and greater than zero.
- Phase 11 (`Color.resolve`) must be complete before this phase can be implemented. Color validation depends on it.

Implementation conventions for every task in this phase:

- Every new schema entry uses the `validate` function form from `lib/ui/utils/schema.lua` — the `{ validate = function(key, value, ctx, level) ... end }` shape.
- All validation errors use `Assert.fail(msg, level)` or `error(msg, 2)` with a descriptive message that names the property and the violated rule.
- New entries are appended to `lib/ui/core/drawable_schema.lua`. The existing entries are not modified.
- Reuse `lib/ui/utils/assert.lua` and `lib/ui/utils/types.lua` for type guards.
- Each property group (background, border, corner radius, shadow) is a coherent block in the schema file, separated by a comment.

Task order:

1. `00-compliance-review.md`
2. `01-background-properties.md`
3. `02-border-properties.md`
4. `03-corner-radius-and-shadow-properties.md`
5. `04-validation-logic.md`
6. `05-acceptance.md`
