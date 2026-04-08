# Spec Patch: Normalize Graphics Capabilities Across Drawable And Shape

## Part 3: Shape-Owned Fill Sources And Texture

---

## Summary

This part defines the complete contract for shape-owned fill sources, covering
gradient-backed and texture-backed fill on `Shape`.

This part closes the following items deferred from Part 1:

- fill source placement algorithm
- stretch versus intrinsic-size placement model
- gradient direction mapping into local shape space
- sprite sub-region mapping into local shape space
- silhouette clipping implementation semantics
- fill repetition scope for this revision
- rendering strategy for textured silhouette fill
- fill source interaction with stroke rendering order

---

## Document Series

- **Part 1: Model And Boundaries** — closed
- **Part 2: Shared Root Compositing** — closed
- **Part 3: Shape-Owned Fill Sources And Texture** — this document

All decisions in Parts 1 and 2 are authoritative. This part extends them.
Fill source rendering is part of step 1 of the canonical compositing order
defined in Part 1: resolving the node's own local paint result. Fill source
rendering precedes root shader, root opacity, and root blend mode application.
Textured fill does not trigger subtree isolation by itself. Isolation is driven
solely by the compositing state record defined in Part 2.

---

## What This Part Decides

Decisions made and closed in this part:

- fill sources are resolved from the shape's local bounds AABB
- default placement behavior without repetition is stretch-to-bounds
- with repetition enabled, the source tiles at its intrinsic dimensions
- fillAlign and fillOffset apply only in the tiling model, not in stretch mode
- gradient fill always spans the full local bounds in the resolved direction
- gradient direction maps horizontally left-to-right and vertically
  top-to-bottom across local bounds
- sprite effective dimensions are always sub-region dimensions; placement uses
  sub-region dimensions in all cases
- all fill pixels outside the shape silhouette are discarded before the result
  is handed to the compositing stage
- stroke is drawn after fill, on top of the composited fill result, within
  the shape-local paint result; silhouette clipping applies to fill, not to
  stroke separately
- fill repetition is included in this revision for both axes
- the rendering strategy is geometry-backed fill with silhouette clipping
  through stencil or equivalent mechanism; offscreen canvas is not the primary
  path
- multiple fill source properties may coexist as set values; exactly one is
  active at render time per the priority rule in Part 1
- gradient fill does not participate in fillAlign or fillOffset

Items not in scope for this part:

- multiple stacked fill layers
- arbitrary UV transforms
- freeform geometry mapping modes
- mask interaction
- shader-specific texture parameter conventions
- shape-aware descendant clipping

---

## Fill Source Surface

The shape-owned fill source surface is:

- `fillColor`
- `fillOpacity`
- `fillGradient`
- `fillTexture`
- `fillRepeatX`
- `fillRepeatY`
- `fillOffsetX`
- `fillOffsetY`
- `fillAlignX`
- `fillAlignY`

Value domains, constraint rules, priority resolution, and gradient contract
reference are defined in Part 1, Interface 4. This part defines how those
values are placed and rendered.

---

## Placement Basis

All fill source placement is resolved against the shape's local bounds AABB.

Local bounds are the axis-aligned bounding box of the shape's silhouette in
its own local coordinate space.

This is the reference geometry for:

- stretch-to-bounds calculation
- tiling origin derivation
- alignment positioning within bounds
- offset application

No placement mode references parent geometry, styled box geometry, or any
coordinate space outside the shape's own local space.

---

## Placement Model

### Stretch Mode

Stretch mode is active when both `fillRepeatX` and `fillRepeatY` are `false`.

In stretch mode:

- the fill source is scaled to exactly fill the local bounds AABB
- `fillAlignX`, `fillAlignY`, `fillOffsetX`, and `fillOffsetY` have no effect
- the source's intrinsic dimensions are not preserved
- for `Sprite` sources, the sub-region is scaled to fill local bounds

