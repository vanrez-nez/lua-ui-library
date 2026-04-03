# Phase 11 Compliance Review

Source under review: existing color handling across `lib/ui/`

Task-set authority:

- `docs/spec/ui-styling-spec.md` §5.3 and §5.4 are authoritative for accepted color input forms and failure semantics.

Primary findings:

1. No general color input parser exists in the current implementation.
   Spec anchors: `ui-styling-spec.md §5.3`, `ui-styling-spec.md §5.4`
   Problem: color values are passed as raw `{ r, g, b, a }` tables in `[0, 1]` space directly to `love.graphics.setColor`. There is no parsing layer for hex strings, named colors, HSL, or 0-255 detection. Consumers who pass a hex string or named color string today would silently fail or produce an unhandled error.
   Required normalization: implement `Color.resolve` as the single entry point for all accepted color forms.

2. `reference/color.lua` contains related but incompatible color logic.
   Problem: the reference module operates in `[0, 255]` space, uses metatables, and implements HSV (not HSL) conversion. Importing it as-is would introduce incompatible numeric space, a class structure inconsistent with the rest of `lib/ui`, and a wrong conversion model for the spec-required `hsl(...)` input form.
   Required normalization: port only the `lerp` arithmetic and `is_color` field-type pattern as plain inline functions. Do not import or require the reference module.

3. No 0-255 range detection or mixed-scale failure exists.
   Spec anchor: `ui-styling-spec.md §5.4`
   Problem: the current implementation assumes all numeric color inputs are already in `[0, 1]`. An input of `{255, 0, 0}` would be passed to the graphics adapter as-is and produce a saturated white rather than a red.
   Required normalization: implement the detection and conversion rule, and fail deterministically on mixed-scale inputs.

4. Named color strings are not resolved anywhere.
   Spec anchor: `ui-styling-spec.md §5.3`
   Problem: if a consumer passes `"red"` as a color value today, nothing handles it.
   Required normalization: implement the nine-entry named color lookup as part of `Color.resolve`.

5. Hex color strings are not parsed anywhere.
   Spec anchor: `ui-styling-spec.md §5.4`
   Problem: hex strings such as `"#FF0000"` or `"#F00"` have no parse path.
   Required normalization: implement parsing for all four accepted hex forms.

6. HSL and HSLA inputs are not parsed or converted anywhere.
   Spec anchor: `ui-styling-spec.md §5.3`, `ui-styling-spec.md §5.4`
   Problem: no hsl/hsla string or value form is handled.
   Required normalization: implement string pattern matching for `hsl(...)` and `hsla(...)` and convert to RGBA.

Secondary notes:

- `lib/ui/themes/default.lua` already stores colors as `{ r, g, b, a }` tables in `[0, 1]` — these are valid passthrough inputs to `Color.resolve` and require no migration.
- The schema validator in Phase 12 will call `Color.resolve` on all color-typed properties. Phase 11 must be complete before Phase 12 can validate color inputs.
- No existing test or demo exercises the new color input forms. Acceptance tests will be introduced in task `04-integration-and-acceptance.md`.
