# Task 03: Stack Layout

## Goal

Implement `Stack` as the layered layout primitive with no sequential axis and with spec-aligned hit and clip behavior.

## Spec Anchors

- `docs/spec/ui-layout-spec.md §4.3 Common state model`
- `docs/spec/ui-layout-spec.md §5 Stack`

## Scope

- Implement `lib/ui/layout/stack.lua`
- Child placement within one content box
- Layered rendering and reverse-order hit resolution
- Empty-state and clip behavior

## Required Behavior

- Children resolve alignment and position independently within the stack content box.
- Stack does not impose sequential placement.
- Stack consumes child margin as a parent-side outer-footprint rule.
- Overlapping children draw in ascending z-order and hit-test in reverse draw order.
- Children beyond stack bounds clip only when `clipChildren = true`.

## Settled Boundaries

- If `Stack` supports `width = "content"` by measuring visible child outer
  footprints, that policy should be treated as implementation-level measurement
  behavior, not a newly stabilized public promise.

## Non-Goals

- No new Stack-specific props.
- No focus-order override beyond the spec.

## Acceptance Checks

- Empty Stack renders nothing and does not fail.
- Hidden children do not affect visual output.
- Clip behavior affects both draw and hit resolution.
