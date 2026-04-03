# Task 05: Acceptance

## Goal

Verify that all 29 styling properties introduced by Phase 12 are present in `drawable_schema.lua`, all validators enforce their documented constraints, all hard failures fire correctly, and a Drawable instance constructed with any combination of valid styling properties behaves correctly.

## Spec Anchors

- `docs/spec/ui-styling-spec.md §6`, §7, §8, §9 — full property catalogs and constraints
- `docs/spec/ui-styling-spec.md §13` — complete hard-failure list

## Scope

- No new implementation — this task verifies the work from tasks 01–04
- Manual verification by constructing Drawable instances with valid and invalid property values
- Confirm nil-default behavior for every property

## Concrete Module Targets

- `lib/ui/core/drawable_schema.lua` — read only
- `lib/ui/core/drawable.lua` — used to construct test instances

## Implementation Guidance

Verify by constructing Drawable instances or by calling the schema validator directly with prepared property tables. For hard-failure cases, wrap each call in a protected call and confirm an error is raised.

**Nil-default pass:**

Construct a bare Drawable with no styling properties set. Confirm that accessing any of the 29 properties returns nil without error. This verifies that nil is a valid and non-erroring state for all properties.

**Background group pass:**

Set each of the ten background properties individually to a valid value and confirm no error. Confirm that all ten can be set simultaneously without conflict.

**Border group pass:**

Set each of the nine border properties individually to a valid value and confirm no error. Confirm the four width properties are independent.

**Corner radius and shadow group pass:**

Set each of the ten corner radius and shadow properties individually to a valid value and confirm no error.

**Hard-failure sweep:**

For each of the following, confirm a Lua error is raised:

Background hard failures:
- `backgroundColor = "purple"` — unsupported named color
- `backgroundOpacity = 1.5` — out of `[0, 1]`
- `backgroundOpacity = -0.1` — below `0`
- `backgroundGradient = { kind="radial", direction="horizontal", colors={{1,0,0},{0,0,1}} }` — unsupported kind
- `backgroundGradient = { kind="linear", direction="diagonal", colors={{1,0,0},{0,0,1}} }` — unsupported direction
- `backgroundGradient = { kind="linear", direction="horizontal", colors={{1,0,0}} }` — fewer than two colors
- `backgroundImage = someImageComponent` — wrong source type (Image component)
- `backgroundAlignX = "middle"` — unsupported enum value
- `backgroundAlignY = "top"` — unsupported enum value

Border hard failures:
- `borderColor = "purple"` — unsupported named color
- `borderOpacity = 1.1` — out of range
- `borderWidthTop = -1` — negative width
- `borderWidthRight = -0.5` — negative width
- `borderStyle = "dashed"` — unsupported enum
- `borderJoin = "round"` — unsupported enum
- `borderMiterLimit = 0` — must be `> 0`
- `borderMiterLimit = -2` — must be `> 0`

Corner radius and shadow hard failures:
- `cornerRadiusTopLeft = -1` — negative
- `cornerRadiusBottomRight = -0.5` — negative
- `shadowColor = "purple"` — unsupported named color
- `shadowOpacity = -0.1` — out of range
- `shadowOpacity = 1.1` — out of range
- `shadowBlur = -1` — negative

**Color resolution pass:**

For color-typed properties, confirm that the stored value is the resolved `{ r, g, b, a }` table, not the raw input:
- Set `backgroundColor = {255, 0, 0}` → stored as `{1, 0, 0, 1}`
- Set `backgroundColor = "#FF0000"` → stored as `{1, 0, 0, 1}`
- Set `borderColor = "hsl(120, 1, 0.5)"` → stored as `{0, 1, 0, 1}`
- Set `shadowColor = {0, 0, 0}` → stored as `{0, 0, 0, 1}`

**Schema load pass:**

Require `lib/ui/core/drawable_schema.lua` in isolation (without a full LÖVE context) and confirm it loads without error.

## Non-Goals

- No rendering verification — that is Phase 13's scope.
- No resolution cascade testing — that is Phase 14's scope.
- No testing of properties that existed before Phase 12.

## Acceptance Checks

- All 29 properties are present in the schema.
- All nil-default cases pass without error.
- All valid-value cases pass without error.
- All hard-failure cases raise an error when triggered via protected call.
- Color-typed properties store the resolved form, not the raw input.
- The schema file loads without error in isolation.
