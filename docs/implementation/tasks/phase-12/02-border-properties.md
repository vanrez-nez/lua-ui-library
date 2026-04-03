# Task 02: Border Properties

## Goal

Add all nine border styling properties to `drawable_schema.lua`. Width properties must enforce the non-negative constraint. Enum properties must enforce their closed value sets. `borderMiterLimit` must be validated only when present and must be greater than zero.

## Spec Anchors

- `docs/spec/ui-styling-spec.md §7.1` — flat border property list
- `docs/spec/ui-styling-spec.md §7.2` — width model: numeric, finite, non-negative
- `docs/spec/ui-styling-spec.md §7.3` — `borderColor` and `borderOpacity` paint model
- `docs/spec/ui-styling-spec.md §7.4` — `borderStyle`, `borderJoin`, `borderMiterLimit` contract
- `docs/spec/ui-styling-spec.md §5.2` — opacity domain `[0, 1]`
- `docs/spec/ui-styling-spec.md §13` — hard failures for negative width, unsupported enum values, invalid border line configuration

## Scope

- Modify `lib/ui/core/drawable_schema.lua`
- Add nine entries: `borderColor`, `borderOpacity`, `borderWidthTop`, `borderWidthRight`, `borderWidthBottom`, `borderWidthLeft`, `borderStyle`, `borderJoin`, `borderMiterLimit`

## Concrete Module Targets

- `lib/ui/core/drawable_schema.lua` — modified only

## Implementation Guidance

**`borderColor`:**

Same pattern as `backgroundColor` — call `Color.resolve` in the validator, return the resolved `{ r, g, b, a }` table. Hard failure propagates from `Color.resolve`.

**`borderOpacity`:**

Numeric, must be in `[0, 1]`. Identical range validation as `backgroundOpacity`.

**`borderWidthTop`, `borderWidthRight`, `borderWidthBottom`, `borderWidthLeft`:**

Each is numeric and must be `>= 0`. The spec says widths must be finite and not negative. A negative value is a hard failure. Zero is valid — a zero-width side simply paints nothing. All four are independent; there is no combined shorthand.

**`borderStyle`:**

Must be one of `"smooth"` or `"rough"`. Hard failure on any other value.

**`borderJoin`:**

Must be one of `"none"`, `"miter"`, or `"bevel"`. Hard failure on any other value.

**`borderMiterLimit`:**

Optional. When nil, skip validation entirely — return nil. When present, must be numeric and must be greater than zero. The spec states it must be finite and `> 0`. Zero is not a valid miter limit. Negative values are not valid.

**Grouping:**

Place all nine entries as a contiguous block preceded by a `-- border` comment.

## Required Behavior

- `borderColor = {0, 0, 0}` → stored as `{0, 0, 0, 1}` (resolved)
- `borderColor = "hsl(0, 1, 0.5)"` → stored as `{1, 0, 0, 1}` (resolved)
- `borderColor = "purple"` → hard failure
- `borderOpacity = 0` → no error
- `borderOpacity = 1` → no error
- `borderOpacity = 1.1` → hard failure
- `borderWidthTop = 0` → no error
- `borderWidthTop = 2` → no error
- `borderWidthTop = -1` → hard failure
- `borderWidthLeft = 0.5` → no error (sub-pixel widths are valid)
- `borderStyle = "smooth"` → no error
- `borderStyle = "rough"` → no error
- `borderStyle = "dashed"` → hard failure (not a documented value)
- `borderJoin = "miter"` → no error
- `borderJoin = "bevel"` → no error
- `borderJoin = "none"` → no error
- `borderJoin = "round"` → hard failure
- `borderMiterLimit = 2` → no error
- `borderMiterLimit = 0` → hard failure (must be `> 0`)
- `borderMiterLimit = -1` → hard failure
- `borderMiterLimit = nil` → no error (treated as absent)
- All border properties nil → no error

## Non-Goals

- No `borderWidth` shorthand covering all four sides. The spec does not define one.
- No stroke dash or stipple properties — the spec explicitly excludes dashed-line patterns from this revision.
- No rendering logic.

## Acceptance Checks

- All required behavior cases produce the correct result or the correct error.
- The four width properties are truly independent — setting one does not affect the others.
- `borderMiterLimit = nil` does not trigger a validation error.
- All nine properties are nil by default when not provided.
