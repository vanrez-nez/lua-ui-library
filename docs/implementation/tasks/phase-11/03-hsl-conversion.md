# Task 03: HSL And HSLA Conversion

## Goal

Extend `Color.resolve` to parse `hsl(...)` and `hsla(...)` string inputs and convert them to RGBA using a correct HSL→RGB algorithm.

## Spec Anchors

- `docs/spec/ui-styling-spec.md §5.3` — HSL and HSLA as accepted input forms
- `docs/spec/ui-styling-spec.md §5.4` — accepted argument forms, component rules, hue wrapping, failure on saturation/lightness/alpha outside `[0, 1]`
- `docs/spec/ui-styling-spec.md §13` — hard-failure: opacity outside `[0, 1]`

## Scope

- Parse `hsl(h, s, l)` and `hsla(h, s, l, a)` string patterns
- Validate component ranges per spec
- Implement HSL→RGB conversion from scratch
- Integrate into `Color.resolve` string routing

## Concrete Module Targets

- Extend `lib/ui/render/color.lua`

## Implementation Guidance

**String parsing:**

Use Lua pattern matching to extract numeric arguments:

```lua
local h, s, l    = input:match("^hsl%s*%((.-),%s*(.-),%s*(.-)%s*%)$")
local h, s, l, a = input:match("^hsla%s*%((.-),%s*(.-),%s*(.-),%s*(.-)%s*%)$")
```

Convert captures to `tonumber`. If any capture fails to convert, the input is malformed — hard failure.

**Validation:**

- `hue`: any finite numeric value. Wrap via `hue = hue % 360`. If `hue < 0`, add 360 after modulo.
- `saturation`: must be in `[0, 1]`. Outside this range is a hard failure.
- `lightness`: must be in `[0, 1]`. Outside this range is a hard failure.
- `alpha`: optional, defaults to `1`. When present must be in `[0, 1]`. Outside is a hard failure.

**HSL → RGB algorithm:**

Do NOT adapt from `reference/color.lua`. That module implements HSV, not HSL. The algorithms differ in the chroma and lightness model. Using HSV for HSL inputs produces wrong colors.

Write the standard HSL→RGB conversion:

```
C = (1 - |2L - 1|) * S        -- chroma
H' = H / 60
X = C * (1 - |H' mod 2 - 1|)

(R1, G1, B1) from H' sector (0-5)
m = L - C/2
R, G, B = R1 + m, G1 + m, B1 + m
```

All intermediate and output values in `[0, 1]`.

**Port from `reference/color.lua`:** The `lerp` scalar function `a + s * (b - a)` appears in `reference/color.lua` at `color.lerp`. This arithmetic can be ported as a plain local function for any intermediate interpolation steps. No import, no metatable — copy the expression only. Operates in `[0, 1]` space (the reference version works in `[0, 255]` but the expression is numerically identical regardless of space).

**String routing addition:**

```lua
if input:sub(1, 4) == "hsl(" or input:sub(1, 5) == "hsla(" then
    return parse_hsl(input)
end
```

This check runs before the catch-all unsupported-string error.

## Required Behavior

- `"hsl(0, 1, 0.5)"` → `{1, 0, 0, 1}` (pure red)
- `"hsl(120, 1, 0.5)"` → `{0, 1, 0, 1}` (pure green)
- `"hsl(240, 1, 0.5)"` → `{0, 0, 1, 1}` (pure blue)
- `"hsl(0, 0, 1)"` → `{1, 1, 1, 1}` (white via full lightness)
- `"hsl(0, 0, 0)"` → `{0, 0, 0, 1}` (black via zero lightness)
- `"hsla(0, 1, 0.5, 0.5)"` → `{1, 0, 0, 0.5}`
- `"hsl(360, 1, 0.5)"` → same as `"hsl(0, 1, 0.5)"` — hue wraps
- `"hsl(720, 1, 0.5)"` → same as `"hsl(0, 1, 0.5)"` — hue wraps
- `"hsl(-90, 1, 0.5)"` → same as `"hsl(270, 1, 0.5)"` — negative hue wraps
- `"hsl(0, 1.5, 0.5)"` → hard failure (saturation out of range)
- `"hsl(0, 1, 1.5)"` → hard failure (lightness out of range)
- `"hsla(0, 1, 0.5, 1.5)"` → hard failure (alpha out of range)
- `"hsl(0, 1)"` → hard failure (missing lightness argument)
- `"hsl()"` → hard failure

## Non-Goals

- No HSV input form.
- No CSS percentage notation (e.g., `hsl(0, 100%, 50%)`) — the spec uses normalized `[0, 1]` for saturation and lightness.
- No color interpolation utilities in this task — that is a rendering concern for Phase 13.

## Acceptance Checks

- All required behavior cases pass.
- Hue wrapping works for values well beyond 360 and for negative values.
- Hard failures for out-of-range saturation, lightness, and alpha produce readable error messages.
- The HSL conversion produces visually correct colors for the primary hue sectors (red, yellow, green, cyan, blue, magenta).
- No reference to `reference/color.lua` in the implementation.
