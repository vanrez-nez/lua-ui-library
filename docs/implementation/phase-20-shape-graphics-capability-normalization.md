# Phase 20: Shape Graphics Capability Normalization

## Purpose

Summarize the current shipped `Shape` graphics surface after the phase-20
normalization work.

This document is the implementation-facing surface summary for the current
`lib/ui` behavior. It supersedes the narrower historical phase scopes from
phase 18 and phase 19 when the question is "what does `Shape` support today?"

## Authority

- `docs/spec/ui-foundation-spec.md`
- `docs/spec/ui-motion-spec.md`
- `docs/incidents/spec_patch_shape_graphics_capability_normalization_part_01_model.md`
- `docs/incidents/spec_patch_shape_graphics_capability_normalization_part_02_root_compositing.md`
- `docs/incidents/spec_patch_shape_graphics_capability_normalization_part_03_fill_sources.md`

## Primitive Boundary

- `Shape` remains a direct subclass of `Container`, not `Drawable`
- `Shape` remains leaf-only
- `Shape` owns its own silhouette, fill, stroke, and hit testing
- `Shape` does not join the styling, theming, or skinning systems
- `Shape` does not adopt `mask`
- `Drawable.border*` and `Shape.stroke*` remain separate vocabularies

## Direct-Instance Surface

### Shared Root Compositing

`Shape` now exposes the shared root compositing surface as direct instance
props:

- `opacity`
- `shader`
- `blendMode`

These props are capability-declared on the class and resolved through the same
retained compositor used by `Drawable`.

Defaults:

- `opacity = 1`
- `shader = nil`
- `blendMode = "normal"`

`mask` remains `Drawable`-only and is not part of the shared root surface.

### Shape-Owned Fill Surface

`Shape` now exposes the full shape-owned fill source surface as direct instance
props:

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

Active fill priority is:

1. `fillTexture`
2. `fillGradient`
3. `fillColor`

Multiple fill props may coexist as stored values, but only one source is
active at render time.

### Shape-Owned Stroke Surface

The shape-owned stroke surface remains:

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

Stroke still renders after fill and remains shape-owned.

## Placement And Rendering Rules

- Fill placement resolves against the shape's local-bounds AABB
- Stretch mode is the default when `fillRepeatX == false` and `fillRepeatY == false`
- Stretch mode scales the active texture or sprite to the full local bounds and ignores `fillAlign*` and `fillOffset*`
- Tiling mode activates when either repeat flag is `true`
- Tiling mode uses intrinsic source dimensions
- Sprite placement always uses sprite-region dimensions, never the underlying texture dimensions
- Gradient fill always spans the full local bounds in the resolved direction
- Gradient fill ignores `fillAlign*`, `fillOffset*`, and `fillRepeat*`
- Non-flat fill is clipped to the concrete shape silhouette before the local result is finalized
- Stroke draws after fill, on top of the clipped local fill result
- Root `shader`, root `opacity`, and root `blendMode` apply after the shape-local fill and stroke result is complete
- Texture-backed or gradient-backed fill does not trigger root isolation by itself

## Motion Surface

Motion-capable root compositing props on `Shape`:

- `opacity`
- `blendMode`
- `shader`

Motion-capable shape-owned fill props:

- `fillColor`
- `fillOpacity`
- `fillGradient`
- `fillTexture`
- `fillOffsetX`
- `fillOffsetY`
- `fillAlignX`
- `fillAlignY`

Not motion-capable:

- `fillRepeatX`
- `fillRepeatY`

## Exclusions

`Shape` still does not expose:

- `background*`
- `border*`
- `cornerRadius*`
- `shadow*`
- `skin`
- `mask`

The normalized graphics surface is direct-instance state only. It is not a
styling alias, not a theming alias, and not a skin surface.

## Verification Surface

The shipped phase-20 behavior is covered by focused runtime specs under
`spec/`, including:

- `spec/graphics_capability_helpers_spec.lua`
- `spec/drawable_content_box_surface_spec.lua`
- `spec/shape_opacity_spec.lua`
- `spec/shape_primitive_surface_spec.lua`
- `spec/shape_fill_placement_spec.lua`
- `spec/shape_fill_renderer_spec.lua`
- `spec/shape_fill_motion_spec.lua`
