# Spec Patch: Add Dashed Border Offset

## Summary

The current dashed-border contract defines:

- `borderPattern`
- `borderDashLength`
- `borderGapLength`

but it does not expose a public way to control dash phase along the resolved
border perimeter.

This makes it impossible to intentionally:

- shift the starting point of a dashed border
- synchronize multiple dashed borders visually
- animate dashed borders through styling updates

This should be a small additive change.

---

## Proposed Addition

Add one new styling property:

- `borderDashOffset: number`

Meaning:

- expressed in logical units
- defaults to `0`
- applies only when `borderPattern = "dashed"`
- shifts the dash phase along the resolved border perimeter

When `borderDashOffset = 0`, behavior remains unchanged.

Positive values should advance the dash pattern forward along the same
perimeter traversal used by the dashed-border contract.

Negative values are valid and shift the phase in the opposite direction.

---

## Why

This is useful for:

- simple dashed-border animation
- deliberate visual alignment between related borders
- avoiding renderer-only debug hooks for phase inspection

It fits the current continuous-perimeter dashed model cleanly and does not
require changing existing dash/gap semantics.

---

## Non-Goals

This patch does not:

- change `borderDashLength`
- change `borderGapLength`
- change the continuous-perimeter dashed model
- require automatic animation behavior

Animation remains user-driven by updating `borderDashOffset` over time.

---

## Open Question

One small point to confirm during implementation:

- whether the spec should say "positive offset advances forward along the
  perimeter traversal" or use a more user-facing directional term like
  "clockwise" when the resolved border geometry is rectangular

I recommend using perimeter-traversal language, since it stays correct for
rounded and mixed-width geometry too.
