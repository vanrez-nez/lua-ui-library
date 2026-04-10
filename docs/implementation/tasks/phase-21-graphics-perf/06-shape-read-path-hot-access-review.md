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
