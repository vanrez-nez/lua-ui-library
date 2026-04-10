# Task 00: Compliance Review

## Goal

Turn the architecture findings into a spec-safe implementation plan before any runtime optimization lands.

## Current implementation notes

- `lib/ui/render/root_compositor.lua` still sizes isolated canvases from the active composition target instead of from subtree paint bounds.
- `lib/ui/core/container.lua` resolves a root-compositing plan for every visible node on every draw traversal.
- `lib/ui/shapes/fill_source.lua` rebuilds fill-surface and active-source tables on every shape draw, even for static shapes.
- `lib/ui/core/shape.lua` rebuilds local-point, world-point, and stroke-option tables per draw.
- `lib/ui/core/container.lua` mutates `clip_state.active_clips` as an append/remove stack on every clipped node draw.
- `Shape.__index` currently pays two hierarchy walks before checking the public-read surface.

## Status key

- `safe`: the finding can be implemented as an internal optimization without touching documented semantics.
- `spec-sensitive`: the finding is only allowed if the implementation preserves the published contract exactly and proves equivalence with focused tests.
- `excluded`: the finding as proposed would alter docs/spec, add contract surface, or rely on undocumented semantics.

## Review matrix

| Finding / refactor direction | Status | Why |
|---|---|---|
| Bounds-aware isolation canvases for root compositing | spec-sensitive | Allowed only if the visible result remains identical for root `shader`, root `opacity`, root `blendMode`, result clipping, composition-target-stack behavior, and current failure semantics. |
| Internal memoization of normalized compositing-plan fast paths | spec-sensitive | Safe only when treated as an internal cache over the current resolved state. No public dirty flag, no public opt-in, and no stale reuse across relevant property, motion, bounds, or clip changes. |
| Caching shape fill-surface / active-fill resolution | safe | The fill contract is unchanged if invalidation covers all `fill*` inputs, motion state, and local-bounds changes. |
| Reusing transient point / stroke / clip-stack scratch structures | safe | Internal allocation strategy is not public as long as no scratch object escapes and no error path leaks mutated state between nodes. |
| Optimizing `Shape.__index` lookup | spec-sensitive | Public read precedence must remain identical. This includes class lookup, inherited methods, public-surface reads, and nil fallthrough. |
| New public dirty flags, opt-in performance knobs, or public cache control | excluded | This would add new contract surface not present in the specs or the findings. |
| Heuristics that skip required isolation for non-default compositing state | excluded | This would violate the root-compositing contract. |
| Changing shader coordinate semantics or defining new shader sampling behavior as part of perf work | excluded | The current specs do not authorize a behavior change here. |

## Scope constraints for downstream tasks

- Preserve canonical compositing order:
  1. node-local paint result
  2. descendant contribution
  3. root shader
  4. root opacity
  5. composite into the immediate parent target using root blend mode
- Preserve current deterministic failure rules for invalid shader assignment, renderer-capability failure, and active-source failure.
- Do not change shape fill priority:
  - `fillTexture`
  - `fillGradient`
  - `fillColor`
- Do not change stretch vs tiling semantics for shape fill or background-image placement.
- Do not move any work from draw time into a public update/lifecycle contract unless the specs already require it.
- Do not introduce perf-only user-facing demo controls or public benchmark scenes. Perf harnesses should stay internal or reuse the existing profiling shell.

## Work items

- Record the implementation hotspots from the findings against concrete runtime modules.
- Record which proposed changes are safe, spec-sensitive, or excluded.
- Add an implementation-notes section to each downstream task explaining the relevant contract boundary and invalidation risks.
- Explicitly call out any optimization that must retain a fallback path to the current behavior until equivalence is proven.

## Deliverable

A phase-local review that future tasks can cite instead of re-litigating whether the work is contract-safe.

## Acceptance criteria

- Every major finding from `graphics_pipeline_analysis_findings.md` is classified as safe, spec-sensitive, or excluded.
- The review explicitly states that this phase is internal-only and does not authorize public contract changes.
- The review explicitly states that bounds-aware isolation and `Shape.__index` work are spec-sensitive, not automatic green lights.
- No downstream task requires a spec patch just to begin implementation.
