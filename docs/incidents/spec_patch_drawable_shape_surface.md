# Incident: `Shape` Primitive Patch Draft

## Status

Draft only. No direct changes have been applied to `docs/spec`.

This patch draft supersedes the earlier direction that placed shape support on
`Drawable`.

## Problem

The earlier direction added shape to `Drawable`.

That is the wrong inheritance boundary. `Drawable` already owns a broad surface:
content-box semantics, padding and alignment, theming and skinning, render
effects, and a broad set of styling families. Most of that surface has no
coherent meaning on a geometric shape primitive.

Attaching shape to `Drawable` forces one of two bad outcomes:

- shapes inherit a large surface that does not apply to them
- or that surface is selectively overridden and hollowed out

Neither produces a clean primitive model.

Shapes still need retained-node interaction behavior equivalent to other
render-capable nodes: mouse and touch targeting, hover ownership, press and drag
containment checks. The correct answer is not to remove shapes from the retained
tree, but to give them their own primitive boundary.

## Goals

Define a first-class `Shape` primitive that:

- extends `Container`, not `Drawable`
- is render-capable
- participates in mouse and touch targeting through the existing Stage path
- uses the existing public containment name
- is narrow enough to be a stable v1

## Proposed Primitive

Introduce `Shape` as a render-capable primitive extending `Container`.

`Shape` is parallel to `Drawable` in the foundation taxonomy. It does not
inherit the `Drawable` content-box, styling, or effect contract.

First concrete classes:

- `RectShape`
- `CircleShape`
- `TriangleShape`
- `DiamondShape`

## Public Surface

The v1 surface is fill-only.

Approved props:

- `fillColor`
- `fillOpacity`

Deferred from v1:

- `strokeColor`, `strokeOpacity`, `strokeWidth`
- all `Drawable` styling families: `background*`, `border*`, `cornerRadius*`,
  `shadow*`
- `skin`, `shader`, `mask`, `blendMode`
- `padding`, `alignX`, `alignY`

This patch does not partially define these surfaces. They are absent rather than
present-but-unresolved.

## Interaction Contract

Shapes participate in mouse and touch targeting through the same retained-tree
path used by other interactive nodes.

The public containment method is:

- `containsPoint(x, y)`

This name is reused deliberately. Stage already routes input through
`containsPoint`, `_is_effectively_targetable`, and `_hit_test_resolved`. If
`Shape` introduced a parallel name, the runtime would need to learn a second
targeting vocabulary for no gain.

### Containment Model

`Shape:containsPoint(x, y)` should:

1. accept a world-space point
2. apply the node's inverse world transform to get a local-space point
3. delegate local containment to a shape-family hook

Protected hook:

- `_contains_local_point(local_x, local_y)`

Base behavior on `Shape`:

- rectangular fallback against local bounds

Concrete override model:

- `RectShape` inherits the base rectangular fallback unchanged
- `CircleShape`, `TriangleShape`, and `DiamondShape` each override
  `_contains_local_point` for their geometry

### Transform Rule

Shape geometry is defined in local node space. Point containment is always
evaluated in that space after inverse transform.

The stable containment rule is: **inverse-transform first, local geometry test
second.**

This applies uniformly to translation, rotation, scale, skew, and
pivot-driven transforms. Containment is not computed as a world-space polygon
procedure.

## Coordinate System And Canonical Geometry

All shapes are defined in local node space:

- origin at the top-left corner of the node's border box
- `x` increases to the right
- `y` increases downward

### `RectShape`

Uses the full local border box rectangle. This is the base containment fallback.

### `CircleShape`

The name `circle` is a convention, not a guarantee of equal radii.

`CircleShape` means the ellipse inscribed in the node's border box:

- when `width == height`, the result is a true circle
- when `width ~= height`, the result is an ellipse

Padding affects only the content box, not the outer silhouette.

### `TriangleShape`

An upright isosceles triangle inscribed in the node's border box.

Canonical vertices (local space):

- top-center
- bottom-right
- bottom-left

