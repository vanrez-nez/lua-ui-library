# Phase 21 Baseline Summary

This document records the before-state benchmark and spec baseline for phase 21 graphics pipeline performance work.

## Harness notes

- Baselines were captured on `2026-04-10`.
- Runtime: `LOVE 11.5`.
- The graphics demo now records internal-only runtime zones during active timing or memory profiling. The probes stay dormant when profiling is off.
- `demos/04-graphics/screens/texture_surfaces.lua` now loads its source image through `TextureCommon.load_image()` so the demo works when launched as `love demos/04-graphics`.

## Capture matrix

| Screen | Index | Timing artifact | Memory artifact |
|---|---:|---|---|
| opacity | 1 | `tmp/phase-21-graphics-perf/opacity-before.txt` | `tmp/phase-21-graphics-perf/opacity-memory-before.txt` |
| blend mode | 2 | `tmp/phase-21-graphics-perf/blendmode-before.txt` | `tmp/phase-21-graphics-perf/blendmode-memory-before.txt` |
| retained render effects | 3 | `tmp/phase-21-graphics-perf/render-effects-before.txt` | `tmp/phase-21-graphics-perf/render-effects-memory-before.txt` |
| texture surfaces | 4 | `tmp/phase-21-graphics-perf/texture-surfaces-before.txt` | `tmp/phase-21-graphics-perf/texture-surfaces-memory-before.txt` |
| dense isolation stress | 5 | `tmp/phase-21-graphics-perf/dense-isolation-before.txt` | `tmp/phase-21-graphics-perf/dense-isolation-memory-before.txt` |

Screen `5` exists only when `UI_GRAPHICS_PERF_STRESS=1`.

## Commands

Timing:

```sh
UI_TIME_PROFILE=1 UI_TIME_PROFILE_SECONDS=5 UI_PROFILE_SCREEN=1 UI_TIME_PROFILE_OUTPUT=tmp/phase-21-graphics-perf/opacity-before.txt love demos/04-graphics
UI_TIME_PROFILE=1 UI_TIME_PROFILE_SECONDS=5 UI_PROFILE_SCREEN=2 UI_TIME_PROFILE_OUTPUT=tmp/phase-21-graphics-perf/blendmode-before.txt love demos/04-graphics
UI_TIME_PROFILE=1 UI_TIME_PROFILE_SECONDS=5 UI_PROFILE_SCREEN=3 UI_TIME_PROFILE_OUTPUT=tmp/phase-21-graphics-perf/render-effects-before.txt love demos/04-graphics
UI_TIME_PROFILE=1 UI_TIME_PROFILE_SECONDS=5 UI_PROFILE_SCREEN=4 UI_TIME_PROFILE_OUTPUT=tmp/phase-21-graphics-perf/texture-surfaces-before.txt love demos/04-graphics
UI_GRAPHICS_PERF_STRESS=1 UI_TIME_PROFILE=1 UI_TIME_PROFILE_SECONDS=5 UI_PROFILE_SCREEN=5 UI_TIME_PROFILE_OUTPUT=tmp/phase-21-graphics-perf/dense-isolation-before.txt love demos/04-graphics
```

Memory:

```sh
UI_MEMORY_PROFILE=1 UI_MEMORY_PROFILE_SECONDS=5 UI_PROFILE_SCREEN=1 UI_MEMORY_PROFILE_OUTPUT=tmp/phase-21-graphics-perf/opacity-memory-before.txt love demos/04-graphics
UI_MEMORY_PROFILE=1 UI_MEMORY_PROFILE_SECONDS=5 UI_PROFILE_SCREEN=2 UI_MEMORY_PROFILE_OUTPUT=tmp/phase-21-graphics-perf/blendmode-memory-before.txt love demos/04-graphics
UI_MEMORY_PROFILE=1 UI_MEMORY_PROFILE_SECONDS=5 UI_PROFILE_SCREEN=3 UI_MEMORY_PROFILE_OUTPUT=tmp/phase-21-graphics-perf/render-effects-memory-before.txt love demos/04-graphics
UI_MEMORY_PROFILE=1 UI_MEMORY_PROFILE_SECONDS=5 UI_PROFILE_SCREEN=4 UI_MEMORY_PROFILE_OUTPUT=tmp/phase-21-graphics-perf/texture-surfaces-memory-before.txt love demos/04-graphics
UI_GRAPHICS_PERF_STRESS=1 UI_MEMORY_PROFILE=1 UI_MEMORY_PROFILE_SECONDS=5 UI_PROFILE_SCREEN=5 UI_MEMORY_PROFILE_OUTPUT=tmp/phase-21-graphics-perf/dense-isolation-memory-before.txt love demos/04-graphics
```

