# Task 02: Bounds-Aware Root Isolation

## Goal

Reduce the cost of isolated compositing by sizing offscreen targets from the isolated subtree's required coverage rather than from the full active composition target when equivalence can be proven.

## Scope

In scope:

- `lib/ui/render/root_compositor.lua`
- `lib/ui/render/canvas_pool.lua`
- helper extraction needed to compute subtree isolation bounds and destination offsets
- conservative fallback to the current full-target isolation path whenever proof is incomplete

Out of scope:

- changing canonical compositing order
- changing the composition-target-stack model
- changing root shader semantics
- changing failure behavior when canvas isolation is required but unavailable
- changing result-clip semantics for shapes or drawables

## Current implementation notes

- `get_isolation_canvas_size` currently sizes from the active composition target, often the full stage-sized canvas.
- `composite_isolated_subtree` already computes subtree world bounds and crops with a source quad on the composite-back path.
- The current runtime already has state-save/restore and pooled-canvas ownership machinery that must remain authoritative.

## Implementation notes

- This task is spec-sensitive. It must preserve visible equivalence for:
  - root `opacity`
  - root `blendMode`
  - root `shader`
  - result clipping
  - immediate-parent-target blend reference frame
  - compositing extras already supported by the current runtime
- If root shader equivalence cannot be proven for a given path, retain the current full-target isolation path for that path.
- If result clipping or compositing-motion transforms require the current full-target path to remain correct, retain the fallback until explicit proof exists.
- Do not change the public meaning of subtree "resolved result". This task only changes how much empty offscreen space is allocated around it.

## Work items

- Derive the minimum required isolation region from subtree world paint bounds plus any required composite-back motion coverage.
- Acquire pooled canvases against that resolved region instead of the full composition target when safe.
- Draw the isolated subtree into the smaller canvas with the correct origin offset.
- Composite back from the smaller canvas into the parent target using the same blend, shader, opacity, scissor, and stencil rules as today.
- Preserve the current full-target fallback path behind explicit guard conditions where equivalence is not yet proven.
- Keep bucketed pooling and release semantics intact.

## File targets

- `lib/ui/render/root_compositor.lua`
- `lib/ui/render/canvas_pool.lua`
- related compositor specs added in this task

## Testing

Required focused specs:

- add a new focused root-compositor spec covering:
  - canvas size selection for small isolated subtrees
  - correct composite-back placement from a cropped offscreen target
  - fallback to full-target isolation when the optimized path is not proven safe
- extend or reuse existing specs to cover:
  - `Drawable` root opacity
  - `Shape` root opacity
  - root blend-mode compositing
  - result-clip behavior on shapes

Suggested existing regression suite:

- `spec/shape_opacity_spec.lua`
- `spec/drawable_content_box_surface_spec.lua`
- `spec/shape_fill_renderer_spec.lua`

Required runtime verification:

- rerun the phase-21 timing and memory baseline for the graphics screens
- add or use a dense isolated-subtree fixture and confirm reduced canvas allocation pressure
- confirm the visual result on the graphics demo screens is unchanged

## Acceptance criteria

- Small isolated nodes no longer automatically allocate stage-sized canvases on the optimized path.
- Optimized isolation preserves current visible output on the covered root-compositing cases.
- Any unproven case explicitly retains the current full-target fallback.
- No spec contract needs to be rewritten to explain the optimization.
