# Phase 12 Compliance Review

Source under review: `lib/ui/core/drawable_schema.lua` and related styling infrastructure across `lib/ui/`

Task-set authority:

- `docs/spec/ui-styling-spec.md` §6, §7, §8, §9 are authoritative for all styling property definitions.
- `docs/spec/ui-styling-spec.md` §13 is authoritative for all failure semantics.

Primary findings:

1. No background, border, corner radius, or shadow properties exist in the current schema.
   Spec anchors: `ui-styling-spec.md §6.2`, `ui-styling-spec.md §7.1`, `ui-styling-spec.md §8`, `ui-styling-spec.md §9.1`
   Problem: `lib/ui/core/drawable_schema.lua` currently defines layout and motion properties only. The full flat styling property surface — all background, border, corner radius, and shadow properties — is absent. Consumers cannot set `backgroundColor`, `borderWidthTop`, `cornerRadiusTopLeft`, `shadowBlur`, or any other styling property through the validated public surface.
   Required addition: add all 29 styling properties across the four property families to the schema.

2. No color input validation exists at the schema level.
   Spec anchor: `ui-styling-spec.md §5.3`, `ui-styling-spec.md §13`
   Problem: the current schema has no mechanism to validate color inputs. A consumer setting `backgroundColor` today would not be validated at all since the key is not present in the schema. After Phase 12, all color-typed properties must be passed through `Color.resolve` at validation time, producing hard failures on invalid inputs such as unsupported named colors, malformed hex strings, or out-of-range components.
   Required addition: schema validator functions that call `Color.resolve` for each color-typed property.

3. No gradient structure validation exists.
   Spec anchor: `ui-styling-spec.md §6.4`, `ui-styling-spec.md §13`
   Problem: there is no code that validates the `backgroundGradient` table shape. A consumer could set a gradient with zero colors, an unsupported kind, or an unsupported direction without any error today.
   Required addition: structural validation for `backgroundGradient` — check that `kind` is `"linear"`, `direction` is `"horizontal"` or `"vertical"`, and `colors` contains at least two valid color inputs.

4. No `backgroundImage` type guard exists.
   Spec anchor: `ui-styling-spec.md §5.5`, `ui-styling-spec.md §13`
   Problem: the spec explicitly prohibits using an `Image` component instance (a display component) as a `backgroundImage` source, and requires `Texture` or `Sprite` only. No validation currently enforces this. The `Image` naming overlap with the `backgroundImage` property name makes this a realistic mistake.
   Required addition: type check that rejects any value that is not a `Texture` or `Sprite` instance, with a dedicated error message identifying the `Image`-as-source mistake.

5. No enum validation exists for background alignment or border line properties.
   Spec anchor: `ui-styling-spec.md §6.5`, `ui-styling-spec.md §7.4`, `ui-styling-spec.md §13`
   Problem: `backgroundAlignX`, `backgroundAlignY`, `borderStyle`, and `borderJoin` each have documented closed value sets. No schema guard enforces these sets. An unsupported value would silently reach the renderer.
   Required addition: enum validators for each property that fail deterministically on unsupported values.

6. No numeric range validation exists for opacity, width, blur, or radius properties.
   Spec anchor: `ui-styling-spec.md §5.1`, `ui-styling-spec.md §5.2`, `ui-styling-spec.md §7.2`, `ui-styling-spec.md §8`, `ui-styling-spec.md §9.1`, `ui-styling-spec.md §13`
   Problem: opacity properties must be clamped to `[0, 1]`, width and blur properties must be `>= 0`, and radius properties must be `>= 0`. None of these constraints exist in the current schema.
   Required addition: range validators for each affected property.

Secondary notes:

- `lib/ui/utils/schema.lua` provides `Schema.validate`, `Schema.merge`, and the `{ validate = function }` rule shape. All new schema entries should use this convention to remain consistent with existing entries.
- The existing schema entries (`padding`, `margin`, `alignX`, `alignY`, `skin`, `opacity`, etc.) are not affected by this phase. The new properties are additive.
- `Color.resolve` from Phase 11 is the only validation entry point for color-typed properties. Do not re-implement color parsing in the schema validators.
- Phase 13 will rely on the assumption that any value stored for a color property has already been resolved through `Color.resolve` — if the schema runs resolution at assignment time, the renderer gets clean data.
- No tests or demo exercises these new properties today. Acceptance checks are introduced in task `05-acceptance.md`.
