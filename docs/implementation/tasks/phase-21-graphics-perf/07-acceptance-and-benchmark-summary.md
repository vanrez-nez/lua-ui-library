# Task 07: Acceptance And Benchmark Summary

## Goal

Verify the graphics performance hardening work end to end and record what changed, what did not change, and what remains intentionally deferred.

## Scope

Runtime verification:

- rerun the phase-21 timing and memory baselines
- rerun the graphics-sensitive spec suite
- compare before/after hotspot behavior for the tasks actually implemented

Review verification:

- confirm no task introduced a new public API, dirty flag, or perf opt-in
- confirm no task changed canonical compositing order, isolation derivation, or failure semantics
- confirm any deferred optimization is documented with a reason

## Implementation notes

- This task remains bound by the task-00 compliance review; benchmark wins do not authorize behavior drift.
- Compare only like-for-like captures:
  - same command shape
  - same screen index
  - same internal stress-fixture setting when used
  - same profiling duration
- If internal-only observability probes from task 01 remain in place, keep them disabled unless the profiling env flags are active.
- Acceptance notes must call out any retained fallback path that keeps the old behavior for correctness proof reasons.

## Work

1. Rerun the same timing and memory commands recorded in task 01.
2. Compare before/after captures for at least:
   - opacity
   - blend mode
   - retained render effects
   - texture surfaces
3. Rerun the graphics-sensitive spec suite, including:
   - `spec/graphics_capability_helpers_spec.lua`
   - `spec/shape_opacity_spec.lua`
   - `spec/shape_fill_placement_spec.lua`
   - `spec/shape_fill_renderer_spec.lua`
   - `spec/shape_fill_motion_spec.lua`
   - all new focused specs added in tasks `02-06`
4. Write a short acceptance summary that records:
   - the hotspots addressed
   - the measured effect
   - any fallback path intentionally retained
   - any finding intentionally deferred

## Required acceptance notes

- If bounds-aware isolation ships only for a subset of compositor paths, record exactly which paths still use full-target isolation and why.
- If `Shape.__index` is left unchanged, record the reason and the measurement evidence.
- If any proposed allocation reduction was rejected because the aliasing or error-path risk was too high, record that explicitly.

## Exit criteria

- before/after benchmark artifacts exist for the same scenarios and commands
- the targeted graphics specs are green
- no public contract changes were required to land the accepted optimizations
- the acceptance summary is explicit enough that the next performance pass does not need to rediscover what phase 21 already proved or rejected

## Acceptance summary

### Environment

- Runtime: `LOVE 11.5 (Mysterious Mysteries)`
- Captured: 2026-04-10
- Harness: the env-driven profiling shell in `demos/common/demo_profiling.lua`, same commands as `baseline-summary.md`
- Artifact suffix: `*-after-task-07.txt` alongside the baseline `*-before.txt` files under `tmp/phase-21-graphics-perf/`

### Timing — before vs after (5s captures)

| Screen | Stage.draw total | clip_children total | Notable zone delta |
|---|---:|---:|---|
| opacity | 900.725ms → 826.845ms | 723.695ms → 644.535ms | `FillSource.resolve_surface` 52.401ms/4908 calls → 0.050ms/3 calls; `RootCompositor.resolve_node_plan` 76.607ms → 7.939ms |
| blend mode | 897.948ms → 870.674ms | 722.327ms → 682.257ms | `FillSource.resolve_surface` 52.049ms/4914 calls → 0.041ms/3 calls; `RootCompositor.resolve_node_plan` 77.444ms → 8.615ms |
| retained render effects | 615.073ms → 550.147ms | — | `RootCompositor.draw_isolated_subtree` 331.309ms → 283.729ms; `RootCompositor.resolve_node_plan` 33.792ms → 7.486ms |
| texture surfaces | 1279.560ms → 1158.917ms | 928.525ms → 797.381ms | `Shape._resolve_active_fill_placement` 35.985ms → 3.344ms; `FillPlacement.resolve` 13.646ms/1592 calls → 0.020ms/2 calls; `FillSource.resolve_surface` 37.614ms/3980 calls → 0.014ms/2 calls |
| dense isolation stress | 1800.261ms → 1620.399ms | 752.015ms → 516.148ms | `RootCompositor.draw_isolated_subtree` 1699.141ms → 1553.678ms; `RootCompositor.resolve_node_plan` 94.643ms → 17.246ms |

### Memory — before vs after (5s captures, self-alloc)

