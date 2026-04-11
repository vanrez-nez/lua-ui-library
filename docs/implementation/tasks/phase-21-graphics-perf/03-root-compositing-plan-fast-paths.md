# Task 03: Root Compositing Plan Fast Paths

## Goal

Reduce repeated per-node root-compositing work while preserving the current compositing contract and invalidation behavior.

## Scope

In scope:

- internal fast paths around `RootCompositor.resolve_node_plan(...)`
- memoization of normalized default-state decisions and other plan fragments
- invalidation tied to existing node property, motion, bounds, and result-clip contributors

Out of scope:

- new public dirty-flag APIs
- consumer-visible opt-in or opt-out switches
- skipping isolation when the current contract requires it
- changing the meaning of "resolved compositing state"

## Current implementation notes

- `Container.draw_subtree` calls `RootCompositor.resolve_node_plan(...)` for every visible node every draw traversal.
- Class capability lookup is already cached in `root_compositing_capability_cache`.
- Per-node state normalization still happens every frame even for static nodes in exact default state.
- Result-clip participation can depend on node-owned visuals such as visible stroke/border coverage, so invalidation cannot be limited to root props alone.

## Implementation notes

- This task is spec-sensitive because the phase-20 contract says the compositing state used at draw time must be the current resolved per-node state.
- Internal memoization is allowed only if every contributing input invalidates the cache before draw uses it.
- At minimum, invalidation must consider:
  - `opacity`
  - `blendMode`
  - `shader`
  - motion-written values on the same surface
  - node-specific compositing extras
  - node-specific result-clip contributors
- Do not couple this task to a new update-pass contract. The optimization must fit the existing retained invalidation model.

## Work items

- Identify the exact contributors to the compositing plan for `Drawable`, `Shape`, and plain `Container`.
- Introduce an internal memoization strategy for the normalized plan or plan fragments.
- Ensure any relevant property/motion change invalidates the cached plan before the next draw pass consumes it.
- Preserve the current nil/default fast path for non-adopting or default-state nodes.
- Add instrumentation or internal counters if needed to prove that plan recomputation drops for static trees.

## File targets

- `lib/ui/render/root_compositor.lua`
- `lib/ui/core/container.lua`
- any shared invalidation helpers introduced by the task

## Testing

Required focused specs:

- add a compositor-plan regression spec covering:
  - default-state node stays on the fast path
  - changing `opacity`, `blendMode`, or `shader` invalidates the cached plan
  - motion-written values invalidate the cached plan
  - result-clip-relevant visual changes invalidate the cached plan

Suggested existing regression suite:

- `spec/graphics_capability_helpers_spec.lua`
- `spec/shape_opacity_spec.lua`
- any root-compositing specs introduced in task 02

Required runtime verification:

- repeat the baseline timing captures and compare plan-resolution-heavy screens before/after
- if internal counters were added in task 01, confirm recomputation counts drop for static trees

## Acceptance criteria

- Static default-state trees spend less time in per-node compositing-plan resolution.
- Cache invalidation is explicit and covered by focused regression tests.
- No public dirty flag or new consumer knob is introduced.
- The current root-compositing semantics remain unchanged.

## Execution notes

- `RootCompositor.resolve_node_plan(...)` now caches per-node, per-runtime plan results and normalizes the no-plan and default-plan cases to shared internal sentinels.
- Cache invalidation is wired through plan-affecting public prop writes, responsive override replacement, root-surface motion writes, and world/bounds invalidation in the retained node model.
- Focused regression coverage lives in `spec/root_compositor_plan_fast_paths_spec.lua`.
- Task-03 timing captures were written to:
  - `tmp/phase-21-graphics-perf/opacity-after-task-03.txt`
  - `tmp/phase-21-graphics-perf/blendmode-after-task-03.txt`
  - `tmp/phase-21-graphics-perf/render-effects-after-task-03.txt`
  - `tmp/phase-21-graphics-perf/texture-surfaces-after-task-03.txt`
  - `tmp/phase-21-graphics-perf/dense-isolation-after-task-03.txt`
