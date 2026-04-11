# Task 06: Drawable And Shape Migration

## Goal

Migrate `lib/ui/core/drawable.lua` and `lib/ui/core/shape.lua` (plus concrete shape subclasses) onto the new object model landed in task 05. Drawable becomes a thin extension of the migrated Container. Shape gains its own local `DirtyState({'paint', 'geometry'})` layered on top of Container's eight flags, hoists the draw sequence from subclasses (`RE-02`), caches frame-hot scratch tables keyed to the new dirty buckets (`AP-01`), and standardizes the draw-fallback contract (`CS-08`). Every shape and drawable spec passes unchanged.

## Scope

In scope:

- rewrite `Drawable:constructor` to consume the Container base migration and bind `DrawableSchema` via `self.schema:define(...)`
- replace Drawable's `apply_resolved_size`/`apply_content_measurement` overrides with calls into the base helper from task 05
- rewrite `Shape:constructor` to build `self.shape_dirty = DirtyState({'paint', 'geometry'})` alongside Container's local dirty set, bind `ShapeSchema`, and register paint/geometry watchers
- hoist the draw sequence from `rect_shape`, `circle_shape`, `triangle_shape`, `diamond_shape` into `Shape:draw`; subclasses are reduced to `_get_local_points()` plus any concrete-shape-specific schema merge
- cache local-points, world-points, and stroke-options scratch tables on the Shape instance, invalidated by `shape_dirty:mark('geometry')`
- standardize the "graphics is not a table" draw fallback across all four shape subclasses to a single base path (`CS-08`)
- add shape migration specs covering paint/geometry dirty marks and scratch-table reuse across frames

Out of scope:

- cached mesh/vertex buffer work on `fill_renderer.lua` and `fill_source.lua` — those are `ML-01`/`AP-02` and land in task 10
- the Image quad cache (`ML-02`) — task 10
- any public API change on Drawable or Shape
- any layout-family migration — task 07

## Spec anchors

- [audits/source_code_audit_findings.md](/Users/vanrez/Documents/game-dev/lua-ui-library/audits/source_code_audit_findings.md) — `DC-01`, `CS-08`, `RE-02`, `AP-01`
- [audits/dirty_props_refactor.md](/Users/vanrez/Documents/game-dev/lua-ui-library/audits/dirty_props_refactor.md) §5 — `apply_resolved_size` / `apply_content_measurement` dedup
- Task 00 compliance review — Shape is the only subclass allowed to add its own `DirtyState`; `paint` and `geometry` are genuinely shape-local.

## Current implementation notes

- `lib/ui/core/drawable.lua` had duplicate `__index`/`__newindex` at lines 21–49; task 01 (DC-01) already deleted that dead block. After task 05, Drawable's remaining metatable interaction is fully replaced by the proxy pipeline.
- Drawable currently overrides `apply_resolved_size` and `apply_content_measurement` with inline copies of the invalidation code. Task 05 extracted the base helpers; task 06 removes the overrides and calls the base helpers.
- `lib/ui/core/shape.lua` today manages paint state and geometry-derived caches ad hoc. Every subclass (`rect_shape`, `circle_shape`, `triangle_shape`, `diamond_shape`) reimplements a near-identical `draw` method with only `_get_local_points` or equivalent varying. `RE-02` calls for a base `Shape:draw` that owns the sequence.
- The shape draw methods each include a "graphics is not a table" fallback branch. `CS-08` calls for standardizing the fallback to a single path in the base class.
- Shape stores scratch data (local points, world points, stroke options) as plain instance tables that are rebuilt every draw. `AP-01` calls for caching them per-shape and invalidating when the shape's geometry changes.

## Work items

- **Drawable constructor rewrite.** Rewrite `Drawable:constructor(opts)` so it delegates to `Container:constructor(opts)` (which already builds `DirtyState`, `Reactive`, `Schema(self)` after task 05), then calls `self.schema:define(DrawableSchema)` to merge the drawable-specific rules onto the proxy. Every drawable-specific rule (background, border, corner radius, shadow, styling-capable fields) is already a Rule builder from task 04; the `set` options wire automatically through `Schema(self)`.
- **Drop Drawable `apply_resolved_size` override.** Remove the Drawable-level override of `apply_resolved_size` (and `apply_content_measurement` if overridden). Drawable calls into `Container:_apply_resolved_size` / `Container:_apply_content_measurement` from task 05. Verify no behavior delta by running the drawable spec set.
- **Drawable shared canvas pool.** Drawable's styling path consumes the shared `canvas_pool_registry` from task 01 (already wired in `styling.lua` and `root_compositor.lua`); task 06 does not re-thread this but confirms no direct `canvas_pools = {}` references remain inside Drawable.
- **Shape constructor rewrite.** Rewrite `Shape:constructor(opts)` to delegate to `Container:constructor(opts)`, then:
  1. Install `self.shape_dirty = DirtyState({'paint', 'geometry'})`.
  2. Call `self.schema:define(ShapeSchema)` to bind the shape-specific Rule table from task 04.
  3. Register `Reactive:watch` handlers on paint-affecting keys (fill color/opacity, stroke color/opacity/width/style, gradient fields, blend mode) that mark `shape_dirty:mark('paint')`.
  4. Register watchers on geometry-affecting keys (width/height/radius/corner fields specific to shape) that mark `shape_dirty:mark('geometry')` in addition to the Container-level watchers already marked in task 05.
  5. Initialize scratch tables `self._local_points = {}`, `self._world_points = {}`, `self._stroke_options = {}`.
