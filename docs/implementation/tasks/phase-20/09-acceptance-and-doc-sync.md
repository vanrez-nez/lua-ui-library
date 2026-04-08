# Task 09: Acceptance And Doc Sync

## Goal

Add verification coverage for the normalized root compositing and shape fill-source behavior, then sync the public implementation docs to the shipped surface.

## Current implementation notes

- The repo already has spec-style verification files under `spec/`, including existing shape, styling, opacity, and stroke coverage.
- There is no current verification surface for root shader or root blend mode on `Shape`, nor for shape gradient or texture-backed fill.

## Work items

- Add or extend `spec/` coverage for shared root compositing on both `Drawable` and `Shape`:
  - default-state fast path
  - `opacity`
  - `blendMode`
  - `shader`
  - nested isolation order
  - state restore on failure
- Add or extend `spec/` coverage for shape fill sources:
  - flat color fallback
  - gradient horizontal and vertical placement
  - texture stretch placement
  - sprite intrinsic-size tiling
  - repeat on one axis and both axes
  - align and offset behavior
  - stroke drawn after clipped fill
  - root opacity, shader, and blend mode applied after local fill and stroke resolution
- Add negative-path coverage for:
  - invalid `blendMode`
  - invalid shader assignment
  - invalid `fillTexture` type
  - invalid gradient configuration
  - unsupported renderer path for gradient or textured shape fill
  - draw-time unusable texture source
  - motion attempts against `fillRepeatX` and `fillRepeatY`
- Update public implementation-facing docs or examples so the new shape surface is discoverable:
  - `fillGradient`
  - `fillTexture`
  - `fillRepeat*`
  - `fillOffset*`
  - `fillAlign*`
  - `shader`
  - `blendMode`

## Implementation notes

- Existing spec coverage already lives in `spec/drawable_content_box_surface_spec.lua`, `spec/shape_opacity_spec.lua`, `spec/shape_primitive_surface_spec.lua`, `spec/nonrect_shape_spec.lua`, and `spec/styling_renderer_spec.lua`. Extend those before adding broad new harnesses.
- Negative-path coverage must include the remaining compliance-review gaps: invalid shader assignment, unsupported renderer path, draw-time unusable texture source, and forbidden fill-repeat motion.
- Public docs must present Shape's new surface as direct-instance graphics capability and shape-owned fill state only. Do not imply styling, skinning, or mask participation.

## File targets

- `spec/`
- `demos/` if a visual acceptance scene is needed
- `docs/` implementation-facing surface documentation

## Acceptance criteria

- The new behavior is covered by automated specs, not just demo scenes.
- Failure paths are verified alongside the success paths.
- Documentation reflects the shipped shape surface without implying styling or mask participation.
- Phase 20 can be closed from tests and docs alone without relying on older phase task notes.
