# Task 01: Source Audit Prep And Helper Consolidation

## Goal

Land every small, orthogonal source-audit item that clears the path for later tasks, so tasks 02–10 work on a clean base. Each item is independently verifiable and none of them depends on the new object-model modules.

## Scope

In scope:

- fix the latent `Schema.validate` signature bug (`DC-02`)
- remove dead code identified in `DC-01` and `DC-03`
- make the styling canvas pool weak-keyed (`ML-03`)
- consolidate the helper duplication identified in `CS-01`, `CS-02`, `CS-03`, `CS-04`, `CS-05`
- introduce `lib/ui/render/canvas_pool_registry.lua` as the single weak-keyed canvas pool accessor

Out of scope:

- any work that touches the object-model modules (`DirtyState`, `Proxy`, `Reactive`, `Rule`, `Schema(instance)`)
- any behavior change in rendering, layout, or control logic
- any public API change

## Spec anchors

- [source_code_audit_findings.md](/Users/vanrez/Documents/game-dev/lua-ui-library/audits/source_code_audit_findings.md) — `DC-01`, `DC-02`, `DC-03`, `ML-03`, `CS-01`, `CS-02`, `CS-03`, `CS-04`, `CS-05`

## Current implementation notes

- `lib/ui/utils/schema.lua:7` declares `function Schema.validate(schema, key, value, ctx_obj, level, ctx_name)` but line 41 references `full_opts`, which is not in the signature. The caller at line 53 passes a 7th argument (`opts`) that the function silently drops. Any custom validator that relies on the 5th argument receives `nil`.
- `lib/ui/core/drawable.lua:21-49` defines `Drawable.__index` and `Drawable.__newindex`. Lines 410–438 redefine both — the first block is overwritten at load time and never executes.
- `lib/ui/shapes/draw_helpers.lua:316` exports `DrawHelpers.for_each_dashed_segment` (65 lines). No caller anywhere in the codebase references it.
- `lib/ui/render/styling.lua:22` initializes `local canvas_pools = {}` with a plain table, while `lib/ui/render/root_compositor.lua:30` correctly uses `setmetatable({}, { __mode = 'k' })`. The `styling.lua` pool retains strong references to graphics adapters.
- `save_color`/`restore_color` appear in both `lib/ui/shapes/draw_helpers.lua:8-27` and `lib/ui/shapes/fill_renderer.lua:19-38` as identical 20-line implementations.
- `positive_mod` appears in both `lib/ui/shapes/draw_helpers.lua:33-44` and `lib/ui/shapes/circle_shape.lua:50-61` as identical 12-line implementations.
- `copy_bounds` appears in both `lib/ui/shapes/fill_placement.lua:6-13` and `lib/ui/render/source_placement.lua:5-12` as identical 8-line implementations. `lib/ui/core/rectangle.lua` provides `Rectangle:clone()` but the duplication operates on plain tables, not Rectangle instances.
- Local `clamp(value, lo, hi)` is defined in `lib/ui/controls/slider.lua:8`, `lib/ui/controls/progress_bar.lua:8`, `lib/ui/controls/text_input.lua:9`, `lib/ui/scroll/scrollable_container.lua:56`, and `lib/ui/scene/transitions.lua:9`. `lib/ui/utils/math.lua:23` has a `clamp_number` that always applies `max(0, value)` and is not a drop-in replacement.
- `lib/ui/render/root_compositor.lua:101-112` and `lib/ui/render/styling.lua:23-30` each define their own `get_canvas_pool` accessor.

## Work items

