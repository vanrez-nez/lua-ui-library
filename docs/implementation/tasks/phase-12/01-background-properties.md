# Task 01: Background Properties

## Goal

Add all ten background styling properties to `drawable_schema.lua`. Each property must be optional, use a validator that enforces the spec constraints when a value is present, and store the resolved form — not the raw input — for color-typed entries.

## Spec Anchors

- `docs/spec/ui-styling-spec.md §6.2` — flat background property list
- `docs/spec/ui-styling-spec.md §6.3` — `backgroundColor` and `backgroundOpacity` semantics
- `docs/spec/ui-styling-spec.md §6.4` — `backgroundGradient` shape contract
- `docs/spec/ui-styling-spec.md §6.5` — image-backed placement properties and `backgroundOpacity`
- `docs/spec/ui-styling-spec.md §5.5` — accepted source types for `backgroundImage`
- `docs/spec/ui-styling-spec.md §5.2` — opacity domain `[0, 1]`
- `docs/spec/ui-styling-spec.md §13` — hard failures for invalid gradient structure, wrong image source type, unsupported enum values, opacity out of range

## Scope

- Modify `lib/ui/core/drawable_schema.lua`
- Add ten entries: `backgroundColor`, `backgroundOpacity`, `backgroundGradient`, `backgroundImage`, `backgroundRepeatX`, `backgroundRepeatY`, `backgroundOffsetX`, `backgroundOffsetY`, `backgroundAlignX`, `backgroundAlignY`
- Validator logic for each entry as described below

## Concrete Module Targets

- `lib/ui/core/drawable_schema.lua` — modified only

## Implementation Guidance

**`backgroundColor`:**

Use a validate function that calls `Color.resolve` on the value and returns the resolved `{ r, g, b, a }` table. Hard failure propagates from `Color.resolve` if the input is invalid. Store the resolved form.

**`backgroundOpacity`:**

Numeric, must be in `[0, 1]`. Fail if not a number. Fail if less than `0` or greater than `1`.

**`backgroundGradient`:**

Must be a table. Validate the following fields:
- `kind`: must be the string `"linear"`. Any other value is a hard failure.
- `direction`: must be `"horizontal"` or `"vertical"`. Any other value is a hard failure.
- `colors`: must be a sequential table with at least two entries. Each entry must pass through `Color.resolve`. If any entry fails resolution, it is a hard failure. If fewer than two entries are present, it is a hard failure.

The validator returns a normalized gradient table with colors already resolved to `{ r, g, b, a }` form.

**`backgroundImage`:**

Must be a `Texture` or `Sprite` instance. Use `Types.is_userdata` or the type-check mechanism used by the graphics module to identify valid source objects. A value that is an `Image` component instance (a display-layer object) must produce a dedicated hard failure message: `"backgroundImage: Image component is not a valid source — use Texture or Sprite"`. Any other invalid type is a hard failure with a general message.

**`backgroundRepeatX` and `backgroundRepeatY`:**

Must be booleans. Use `{ type = 'boolean' }` rule form.

**`backgroundOffsetX` and `backgroundOffsetY`:**

Must be numbers. The spec does not restrict these to non-negative — offsets may be negative. Use `{ type = 'number' }` rule form.

**`backgroundAlignX`:**

Must be one of `"start"`, `"center"`, `"end"`. Hard failure on any other value.

**`backgroundAlignY`:**

Must be one of `"start"`, `"center"`, `"end"`. Hard failure on any other value.

**Grouping:**

Place all ten entries as a contiguous block in the schema table, preceded by a `-- background` comment, consistent with the style used for other property groups in the file.

## Required Behavior

- `backgroundColor = {1, 0, 0}` → stored as `{1, 0, 0, 1}` (resolved)
- `backgroundColor = "#FF0000"` → stored as `{1, 0, 0, 1}` (resolved)
- `backgroundColor = "purple"` → hard failure (unsupported named color)
- `backgroundOpacity = 0.5` → stored as `0.5`
- `backgroundOpacity = 1.5` → hard failure
- `backgroundOpacity = -0.1` → hard failure
- `backgroundGradient = { kind="linear", direction="horizontal", colors={{1,0,0},{0,0,1}} }` → no error, colors resolved
- `backgroundGradient = { kind="radial", direction="horizontal", colors={{1,0,0},{0,0,1}} }` → hard failure (unsupported kind)
- `backgroundGradient = { kind="linear", direction="diagonal", colors={{1,0,0},{0,0,1}} }` → hard failure (unsupported direction)
- `backgroundGradient = { kind="linear", direction="horizontal", colors={{1,0,0}} }` → hard failure (fewer than two colors)
- `backgroundImage = someTexture` → no error
- `backgroundImage = someImageComponent` → hard failure with dedicated message
- `backgroundAlignX = "center"` → no error
- `backgroundAlignX = "middle"` → hard failure
- `backgroundRepeatX = true` → no error
- `backgroundOffsetX = -10` → no error
- All properties nil → no error

## Non-Goals

- No rendering logic or paint calls in this task.
- No enforcement of the single-source rule (only one background source active at a time) — that is a Phase 13 rendering concern.
- No shorthand `background` property that sets multiple sub-properties at once.

## Acceptance Checks

- All required behavior cases produce the correct result or the correct error.
- `drawable_schema.lua` loads without error in isolation.
- A Drawable instance can be constructed with any subset of the ten properties set.
- All ten properties are nil by default when not provided.
- The gradient validator stores color inputs in resolved form.
