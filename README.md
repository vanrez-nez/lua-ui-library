# Lua UI Library

Standalone LÖVE project for the extracted `lib/ui` package from `idle-game`.

## Run

From the project root:

```bash
love .
```

That opens the default scene showcase with three library-focused scenes:

- `home`
- `components`
- `transforms`

## Manual Demos

The original focused demos were copied over so component work can stay isolated:

```bash
love _test/phase1
love _test/ui
love _test/button
love _test/text
love _test/scene
```

## Focused Component Demos

The rebuilt demos under `demos/` are component-centered and follow the shared demo shell in `demos/common/`:

```bash
love demos/01-container
love demos/02-drawable
```

`01-container` covers retained tree, bounds, sizing, clamp, and visibility behavior.
`02-drawable` only covers the `Drawable` surface not already proven by `01-container`: alignments, padding, margin, opacity, skin, blend mode, retained render effects, and motion inspection. The demo does not currently include a dedicated shader screen, and mask rendering still fails deterministically until a concrete mask asset contract is implemented.

## Unit Tests

The non-graphics core has a lightweight Lua test suite:

```bash
lua scripts/run_unit_tests.lua
```

## Project Layout

- `lib/ui`: extracted library code
- `scenes`: default showcase scenes for day-to-day iteration
- `_test`: manual LÖVE demos copied from the source project
- `test`: intentionally empty staging area for rebuilt demos
- `spec`: headless unit tests for core math and layout behavior
- `assets`: demo font and image dependencies

## Profiling

The `demos/02-drawable` demo includes three profiling modes for the retained render pipeline:

- `P`: sampled `jit.p` hotspot profiling
- `T`: wall-time profiling in milliseconds
- `Y`: Lua heap memory profiling with `collectgarbage("count")`

Reports are written to `tmp/`.

Interactive use:

```bash
love demos/02-drawable
```

Then press:

- `P` to start/stop the sampled profiler
- `T` to start/stop the timing profiler
- `Y` to start/stop the memory profiler

Non-interactive capture:

```bash
UI_JIT_PROFILE=1 UI_PROFILE_SCREEN=1 UI_JIT_PROFILE_SECONDS=3 love demos/02-drawable
UI_TIME_PROFILE=1 UI_PROFILE_SCREEN=1 UI_TIME_PROFILE_SECONDS=3 love demos/02-drawable
UI_MEMORY_PROFILE=1 UI_PROFILE_SCREEN=1 UI_MEMORY_PROFILE_SECONDS=3 love demos/02-drawable
```

Useful environment variables:

- `UI_PROFILE_SCREEN`: screen index to open before capture
- `UI_JIT_PROFILE_OUTPUT`: explicit output path for the sampled report
- `UI_TIME_PROFILE_OUTPUT`: explicit output path for the timing report
- `UI_MEMORY_PROFILE_OUTPUT`: explicit output path for the memory report

Output types:

- `jit.p`: sampled hotspots by zone and stack
- `timing`: `total_ms`, `self_ms`, `avg_ms`, `max_ms`, and call counts per zone
- `memory`: Lua heap churn by zone; signed `net` columns may be negative when a zone frees more heap than it retains
