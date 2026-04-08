# Spec Patch: Foundation Anchor And Pivot Contract

## Goal

Resolve the `Container`-level contract for:

- `anchorX`
- `anchorY`
- `pivotX`
- `pivotY`

This patch is a review of what should go into the published spec text in
`docs/spec/ui-foundation-spec.md`.

## Affected Spec Surface

Patch:

- [docs/spec/ui-foundation-spec.md](/Users/vanrez/Documents/game-dev/lua-ui-library/docs/spec/ui-foundation-spec.md)

No additional spec patch is required outside foundation for this contract.

## Contract To Add

Insert this block immediately after the `Container` props list:

```text
Anchor and pivot semantics:

- `pivotX` and `pivotY` define the node's local transform origin. Rotation,
  scaling, and skewing occur relative to this pivot.
- `anchorX` and `anchorY` define the node's parent-relative attachment basis.
  They determine how the node attaches to or is measured from its parent region.

`pivotX` and `pivotY` are normalized local-space coefficients, not absolute
offsets.
`anchorX` and `anchorY` are normalized parent-space coefficients, not absolute
offsets.

Default pivot values:

- `pivotX = 0.5`
- `pivotY = 0.5`

Default anchor values:

- `anchorX = 0.0`
- `anchorY = 0.0`

These defaults are part of the stable public `Container` surface.
```

## Resulting Spec Meaning

- `pivot` answers where local transforms happen
- `anchor` answers how the node attaches to or is measured from its parent
- omitted `pivotX` / `pivotY` resolve to center-based local transforms
- omitted `anchorX` / `anchorY` resolve to origin-based parent attachment

## Scope Boundary

This patch does not:

- change the meaning of `x` or `y`
- define component-specific overrides
- define shape-specific defaults
- add any new props

## Notes

This document supersedes the split drafts for anchor semantics/defaults and
pivot defaults by combining them into one foundation patch review.
