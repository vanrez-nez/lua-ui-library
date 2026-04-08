# Task 05: Shape Fill Source Surface And Priority

## Goal

Expand `Shape` with the full fill-source prop surface defined by the spec while keeping fill ownership entirely shape-local.

## Current implementation notes

- `lib/ui/core/shape_schema.lua` currently exposes only flat-color fill and stroke props.
- The concrete shapes currently hardcode flat-color fill reads directly from `fillColor` and `fillOpacity`.
- Drawable background props already have parallel concepts, but they must not be aliased onto `Shape`.

## Work items

- Add the following direct instance props to `Shape`:
  - `fillGradient`
  - `fillTexture`
  - `fillRepeatX`
  - `fillRepeatY`
  - `fillOffsetX`
  - `fillOffsetY`
  - `fillAlignX`
  - `fillAlignY`
- Use shared validators from task 01 for:
  - gradient object structure
  - `Texture | Sprite` acceptance
  - numeric offsets
  - align enums
- Set defaults per the patch:
  - `fillOpacity = 1`
  - `fillGradient = nil`
  - `fillTexture = nil`
  - `fillRepeatX = false`
  - `fillRepeatY = false`
  - `fillOffsetX = 0`
  - `fillOffsetY = 0`
  - `fillAlignX = "center"`
  - `fillAlignY = "center"`
- Add a shared active-source resolver for `Shape` that enforces render-time priority:
  1. `fillTexture`
  2. `fillGradient`
  3. `fillColor`
- Keep fill source ownership out of:
  - theming
  - skinning
  - styling inheritance
  - `background*` property names
- Do not add `border*` props to `Shape` and do not attempt to collapse `Shape.stroke*` into Drawable border vocabulary.

## Implementation notes

- Reuse `lib/ui/render/graphics_validation.lua` for `fillGradient`, `fillTexture`, `fillOffset*`, and `fillAlign*` validation. Do not copy the old Drawable background validators back into `shape_schema.lua`.
- Shape fill remains direct-instance state only. Do not route these props through theme resolution, skin lookup, or `background*` aliases.
- No current module resolves active fill-source priority, so this task must introduce that resolver explicitly instead of hiding it in the concrete shape classes.

## File targets

- `lib/ui/core/shape_schema.lua`
- `lib/ui/core/shape.lua`
- new shared fill-resolution helper(s), likely under `lib/ui/shapes/` or `lib/ui/render/`

## Acceptance criteria

- `Shape` accepts the full fill-source prop surface as direct instance props.
- `fillTexture` accepts only `Texture` or `Sprite`.
- `fillGradient` accepts only valid gradient objects.
- Multiple fill source props may coexist as stored values, but exactly one active source is selected at render time by the documented priority rule.
