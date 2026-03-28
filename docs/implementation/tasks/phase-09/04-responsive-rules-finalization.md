# Task 04: Responsive Rules Finalization

## Goal

Finalize responsive behavior in a way that is declarative, spec-backed, and not narrower than the foundation rules.

## Spec Anchors

- `docs/spec/ui-foundation-spec.md §6.1.1 Container`
- `docs/spec/ui-foundation-spec.md §6.2 Layout Family`
- `docs/spec/ui-foundation-spec.md §7.3 Responsive Rules`
- `docs/spec/ui-foundation-spec.md §6.2.8 SafeAreaContainer`

## Scope

- Percentage sizing integration
- Min/max clamp integration
- Declarative breakpoint re-evaluation
- Safe-area-relative percentage resolution where applicable

## Required Behavior

- Responsive rules resolve before measurement and layout for the affected subtree.
- Responsive inputs may depend on viewport size, orientation, safe area, and parent dimensions.
- Percentage sizing and clamps remain supported across layout families.
- SafeAreaContainer resolves child percentages against its safe-area content box when that is the effective parent region.

## Settled Boundaries

- The spec does not freeze a public breakpoint-table schema or a single exact resolver algorithm.
- This task should preserve an internal normalization layer that can evolve without forcing a public API break.
- Stage may orchestrate responsive invalidation, but the exact node traversal strategy should remain an implementation detail unless the spec requires otherwise.

## Non-Goals

- No public promise about a specific `resolveSize` call graph.
- No public promise that breakpoint inputs are viewport-only.
- No new responsive props beyond the spec surface.

## Acceptance Checks

- Window resize triggers the correct responsive re-evaluation path.
- Percentage sizing resolves to zero rather than crashing when parent dimensions are unavailable.
- Clamps apply consistently after size resolution.
