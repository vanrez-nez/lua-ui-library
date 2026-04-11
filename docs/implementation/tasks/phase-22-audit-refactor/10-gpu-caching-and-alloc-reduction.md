# Task 10: GPU Caching And Allocation Reduction

## Goal

Close the frame-hot performance findings from `audits/source_code_audit_findings.md` that are not directly coupled to the object-model migration but become easy to invalidate correctly once the migration has landed. Every cache introduced in this task keys its invalidation off a `DirtyState` bucket installed in tasks 05–06, so the correctness reasoning is simply "when the dirty bucket fires, drop the cache." No cache has its own ad hoc invalidation logic.

## Scope

In scope:

- **ML-01** cache gradient and texture meshes per Shape instance in `fill_renderer.lua`, invalidated by Shape's `paint` dirty bucket from task 06
- **AP-02** cache vertex data per Shape instance keyed on a placement hash, invalidated by Shape's `geometry` bucket
- **ML-02** cache quad per Image instance in `lib/ui/graphics/image.lua`, invalidated via `Reactive:watch` on source/region/texture fields
- **AP-01** cache frame-hot scratch tables (fill surface descriptor, draw options) per Shape instance, invalidated by Shape's `paint` bucket
- **RE-02** cross-check that Shape's draw sequence hoist landed in task 06 covers every subclass; fix any subclass that drifted
- phase-21 baseline regression check: rerun any phase-21 captures if the infrastructure exists, confirm no regression from the migration work

Out of scope:

- any new dirty domain beyond `paint`/`geometry` on Shape (flagged as future work in the compliance review)
- any cache on Drawable beyond what the existing styling canvas pool already provides
- any spec change; the performance improvements must not alter observable behavior

## Spec anchors

- [audits/source_code_audit_findings.md](/Users/vanrez/Documents/game-dev/lua-ui-library/audits/source_code_audit_findings.md) — `ML-01`, `ML-02`, `AP-01`, `AP-02`, `RE-02`
- Task 00 compliance review — memory-leak and allocation-reduction items classified as `safe` provided cache invalidation covers every affecting property change.

## Current implementation notes

- `lib/ui/shapes/fill_renderer.lua` rebuilds a gradient or texture mesh on every draw call for any shape with a gradient or texture fill. The mesh depends on fill color stops, texture handle, and placement region; none of that changes frame-to-frame for a static shape.
- `lib/ui/shapes/fill_source.lua` allocates temporary tables (surface descriptor, draw options) on every draw call. These are cleared and rebuilt identically each frame when no paint prop changes.
- `lib/ui/graphics/image.lua` rebuilds a LÖVE `Quad` object on every draw based on `source`/`region`/texture fields. The quad is invariant across frames when none of those fields change.
- Shape's `paint` and `geometry` `DirtyState` buckets were installed in task 06; they fire exactly when a paint or geometry prop is written through the proxy pipeline.

## Work items

- **ML-01: gradient/texture mesh cache.** In `fill_renderer.lua`, add a per-shape cache slot (e.g. `shape._fill_mesh_cache`) that stores the last-built gradient or texture mesh. At the top of the gradient/texture draw path, check `shape.shape_dirty:is_dirty('paint')`; if clean and the cache is populated, reuse it; otherwise rebuild and store, then clear `'paint'` after the draw loop via the existing draw pipeline. If the fill type switches between gradient/texture/solid, invalidate the cache as part of the `paint` dirty event. Verify cache reuse by adding a small instrumentation counter in a dev build (optional) or by writing a test that records mesh identity across two draws.
- **AP-02: vertex data cache.** Cache per-shape vertex arrays keyed on a placement hash (width, height, corner radius, shape kind). When `geometry` dirty fires, drop the vertex cache. The placement hash is computed once from the current geometry state; subsequent draws reuse the cached vertex array until geometry changes.
- **ML-02: Image quad cache.** In `lib/ui/graphics/image.lua`, add a per-instance quad cache. Install `Reactive:watch` handlers on `source`, `region`, and any texture-related field that invalidate the cache. On draw, consult the cache before building a new quad. The Image class does not have a `DirtyState` bucket; the watcher-based invalidation is sufficient because these fields are the only inputs to the quad.
- **AP-01: scratch table cache.** In `fill_source.lua` (and any other frame-hot file the audit flagged), replace per-draw table allocations with per-shape cached tables. Each table is rebuilt only when `paint` dirty fires. The caller writes into the shared table rather than allocating a new one; the shape instance owns the table lifetime.
- **RE-02 cross-check.** Walk each shape subclass (`rect_shape`, `circle_shape`, `triangle_shape`, `diamond_shape`) and confirm the base `Shape:draw` hoist from task 06 is in effect. Each subclass should have zero draw-sequence boilerplate — only `_get_local_points` and any subclass-specific schema merge. If any subclass drifted after task 06 landed, fix it here.
- **Phase-21 baseline regression.** If phase-21 produced before/after capture infrastructure, rerun the representative scenes with the phase-22 changes in place and record any delta. The expected outcome is no regression; any regression is a bug and must be root-caused before task 11 closes.

## File targets

- `lib/ui/shapes/fill_renderer.lua`
- `lib/ui/shapes/fill_source.lua`
- `lib/ui/graphics/image.lua`
- `lib/ui/core/shape.lua` (only if cache plumbing needs to hang off Shape instance state; otherwise no edit)
- `lib/ui/shapes/rect_shape.lua`, `circle_shape.lua`, `triangle_shape.lua`, `diamond_shape.lua` (RE-02 cross-check; edit only if drift is found)

## Testing

Required runtime verification:

- `love demos/04-graphics` renders identically across the four graphics screens
- a demo exercising gradients and textures with dynamic paint changes renders identically
- a demo exercising image rendering with region changes renders identically

Required spec verification:

- `spec/shape_primitive_surface_spec.lua`
- `spec/shape_stroke_acceptance_spec.lua`
- `spec/shape_fill_motion_spec.lua`
- `spec/rect_shape_render_spec.lua`
- `spec/nonrect_shape_spec.lua`
- any existing image-related spec
- full `spec/` suite green with zero edits to existing spec files

## Acceptance criteria

- `fill_renderer.lua` caches gradient and texture meshes per Shape instance; the cache is invalidated exclusively via Shape's `paint` DirtyState bucket.
- `fill_source.lua` reuses scratch tables across frames for static shapes; the tables are invalidated exclusively via Shape's `paint` DirtyState bucket.
- Per-shape vertex data is cached and keyed on a placement hash; invalidation runs exclusively via Shape's `geometry` DirtyState bucket.
- `image.lua` caches the LÖVE `Quad` per Image instance; invalidation runs via `Reactive:watch` on `source`/`region`/texture fields.
- Every shape subclass still delegates its full draw sequence to the base `Shape:draw` from task 06.
- Every shape, image, and graphics-related spec passes with zero edits.
- If phase-21 baseline capture infrastructure exists, the phase-22 capture shows no regression.