Implications:

- the default local-space triangle points upward
- no equilateral guarantee is implied
- no per-shape orientation prop exists in v1
- downward or sideways triangles are achieved by generic node rotation

### `DiamondShape`

A four-point polygon using the edge midpoints of the border box.

Canonical vertices (local space):

- top-center
- right-center
- bottom-center
- left-center

Implications:

- the diamond follows the node's aspect ratio
- it is a fixed preset silhouette, not a freeform rhombus API

## Composition And Layout Boundaries

`Shape` derives from `Container` and retains a rectangular node bounds box for
transform, layout, and ancestry purposes.

### Layout Footprint

Layout participation remains rectangular. A shape occupies its full rectangular
footprint regardless of its visible silhouette. Transparent corners and dead
zones do not reduce that footprint.

### Descendant Clipping

`clipChildren` remains rectangular and bounds-based, owned by `Container`.

A non-rect or rotated shape with `clipChildren` enabled clips descendants to its
rectangular bounds, not to its visible silhouette. A child node may be visible
inside the rectangular clip region while appearing outside the visible diamond or
triangle. **This mismatch should be documented explicitly as a v1 limitation.**

Recommended author guidance for v1:

- do not rely on non-rect `Shape` nodes as silhouette clips for descendants
- use shapes for node-local presentation and interaction, not descendant masking

### Leaf-Only Rule

Even though `Shape` derives from `Container`, v1 should reject child
composition.

This keeps the primitive focused on geometry, paint, and interaction. Admitting
children would reopen content-box and descendant-layout questions under a new
name without a defined answer.

## First-Revision Exclusions

Not approved in this patch:

- shape support on `Drawable`
- arbitrary polygons and curved freeform silhouettes
- `star`, `heart`
- stroke and border semantics
- shadow semantics
- shape-aware clipping
- shape-aware layout footprints
- per-shape orientation props

## Decisions Required Before Publication

### 1. `circle` Naming

The name `circle` describes an ellipse for non-square nodes by explicit contract.
This should be stated in the spec as a named convention rather than left
implicit.

### 2. Rectangular Clipping Mismatch

`clipChildren` remains bounds-based in v1. The visible mismatch described above
must be documented as an explicit v1 limitation, not treated as an unresolved
edge case.

### 3. Stroke Semantics

Stroke props are deferred. The spec should state explicitly that `Shape` in v1
has no stroke surface, not merely omit those props silently.

## Acceptance Criteria

A correct implementation satisfies all of the following:

- `Shape` participates in Stage mouse and touch targeting through the existing
  spatial target-resolution path
- `RectShape` uses the base rectangular fallback without custom containment math
- `CircleShape`, `TriangleShape`, and `DiamondShape` each override
  `_contains_local_point`
- containment is evaluated in inverse-transformed local space, so transforms
  affect hit testing correctly
- hover, press/release, and drag-start all respect the transformed visible
  silhouette
- mixed sibling trees containing `Container`, `Drawable`, and `Shape` preserve
  normal z-order targeting
- `clipChildren` remains rectangular on shapes
- `Shape` rejects child composition in v1
- the drawn silhouette and hit silhouette match for each concrete shape class

## Recommended Spec Patch Direction

The follow-up spec patch should:

- add `Shape` to the foundation primitive taxonomy
- define its v1 fill-only public surface
- define `containsPoint` and `_contains_local_point` as the retained interaction
  contract
- define canonical local-space geometry for each approved concrete class
- document rectangular layout footprint and rectangular clipping as explicit v1
  constraints

Implementation review should begin only after that spec text is written.

## References

- [UI Foundation Specification](../spec/ui-foundation-spec.md)
- [`lib/ui/core/container.lua`](../../lib/ui/core/container.lua)
- [`lib/ui/core/drawable.lua`](../../lib/ui/core/drawable.lua)
- [`lib/ui/scene/stage.lua`](../../lib/ui/scene/stage.lua)
- existing `docs/incidents/spec_patch_*` documents for incident format and tone