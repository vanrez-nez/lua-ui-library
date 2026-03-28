# Task 07: Phase 03 Demo And Acceptance

## Goal

Build a Phase 3 verification harness that demonstrates spec-backed layout behavior without over-claiming implementation-local responsive schemas or measurement algorithms.

## Spec Anchors

- `docs/spec/ui-foundation-spec.md §6.2 Layout Family`
- `docs/spec/ui-foundation-spec.md §7.3 Responsive Rules`
- `docs/spec/ui-foundation-spec.md §3G Failure Semantics`

## Scope

- Create or revise `test/phase3/`
- Demonstrate Stack, Row, Column, Flow, SafeAreaContainer, nested layout, and responsive behavior

## Screen Normalization

- Keep Stack, Row/Column, Flow, SafeAreaContainer, nested layout, and breakpoint demonstrations.
- Responsive demos must treat `responsive` and `breakpoints` as alternate entry points into the same pre-measure step, not as cumulative sources.
- Breakpoint demos must not imply that the chosen breakpoint data schema is itself stabilized by the spec.
- Flow demos must use the common layout prop surface rather than introducing public `gapX` / `gapY` controls.
- Nested and safe-area demos should make it clear that percentages resolve against the effective parent content region.
- Circular-dependency and dual-source responsive invalidity may be demonstrated as deterministic error cases according to the normalized scope.

## Non-Goals

- No control-family composition assertions yet.
- No scroll-container assertions yet.
- No public claim about exact fill-allocation policy.

## Acceptance Checks

- Each screen ties back to a spec-backed layout behavior.
- Harness controls do not depend on undocumented internals.
- Hard-failure cases can be observed without making the harness unusable afterward when `pcall` is appropriate.
