# Task 01: Benchmark Baseline And Observability

## Goal

Establish repeatable timing and memory baselines for the current graphics pipeline before any optimization changes land.

## Scope

In scope:

- baseline timing captures for the current `demos/04-graphics` screens
- baseline memory captures for the same screens
- optional internal-only counters or probes for root-compositing, fill-resolution, and clip-stack hot paths
- storing benchmark instructions and output locations in a phase-local summary or README note

Out of scope:

- performance-driven API changes
- user-facing demo chrome added only for profiling
- changing behavior during measurement

## Current implementation notes

- `demos/04-graphics/main.lua` already wires `DemoProfiling` with timing, JIT, and memory prefixes.
- `demos/common/demo_profiling.lua` already supports env-driven automatic capture and screen selection.
- internal-only runtime zones may be added for the phase as long as they stay removable and do not alter draw behavior when profiling is off.
- The phase-local baseline summary and output matrix should live beside this task in `baseline-summary.md`.

## Work items

- Define the baseline capture matrix at minimum for these screens:
  1. opacity
  2. blend mode
  3. retained render effects
  4. texture surfaces
- Record the exact commands used to gather timings and memory.
- Prefer the existing env-based profiling shell before adding new instrumentation.
- If additional counters are required, keep them internal-only and removable after the phase.
- Record at least one dense-case capture where isolated compositing is active on many nodes, using either:
  - an internal stress fixture outside the public demo surface, or
  - a temporary internal harness built on the existing graphics demo shell
- If the dense case is added to the shared demo shell, gate it behind an internal env flag so the normal user-facing screen list stays unchanged.
- Capture baseline spec results for the graphics-sensitive specs that downstream tasks must keep green.

## Suggested baseline commands

Timing example:

```sh
UI_TIME_PROFILE=1 \
UI_TIME_PROFILE_SECONDS=5 \
UI_PROFILE_SCREEN=1 \
UI_TIME_PROFILE_OUTPUT=tmp/phase-21-graphics-perf/opacity-before.txt \
love demos/04-graphics
```

Memory example:

```sh
UI_MEMORY_PROFILE=1 \
UI_MEMORY_PROFILE_SECONDS=5 \
UI_PROFILE_SCREEN=4 \
UI_MEMORY_PROFILE_OUTPUT=tmp/phase-21-graphics-perf/texture-surfaces-memory-before.txt \
love demos/04-graphics
```

Dense internal stress example:

```sh
UI_GRAPHICS_PERF_STRESS=1 \
UI_TIME_PROFILE=1 \
UI_TIME_PROFILE_SECONDS=5 \
UI_PROFILE_SCREEN=5 \
UI_TIME_PROFILE_OUTPUT=tmp/phase-21-graphics-perf/dense-isolation-before.txt \
love demos/04-graphics
```

## File targets

- `demos/04-graphics/main.lua`
- `demos/common/demo_profiling.lua`
- optional internal harness files if the existing screens are not sufficient
- `docs/implementation/tasks/phase-21-graphics-perf/baseline-summary.md`
- phase-21 task docs or a sibling baseline summary document

## Testing

Required runtime verification:

- capture timing output for all four graphics screens
- capture memory output for all four graphics screens
- if internal counters are added, verify they can be disabled with no behavior change

Required spec verification before optimization work begins:

- `spec/shape_opacity_spec.lua`
- `spec/graphics_capability_helpers_spec.lua`
- `spec/shape_fill_placement_spec.lua`
- `spec/shape_fill_renderer_spec.lua`
- `spec/shape_fill_motion_spec.lua`
- any existing spec directly touched by the instrumentation work

## Acceptance criteria

- A reproducible before-state timing and memory baseline exists for the phase.
- The benchmark commands, screen indices, and output paths are documented.
- Any added observability surface is internal-only and removable after the phase.
- The baseline spec pass list is recorded and green before optimization work proceeds.
