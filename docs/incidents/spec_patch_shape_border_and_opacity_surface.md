# Spec Patch: Shape Stroke Surface And Node Opacity

## Summary

This patch adds a stroke surface and node-level opacity to `Shape`.

The stroke surface is shape-owned. It does not reuse `Drawable` border prop
names and does not inherit the `Drawable` border contract. It is defined
independently as a geometric outline vocabulary appropriate for silhouette-based
primitives.

Props added to `Shape` in this patch:

- `strokeColor`
- `strokeOpacity`
- `strokeWidth`
- `strokeStyle`
- `strokeJoin`
- `strokeMiterLimit`
- `strokePattern`
- `strokeDashLength`
- `strokeGapLength`
- `strokeDashOffset`
- `opacity`

This surface is intentionally narrower than `Drawable`:

- no `borderColor`, `borderOpacity`, `borderWidth`, or any `border*` name
- no `borderWidthTop/Right/Bottom/Left`
- no `background*`
- no `cornerRadius*`
- no `shadow*`
- no `skin`, `shader`, `mask`, `blendMode`
- no per-segment or edge-owned props

`Shape` remains a `Container` subclass parallel to `Drawable`. This patch does
not change that taxonomy.

---

## Decisions

### 1. Stroke Props Use Shape-Owned Names, Not `Drawable` Border Names

`Shape` does not expose any `border*` prop.

The outline surface is named `stroke*` throughout. This is not a cosmetic
rename. It reflects that the stroke contract on `Shape` is independently
defined and does not inherit validation rules, input forms, or semantics from
the `Drawable` border family.

Within that shape-owned family, `strokeStyle` and `strokePattern` follow the
same semantic split used by `Drawable.borderStyle` and
`Drawable.borderPattern`:

- `strokeStyle` controls line quality
- `strokePattern` controls solid versus dashed segmentation

Consequence: there is no compatibility constraint between `Shape.strokeWidth`
and `Drawable.borderWidth`. They are different props on different primitives
with different contracts.

### 2. `strokeWidth` Is Scalar-Only

`strokeWidth` on `Shape` accepts a single non-negative finite number.

It does not accept `SideQuad` input. Per-side stroke widths have no coherent
meaning on non-rect silhouettes and are not part of the shape stroke contract.

Default: `0`. No stroke paints unless `strokeWidth` is explicitly set to a
positive value.

### 3. Stroke Is Center-Aligned On The Silhouette

The stroke is center-aligned on the canonical shape outline.

- half the resolved `strokeWidth` paints inward from the silhouette
- half the resolved `strokeWidth` paints outward from the silhouette
- stroke painting does not alter layout footprint
- stroke painting does not alter `containsPoint`

Hit testing remains silhouette-based on the fill geometry. Outward stroke
extent does not expand the interactive region.

Inside-only and outside-only stroke placement are deferred to a later patch.

### 4. No Stroke Paints Without `strokeColor`

There is no implicit default stroke color.

If `strokeColor` is absent, no stroke paints regardless of `strokeWidth`.

The alpha composition when stroke does paint is:

```
stroke alpha = strokeColor.alpha * strokeOpacity * opacity
```

### 5. `opacity` Requires Generalized Render-Capable-Node Compositing

`Shape.opacity` is a whole-node alpha control.

It is not a fill-only or stroke-only modulation. It applies to the fully
composited shape result uniformly.

Final alpha values:

```
fill alpha   = fillColor.alpha * fillOpacity * opacity
stroke alpha = strokeColor.alpha * strokeOpacity * opacity
```

`opacity` does not alter hit testing or layout.

Implementing `Shape.opacity` requires generalizing node-level opacity isolation
from `Drawable` to all render-capable retained nodes. This must not be
implemented as a per-shape paint-level alpha hack. It is a foundation-level
render path change.

This is a publication requirement. `Shape.opacity` must not ship until that
generalized compositing path exists and motion-driven `opacity` is verified to
work on `Shape` through the same retained path used by `Drawable`.

Default: `1`.

### 6. `strokeJoin` Applies At Discrete Vertices Only

`strokeJoin` is valid on all concrete `Shape` classes.

On shapes with discrete corners — `RectShape`, `TriangleShape`, `DiamondShape`
— `strokeJoin` controls the join geometry at each vertex.

