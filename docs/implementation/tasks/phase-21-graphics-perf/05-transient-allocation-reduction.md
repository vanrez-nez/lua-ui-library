# Task 05: Transient Allocation Reduction

## Goal

Reduce per-frame GC pressure from short-lived graphics pipeline tables without changing rendering semantics.

## Scope

In scope:

- point-array churn in `Shape`
- stroke-option table churn in `Shape`
- fill-surface / descriptor scratch churn not already eliminated by task 04
- clip-stack helper churn in `Container.draw_subtree`
- compositor scratch structures that can be safely reused internally

Out of scope:

- public object pooling APIs
- reuse schemes that let scratch tables escape the draw path
- changes to `Rectangle` semantics or other shared value-object contracts unless separately proven safe

## Current implementation notes

- `Shape:_get_local_points()`, `_get_world_bounds_points()`, and `_resolve_polygon_stroke_options()` allocate new tables frequently.
- `Container.draw_subtree` pushes and pops clip-related state through mutable lists and per-branch local state.
- The findings call out these short-lived tables as a GC-pressure source in dense scenes.

## Implementation notes

- Internal scratch storage is allowed only if:
  - it never becomes part of the public surface
  - it is not retained across nodes in a way that causes aliasing bugs
  - error paths leave scratch state reusable for the next draw
- Favor per-instance scratch storage over global mutable scratch when node-local state is easier to reason about.
- Do not trade a small allocation win for a hard-to-prove semantic change in clipping or stroke output.

## Work items

- Audit per-draw transient tables in the graphics hot paths and classify them as:
  - removable
  - reusable
  - must remain fresh
- Reuse local/world point buffers where safe.
- Reuse stroke-option or fill scratch tables where safe.
- Reduce clip-stack churn in `Container.draw_subtree` if the same semantics can be expressed with less transient mutation or fewer temporary objects.
- Add narrow comments where reuse logic is non-obvious and future refactors could accidentally break it.

## File targets

- `lib/ui/core/shape.lua`
- `lib/ui/core/container.lua`
- `lib/ui/shapes/draw_helpers.lua`
- `lib/ui/shapes/fill_source.lua`
- other directly involved shape/compositor helpers

## Testing

Required focused specs:

- add regression coverage proving scratch reuse does not leak state between sibling draws
- add regression coverage for clipped subtree behavior if clip-stack internals change

Suggested existing regression suite:

- `spec/container_order_clipping_hit_testing_spec.lua`
- `spec/nonrect_shape_spec.lua`
- `spec/rect_shape_render_spec.lua`
- `spec/shape_draw_helpers_spec.lua`

Required runtime verification:

- compare memory-profile outputs before/after on the graphics screens
- compare any dense internal stress fixture from task 01 before/after

## Acceptance criteria

- Memory-profile output shows reduced transient allocation pressure in the targeted graphics cases.
- Reused scratch state does not leak across nodes or frames.
- Clipping and stroke behavior remain unchanged on the covered regression suite.