Spec baseline:

```sh
lua spec/shape_opacity_spec.lua
lua spec/graphics_capability_helpers_spec.lua
lua spec/shape_fill_placement_spec.lua
lua spec/shape_fill_renderer_spec.lua
lua spec/shape_fill_motion_spec.lua
```

Spec pass artifact:

- `tmp/phase-21-graphics-perf/spec-baseline-before.txt`

## Internal observability surface

The baseline reports currently expose these internal-only zones:

- `Stage.draw`
- `Container.draw_subtree.clip_children`
- `RootCompositor.resolve_node_plan`
- `RootCompositor.plan_requires_isolation`
- `RootCompositor.draw_isolated_subtree`
- `FillSource.resolve_surface`
- `FillSource.resolve_active_descriptor`
- `FillPlacement.resolve`
- `FillRenderer.draw`
- `Shape._get_local_points`
- `Shape._resolve_active_fill_placement`
- `Shape._resolve_polygon_stroke_options`
- `Shape.draw`

## Before-state hotspot summary

| Screen | Frames / 5s | Timing hotspots | Memory hotspots |
|---|---:|---|---|
| opacity | 818 | `Stage.draw` avg `1.101ms`; `Container.draw_subtree.clip_children` `723.695ms`; `RootCompositor.resolve_node_plan` `76.607ms`; `FillSource.resolve_surface` `52.401ms` | `Container.draw_subtree.clip_children` `63000.656 KB` self alloc; `FillSource.resolve_surface` `9533.195 KB`; `FillSource.resolve_active_descriptor` `2142.000 KB` |
| blend mode | 819 | `Stage.draw` avg `1.096ms`; `Container.draw_subtree.clip_children` `722.327ms`; `RootCompositor.resolve_node_plan` `77.444ms`; `FillSource.resolve_surface` `52.049ms` | `Container.draw_subtree.clip_children` `63153.582 KB`; `FillSource.resolve_surface` `9485.473 KB`; `FillSource.resolve_active_descriptor` `2136.750 KB` |
| retained render effects | 749 | `Stage.draw` avg `0.821ms`; `RootCompositor.draw_isolated_subtree` `331.309ms`; `RootCompositor.resolve_node_plan` `33.792ms` | `Stage.draw` `25338.586 KB`; `RootCompositor.draw_isolated_subtree` `19368.719 KB`; `RootCompositor.resolve_node_plan` `8843.719 KB` |
| texture surfaces | 796 | `Stage.draw` avg `1.607ms`; `Container.draw_subtree.clip_children` `928.525ms`; `FillRenderer.draw` `288.002ms`; `Shape._resolve_active_fill_placement` `35.985ms`; `FillPlacement.resolve` `13.646ms` | `Container.draw_subtree.clip_children` `43888.762 KB`; `Stage.draw` `30354.957 KB`; `FillSource.resolve_surface` `8149.984 KB`; `FillPlacement.resolve` `5071.336 KB` |
| dense isolation stress | 412 | `Stage.draw` avg `4.370ms`; `RootCompositor.draw_isolated_subtree` `1699.141ms`; `Container.draw_subtree.clip_children` `752.015ms`; `RootCompositor.resolve_node_plan` `94.643ms` | `RootCompositor.draw_isolated_subtree` `64255.160 KB`; `Container.draw_subtree.clip_children` `45125.938 KB`; `RootCompositor.resolve_node_plan` `24632.652 KB` |

## Baseline spec status

- `PASS spec/shape_opacity_spec.lua`
- `PASS spec/graphics_capability_helpers_spec.lua`
- `PASS spec/shape_fill_placement_spec.lua`
- `PASS spec/shape_fill_renderer_spec.lua`
- `PASS spec/shape_fill_motion_spec.lua`