Stretch mode is the default. A shape with no explicit fill-source configuration
beyond `fillColor` is in stretch mode, though stretch has no visible effect on
a flat color.

### Tiling Mode

Tiling mode is active when `fillRepeatX` or `fillRepeatY` is `true`.

In tiling mode:

- the source is placed at its intrinsic dimensions
- for `Sprite` sources, intrinsic dimensions are the sub-region dimensions
- `fillAlignX` and `fillAlignY` position the initial tile within local bounds
- `fillOffsetX` and `fillOffsetY` shift the tiling origin in local-space units
- the source repeats along each enabled axis to cover local bounds
- axes with repetition disabled are treated as a single tile in that axis
  without repetition, still positioned by alignment and offset

On a non-repeating axis, the source is placed at its intrinsic dimension and
is not stretched. A source that extends beyond local bounds on that axis is
clipped by the silhouette. Alignment and offset position the tile normally on
that axis.

Alignment values map to the tiling origin position:

- `"start"`: tiling origin is at the start edge of local bounds on that axis
- `"center"`: tiling origin is centered within local bounds on that axis
- `"end"`: tiling origin is at the end edge of local bounds on that axis

Offset is applied after alignment. A positive `fillOffsetX` shifts the tiling
origin to the right. A positive `fillOffsetY` shifts the tiling origin
downward, consistent with local-space coordinate conventions.

---

## Gradient Placement

Gradient fill always spans the full local bounds AABB in the resolved
direction.

Direction mapping:

- `"horizontal"`: gradient runs left-to-right across local bounds; `colors[0]`
  maps to the left edge, `colors[last]` maps to the right edge
- `"vertical"`: gradient runs top-to-bottom across local bounds; `colors[0]`
  maps to the top edge, `colors[last]` maps to the bottom edge

Gradient fill does not participate in `fillAlignX`, `fillAlignY`,
`fillOffsetX`, `fillOffsetY`, `fillRepeatX`, or `fillRepeatY`. Those
properties apply only to texture-backed sources.

Gradient alpha resolution follows the Paint Alpha Contract from Part 1:

- resolved pixel alpha = interpolated gradient alpha at sampled point ×
  `fillOpacity`

---

## Texture And Sprite Placement

`Texture` and `Sprite` sources follow the placement model defined above.

For `Sprite` sources:

- the effective dimensions used for all placement calculations are the
  sub-region dimensions
- the underlying texture dimensions are never read or referenced during
  placement
- the sub-region is the complete source geometry from the placement model's
  perspective

A `Sprite` whose region equals full texture bounds behaves identically to
using the texture directly at those dimensions.

Texture alpha resolution follows the Paint Alpha Contract from Part 1:

- resolved pixel alpha = sampled texel alpha at point × `fillOpacity`

---

## Silhouette Clipping

All fill source output is clipped to the shape's resolved silhouette before
the shape-local paint result is finalized.

The silhouette is the canonical shape boundary. Fill pixels that fall outside
the silhouette are discarded. Fill pixels inside the silhouette are retained
at their resolved alpha.

Silhouette clipping is applied to the fill result. It is not applied
separately to stroke. Stroke is drawn on top of the fill result after
silhouette clipping, as part of the shape-local paint result. Stroke geometry
is defined by the shape silhouette and stroke width, and is positioned per the
center-aligned stroke contract defined in Part 1.

The shape-local paint result that is passed to the compositing stage is:

1. fill source resolved and clipped to silhouette
2. stroke drawn on top

Both are composited together before root shader, root opacity, and root blend
mode are applied.

The foundation spec §6.1.3 note that `clipChildren = true` clips descendants
to rectangular bounds rather than the silhouette applies to child node layout
clipping only. It does not affect fill pixel silhouette clipping. Fill pixel
clipping is a paint-stage operation in the geometry-backed rendering pipeline
and is entirely independent of child layout clipping behavior.

---

