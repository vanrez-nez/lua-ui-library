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

## Execution notes

- `Shape` now keeps instance-local scratch for local points, transformed world points, flattened point arrays, world-bounds points, and polygon stroke options. The concrete polygon shapes (`RectShape`, `DiamondShape`, `TriangleShape`, and the circle point builder) were moved onto that scratch path so sibling nodes do not alias each other.
- `FillRenderer` now reuses shape-local silhouette, gradient-vertex, and textured-tile vertex buffers, and the texture path draws meshes directly inside the silhouette clip instead of building an intermediate mesh list.
- `Container.draw_subtree` now reuses clip-polygon flatten buffers, world clip points, and depth-scoped scissor rect scratch. The current clip rect is copied/intersected into scratch instead of allocating fresh rectangle wrappers for each clip branch.
- `RootCompositor.draw_isolated_subtree` now reuses depth-scoped nested clip/render state scratch and composition-target origin entries. This keeps nested isolated draws safe without sharing a single mutable structure across branches.
- Focused regression coverage was added in `spec/graphics_transient_allocation_reuse_spec.lua`, and the clip/state regressions were rechecked with `spec/container_order_clipping_hit_testing_spec.lua`, `spec/root_compositor_plan_fast_paths_spec.lua`, and `spec/root_compositor_bounds_aware_isolation_spec.lua`.
- Runtime artifacts:
  - `tmp/phase-21-graphics-perf/opacity-memory-after-task-05.txt`
  - `tmp/phase-21-graphics-perf/blendmode-memory-after-task-05.txt`
  - `tmp/phase-21-graphics-perf/render-effects-memory-after-task-05.txt`
  - `tmp/phase-21-graphics-perf/texture-surfaces-memory-after-task-05.txt`
  - `tmp/phase-21-graphics-perf/dense-isolation-memory-after-task-05.txt`
- The targeted allocation cuts landed where expected:
  - Opacity `Container.draw_subtree.clip_children`: `63000.656 KB -> 28999.648 KB`
  - Blend mode `Container.draw_subtree.clip_children`: `63153.582 KB -> 29222.188 KB`
  - Texture surfaces since task 04: `Container.draw_subtree.clip_children` `41444.129 KB -> 24594.469 KB`, `FillRenderer.draw` `4693.418 KB -> 2162.168 KB`, `Shape._resolve_polygon_stroke_options` `348.250 KB -> 0.438 KB`
  - Dense isolation since the earlier post-task-02 memory capture: `Container.draw_subtree.clip_children` `45835.586 KB -> 38997.984 KB`, `RootCompositor.resolve_node_plan` `24568.344 KB -> 94.453 KB`
- Dense isolation is still mixed overall: `RootCompositor.draw_isolated_subtree` remains the dominant allocator (`72608.031 KB` in the task-05 capture), so later work should continue inside that retained-isolation path rather than the shape/clip scratch surfaces touched here.
