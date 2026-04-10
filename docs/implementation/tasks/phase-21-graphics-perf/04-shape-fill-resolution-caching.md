# Task 04: Shape Fill Resolution Caching

## Goal

Reduce repeated fill-surface and fill-placement re-derivation for shapes without changing the shape fill contract.

## Scope

In scope:

- `lib/ui/shapes/fill_source.lua`
- `lib/ui/shapes/fill_placement.lua`
- `lib/ui/core/shape.lua`
- optional shared helpers for cache invalidation or scratch reuse

Out of scope:

- changing fill priority
- changing stretch vs tiling semantics
- changing active-source failure semantics
- changing motion semantics for `fill*` props

## Current implementation notes

- `Shape:_resolve_fill_surface()` rebuilds a fill-surface table on every draw.
- `Shape:_resolve_active_fill_source()` rebuilds an active descriptor on every draw.
- Placement is recomputed from local bounds on every non-color fill draw.
- The common solid-color path already short-circuits the heavier renderer path and must remain fast.

## Implementation notes

- The cache must preserve:
  - `fillTexture > fillGradient > fillColor`
  - shape-local-bounds placement basis
  - stretch mode semantics when both repeats are false
  - tiling semantics when either repeat flag is true
- Invalidation must include:
  - all `fill*` props
  - motion-written `fill*` props
  - local bounds changes
  - any source-object replacement that changes intrinsic dimensions or region
- Do not cache renderer outputs or stencil products in this task unless their invalidation is separately proven. This task is about cheap state re-derivation first.

## Work items

- Introduce internal caching for the resolved fill surface.
- Introduce internal caching for the resolved active descriptor.
- Introduce internal caching for placement when the active descriptor and local bounds are unchanged.
- Preserve the flat-color fast path and confirm the cache does not make it slower.
- Keep the source-validation and failure behavior from the current fill pipeline unchanged.

## File targets

- `lib/ui/shapes/fill_source.lua`
- `lib/ui/shapes/fill_placement.lua`
- `lib/ui/core/shape.lua`
- any directly affected fill renderer helpers

## Testing

Required focused specs:

- add cache-invalidation coverage for:
  - `fillColor`
  - `fillGradient`
  - `fillTexture`
  - `fillRepeatX`
  - `fillRepeatY`
  - `fillAlignX`
  - `fillAlignY`
  - `fillOffsetX`
  - `fillOffsetY`
  - motion-driven changes for the same properties
  - local-bounds changes

Suggested existing regression suite:

- `spec/shape_fill_placement_spec.lua`
- `spec/shape_fill_renderer_spec.lua`
- `spec/shape_fill_motion_spec.lua`
- `spec/nonrect_shape_spec.lua`
- `spec/rect_shape_render_spec.lua`

Required runtime verification:

- compare timing and memory outputs for the texture-heavy graphics demo screen before/after
- confirm no visible change in the texture/gradient demo cases

## Acceptance criteria

- Static textured and gradient-filled shapes no longer rebuild the same fill-surface state every frame.
- Cache invalidation is explicit and regression-tested.
- The common solid-color path remains a fast path.
- No fill-contract or motion-contract behavior changes are required.