## Rendering Strategy

Textured shape fill uses a geometry-backed path.

The shape's silhouette is triangulated. Fill source coordinates are mapped into
the triangulated mesh using the local bounds AABB as the UV reference frame.
The renderer samples the fill source across the mesh and discards fragments
outside the silhouette boundary.

UV (0, 0) maps to the top-left corner of the local bounds AABB. UV (1, 1)
maps to the bottom-right corner. This is consistent with the gradient
direction mapping defined above and with the target rendering environment's
coordinate conventions.

Silhouette clipping may be implemented through the stencil buffer or through
an offscreen canvas pass. Both are equivalent implementation paths. In the
stencil path, the shape geometry is written to the stencil first, then the
fill source is sampled and written only to stenciled fragments. In the
offscreen path, the fill source is rendered to an intermediate surface which
is then composited using the silhouette as a clip mask. The choice of path
is implementation-defined.

The public contract — placement semantics, alpha behavior, silhouette
boundary — is defined by the geometry-backed model. Any implementation that
produces a result semantically identical to that model satisfies the contract,
regardless of which clipping mechanism it uses.

---

## Fill Source And Compositing Interaction

Fill source rendering is strictly a paint-source concern, not a compositing
concern.

- textured fill does not trigger subtree isolation
- textured fill does not alter the compositing state record
- textured fill does not interact with `blendMode` or `shader` directly
- `fillOpacity` is a paint-family concern; `opacity` is a compositing concern
- both apply, at their respective stages in the canonical compositing order

The full alpha path for a texture-backed fill is:

1. sampled texel alpha × `fillOpacity` → fill pixel alpha (paint stage)
2. fill result composited with stroke into shape-local result (paint stage)
3. root shader applied to shape-local result (compositing stage)
4. root opacity applied to shader result (compositing stage)
5. blended into parent composition target (compositing stage)

---

## Motion Capability

All fill-surface properties declared in the Fill Source Surface section are
motion-capable or not as follows. This mirrors the Drawable parallel exactly
and closes the motion capability item deferred from Part 1.

| Property            | Motion-capable | Interpolation                                                        |
|---------------------|----------------|----------------------------------------------------------------------|
| fillColor           | Yes            | Continuous color, same as backgroundColor                            |
| fillOpacity         | Yes            | Continuous numeric [0, 1], same as backgroundOpacity                 |
| fillGradient colors | Yes            | Continuous color interpolation per stop, same as styling spec §12    |
| fillTexture         | Yes            | Discrete step, whole-object replacement only — same as shader in Part 2 |
| fillOffsetX         | Yes            | Continuous numeric, same as backgroundOffsetX                        |
| fillOffsetY         | Yes            | Continuous numeric, same as backgroundOffsetY                        |
| fillAlignX          | Yes            | Discrete step only — enum, no interpolation                          |
| fillAlignY          | Yes            | Discrete step only — enum, no interpolation                          |
| fillRepeatX         | No             | Boolean, not motion-capable                                          |
| fillRepeatY         | No             | Boolean, not motion-capable                                          |

Motion capability applies to the property value only. The active fill source
priority rule from Part 1 is not affected by motion — transitions animate the
active source's property values, not the priority resolution itself.

---

## Failure Semantics

All failures follow the deterministic failure model from Part 1.

**Invalid fill source type** — fires at assignment time. Raised when the value
assigned to `fillTexture` is not a `Texture` or `Sprite` object. Hard error,
no fallback, no prior-value retention.

**Invalid sprite region: out-of-bounds sub-region** — fires at assignment time.
Raised when a `Sprite` object's sub-region extends beyond its underlying
texture bounds. The sub-region is clipped to valid bounds and a warning is
emitted. No hard error. This matches the graphics spec §4B.4 contract and
is consistent with atlas-based usage where minor boundary violations from
floating-point math are expected. This is not an override of the graphics
spec — it is alignment with it.

