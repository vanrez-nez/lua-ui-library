# Task 07: Phase 01 Demo Harness And Acceptance

## Goal

Build a Phase 1 verification harness that proves the implemented behavior against the normalized scope without pretending later systems already exist.

## Spec Anchors

- `docs/spec/ui-foundation-spec.md §6.1.1 Container`
- `docs/spec/ui-foundation-spec.md §6.1.2 Drawable`
- `docs/spec/ui-foundation-spec.md §6.4.1 Stage`
- `docs/spec/ui-foundation-spec.md §3G Failure Semantics`

## Scope

- Create `test/phase1/`
- Raw Love2D chrome only
- Deterministic screens for clipping, ordering, hit resolution, clamps, content box, and layer precedence

## Screen Normalization

- Keep z-order and clip demonstrations.
- Keep min/max clamp demonstrations.
- Keep Drawable content-box and alignment demonstrations.
- Keep overlay precedence demonstrations, but use Stage-owned hit-resolution probes rather than claiming full event propagation already exists.
- If a screen visually depends on "clicking" behavior, the harness should explicitly call the current Stage hit-resolution surface and display the resolved node label.

## Required Checks

- Scissor and stencil clipping both operate against retained-tree bounds and nested clip composition.
- Reverse draw-order hit resolution matches z-order behavior.
- Overlay precedence is determined by Stage layers, not by cross-layer `zIndex`.
- The two-pass violation can be triggered and observed safely in the harness.

## Non-Goals

- No event propagation assertions yet.
- No focus assertions yet.
- No scene lifecycle assertions yet.

## Acceptance Checks

- Each screen maps to a specific spec-backed behavior, not to an implementation convenience.
- The harness does not rely on undocumented internals to present results.
- Hard-failure demonstrations use caught errors where needed so the harness remains usable after the assertion fires.
