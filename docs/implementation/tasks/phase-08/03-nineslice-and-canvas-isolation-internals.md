# Task 03: Nine-Slice And Canvas Isolation Internals

## Goal

Implement the render helpers needed for nine-slice drawing and subtree isolation without promoting their helper-module shapes to public API.

## Spec Anchors

- `docs/spec/ui-foundation-spec.md §8.10 Texture And Atlas Contract`
- `docs/spec/ui-foundation-spec.md §8.11 Nine-Slice Contract`
- `docs/spec/ui-foundation-spec.md §8.13 Shader Contract`
- `docs/spec/ui-foundation-spec.md §8.14 Isolation Rules`
- `docs/spec/ui-foundation-spec.md §8.15 Performance Rules`

## Scope

- Implement nine-slice texture subdivision and draw support
- Implement canvas-isolation internals for opacity, blend mode, shader, and mask cases that require offscreen compositing
- Implement caching behavior for geometry and render descriptions where safe
- Keep the implementation aligned to the foundation visual contract even when the phase draft describes concrete helper policies

## Required Behavior

- Nine-slice geometry must obey the spec’s cut-line and corner-scaling rules.
- Isolation must be triggered only when the spec requires it.
- Performance helpers should prefer native Love2D primitives where contract-compliant.
- Invalid shaders and invalid skin assets must fail deterministically.

## Public Surface Boundary

- The concrete module names, helper structs, and pool internals are implementation detail.
- The phase doc’s bucket sizing, release policy, and helper-module layout can remain internal policy, but none of them should be treated as public contract.

## Non-Goals

- No new public render graph API.
- No public guarantee on canvas pool sizing policy.

## Acceptance Checks

- Nine-slice output respects the spec’s edge and center rules.
- Isolation is used when opacity, blend mode, or shader composition requires it.
- Custom renderer errors are not swallowed.
- The helper implementation does not expose a new public API beyond the documented skin and effect contract.