**Invalid sprite region: non-positive dimensions** — fires at assignment time.
Raised when a `Sprite` object's sub-region has a width or height of zero or
less. Hard error, no fallback. No valid region can be derived from
non-positive dimensions.

**Unusable texture source** — fires at draw time. Raised when a previously
valid texture source becomes unresolvable at draw time due to the backing
graphics resource becoming unresolvable — either because it was explicitly
released, the graphics context was reset, or the provider that created it has
invalidated it. Detection of this condition is implementation-defined. The
obligation is to detect it at draw time and raise a hard error rather than
sampling undefined data.

**Unsupported renderer path** — fires at draw time. Raised when the active
renderer cannot produce any semantically correct geometry-backed
silhouette-clipped fill result for the active fill source — neither through
stencil nor through an offscreen-equivalent path. Hard error, no fallback to
a different fill mode.

This failure applies to the currently active fill source at render time. If
the active source is `fillColor`, this failure does not apply — flat-color
fill has a guaranteed renderer path. If the active source is `fillTexture` or
`fillGradient` and the renderer cannot execute geometry-backed fill for that
source type, the failure fires for that draw and the shape does not fall back
to a lower-priority source.

**Invalid gradient configuration** — fires at assignment time. Raised when the
gradient object fails the validation rules defined in the gradient contract
(Styling Document, Section 6.4): fewer than two colors, missing direction,
invalid kind. Hard error, no fallback to flat color.

Behavioral guarantees:

- textured fill does not alter layout footprint
- textured fill does not alter silhouette hit testing
- textured fill participates in node opacity through the canonical compositing
  order, not through a separate alpha path
- stroke rendering is unaffected by the active fill source

---

## Fast Path Obligation

Shapes using only `fillColor` must not incur texture or gradient rendering
overhead.

The renderer must guarantee:

- no mesh generation for flat-color fill
- no stencil pass for flat-color fill unless required by other active state
- no UV mapping work for flat-color fill

Fill source resolution must check priority first. If `fillTexture` and
`fillGradient` are both nil or invalid, the renderer takes the flat-color path
immediately. No texture or gradient infrastructure is touched.

---

## Acceptance Criteria

This part is complete when:

- `Shape` accepts `Texture` and `Sprite` through `fillTexture` with correct
  placement and silhouette clipping
- `Shape` accepts gradient objects through `fillGradient` with correct
  span-to-bounds placement
- stretch mode correctly fills local bounds with no alignment or offset applied
- tiling mode correctly tiles at intrinsic dimensions with alignment and offset
  applied
- sprite placement uses sub-region dimensions in all cases
- gradient direction maps correctly to local bounds axes
- silhouette clipping discards all fill pixels outside the shape boundary
- stroke is drawn on top of fill within the shape-local paint result
- fill source rendering precedes root shader, root opacity, and root blend
  application
- textured fill does not trigger subtree isolation
- all failure kinds fire at the correct stage as hard errors with no fallback
- flat-color fill incurs no texture or gradient rendering overhead
- `background*` props remain drawable-owned
- `stroke*` remains shape-owned
- `Shape` does not participate in the styling or skinning system as a result
  of this change

---

## Final Amends Per File

These are the concrete edits to apply to each spec file when this patch is
ratified. Each amendment includes the file, the located target, and the exact
replacement.

---

### `docs/spec/ui-foundation-spec.md`

**Amendment F-1 — Section 6.1.3, behavioral edge cases, `clipChildren` bullet**

Locate the bullet:

> A `Shape` with `clipChildren = true` clips descendants to rectangular bounds,
> not to the visible silhouette; authors must not rely on `Shape` as a
> silhouette clip in this revision.

Append a normative note immediately after that bullet:

> This applies to child-node layout clipping only. Fill-pixel silhouette
> clipping is a paint-stage operation resolved during fill rendering and always
> clips to the shape's resolved silhouette regardless of the `clipChildren`
> setting. The two mechanisms are independent.

