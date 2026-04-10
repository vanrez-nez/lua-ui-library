# Phase 21: Graphics Pipeline Performance Hardening

This phase translates [graphics_pipeline_analysis_findings.md](/Users/vanrez/Documents/game-dev/lua-ui-library/graphics_pipeline_analysis_findings.md) into implementation tasks for the current `lib/ui` runtime.

The phase is intentionally constrained:

- no public API expansion
- no public prop-surface changes
- no spec or behavior changes hidden under "performance"
- no weakening of deterministic failure semantics
- no changes to canonical compositing order, isolation derivation, or shape-fill priority

This phase is about internal cost reduction only.

Authoritative contracts remain:

- [UI Foundation Specification](/Users/vanrez/Documents/game-dev/lua-ui-library/docs/spec/ui-foundation-spec.md)
- [UI Graphics Specification](/Users/vanrez/Documents/game-dev/lua-ui-library/docs/spec/ui-graphics-spec.md)
- [UI Motion Specification](/Users/vanrez/Documents/game-dev/lua-ui-library/docs/spec/ui-motion-spec.md)
- phase-20 root-compositing and shape-fill tasks in [phase-20](/Users/vanrez/Documents/game-dev/lua-ui-library/docs/implementation/tasks/phase-20)

Phase assumptions:

- the phase-20 graphics/runtime contracts are already authoritative
- `lib/ui/render/root_compositor.lua` is the shared retained isolation runtime
- `lib/ui/shapes/fill_source.lua`, `fill_placement.lua`, and `fill_renderer.lua` are the hot path for shape non-color fill
- `demos/04-graphics/main.lua` and `demos/common/demo_profiling.lua` are the existing profiling entry points and should be reused before adding new harnesses

Task order:

1. `00-compliance-review.md`
2. `01-benchmark-baseline-and-observability.md`
3. `02-bounds-aware-root-isolation.md`
4. `03-root-compositing-plan-fast-paths.md`
5. `04-shape-fill-resolution-caching.md`
6. `05-transient-allocation-reduction.md`
7. `06-shape-read-path-hot-access-review.md`
8. `07-acceptance-and-benchmark-summary.md`

Phase-wide stop conditions:

- If bounds-aware isolation cannot preserve current root `shader`, root `opacity`, root `blendMode`, result-clip, and immediate-parent-target semantics, stop and open a spec/incident discussion instead of landing the optimization.
- If compositing-plan caching requires a new public dirty flag, public opt-in, or any documented lifecycle contract change, stop and resolve that contract first.
- If shape `__index` optimization changes public read precedence, `allowed_public_keys` behavior, or failure semantics, stop and resolve that contract first.

Exit criteria:

- representative graphics timing and memory baselines exist before and after the phase
- the targeted hotspots from the analysis have a concrete implementation or an explicit rejection note backed by proof
- existing graphics specs still pass
- no task in the phase requires a spec patch to explain its behavior
- the final acceptance summary records what improved, what stayed intentionally unchanged, and what remains deferred
