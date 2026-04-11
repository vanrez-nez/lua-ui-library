# Task 06: Shape Read Path Hot Access Review

## Goal

Evaluate and, if safe, optimize `Shape.__index` without changing public read semantics.

## Scope

In scope:

- `lib/ui/core/shape.lua`
- shared class-lookup helpers if they can be optimized without semantic change
- adding explicit regression tests for shape public-read precedence

Out of scope:

- changing the public readable prop set
- changing method/inheritance precedence
- changing error semantics for writes or invalid props

## Current implementation notes

- `Shape.__index` currently performs:
  1. hierarchy walk from the concrete shape class
  2. hierarchy walk from `Shape`
  3. `allowed_public_keys` lookup
  4. public-surface read fallback
- The architecture findings identify this as a hot-path cost paid on every shape property access.

## Implementation notes

- This task is spec-sensitive even though the exact internal lookup algorithm is not public, because observable property reads are public behavior.
- Any optimization must preserve:
  - inherited method lookup from the concrete class chain
  - inherited method lookup from `Shape`
  - public-surface reads through `_allowed_public_keys`
  - nil for unsupported reads
- Add explicit regression coverage for the precedence before changing the runtime.

## Work items

- Write focused tests that lock down current `Shape` read precedence.
- Audit whether the dual hierarchy walk is still necessary exactly as written.
- If safe, replace repeated hierarchy walks with a cached lookup structure or equivalent fast path.
- Keep the implementation easy to inspect; do not replace clear behavior with opaque micro-optimization unless the gain is measurable.

## File targets

- `lib/ui/core/shape.lua`
- any shared class-lookup helper introduced by the task
- new focused spec file(s)

## Testing

Required focused specs:

- add a dedicated spec for:
  - concrete-class method lookup precedence
  - `Shape` base-method lookup precedence
  - public-prop lookup precedence
  - unsupported-key nil behavior

Suggested existing regression suite:

- `spec/shape_primitive_surface_spec.lua`
- `spec/nonrect_shape_spec.lua`
- `spec/rect_shape_render_spec.lua`

Required runtime verification:

- compare before/after timing for dense shape scenes from the phase baseline

## Acceptance criteria

- Public read precedence is explicitly specified by regression tests before and after the optimization.
- Any runtime change improves the hot path measurably or is rejected with a documented note.
- No public shape-surface behavior changes.

## Outcome

- Added regression coverage for shape read precedence in `spec/shape_read_precedence_spec.lua` that locks down concrete-class method lookup, Shape base-method lookup, Container super-method lookup, public-prop reads, and nil behavior for unsupported keys.
- Audit conclusion: the second `walk_hierarchy(Shape, key)` call in `Shape.__index` was strictly redundant. Every concrete shape class extends `Shape`, so walking from `getmetatable(self)` already traverses `Shape -> Container -> Object` via the explicit `super` chain. Removing the second walk cannot reach a key the first walk has not already visited.
- Optimized `lib/ui/core/shape.lua` by dropping the redundant walk and caching `walk_hierarchy` / `get_public_read_value` as module-local upvalues to avoid per-read table lookups against `Container`.
- `__newindex` was intentionally left unchanged; the task is scoped to the read path.
- All shape regression specs that pass on baseline also pass after the change (`spec/shape_read_precedence_spec.lua`, `spec/shape_primitive_surface_spec.lua`, `spec/rect_shape_render_spec.lua`, `spec/shape_fill_resolution_cache_spec.lua`, `spec/shape_fill_motion_spec.lua`, `spec/shape_fill_placement_spec.lua`, `spec/shape_draw_helpers_spec.lua`, `spec/graphics_capability_helpers_spec.lua`, and the container surface suite). Pre-existing infinite-recursion failures in `spec/shape_fill_renderer_spec.lua` and `spec/shape_stroke_acceptance_spec.lua` (circle draw path hitting `refresh_bounds` during `getLocalBounds`) reproduce on baseline and are unrelated to this task.

## Runtime verification

Since the phase 21 baseline dense scenes require LÖVE and a GUI session, a Lua-level micro-benchmark was used as the runtime signal for the hot-access change. The harness reads ten mixed keys (mix of public props and inherited methods) on a `RectShape` and a `CircleShape` instance in a tight loop.

Harness: `tmp/shape_read_bench.lua` (500 000 iterations, 10 reads per iteration, 5M reads total per shape).

| Shape | Before (s) | After (s) | Speedup |
|---|---:|---:|---:|
| RectShape | 3.692 | 2.195 | ~1.68x |
| CircleShape | 3.615 | 2.093 | ~1.73x |

Artifacts: `tmp/phase-21-graphics-perf/shape-read-bench-before-task-06.txt`, `tmp/phase-21-graphics-perf/shape-read-bench-after-task-06.txt`. Three follow-up runs of the after-build stayed within ~2.1s–2.4s for both shapes, so the delta is well above noise.