---

**Amendment F-2 — Section 6.1.3, Shape-owned stroke contract, add ordering rule**

Locate the rule:

> when `strokePattern = "solid"`, `strokeDashLength`, `strokeGapLength`, and
> `strokeDashOffset` are ignored

Append immediately after that rule:

> stroke is drawn on top of fill within the shape-local paint result; fill is
> silhouette-clipped first; stroke is not separately clipped to the silhouette;
> both fill and stroke are combined into the shape-local result before root
> shader, root opacity, and root blend mode are applied

---

**Amendment F-3 — Section 6.1.3, add fill placement contract section**

After the "Shape-owned stroke and opacity contract" block, insert a new
section:

**Shape-owned fill placement contract**

The placement basis for all fill sources is the shape's local bounds AABB.
No placement mode references parent geometry or any coordinate space outside
the shape's own local space.

Stretch mode is active when both `fillRepeatX` and `fillRepeatY` are `false`:

- the fill source is scaled to exactly fill the local bounds AABB
- `fillAlignX`, `fillAlignY`, `fillOffsetX`, and `fillOffsetY` have no effect
  in this mode
- for `Sprite` sources, the sub-region is scaled to fill local bounds

Tiling mode is active when `fillRepeatX` or `fillRepeatY` is `true`:

- the source is placed at its intrinsic dimensions; for `Sprite` sources,
  intrinsic dimensions are the sub-region dimensions
- `fillAlignX` and `fillAlignY` position the initial tile within local bounds
- `fillOffsetX` and `fillOffsetY` shift the tiling origin in local-space units
- the source repeats along each enabled axis; axes with repetition disabled
  are treated as a single tile without repetition on that axis, still
  positioned by alignment and offset

Gradient fill always spans the full local bounds AABB in the resolved
direction:

- `"horizontal"`: `colors[0]` at the left edge, `colors[last]` at the right
  edge
- `"vertical"`: `colors[0]` at the top edge, `colors[last]` at the bottom
  edge

Gradient fill does not participate in `fillAlignX`, `fillAlignY`,
`fillOffsetX`, `fillOffsetY`, `fillRepeatX`, or `fillRepeatY`.

All fill pixels outside the shape silhouette are discarded. Fill pixel
silhouette clipping is applied before stroke is drawn.

---

### `docs/spec/ui-motion-spec.md`

**Amendment M-1 — Section 4C, add Shape fill-source component-specific motion
properties**

Locate the component-specific examples list ending with:

> shader-bound visual parameters for a documented part that already exposes
> shader behavior through the visual contract

Add a new entry to that list:

> fill-source visual properties for `Shape` as documented in the
> capability-normalization patch

Then, after that examples list and before the `Motion properties are
visual-only in this revision.` line, insert the following table:

`Shape` fill-source motion-capable properties:

| Property | Motion-capable | Interpolation |
|---|---|---|
| `fillColor` | Yes | Continuous color, same contract as `backgroundColor` |
| `fillOpacity` | Yes | Continuous numeric `[0, 1]`, same contract as `backgroundOpacity` |
| `fillGradient` color stops | Yes | Continuous color per stop, same contract as styling spec §12 |
| `fillTexture` | Yes | Discrete step, whole-object replacement only |
| `fillOffsetX` | Yes | Continuous numeric, same contract as `backgroundOffsetX` |
| `fillOffsetY` | Yes | Continuous numeric, same contract as `backgroundOffsetY` |
| `fillAlignX` | Yes | Discrete step only |
| `fillAlignY` | Yes | Discrete step only |
| `fillRepeatX` | No | Boolean, not motion-capable |
| `fillRepeatY` | No | Boolean, not motion-capable |

Motion capability applies to the property value only. The fill source priority
rule is not motion-driven — transitions animate the active source's property
values, not the priority resolution itself.