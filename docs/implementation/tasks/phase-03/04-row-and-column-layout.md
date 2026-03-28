# Task 04: Row And Column Layout

## Goal

Implement `Row` and `Column` as sequential layout primitives while keeping measurement policy separate from public contract where the spec is silent.

## Spec Anchors

- `docs/spec/ui-foundation-spec.md §6.2.5 Row`
- `docs/spec/ui-foundation-spec.md §6.2.6 Column`
- `docs/spec/ui-foundation-spec.md §6.2.3 Common state model`
- `docs/spec/ui-foundation-spec.md §7.3 Responsive Rules`

## Scope

- Implement `lib/ui/layout/row.lua`
- Implement `lib/ui/layout/column.lua`
- Sequential placement, cross-axis alignment, justify spacing, wrap handling, and circular-dependency failure handling

## Required Behavior

- `Row` places children horizontally, honoring `direction`.
- `Column` places children vertically.
- Both apply common layout props and common state model.
- Overflow without clipping remains valid when `wrap = false` and `clipChildren = false`.
- Circular measurement dependencies hard-fail deterministically.

## Measurement Policy Boundary

- Policies such as equal-share `fill` allocation may be used internally, but they must not be documented as stable public contract unless the spec later defines them.
- The implementation must keep enough separation that fill policy can change without pretending to be a breaking public API change.

## Non-Goals

- No grid semantics.
- No table or form semantics.
- No public defaults beyond the spec text.

## Acceptance Checks

- `justify = "space-between"` with one child resolves to the start position.
- Circular dependency cases fail deterministically rather than looping.
- Nested layout primitives are measured before placement as required by the spec.
