# Task 02: Corner Radius Resolution

## Goal

Implement the overflow-protected corner radius resolution function. Given the four raw corner radius values from `props` and the node's `bounds`, produce a `resolved_radii` table with all four values scaled so that adjacent radii never exceed the available side length. This table is passed to all subsequent paint steps.

## Spec Anchors

- `docs/spec/ui-styling-spec.md §8` — corner radius definitions and the overflow-protection proportional scale-down rule

## Scope

- Modify `lib/ui/render/styling.lua`
- Replace the stub `resolved_radii` in `Styling.draw` with the output of a new local function `resolve_radii(props, bounds)`
- `resolve_radii` is a local (file-private) function

## Concrete Module Targets

- `lib/ui/render/styling.lua` — modified only

## Implementation Guidance

**Input:**

Read the four corner radius properties from `props`:
- `props.cornerRadiusTopLeft` (nil treated as `0`)
- `props.cornerRadiusTopRight` (nil treated as `0`)
- `props.cornerRadiusBottomRight` (nil treated as `0`)
- `props.cornerRadiusBottomLeft` (nil treated as `0`)

**Overflow check and scale-down:**

Apply four independent scale checks, in any order. Each check may reduce one or two values; apply all reductions before returning.

- Top side: if `tl + tr > bounds.width`, compute `scale = bounds.width / (tl + tr)` and set `tl = tl * scale`, `tr = tr * scale`
- Bottom side: if `bl + br > bounds.width`, compute `scale = bounds.width / (bl + br)` and set `bl = bl * scale`, `br = br * scale`
- Left side: if `tl + bl > bounds.height`, compute `scale = bounds.height / (tl + bl)` and set `tl = tl * scale`, `bl = bl * scale`
- Right side: if `tr + br > bounds.height`, compute `scale = bounds.height / (tr + br)` and set `tr = tr * scale`, `br = br * scale`

The scale checks must all be evaluated using the values as modified by prior checks — order matters. Run them in the sequence listed above so that horizontal constraints are applied before vertical constraints pick up the already-adjusted values.

**Output:**

Return a table:
```
{ tl = ..., tr = ..., br = ..., bl = ... }
```

All four fields are numbers `>= 0`. If all input radii were nil, all four fields are `0`.

**Integration:**

Call `resolve_radii(props, bounds)` at the top of `Styling.draw`, immediately after argument validation. Pass the result as the fourth argument to all four paint step functions.

## Required Behavior

- All radii nil, any bounds → `{ tl=0, tr=0, br=0, bl=0 }`
- `tl=8, tr=8, bl=8, br=8`, bounds `100×100` → no scale-down, all return as `8`
- `tl=60, tr=60`, bounds `100×100` (top sum = 120 > 100) → scale = 100/120 ≈ 0.833, `tl ≈ 50`, `tr ≈ 50`
- `tl=100, tr=100, bl=0, br=0`, bounds `100×200` → top side: scale = 100/200 = 0.5, `tl=50, tr=50`; left side: `tl + bl = 50 + 0 = 50 <= 200` → no further change
- `tl=200, tr=0, bl=200, br=0`, bounds `100×100` → top side: `tl=200` alone but `200+0=200 > 100`, scale=0.5, `tl=100`; left side: `100+200=300 > 100`, scale=100/300, `tl≈33`, `bl≈66`
- `tl=50, tr=50, bl=50, br=50`, bounds `50×50` → top: `100>50`, scale=0.5, `tl=25,tr=25`; bottom: `100>50`, scale=0.5, `bl=25,br=25`; left: `50==50` → no change; right: `50==50` → no change → `{tl=25,tr=25,br=25,bl=25}`

## Non-Goals

- No caching of resolved radii between frames — resolution is cheap and bounds can change.
- No validation that raw radius values are non-negative — that is Phase 12's responsibility.
- No rounding of resolved values to integers — sub-pixel radii are valid.

## Acceptance Checks

- All required behavior cases produce the documented result.
- When all radii are zero, no scale-down is performed and the output is all zeros.
- The function never returns a negative value for any radius.
- `Styling.draw` uses the resolved radii (not raw props values) when calling paint steps.