On `CircleShape`, which has no discrete joins, `strokeJoin` is accepted and
has no visual effect. It must not warn and must not fail.

Accepted values: `"miter"`, `"bevel"`, `"none"`.

Default: `"miter"`.

### 7. `strokeMiterLimit` Applies When `strokeJoin` Is `"miter"`

`strokeMiterLimit` is valid on all concrete `Shape` classes.

It has no visual effect when `strokeJoin` is not `"miter"` or when the shape
has no discrete corners.

Default: `10`.

### 8. Dashed Stroke Uses Polyline Approximation

Dashed stroke traversal uses the same polygonal approximation as fill
geometry. It does not use true ellipse arc stepping.

This keeps fill edge and stroke center geometrically coupled by construction.
A separate arc-stepping path for `CircleShape` stroke would introduce visible
misalignment between the fill boundary and the stroke center at low segment
counts.

The approximation resolution for `CircleShape` is shared between fill and
stroke rendering. The public contract is approximation-friendly.

### 9. Canonical Perimeter Traversal Is Defined Per Shape

Dash phase is computed as cumulative perimeter distance from a canonical start
point, traveling clockwise in local node space.

Canonical traversal start points:

- `RectShape`: top-left corner
- `CircleShape`: top-center of the inscribed ellipse
- `TriangleShape`: top vertex
- `DiamondShape`: top-center vertex

`strokeDashOffset` advances or reverses phase along that traversal. A positive
offset shifts the pattern forward along the path.

### 10. `strokeColor` Has No Default

`strokeColor` is unset by default.

No stroke paints unless `strokeColor` is explicitly provided and `strokeWidth`
is greater than zero.

---

## Public Contract

### Props Added To `Shape`

```text
strokeColor       -- color value, no default, required for stroke to paint
strokeOpacity     -- number, clamped [0, 1], default 1
strokeWidth       -- non-negative finite number, scalar only, default 0
strokeStyle       -- "smooth" | "rough", default "smooth"
strokeJoin        -- "miter" | "bevel" | "none", default "miter"
strokeMiterLimit  -- positive finite number, default 10
strokePattern     -- "solid" | "dashed", default "solid"
strokeDashLength  -- positive finite number, default 8
strokeGapLength   -- non-negative finite number, default 4
strokeDashOffset  -- finite number, default 0
opacity           -- number, clamped [0, 1], default 1
```

### Props Explicitly Rejected On `Shape`

```text
borderColor, borderOpacity, borderWidth
borderWidthTop, borderWidthRight, borderWidthBottom, borderWidthLeft
borderStyle, borderJoin, borderMiterLimit
borderPattern, borderDashLength, borderGapLength, borderDashOffset
background*, cornerRadius*, shadow*
skin, shader, mask, blendMode
padding, alignX, alignY
```

Rejected props must fail validation, not silently ignore.

---

## Stroke Semantics Per Shape

### `RectShape`

- rectangular outline at the border-box boundary
- four discrete corners, all subject to `strokeJoin`
- perimeter traversal: top-left → top-right → bottom-right → bottom-left →
  back to top-left

### `CircleShape`

- ellipse outline inscribed in the border box
- no discrete joins, `strokeJoin` and `strokeMiterLimit` accepted and inert
- perimeter traversal: clockwise from top-center using the shared polygon
  approximation

### `TriangleShape`

- three-edge polygon outline following canonical vertices: top-center,
  bottom-right, bottom-left
- three discrete corners, all subject to `strokeJoin`
- note: the top vertex is acute for non-square bounds — `"miter"` join will
  spike at high `strokeWidth` values; authors should use `strokeMiterLimit`
  to control this
- perimeter traversal: top → bottom-right → bottom-left → back to top

### `DiamondShape`

- four-edge polygon outline following canonical vertices: top, right, bottom,
  left
- four discrete corners, all subject to `strokeJoin`
- perimeter traversal: top → right → bottom → left → back to top

---

## What Does Not Change

- `Shape` remains a `Container` subclass, not a `Drawable` subclass
- `Shape` remains leaf-only
- `Shape` layout footprint remains rectangular
- `Shape` hit testing remains silhouette-based on fill geometry
- `pivotX` and `pivotY` are unaffected
- `anchorX` and `anchorY` are unaffected
- `fillColor` and `fillOpacity` are unaffected
- `get_local_centroid()` and `set_centroid_pivot()` are unaffected

