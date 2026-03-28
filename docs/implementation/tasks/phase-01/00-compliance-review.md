# Phase 01 Compliance Review

Source under review: `docs/implementation/phase-01-foundation.md`

Disposition: the deltas below are settled by `docs/spec/ui-foundation-spec.md` and are the baseline assumptions for every task in this directory. They are not open design questions.

Primary findings, ordered by severity:

1. Public API narrowing on `Container.width` and `Container.height` is not spec-compliant.
   Source: `phase-01-foundation.md:59-61`
   Spec anchor: `ui-foundation-spec.md §6.1.1 Props and API surface`
   Problem: the phase doc says width and height are absolute pixel values in Phase 1, but the stable spec surface is `number | "content" | "fill" | percentage`.
   Settled requirement: keep the full prop surface in the implementation contract now. Phase 1 may defer some resolution paths, but it must not redefine the public surface.
   Trace-note closure: `§6.1.1` explicitly states that implementation phases may stage resolution-path completion, but must not narrow the accepted prop domain.

2. Phase 1 introduces unrooted public `Container` props.
   Source: `phase-01-foundation.md:63-69`
   Spec anchors: `ui-foundation-spec.md §6.1.1 Props and API surface`, `ui-foundation-spec.md §7.2 Focus`
   Problem: `focusScope` and `trapFocus` are listed as `Container` flags even though they are not part of the documented `Container` prop surface.
   Settled requirement: do not expose them as Phase 1 `Container` props. Focus-scope and trap behavior belong to named runtime or overlay contracts, not the foundation primitive API surface.
   Trace-note closure: `§7.2.1` and `§7.2.5` explicitly prevent generic `focusScope` and `trapFocus` foundation props from being inferred into the public surface.

3. Visibility, disabled targeting, and hit-testing semantics diverge from the spec.
   Source: `phase-01-foundation.md:55`, `phase-01-foundation.md:65`, `phase-01-foundation.md:77-79`
   Spec anchors: `ui-foundation-spec.md §6.1.1 Composition rules`, `ui-foundation-spec.md §6.1.1 Behavioral edge cases`, `ui-foundation-spec.md §7.1.2 Target resolution rules`, `ui-foundation-spec.md Glossary`
   Problems:
   - `visible = false` is described as skipping update, but the spec commits to skipped hit targeting and rendering, not to skipping retained-tree consistency work.
   - `enabled = false` is described as allowing hit-test descent to children, but the spec says disabled suppresses focus acquisition for the node and its descendants.
   - the current `hitTest` wording contradicts itself by requiring `interactive = true` and then describing descent from a non-interactive hit node.
   Settled requirement: keep non-interactive nodes as structural ancestors, exclude effectively disabled branches from direct targeting, and ensure clip bounds affect hit testing as well as rendering.
   Trace-note closure: `§6.1.1` and `§7.1.2` now explicitly define effective targeting, visible-false behavior, and ancestor-aware targeting constraints.

4. `Stage` is under-scoped relative to the spec.
   Source: `phase-01-foundation.md:124-134`
   Spec anchor: `ui-foundation-spec.md §6.4.1 Stage`
   Problems:
   - the draft exposes `getSafeArea()` as insets only, while the spec also requires queryable safe-area bounds
   - the draft omits a stable root input delivery entry point entirely until Phase 2
   Settled requirement: Phase 1 must establish `Stage` as the runtime root with base/overlay layers, update and draw traversal entry points, safe-area insets, safe-area bounds, viewport bounds, a root input-delivery surface, and the root focus-scope boundary even if downstream propagation and traversal logic are deferred.
   Trace-note closure: `§6.4.1` explicitly closes the insets-only gap and forbids introducing a second raw-input intake path beneath `Stage`.

5. Zero-size clipping is incorrectly normalized to a no-op.
   Source: `phase-01-foundation.md:168`
   Spec anchor: `ui-foundation-spec.md §6.1.1 Behavioral edge cases`
   Problem: a clipped node must clip rendering and hit testing to its own bounds. Turning a zero-area clip into a no-op expands behavior beyond the spec.
   Settled requirement: zero-area or degenerate clip bounds must produce an empty effective clip region, not unclipped descendant output.
   Trace-note closure: `§6.1.1` explicitly resolves this as an empty-region case.

Secondary scoping notes:

- `lib/ui/core/color.lua` and `lib/ui/core/easing.lua` are useful shared utilities, but they are not Phase 1 spec-compliance blockers.
- Overlay precedence may be demonstrated in the test harness through Stage-owned hit-resolution helpers without claiming that full event propagation already exists in Phase 1.
- No unresolved compliance gap remains in this directory on the reviewed width/height, focus-scope, target-eligibility, safe-area, or degenerate-clip topics; the tasks below should treat those points as settled.
