# Phase 19 Task 06: Acceptance

## Goal

Verify the new shape stroke and opacity contract end to end against the current
`lib/ui` runtime.

## Scope

Runtime verification:

- `spec/shape_primitive_surface_spec.lua`
- `spec/rect_shape_render_spec.lua`
- `spec/nonrect_shape_spec.lua`
- any new focused shape stroke / opacity spec files

Implementation review:

- confirm the phase did not pull `Shape` into the `Drawable` styling pipeline
- confirm the retained opacity generalization still preserves current
  `Drawable` behavior

## Work

1. Add regression coverage for the `Shape` public surface:
   - approved `stroke*` props
   - `opacity`
   - rejected `border*` props
   - invalid `strokeWidth`, `strokeStyle`, and `strokePattern`
2. Add draw coverage for:
   - solid stroke on every built-in shape
   - dashed stroke on every built-in shape
   - `strokeColor`-absent no-op behavior
   - `strokeJoin` behavior on polygon shapes
   - inert `strokeJoin` behavior on `CircleShape`
3. Add opacity coverage for:
   - direct `Shape.opacity`
   - motion-driven root `opacity`
   - `opacity = 0` remaining targetable
4. Add interaction coverage proving outward stroke extent does not expand
   hit testing.

## Exit Criteria

- focused verification exists for the full published `Shape` stroke and
  opacity contract
- no regression test suggests that `Shape` depends on the `Drawable`
  styling-family pipeline