---

## Spec Work Required

### 1. Patch `ui-foundation-spec.md`

- add `opacity` and all `stroke*` props to the `Shape` section
- define stroke placement as center-aligned on the silhouette
- define that stroke does not affect hit testing or layout footprint
- define the canonical traversal start points per shape
- state that `border*` props remain rejected on `Shape`

### 2. Patch `ui-styling-spec.md`

- broaden the whole-node opacity statement from `Drawable`-only to
  render-capable-node
- add a `Shape` stroke section that defines the `stroke*` family as a
  shape-owned contract independent of the `Drawable` border family
- explicitly state that `Shape.strokeWidth` is scalar-only and does not use
  `SideQuad` input

### 3. Patch `phase-18` Planning Docs

- replace the blanket border/stroke exclusion with the narrower statement:
  `Shape` gains a shape-owned `stroke*` surface and node `opacity`; it does
  not inherit the `Drawable` border or styling pipeline

---

## Implementation Work Required

### 1. Schema And Surface

Files:

- `lib/ui/core/shape_schema.lua`
- `spec/shape_primitive_surface_spec.lua`

Changes:

- add `opacity` and all approved `stroke*` props
- validate `strokeWidth` as scalar-only
- reject all `border*` props explicitly
- reject background/radius/shadow/skin/shader/mask/blend props

### 2. Shape Stroke Renderer

Files:

- `lib/ui/core/shape.lua`
- `lib/ui/shapes/rect_shape.lua`
- `lib/ui/shapes/circle_shape.lua`
- `lib/ui/shapes/triangle_shape.lua`
- `lib/ui/shapes/diamond_shape.lua`
- one new shared shape stroke helper module

Changes:

- add stroke paint pass after fill
- use canonical local geometry for both draw and containment
- implement center-aligned stroke using the shared polygon approximation
- implement dashed traversal using cumulative perimeter distance from the
  canonical start point
- implement join geometry at discrete vertices for polygon shapes
- `CircleShape` stroke uses the same approximation segments as fill

The current `Drawable` border renderer must not be reused here. It assumes
rectangular bounds and per-side widths. A separate shape-stroke helper should
own the stroke path independently.

### 3. Node Opacity Runtime

Files:

- `lib/ui/core/container.lua`
- possibly `lib/ui/core/shape.lua`
- shape render specs

The current opacity compositing path is gated to `_ui_drawable_instance`.

Required change: generalize node-level opacity isolation to all render-capable
retained nodes. This is a foundation render path change, not a per-shape alpha
multiply.

`Shape.opacity` must not ship until this generalization is in place and
motion-driven opacity on `Shape` is verified through the retained motion path.

### 4. Tests

Required coverage:

- `Shape` accepts all new `stroke*` props and `opacity`
- `Shape` rejects all `border*` props
- `strokeWidth` rejects non-scalar input
- `strokeWidth = 0` paints no stroke
- absent `strokeColor` paints no stroke regardless of `strokeWidth`
- `opacity` defaults to `1`
- `opacity = 0` keeps the node targetable
- motion-driven `opacity` works on `Shape`
- stroke alpha composes correctly from `strokeColor`, `strokeOpacity`, and
  `opacity`
- dashed stroke uses cumulative perimeter phase from the canonical start point
- `strokeJoin` affects polygon corners on `RectShape`, `TriangleShape`,
  `DiamondShape`
- `strokeJoin` on `CircleShape` does not fail and has no visual effect
- acute triangle vertex with high `strokeWidth` and `"miter"` join is clamped
  by `strokeMiterLimit`

---

## Non-Goals

This patch does not propose:

- making `Shape` a subtype of `Drawable`
- reusing any `border*` prop name on `Shape`
- inside or outside stroke placement
- per-segment or edge-owned stroke props
- adding `cornerRadius` to `RectShape`
- changing `Shape` layout footprint
- changing `Shape` hit testing to include outward stroke extent
- shape-aware clipping for descendants
- skins, tokens, named parts, shader, mask, or blend support on `Shape`
- `strokePattern` beyond the `"solid"` and `"dashed"` values already defined
