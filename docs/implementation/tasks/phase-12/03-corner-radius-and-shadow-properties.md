# Task 03: Corner Radius And Shadow Properties

## Goal

Add the four corner radius properties and the six shadow properties to `drawable_schema.lua`. Corner radius and shadow blur must enforce the non-negative constraint. Shadow color and opacity follow the same pattern as background and border color/opacity. `shadowInset` is a boolean.

## Spec Anchors

- `docs/spec/ui-styling-spec.md §8` — corner radius flat property list and constraints
- `docs/spec/ui-styling-spec.md §9.1` — shadow flat property list
- `docs/spec/ui-styling-spec.md §9.2` — shadow semantics: `shadowInset`, color, opacity, blur constraints
- `docs/spec/ui-styling-spec.md §5.2` — opacity domain `[0, 1]`
- `docs/spec/ui-styling-spec.md §13` — hard failures for negative radius or blur values

## Scope

- Modify `lib/ui/core/drawable_schema.lua`
- Add four corner radius entries: `cornerRadiusTopLeft`, `cornerRadiusTopRight`, `cornerRadiusBottomRight`, `cornerRadiusBottomLeft`
- Add six shadow entries: `shadowColor`, `shadowOpacity`, `shadowOffsetX`, `shadowOffsetY`, `shadowBlur`, `shadowInset`

## Concrete Module Targets

- `lib/ui/core/drawable_schema.lua` — modified only

## Implementation Guidance

**`cornerRadiusTopLeft`, `cornerRadiusTopRight`, `cornerRadiusBottomRight`, `cornerRadiusBottomLeft`:**

Each is numeric and must be `>= 0`. Negative values are hard failures. Zero is valid and means no rounding at that corner. Each corner is fully independent. There is no combined shorthand that sets all four.

The overflow protection described in the spec — where adjacent radii on one side exceed the side's available length — is a rendering concern that belongs in Phase 13. The schema does not validate radii against bounds because bounds are not known at assignment time.

**`shadowColor`:**

Same pattern as `backgroundColor` — call `Color.resolve` in the validator, return the resolved `{ r, g, b, a }` table.

**`shadowOpacity`:**

Numeric, must be in `[0, 1]`. Fail if less than `0` or greater than `1`.

**`shadowOffsetX` and `shadowOffsetY`:**

Must be numbers. Offsets may be negative (a shadow can be cast in any direction). Use `{ type = 'number' }` rule form.

**`shadowBlur`:**

Numeric, must be `>= 0`. A blur of zero produces a hard-edged shadow with no softening, which is valid. Negative blur is a hard failure.

**`shadowInset`:**

Must be a boolean. `false` means outer shadow; `true` means inset shadow. Use `{ type = 'boolean' }` rule form. When nil, the renderer treats the shadow as absent (there is no default inset setting — shadow is absent when `shadowColor` is absent).

**Grouping:**

Place the four corner radius entries as a contiguous block preceded by a `-- corner radius` comment. Place the six shadow entries as a contiguous block preceded by a `-- shadow` comment.

## Required Behavior

- `cornerRadiusTopLeft = 0` → no error
- `cornerRadiusTopLeft = 8` → no error
- `cornerRadiusTopLeft = -1` → hard failure
- `cornerRadiusBottomRight = 100` → no error (overflow protection is a render-time concern)
- All four corner radius properties nil → no error
- `shadowColor = {0, 0, 0}` → stored as `{0, 0, 0, 1}`
- `shadowColor = "black"` → stored as `{0, 0, 0, 1}`
- `shadowColor = "purple"` → hard failure
- `shadowOpacity = 0.8` → no error
- `shadowOpacity = -0.1` → hard failure
- `shadowOpacity = 1.1` → hard failure
- `shadowOffsetX = 4` → no error
- `shadowOffsetX = -4` → no error (negative offsets are valid)
- `shadowOffsetY = 0` → no error
- `shadowBlur = 0` → no error
- `shadowBlur = 6` → no error
- `shadowBlur = -1` → hard failure
- `shadowInset = false` → no error
- `shadowInset = true` → no error
- All shadow properties nil → no error

## Non-Goals

- No shorthand `cornerRadius` that sets all four corners. The spec does not define one.
- No shadow spread property — the spec explicitly excludes it from this revision.
- No multiple simultaneous shadows — the spec limits to one shadow per node in this revision.
- No bounds-aware overflow validation — that is Phase 13's responsibility.

## Acceptance Checks

- All required behavior cases produce the correct result or the correct error.
- The four corner radius properties are fully independent.
- `shadowBlur = 0` is valid and does not trigger an error.
- All ten new properties are nil by default when not provided.
- Corner radius properties do not interact with or modify existing layout or padding schema entries.