- **Hoist `Shape:draw`.** Move the common draw sequence out of `rect_shape`, `circle_shape`, `triangle_shape`, `diamond_shape` into `Shape:draw(graphics)`. The sequence is:
  1. Early-return via the standardized `graphics is not a table` fallback (`CS-08`).
  2. Refresh container state via `self:_refresh_if_dirty()` if not already called by the caller.
  3. Recompute local and world points if `shape_dirty:is_dirty('geometry')` is set; clear `'geometry'` after.
  4. Recompute stroke options if `shape_dirty:is_dirty('paint')` is set; clear `'paint'` after.
  5. Call `self:_draw_fill(graphics)` and `self:_draw_stroke(graphics)`.
  Subclasses keep only `Shape:_get_local_points(out_table)` (writing into the provided scratch table) plus any subclass-specific schema merge. Reuse across frames is load-bearing — the scratch tables must not be reallocated unless the corresponding dirty flag fires.
- **Standardized draw fallback (`CS-08`).** Centralize the `graphics not a table` fallback in `Shape:draw`. The fallback behavior is whichever current subclass is documented as the canonical path (document the choice in the task PR body); all four subclasses use it via the base.
- **Concrete shape subclasses.** Rewrite `rect_shape.lua`, `circle_shape.lua`, `triangle_shape.lua`, `diamond_shape.lua` so each file contains:
  - the `setmetatable` boilerplate
  - a small constructor calling `Shape:constructor(opts)` and optionally calling `self.schema:define(SubclassSchema)` when the subclass owns additional rules
  - a single `_get_local_points(self, out_table)` that writes the shape-specific points into `out_table`
  Any other method that currently exists on the subclass should move up to `Shape` if it is shared or stay on the subclass only if it is genuinely specialized.
- **Shape migration specs.** Add `spec/shape_proxy_migration_spec.lua` (or integrate into existing shape spec layout) covering:
  - `shape_dirty:is_dirty('paint')` becomes true after setting a paint prop (fillColor), false after a draw cycle clears it
  - `shape_dirty:is_dirty('geometry')` becomes true after setting width/height, false after a draw cycle clears it
  - cached `_local_points` table identity is preserved across draws when geometry dirty is not marked
  - cached `_stroke_options` table identity is preserved across draws when paint dirty is not marked
  - the standardized "graphics not a table" fallback path is taken for all four shape subclasses

## File targets

- `lib/ui/core/drawable.lua`
- `lib/ui/core/shape.lua`
- `lib/ui/shapes/rect_shape.lua`
- `lib/ui/shapes/circle_shape.lua`
- `lib/ui/shapes/triangle_shape.lua`
- `lib/ui/shapes/diamond_shape.lua`
- `spec/shape_proxy_migration_spec.lua` (new; or integrated into existing layout)

## Testing

Required runtime verification:

- `love demos/04-graphics` renders identically across the four graphics screens (this is the primary drawable + shape smoke test)
- any demo exercising interactive drawable styling (backgrounds, borders, shadows) renders identically

Required spec verification:

- `spec/drawable_content_box_surface_spec.lua`
- `spec/styling_resolution_spec.lua`
- `spec/styling_renderer_spec.lua`
- `spec/shape_primitive_surface_spec.lua`
- `spec/shape_stroke_acceptance_spec.lua`
- `spec/shape_fill_motion_spec.lua`
- `spec/rect_shape_render_spec.lua`
- `spec/nonrect_shape_spec.lua`
- the new shape migration spec
- full `spec/` suite green with zero edits to existing spec files

## Acceptance criteria

- `Drawable:constructor` delegates to `Container:constructor` and calls `self.schema:define(DrawableSchema)`; no reference to `_public_values`/`_effective_values`/`_set_public_value` remains in `drawable.lua`.
- Drawable's `apply_resolved_size` / `apply_content_measurement` overrides are gone; the base Container helpers from task 05 are the single implementation path.
- `Shape:constructor` installs `self.shape_dirty = DirtyState({'paint', 'geometry'})`, binds `ShapeSchema`, and registers watchers that mark `paint`/`geometry` on the relevant keys.
- `Shape:draw` owns the full draw sequence; the four shape subclasses only override `_get_local_points` (and optional per-subclass schema merge).
- The "graphics not a table" fallback lives in exactly one place (`Shape:draw`) and every subclass inherits it.
- `self._local_points`, `self._world_points`, and `self._stroke_options` are cached on the instance and rebuilt only when the corresponding dirty flag fires.
- Every shape and drawable spec passes with zero edits.
