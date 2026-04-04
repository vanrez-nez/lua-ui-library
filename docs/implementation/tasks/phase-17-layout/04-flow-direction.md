# Phase 17 Task 04: Flow Direction

## Goal

Add `direction: "ltr" | "rtl"` support to `Flow` to satisfy §8.3 and §8.6 of
`docs/spec/ui-layout-spec.md`.

## Scope

Primary files:

- `lib/ui/layout/flow.lua`

## Work

1. Accept `direction` as a prop on `Flow`. Accepted values: `"ltr"`, `"rtl"`.
   Default: `"ltr"`.
   Implementation detail:
   - reuse the same accepted-value check already used by `Row`; do not
     duplicate validation logic
2. In the row-building loop, when `direction = "rtl"`, reverse the order in
   which children are placed within each row.
   Implementation detail:
   - the wrapping decision and outer-footprint threshold check remain
     direction-agnostic
   - after building each row's entry list, reverse the list before computing
     x-offsets when `direction = "rtl"`
   - the placement cursor starts from the right edge of the content box in RTL
3. Preserve the wrapping threshold condition unchanged:
   a child is placed on the current row if its outer footprint fits within
   remaining width, where remaining = available – sum of already-placed outer
   footprints on that row – accumulated gaps.

## Concrete Changes

- `lib/ui/layout/flow.lua`
  - read the effective `direction` value once before the row-building loop
  - after finalizing each row's entry list, reverse it before x-offset
    computation when `direction = "rtl"`
  - compute x-offsets starting from `content_rect.x + content_rect.width`
    advancing leftward for RTL, unchanged for LTR

## Constraints

- Do not change the wrapping condition, gap accumulation, or outer-footprint
  math.
- Do not duplicate direction string validation; reuse the Row path.
- `direction` on `Flow` must use the same schema slot that `Row` uses if
  `layout_node_schema` is shared; otherwise add it as a Flow-local prop read.

## Acceptance Examples

- `Flow { direction = "rtl" }` with three equal-width children and no gap places
  child 1 rightmost, child 2 in the middle, child 3 leftmost.
- `Flow { direction = "ltr" }` behavior is unchanged from pre-task behavior.
- `Flow {}` (no `direction`) behaves identically to `Flow { direction = "ltr" }`.
- `Flow { direction = "invalid" }` must fail deterministically.

## Exit Criteria

- RTL and default-LTR Flow tests pass in `spec/flow_layout_spec.lua`.
- No change in behavior for any existing LTR flow test.
