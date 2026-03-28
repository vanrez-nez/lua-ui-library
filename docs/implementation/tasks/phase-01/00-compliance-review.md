# Phase 01 Compliance Review

Source under review: `docs/implementation/phase-01-foundation.md`

Primary findings, ordered by severity:

1. Public API narrowing on `Container.width` and `Container.height` is not spec-compliant.
   Source: `phase-01-foundation.md:59-61`
   Spec anchor: `ui-foundation-spec.md §6.1.1 Props and API surface`
   Problem: the phase doc says width and height are absolute pixel values in Phase 1, but the stable spec surface is `number | "content" | "fill" | percentage`.
   Required normalization: keep the full prop surface in the implementation contract now. Phase 1 may defer some resolution paths, but it must not redefine the public surface.

2. Phase 1 introduces unrooted public `Container` props.
   Source: `phase-01-foundation.md:63-69`
   Spec anchor: `ui-foundation-spec.md §6.1.1 Props and API surface`
   Problem: `focusScope` and `trapFocus` are listed as `Container` flags even though they are not part of the documented `Container` prop surface.
   Required normalization: do not expose them as Phase 1 `Container` props. Focus-scope and trap behavior belong to the focus system and overlay contracts, not the foundation primitive API surface.

3. Visibility, disabled targeting, and hit-testing semantics diverge from the spec.
   Source: `phase-01-foundation.md:55`, `phase-01-foundation.md:65`, `phase-01-foundation.md:77-79`
   Spec anchors: `ui-foundation-spec.md §6.1.1 Behavioral edge cases`, `ui-foundation-spec.md §6.1.1 Composition rules`, `ui-foundation-spec.md Glossary`
   Problems:
   - `visible = false` is described as skipping update, but the spec commits to skipped hit targeting and rendering, not to skipping retained-tree consistency work.
   - `enabled = false` is described as allowing hit-test descent to children, but the spec says disabled suppresses focus acquisition for the node and its descendants.
   - the current `hitTest` wording contradicts itself by requiring `interactive = true` and then describing descent from a non-interactive hit node.
   Required normalization: keep non-interactive nodes as structural ancestors, exclude disabled nodes from effective targeting, and ensure clip bounds affect hit testing as well as rendering.

4. `Stage` is under-scoped relative to the spec.
   Source: `phase-01-foundation.md:124-134`
   Spec anchor: `ui-foundation-spec.md §6.4.1 Stage`
   Problems:
   - the draft exposes `getSafeArea()` as insets only, while the spec also requires queryable safe-area bounds
   - the draft omits a stable root input delivery entry point entirely until Phase 2
   Required normalization: Phase 1 must establish `Stage` as the runtime root with base/overlay layers, update and draw traversal entry points, safe-area insets, safe-area bounds, viewport bounds, and a root input-delivery surface even if propagation work is deferred.

5. Zero-size clipping is incorrectly normalized to a no-op.
   Source: `phase-01-foundation.md:168`
   Spec anchor: `ui-foundation-spec.md §6.1.1 Behavioral edge cases`
   Problem: a clipped node must clip rendering and hit testing to its own bounds. Turning a zero-area clip into a no-op expands behavior beyond the spec.
   Required normalization: zero-area or degenerate clip bounds must produce an empty effective clip region, not unclipped descendant output.

Secondary scoping notes:

- `lib/ui/core/color.lua` and `lib/ui/core/easing.lua` are useful shared utilities, but they are not Phase 1 spec-compliance blockers.
- Overlay precedence may be demonstrated in the test harness through Stage-owned hit-resolution helpers without claiming that full event propagation already exists in Phase 1.
