# Phase 12: Drawable Styling Schema

## Purpose

Extend the Drawable schema with all flat styling properties defined by the styling spec. This phase adds the public property surface only — no rendering logic. Rendering is covered in Phase 13.

## Authority

- `docs/spec/ui-styling-spec.md` §6 Background Contract
- `docs/spec/ui-styling-spec.md` §7 Border Contract
- `docs/spec/ui-styling-spec.md` §8 Corner Radius Contract
- `docs/spec/ui-styling-spec.md` §9 Shadow Contract

This document is sequencing and scoping context only.

---

## Scope

### File Modified

`lib/ui/core/drawable_schema.lua`

All new properties are optional (nil by default). A nil value means the property is not set at the instance level and will fall through to skin, token, or library default during resolution (Phase 14).

---

## Background Properties

```
backgroundColor        -- color input (any accepted form per §5.3)
backgroundOpacity      -- number, [0, 1]
backgroundGradient     -- table: { kind, direction, colors }
backgroundImage        -- Texture or Sprite instance
backgroundRepeatX      -- boolean
backgroundRepeatY      -- boolean
backgroundOffsetX      -- number (pixels)
backgroundOffsetY      -- number (pixels)
backgroundAlignX       -- "start" | "center" | "end"
backgroundAlignY       -- "start" | "center" | "end"
```

`backgroundGradient` accepted shape:

```
{
  kind      = "linear",
  direction = "horizontal" | "vertical",
  colors    = { <color input>, <color input>, ... }  -- at least two
}
```

---

## Border Properties

```
borderColor            -- color input
borderOpacity          -- number, [0, 1]
borderWidthTop         -- number, >= 0
borderWidthRight       -- number, >= 0
borderWidthBottom      -- number, >= 0
borderWidthLeft        -- number, >= 0
borderStyle            -- "smooth" | "rough"
borderJoin             -- "none" | "miter" | "bevel"
borderMiterLimit       -- number > 0, or nil
```

---

## Corner Radius Properties

```
cornerRadiusTopLeft      -- number, >= 0
cornerRadiusTopRight     -- number, >= 0
cornerRadiusBottomRight  -- number, >= 0
cornerRadiusBottomLeft   -- number, >= 0
```

---

## Shadow Properties

```
shadowColor            -- color input
shadowOpacity          -- number, [0, 1]
shadowOffsetX          -- number
shadowOffsetY          -- number
shadowBlur             -- number, >= 0
shadowInset            -- boolean
```

---

## Schema Validation Rules

Add to the existing schema validator. All properties are optional but when present must conform:

- Color inputs: passed through `Color.resolve()` at validation time — hard failure on invalid input
- Opacity properties: must be numeric and in `[0, 1]` — hard failure otherwise
- Width and blur properties: must be numeric and `>= 0` — hard failure if negative
- Corner radius properties: must be numeric and `>= 0`
- `borderMiterLimit`: when present must be numeric and `> 0`
- Enum properties (`backgroundAlignX/Y`, `borderStyle`, `borderJoin`): must match their documented value sets
- `backgroundGradient.colors`: must contain at least two valid color inputs
- `backgroundImage`: must be a `Texture` or `Sprite` instance — hard failure if `Image` component or any other type is passed

---

## Key Normalizations

- These properties sit at precedence level 1 in the styling resolution cascade (direct instance property). They do not replace the skin/token system — they override it per-property only.
- No shorthand aliases are introduced (e.g., no `borderWidth` shorthand for all four sides). The spec does not define any.
- The schema does not validate that only one background source is set — that is a rendering concern resolved at paint time by source selection priority.

---

## Verification

- Set `backgroundColor = {1, 0, 0}` on a Drawable instance — no error
- Set `backgroundColor = "purple"` — hard failure at schema validation
- Set `backgroundOpacity = 1.5` — hard failure
- Set `borderWidthTop = -1` — hard failure
- Set `backgroundImage = ImageInstance` — hard failure (wrong type)
- Set `backgroundGradient = { kind="linear", direction="horizontal", colors={{1,0,0},{0,0,1}} }` — no error
- Set `backgroundGradient = { kind="linear", direction="horizontal", colors={{1,0,0}} }` — hard failure (fewer than two colors)
- Nil for any property — no error, falls through at render time
