# Phase 11: Color Input Parser

## Purpose

Implement a spec-compliant color input parser that resolves all accepted public color forms into a canonical `{ r, g, b, a }` table in the `[0, 1]` range. This module is a prerequisite for the styling paint pipeline in Phase 13.

## Authority

- `docs/spec/ui-styling-spec.md` §5.3 Color Inputs
- `docs/spec/ui-styling-spec.md` §5.4 Color Conversion

This document is sequencing and scoping context only. It must not widen the accepted input forms beyond those published in the spec.

---

## Scope

### File

`lib/ui/render/color.lua`

This is a stateless utility module. It exposes one primary function: `Color.resolve(input)` which returns `{ r, g, b, a }` in `[0, 1]` or raises a deterministic error.

---

## Accepted Input Forms

### 1. Numeric RGBA sequential table

Input: `{ r, g, b }` or `{ r, g, b, a }`

- All components must be numeric
- If all components are in `[0, 1]`: return as-is, defaulting alpha to `1`
- If any component exceeds `1`: treat as `[0, 255]` range input (see §5.4 conversion below)

### 2. `[0, 255]` Range Detection And Conversion

Trigger: any component in the input exceeds `1`.

Rules:
- All components must be integers — a non-integer value alongside a component greater than `1` is a hard failure (mixed-scale input)
- All components must be `≤ 255` — a component exceeding `255` is a hard failure
- Divide all components by `255` to resolve into `[0, 1]`

**Port from `reference/color.lua`:** The `is_color` validation pattern (checking that all four fields are numbers) can be adapted here. The `reference/color.lua` version operates in 0-255 space and uses metatables — do not import the module or its structure. Extract the table-field validation logic only.

### 3. Hex Strings

Accepted forms: `#RGB`, `#RGBA`, `#RRGGBB`, `#RRGGBBAA`

- Strip the `#` prefix
- Expand 3- or 4-char shorthand by doubling each nibble (`#RGB` → `#RRGGBB`)
- Parse each channel as a hex byte in `[0, 255]`, divide by `255`
- Alpha defaults to `1` when absent
- Any other hex string length or invalid hex character is a hard failure

### 4. Named Colors

Full catalog (from spec):

| Name | RGBA |
|---|---|
| `transparent` | `{0, 0, 0, 0}` |
| `black` | `{0, 0, 0, 1}` |
| `white` | `{1, 1, 1, 1}` |
| `red` | `{1, 0, 0, 1}` |
| `green` | `{0, 0.502, 0, 1}` |
| `blue` | `{0, 0, 1, 1}` |
| `yellow` | `{1, 1, 0, 1}` |
| `cyan` | `{0, 1, 1, 1}` |
| `magenta` | `{1, 0, 1, 1}` |

Any string not in this table is a hard failure.

### 5. HSL / HSLA Strings

Accepted forms: `hsl(h, s, l)` and `hsla(h, s, l, a)`

- `hue`: numeric, degrees, any finite value, resolved by angle wrapping (`hue % 360`)
- `saturation`: numeric, `[0, 1]`
- `lightness`: numeric, `[0, 1]`
- `alpha`: numeric, `[0, 1]`, optional (defaults to `1`)
- Saturation, lightness, or alpha outside `[0, 1]` is a hard failure

**HSL → RGB algorithm** (write from scratch — do NOT adapt from `reference/color.lua`):
The reference module implements HSV-to-RGB, not HSL-to-RGB. These are distinct color models. The HSL→RGB algorithm uses the hue sector and chroma model specific to HSL. Using the HSV algorithm for HSL inputs would produce incorrect colors.

**Port from `reference/color.lua`:** The `lerp` function `a + s * (b - a)` used in intermediate HSL→RGB calculations can be adapted. The reference operates on scalar numbers; no class structure is involved.

---

## Hard Failure Cases

All failures must be raised as errors with a descriptive message. No silent fallback.

- Input is not a table and not a string
- String input is not a valid named color and does not match hex or hsl/hsla pattern
- Hex string has invalid length or non-hex characters
- HSL/HSLA saturation, lightness, or alpha outside `[0, 1]`
- Numeric table with any component exceeding `255` after `[0, 255]` detection
- Numeric table with mixed-scale input (non-integer component alongside a component > 1)

---

## Public API

```
Color.resolve(input) → { r, g, b, a }
```

- Input: any accepted color form
- Output: `{ r, g, b, a }` with all components in `[0, 1]`
- Raises on invalid input

No other public surface is required by this phase.

---

## Reference Reuse Summary

| From `reference/color.lua` | Reuse approach |
|---|---|
| `is_color` validation pattern | Adapt field-type check logic; operate in `[0, 1]` space; no metatable |
| `lerp` scalar function | Port the arithmetic directly into HSL helper |
| `hsv_to_color` | Do NOT reuse — HSV is a different model than HSL |
| `color.new` / metatables | Do NOT import — incompatible class structure and 0-255 space |
| `gamma_to_linear` / `linear_to_gamma` | Available for gradient color accuracy in Phase 13 if needed |

---

## Verification

- Resolve `{1, 0, 0}` → `{1, 0, 0, 1}`
- Resolve `{255, 0, 0}` → `{1, 0, 0, 1}` (0-255 detection)
- Resolve `{255, 0.5, 0}` → hard failure (mixed-scale)
- Resolve `{300, 0, 0}` → hard failure (exceeds 255)
- Resolve `"#FF0000"` → `{1, 0, 0, 1}`
- Resolve `"#F00"` → `{1, 0, 0, 1}`
- Resolve `"#FF000080"` → `{1, 0, 0, 0.502}`
- Resolve `"red"` → `{1, 0, 0, 1}`
- Resolve `"purple"` → hard failure (not in catalog)
- Resolve `"hsl(0, 1, 0.5)"` → `{1, 0, 0, 1}`
- Resolve `"hsl(240, 1, 0.5)"` → `{0, 0, 1, 1}`
- Resolve `"hsla(0, 1, 0.5, 0.5)"` → `{1, 0, 0, 0.5}`
- Resolve `"hsl(0, 1.5, 0.5)"` → hard failure (saturation out of range)
