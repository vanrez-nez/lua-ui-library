# Image Stress Performance Task

## Goal

Improve the runtime performance of `demos/06-performance` for the retained
`Image` stress case so that the 100-image scenario no longer drops into the
current low-FPS range.

## Scope

In scope:

- performance investigation and optimization for the retained `Image` draw path
- per-frame CPU time reduction for the 100-image bounce case
- Lua heap churn reduction during steady-state rendering
- internal caching or fast paths that do not change the public `Image` contract
- updated benchmark captures for before/after comparison

Out of scope:

- changing the public `Image` API or graphics spec
- adding demo-only rendering shortcuts that bypass the real retained path
- replacing `Image` with direct `love.graphics.draw` calls in the demo
- unrelated optimization work outside the `Image`/`Drawable`/styling/render-plan path

## Profile Target

Demo:

- `demos/06-performance`
- screen 1: `demos/06-performance/screens/empty.lua`

Scenario:

- 10 bouncing `Image` nodes sharing one `Texture`
- 100 bouncing `Image` nodes sharing one `Texture`

Baseline capture env:

- `UI_PERF_IMAGE_COUNT=10`
- `UI_PERF_IMAGE_COUNT=100`

## Baseline Commands

Timing baseline:

```sh
UI_PERF_IMAGE_COUNT=100 \
UI_TIME_PROFILE=1 \
UI_TIME_PROFILE_SECONDS=5 \
UI_PROFILE_SCREEN=1 \
UI_TIME_PROFILE_OUTPUT=tmp/06-performance-timing-100.txt \
love demos/06-performance
```

Memory baseline:

```sh
UI_PERF_IMAGE_COUNT=100 \
UI_MEMORY_PROFILE=1 \
UI_MEMORY_PROFILE_SECONDS=5 \
UI_PROFILE_SCREEN=1 \
UI_MEMORY_PROFILE_OUTPUT=tmp/06-performance-memory-100.txt \
love demos/06-performance
```

Sampled hotspot baseline:

```sh
UI_PERF_IMAGE_COUNT=100 \
UI_JIT_PROFILE=1 \
UI_JIT_PROFILE_SECONDS=5 \
UI_PROFILE_SCREEN=1 \
UI_JIT_PROFILE_OUTPUT=tmp/06-performance-jit-100.txt \
love demos/06-performance
```

10-image baseline:

```sh
UI_PERF_IMAGE_COUNT=10 \
UI_TIME_PROFILE=1 \
UI_TIME_PROFILE_SECONDS=5 \
UI_PROFILE_SCREEN=1 \
UI_TIME_PROFILE_OUTPUT=tmp/06-performance-timing-10.txt \
love demos/06-performance
```

## Baseline Artifacts

- [06-performance-timing-10.txt](/Users/vanrez/Documents/game-dev/lua-ui-library/tmp/06-performance-timing-10.txt)
- [06-performance-memory-10.txt](/Users/vanrez/Documents/game-dev/lua-ui-library/tmp/06-performance-memory-10.txt)
- [06-performance-timing-100.txt](/Users/vanrez/Documents/game-dev/lua-ui-library/tmp/06-performance-timing-100.txt)
- [06-performance-memory-100.txt](/Users/vanrez/Documents/game-dev/lua-ui-library/tmp/06-performance-memory-100.txt)
- [06-performance-jit-100.txt](/Users/vanrez/Documents/game-dev/lua-ui-library/tmp/06-performance-jit-100.txt)

## Measured Baseline

10 images:

- about `163 FPS`
- about `6.14 ms/frame`
- `Stage.draw` average about `0.710 ms/frame`

100 images:

- about `49.8 FPS`
- about `20.07 ms/frame`
- `Stage.draw` average about `5.299 ms/frame`

Observed scaling from 10 to 100 images:

- about `+13.93 ms/frame` total frame cost
- about `+4.59 ms/frame` inside the explicit `Stage.draw` timing zone

Memory baseline summary:

- 100-image run: `Stage.draw` self allocation about `264396.7 KB` over 5 seconds
- 10-image run: `Stage.draw` self allocation about `141368.4 KB` over 5 seconds
- `RootCompositor.resolve_node_plan` and `plan_requires_isolation` both scale with node count, but they are secondary to the main `Stage.draw` cost

## Findings

### 1. `Image` inherits unconditional `Drawable` styling work

