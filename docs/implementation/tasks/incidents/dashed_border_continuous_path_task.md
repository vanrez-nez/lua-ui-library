# Implementation Task: Continuous-Path Dashed Border Renderer

## Summary

Implement the consolidated dashed-border contract with two internal renderer
paths:

- a uniform-width fast path guided by
  [`border-fallback.lua`](/Users/vanrez/Documents/game-dev/lua-ui-library/border-fallback.lua)
- a mixed-width compatibility path used only when resolved border widths differ

The dominant uniform-width case must preserve the proof-of-concept performance
shape: one continuous perimeter-distance traversal with no extra procedural
splitting added solely to support mixed-width borders.

## Public Contract To Preserve

Keep the public styling surface unchanged:

- `borderPattern`
- `borderDashLength`
- `borderGapLength`
- `borderWidthTop`
- `borderWidthRight`
- `borderWidthBottom`
- `borderWidthLeft`
- corner-radius properties

Dashed-border behavior to implement:

- dash placement is measured from cumulative distance along the rendered border
  perimeter
- straight segments and rounded corners participate in the same distance model
- dash and gap lengths are approximate rather than pixel-perfect
- `borderGapLength = 0` may collapse to a solid fast path
- sides with resolved border width `0` paint nothing

## Renderer Design

### Uniform-Width Fast Path

Use this path when all resolved border widths are equal and greater than zero.

Requirements:

- preserve a continuous perimeter-distance dash phase
- keep rounded corners in the same phase model as straight segments
- do not introduce mixed-width-only splitting or state changes on this path
- prefer native or pattern-based host primitives first when they satisfy the
  contract
- use custom construction only as fallback

`border-fallback.lua` is the algorithmic guide for this path:

- cumulative perimeter-distance traversal
- dash placement derived from distance along the full border
- corner geometry kept visually in sync with the same distance model

### Mixed-Width Compatibility Path

Use this path only when the resolved side widths differ.

Requirements:

- preserve support for per-side resolved border widths
- allow additional procedural splitting and line-width changes only on this
  path
- define an explicit corner-width rule for transitions between adjacent sides
- keep behavior deterministic even if the geometry must be segmented

This path does not need to match the draw-call profile of the uniform path.

## Acceptance Criteria

- Uniform dashed rectangle with no radii renders as one continuous dashed
  perimeter with no side-boundary phase restart.
- Uniform dashed rounded rectangle keeps corners visually in phase with the
  surrounding straight segments.
- Uniform dashed borders do not pay additional procedural cost caused only by
  mixed-width support.
- Mixed-width dashed borders remain supported and paint every non-zero side.
- `borderGapLength = 0` still behaves as a solid-border optimization.
- Validation rules for dash/gap limits and cycle `<= 255` remain unchanged.

## Suggested Verification

- Add or update demo coverage for uniform dashed rectangles and rounded
  rectangles.
- Add mixed-width dashed examples to verify the compatibility path remains
  functional.
- Profile the uniform-width dashed case before and after the implementation to
  confirm the fast path preserves the intended performance shape.