| Screen | clip_children self_alloc | Stage.draw self_alloc | Notable eliminated allocation |
|---|---:|---:|---|
| opacity | 63000.656 KB → 29405.664 KB | 14511.473 KB → 15489.852 KB | `FillSource.resolve_surface` 9533.195 KB → 6.070 KB; `RootCompositor.resolve_node_plan` 6814.297 KB → 9.063 KB; `FillSource.resolve_active_descriptor` 2142.000 KB → 1.313 KB |
| blend mode | 63153.582 KB → 29330.055 KB | 14581.105 KB → 15630.262 KB | `FillSource.resolve_surface` 9485.473 KB → 4.723 KB; `RootCompositor.resolve_node_plan` 6791.633 KB → 8.184 KB |
| retained render effects | — | 25338.586 KB → 24080.813 KB | `RootCompositor.resolve_node_plan` 8843.719 KB → 19.656 KB |
| texture surfaces | 43888.762 KB → 31830.699 KB | 30354.957 KB → 25426.785 KB | `FillSource.resolve_surface` 8149.984 KB → 4.047 KB; `FillPlacement.resolve` 5071.336 KB → 6.297 KB; `FillRenderer.draw` 4985.418 KB → 2227.805 KB; `Shape._resolve_active_fill_placement` 1763.996 KB → 254.949 KB |
| dense isolation stress | 45125.938 KB → 38120.844 KB | 10203.805 KB → 10751.641 KB | `RootCompositor.resolve_node_plan` 24632.652 KB → 94.453 KB |

Headline effects:

- The shape fill-resolution path (task 04) is now effectively free after the first draw: every `FillSource.*` and `FillPlacement.*` zone drops from thousands of calls per 5-second capture to single-digit calls. Both the time budget and the allocation footprint of that pipeline are eliminated for the steady-state.
- The root-compositing plan fast paths (task 03) reduced `RootCompositor.resolve_node_plan` from ~77ms/11466 calls to ~8ms/11410 calls across the opacity and blend-mode screens, and eliminated its steady-state allocation almost entirely. The dense-isolation capture went from 24.6 MB of `resolve_node_plan` self-allocation to 94 KB.
- Bounds-aware root isolation (task 02) shows most strongly on `Container.draw_subtree.clip_children`: the opacity and blend-mode screens dropped self-allocation there from ~63 MB to ~29 MB over 5 seconds, and dense-isolation `draw_subtree.clip_children` total time fell from 752ms to 516ms.
- Transient allocation reduction (task 05) shows up across `FillRenderer.draw` self-allocation (texture-surfaces: 4.9 MB → 2.2 MB) and `Shape._resolve_active_fill_placement` (1.7 MB → 0.25 MB), consistent with reusing scratch buffers rather than rebuilding them per frame.
- `Shape.__index` (task 06) is measurable at the Lua level via `tmp/shape_read_bench.lua`: ~1.68–1.73x speedup on the hot read path. No phase-21 hotspot on the 5-second captures listed `Shape.__index` as a top zone before or after, so the micro-benchmark is the primary signal; see task 06 for details.

### Spec verification

Captured in `tmp/phase-21-graphics-perf/spec-pass-after-task-07.txt`. Twelve of the fifteen targeted specs pass under the current working tree plus the pre-existing baseline (see "Pre-existing blockers" below):

```
PASS spec/graphics_capability_helpers_spec.lua
PASS spec/shape_fill_placement_spec.lua
PASS spec/shape_fill_motion_spec.lua
PASS spec/shape_primitive_surface_spec.lua
PASS spec/shape_fill_resolution_cache_spec.lua
PASS spec/shape_draw_helpers_spec.lua
PASS spec/shape_stroke_acceptance_spec.lua
PASS spec/shape_read_precedence_spec.lua
PASS spec/rect_shape_render_spec.lua
PASS spec/root_compositor_bounds_aware_isolation_spec.lua
PASS spec/root_compositor_plan_fast_paths_spec.lua
PASS spec/graphics_transient_allocation_reuse_spec.lua
FAIL spec/shape_opacity_spec.lua
FAIL spec/shape_fill_renderer_spec.lua
FAIL spec/nonrect_shape_spec.lua
```

The three failing specs are blocked by a pre-existing spec-versus-implementation drift in the circle polygon segment count, not by any phase 21 change. Details in "Pre-existing blockers".

### Required acceptance notes