- **DC-02.** Update `lib/ui/utils/schema.lua` so `Schema.validate` takes a 7th parameter `opts` and the body references `opts` instead of `full_opts`. Update the call site in `Schema.validate_all` so the 7th argument is correctly forwarded. Run the full spec suite to confirm no behavior regression.
- **DC-01.** Delete lines 21–49 from `lib/ui/core/drawable.lua` (the dead first definitions of `Drawable.__index` and `Drawable.__newindex`). Confirm the second definitions at 410–438 remain intact.
- **DC-03.** Delete `DrawHelpers.for_each_dashed_segment` (65 lines) from `lib/ui/shapes/draw_helpers.lua`. Confirm zero grep hits for the symbol across the tree.
- **ML-03.** In `lib/ui/render/styling.lua`, change `local canvas_pools = {}` to `local canvas_pools = setmetatable({}, { __mode = 'k' })` so the graphics-adapter key is weakly referenced. (This will be consolidated in the canvas pool registry step below but the weak-keying change lands here so it is reviewable on its own.)
- **CS-01.** Choose `lib/ui/shapes/draw_helpers.lua` as the canonical owner of `save_color`/`restore_color`. Remove the duplicate definitions from `lib/ui/shapes/fill_renderer.lua` and import them from `draw_helpers` instead.
- **CS-02.** Move `positive_mod` from `lib/ui/shapes/draw_helpers.lua` and `lib/ui/shapes/circle_shape.lua` into `lib/ui/utils/math.lua` as `MathUtils.positive_mod(value, modulus)`. Update both call sites to import it.
- **CS-03.** Replace the two duplicated `copy_bounds` implementations with either `Rectangle:clone()` (preferred if the bounds are already Rectangle instances) or a single small helper in `lib/ui/core/rectangle.lua`. Update both call sites.
- **CS-04.** Add `MathUtils.clamp(value, lo, hi)` to `lib/ui/utils/math.lua`. Replace the five local copies in slider, progress_bar, text_input, scrollable_container, and transitions. The existing `MathUtils.clamp_number` stays where it is because its max(0, value) semantics are different.
- **CS-05.** Create `lib/ui/render/canvas_pool_registry.lua`. Expose a single `CanvasPoolRegistry.get_for(graphics_adapter)` accessor that returns or lazily creates a canvas pool keyed weakly on the graphics adapter. Rewrite the `get_canvas_pool` accessors in `lib/ui/render/root_compositor.lua` and `lib/ui/render/styling.lua` to call the registry. This supersedes the ad hoc `ML-03` weak-keying change and leaves only one canvas pool per graphics adapter system-wide.

## File targets

- `lib/ui/utils/schema.lua`
- `lib/ui/core/drawable.lua`
- `lib/ui/shapes/draw_helpers.lua`
- `lib/ui/shapes/fill_renderer.lua`
- `lib/ui/shapes/circle_shape.lua`
- `lib/ui/shapes/fill_placement.lua`
- `lib/ui/render/source_placement.lua`
- `lib/ui/core/rectangle.lua` (only if the chosen `copy_bounds` approach adds a helper there)
- `lib/ui/utils/math.lua`
- `lib/ui/controls/slider.lua`
- `lib/ui/controls/progress_bar.lua`
- `lib/ui/controls/text_input.lua`
- `lib/ui/scroll/scrollable_container.lua`
- `lib/ui/scene/transitions.lua`
- `lib/ui/render/root_compositor.lua`
- `lib/ui/render/styling.lua`
- `lib/ui/render/canvas_pool_registry.lua` (new)

## Testing

Required runtime verification:

- `love demos/04-graphics` renders identically to the pre-task baseline across all four graphics screens
- at least one interactive demo that exercises Slider, ProgressBar, TextInput, and ScrollableContainer renders identically

Required spec verification:

- `spec/core_math_spec.lua`
- `spec/shape_draw_helpers_spec.lua`
- `spec/shape_fill_renderer_spec.lua`
- `spec/rect_shape_render_spec.lua`
- `spec/nonrect_shape_spec.lua`
- `spec/styling_renderer_spec.lua`
- `spec/root_compositor_plan_fast_paths_spec.lua`
- `spec/root_compositor_bounds_aware_isolation_spec.lua`
- `spec/scrollable_container_spec.lua`
- full spec suite green after the task

## Acceptance criteria

- `Schema.validate` accepts and forwards `opts` as its 7th parameter; zero references to `full_opts` remain.
- `lib/ui/core/drawable.lua` has exactly one definition of `__index` and one of `__newindex`.
- `DrawHelpers.for_each_dashed_segment` is gone; grep returns zero matches.
- `lib/ui/render/canvas_pool_registry.lua` exists and is the only definition of a canvas pool accessor in the codebase; `root_compositor.lua` and `styling.lua` both consume it.
- Zero local `clamp(value, lo, hi)` helpers remain in the five controls listed; all call `MathUtils.clamp`.
- Zero duplicate definitions of `save_color`, `restore_color`, `positive_mod`, or `copy_bounds` remain.
- The full `spec/` suite passes with zero edits to any spec file.
