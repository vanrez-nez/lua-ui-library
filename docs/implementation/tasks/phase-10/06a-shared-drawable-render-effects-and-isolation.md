# Task 06A: Shared Drawable Render Effects And Isolation

## Goal

Implement the shared retained render path required to apply `Drawable` visual effects according to the current foundation, graphics, and motion specs.

This task exists because the earlier `Drawable` phase intentionally stabilized the public surface before activating full render behavior. The current spec set now requires that behavior, and control retrofits cannot safely normalize around shader-capable or effect-bearing surfaces until the shared base path exists.

## Spec Anchors

- `docs/spec/ui-foundation-spec.md §3A.5 Rendering Model Declaration`
- `docs/spec/ui-foundation-spec.md §7.4 Inherited Render-Effect Chain`
- `docs/spec/ui-foundation-spec.md §8.6 Visual Inheritance Within Composition`
- `docs/spec/ui-foundation-spec.md §8.8 Part-Level Skin Contract`
- `docs/spec/ui-foundation-spec.md §8.9 Render Skin Resolution`
- `docs/spec/ui-foundation-spec.md §8.13 Shader Contract`
- `docs/spec/ui-foundation-spec.md §8.14 Isolation Rules`
- `docs/spec/ui-motion-spec.md §4B Motion Surface Model`
- `docs/spec/ui-motion-spec.md §4C Motion Property Model`

## Scope

- Shared render-effect application for retained `Drawable` nodes
- Effect-chain propagation through retained tree traversal
- Subtree isolation decisions for `shader`, `opacity`, `blendMode`, and `mask`
- Correct compositing of isolated subtrees back into the parent render path
- Motion-written visual values when they target documented root surfaces
- Guarded deterministic failure when shader-capable rendering cannot be executed

## Concrete Module Targets

- Patch `lib/ui/core/container.lua` draw traversal internals instead of introducing a parallel renderer
- Patch `lib/ui/core/drawable.lua` only where a stable helper boundary is needed for shared render-effect resolution
- Reuse existing internal render helpers under `lib/ui/render/` only when they fit the shared retained pipeline cleanly
- Add focused specs beside the existing drawable/container coverage instead of relying only on a manual harness

## Implementation Guidance

- Read the current `Container:_draw_subtree_resolved(...)` and `Stage:draw(...)` flow first and patch it in place. This is shared retained-runtime work, not a demo-local workaround and not a control-local renderer.
- Preserve the current public `Drawable` surface: `shader`, `opacity`, `blendMode`, and `mask` remain the entry points. Do not replace them with a second public visual-state channel.
- Keep effect handling aligned with the inherited render-effect chain. The implementation should not treat each node as a disconnected immediate-mode draw call once visual effects are active.
- Introduce isolation only when the published rules require it. Do not isolate every drawable speculatively.
- When isolation is required, render the relevant subtree to an offscreen target, then composite it back using the subtree root's documented effect state.
- Integrate motion-owned visual values through the same shared render path. A motion-written `opacity` on a documented root visual surface must affect rendering through the same rules as directly configured `opacity`.
- Restore Love graphics state deterministically after every isolated or inline effect step. Shader, blend mode, canvas, scissor, and stencil state must not leak across siblings.
- Keep helper-module shapes internal unless the spec explicitly stabilizes them.

## Required Behavior

- A `Drawable` with no active visual effects continues to draw through the normal retained traversal without unnecessary isolation.
- Node-level `shader`, `opacity`, `blendMode`, and `mask` participate in the inherited render-effect chain according to the foundation spec.
- The runtime decides between inline effect application and subtree isolation using the published isolation rules, not ad hoc per-control shortcuts.
- Isolated subtree composition respects descendant rendering order and clips already established by the retained tree traversal.
- Motion-written values on documented root visual surfaces affect rendering through the same shared effect path.
- Invalid shader configuration or unavailable shader-capable rendering fails deterministically.

## Settled Boundaries

- Do not invent a second public renderer API.
- Do not move retained rendering ownership out of `Stage` / `Container` traversal into control-local code.
- Do not expose a public canvas-pool, effect-stack, or isolation-plan object unless the spec later names it.
- Do not widen shader behavior into an undocumented uniform-management surface.

## Non-Goals

- No new graphics-object public API beyond phase-10 task 01.
- No general-purpose public post-processing pipeline.
- No public whole-tree animation or effect graph.
- No demo-driven shortcuts that bypass the retained runtime.

## Acceptance Checks

- `Drawable` visual effects are applied by the shared retained render path rather than remaining storage-only props.
- Inline and isolated rendering both preserve retained draw order and clip behavior.
- Shader-capable and graphics-backed surfaces used by later control retrofits rest on the same shared render-effect implementation.
- Motion-driven visual values on documented root surfaces render correctly without mutating non-visual control state.
- The implementation stays within the existing `Stage` / `Container` / `Drawable` architecture and does not widen the public API.