- **Bounds-aware isolation fallback (task 02).** The optimized bounds-aware canvas sizing is engaged whenever the compositor can resolve a finite paint-bounds rectangle for the isolated subtree. The full-target fallback is retained in every case where the paint-bounds rectangle cannot be resolved (e.g., traversal-phase state where a subtree has not yet reported a bounds rectangle, or where the bounds resolver returns nil) and whenever root compositing state forces a full-size canvas. This fallback is preserved intentionally so that the "no public contract change" invariant holds even for nodes that phase 21 did not prove equivalent. Exercised by `spec/root_compositor_bounds_aware_isolation_spec.lua`.
- **`Shape.__index` optimization (task 06).** Not skipped. `Shape.__index` now performs a single class-hierarchy walk plus the public-surface read fallback; the redundant second walk against `Shape` was removed after regression coverage was added in `spec/shape_read_precedence_spec.lua`. Measurement evidence: `tmp/phase-21-graphics-perf/shape-read-bench-before-task-06.txt` vs `tmp/phase-21-graphics-perf/shape-read-bench-after-task-06.txt`, ~1.68–1.73x speedup on the hot read path.
- **Allocation reductions retained and rejected (task 05).** The accepted reductions reuse instance-local scratch buffers for polygon point arrays, stroke option tables, and the stroke-mask option variant so that sibling shapes cannot alias draw-time scratch. No scratch object is allowed to escape the node that owns it, and fill-resolution invalidation covers all fill motion/state changes so reused placement caches cannot go stale across updates. No proposed reduction was rejected on aliasing grounds in this phase; the record is that aliasing was the explicit non-negotiable constraint, not that it forced a rollback.

### Pre-existing blockers surfaced during verification

Three spec failures reproduce on the committed HEAD (`a809716 docs: graphics perf tasks`) and are not caused by the phase 21 optimization work:

- `spec/shape_opacity_spec.lua`, `spec/shape_fill_renderer_spec.lua`, `spec/nonrect_shape_spec.lua`
- Symptom in the raw HEAD: the `CircleShape` draw path enters an infinite recursion through `refresh_bounds → Shape:_get_world_bounds_points → CircleShape:_get_local_points → resolve_segments → getLocalBounds → ensure_current → update → _refresh_if_dirty → refresh_bounds`.
- Root cause: `resolve_segments` in `lib/ui/shapes/circle_shape.lua` was calling the public `shape:getLocalBounds()` getter, which triggers `ensure_current()` and re-enters the update cycle whenever resolve_segments runs from inside `refresh_bounds`. This was introduced by commit 59378db ("fix: shapes clipping and borders issue", 2026-04-09) when the same commit rewrote `resolve_segments` to compute segments dynamically from world radius instead of always returning `DEFAULT_SEGMENTS`.
- A minimal one-line fix was applied as part of this verification pass: `resolve_segments` now calls `shape:_get_shape_local_bounds()`, matching the convention already used by `triangle_shape.lua`, `diamond_shape.lua`, and `rect_shape.lua`. This eliminates the infinite recursion.
- Residual failure: after the recursion fix, `spec/shape_opacity_spec.lua`, `spec/shape_fill_renderer_spec.lua`, and `spec/nonrect_shape_spec.lua` still fail because their assertions encode hardcoded circle segment counts (e.g., `build_expected_circle_points(shape, 32)` in `spec/nonrect_shape_spec.lua:219`, "expected at least 3 matches for polygon:fill:64" in `spec/shape_opacity_spec.lua:548`). Those expected counts were written against the previous static `DEFAULT_SEGMENTS = 32` / `64` behavior, and commit 59378db never updated the specs when it made segment counts depend on world radius and scale. The fix for this residual is spec-side: rewrite the three assertions to build expected point sets from the same world-radius formula the runtime uses, or reroute the asserts through a helper that queries the shape for its effective segment count. This is explicitly deferred to a follow-up bug-fix task because it is spec drift from a pre-phase-21 commit, not phase 21 work.

### Deferred

- **Spec assertion update for circle segment counts** (see "Pre-existing blockers"). Not in phase 21 scope; needs its own task.
- **Further reductions against `Shape.draw` / `Container.draw_subtree.clip_children`.** These remain the top zones after phase 21 landed but are not free to shrink without touching draw-path contract surface. No proposal in this phase was accepted for them; the recommendation for the next pass is to start from the clip-stack snapshot behavior rather than the shape fill pipeline, since phase 21 has already driven the shape fill pipeline nearly to zero.
- **`Shape.draw` internal zone.** Still appears as a top-level zone in the after captures for the texture-surfaces screen. It was intentionally left alone; the internal `Shape._resolve_polygon_stroke_options` and `Shape._resolve_active_fill_placement` sub-zones already dropped to single-digit ms and KB, which is the load-bearing part.

### Exit criteria status

- **before/after benchmark artifacts exist for the same scenarios and commands**: met. Ten `*-after-task-07.txt` files (five timing + five memory) captured with the same commands documented in `baseline-summary.md`.
- **the targeted graphics specs are green**: partial. Twelve of fifteen targeted specs are green. The remaining three are blocked by pre-existing circle segment-count spec drift documented above; the phase 21 changes do not cause or unblock those assertions.
- **no public contract changes were required to land the accepted optimizations**: met. All optimizations are internal — no new public API, no new dirty flag, no perf opt-in, no change to canonical compositing order, isolation derivation, or failure semantics.
- **the acceptance summary is explicit enough that the next performance pass does not need to rediscover what phase 21 already proved or rejected**: met via this section plus the individual task Outcome notes.
