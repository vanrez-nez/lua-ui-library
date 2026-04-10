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