`Image` extends `Drawable`, and [Drawable:draw](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/core/drawable.lua:576)
always runs:

- `Styling.assemble_props(...)`
- `Styling.draw(...)`

Even in the performance demo, where the `Image` nodes are unstyled, the sampled
hotspots still show styling-related read paths:

- `assemble_props`
- `resolve_layers`
- `resolve_side_quad_layer`
- `resolve_corner_quad_layer`

This indicates that `Image` is paying style-resolution cost that is not useful
for this screen.

### 2. `Image:_draw_control` does per-frame allocation work

Hot code path:

- [lib/ui/graphics/image.lua](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/graphics/image.lua:161)

Per-draw work includes:

- creating a fresh region table for `Texture` sources
- creating a new `Rectangle` in `resolveImageRect`
- creating a new `Quad` every draw
- setting texture filter every draw

This matches the high Lua heap churn captured by the memory profiler.

### 3. Proxy-backed property reads are a visible hotspot

The sampled report shows `read_declared` and proxy `__index` in
[proxy.lua](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/utils/proxy.lua:13)
as high-frequency costs.

This suggests a meaningful part of the frame is being spent on retained prop
read indirection during draw-time styling and geometry access.

### 4. Root compositor planning scales linearly but is not the primary bottleneck

Measured average per frame:

- 10 images:
  - `RootCompositor.resolve_node_plan`: about `0.049 ms/frame`
  - `RootCompositor.plan_requires_isolation`: about `0.008 ms/frame`
- 100 images:
  - `RootCompositor.resolve_node_plan`: about `0.372 ms/frame`
  - `RootCompositor.plan_requires_isolation`: about `0.051 ms/frame`

This is real cost, but it does not explain the majority of the FPS drop by
itself.

## Primary Optimization Targets

1. Introduce a fast path so unstyled `Image` nodes do not pay full
   `Drawable` styling assembly and styling paint resolution each frame.
2. Reduce or eliminate per-frame `Image` draw allocations:
   - cache texture-region data
   - cache reusable quads when source region is stable
   - avoid creating transient rectangles/tables in the hot path
3. Avoid redundant per-frame `setFilter(...)` calls when sampling mode has not changed.
4. Review the highest-frequency proxy read paths involved in `Image` draw and
   styling resolution, and cut unnecessary repeated reads in the hot loop.

## Work Items

- Add explicit timing comparison notes for the 10-image and 100-image cases in
  the implementation summary after optimization.
- Audit `Image` draw behavior against the spec to confirm that any fast path
  preserves:
  - `fit`
  - `alignX`
  - `alignY`
  - `sampling`
  - `cover` clipping behavior
- Implement an internal fast path for `Image` draw when no styling surface is active.
- Cache stable draw artifacts in `Image` where safe:
  - source view data
  - region/quad objects
  - sampling state applied to the shared drawable
- Re-profile timing, memory, and sampled hotspots after optimization.
- Compare before/after results using the same 5-second capture window and the
  same `UI_PERF_IMAGE_COUNT` values.

## File Targets

- `demos/06-performance/screens/empty.lua`
- `lib/ui/graphics/image.lua`
- `lib/ui/core/drawable.lua`
- `lib/ui/render/styling.lua`
- `lib/ui/utils/proxy.lua`
- any helper/cache module added to support the `Image` fast path

## Testing

Required runtime verification:

- run `demos/06-performance` at default count and verify visible bouncing behavior
- verify left click still spawns `+10` images
- verify the 100-image case still uses one shared `Texture`
- capture new timing, memory, and sampled hotspot reports for 10 and 100 images

Required correctness verification:

- validate `Image` behavior still matches the graphics spec for:
  - `contain`
  - `cover`
  - `stretch`
  - `none`
  - `sampling`
- run any existing spec directly affected by changes in:
  - `lib/ui/graphics/image.lua`
  - `lib/ui/core/drawable.lua`
  - `lib/ui/render/styling.lua`
  - `lib/ui/utils/proxy.lua`

## Acceptance Criteria

- The 100-image `demos/06-performance` case shows a clear FPS improvement over
  the current baseline.
- Timing and memory captures are regenerated with the same profiling commands.
- The dominant hotspot share attributed to unconditional styling work and
  per-frame `Image` allocation is measurably reduced.
- No public `Image` behavior regresses relative to the documented spec.
