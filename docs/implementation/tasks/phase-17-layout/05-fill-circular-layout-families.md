# Phase 17 Task 05: Fill-in-Content-Sized Layout Family Check

## Goal

Implement the §2.6 rule: a layout-family component that is content-sized on an
axis must reject a visible child with `"fill"` sizing on that same axis with a
Hard failure. This extends the existing Drawable guard (§3.2) to all layout
families.

## Scope

Primary files:

- `lib/ui/layout/stack.lua`
- `lib/ui/layout/sequential_layout.lua`
- `lib/ui/layout/flow.lua`

## Work

1. `Stack`: when `Stack` is content-sized on an axis (`width = "content"` or
   `height = "content"`), scan visible children before the layout pass begins
   and raise a Hard failure if any visible child has `"fill"` sizing on that
   same axis.
2. `Row`: when `Row` is content-sized on its main axis (`width = "content"`),
   raise a Hard failure if any visible child has `width = "fill"`. Fill on the
   cross axis (`height = "fill"`) remains valid because `Row` is not constraining
   content sizing on that axis.
3. `Column`: mirror `Row` for the vertical main axis.
4. `Flow`: when `Flow` is content-sized on the horizontal axis
   (`width = "content"`), raise a Hard failure if any visible child has
   `width = "fill"`.
5. The check must fire before any measurement state is mutated.
6. Failure mode: Hard failure (error/throw), consistent with Foundation §3G.1
   and the existing Drawable guard already in the codebase.

## Concrete Changes

- `lib/ui/layout/sequential_layout.lua`
  - add a shared pre-pass guard function: given the content-sizing flags and
    the visible child list, scan for the prohibited combination and raise on
    first match
  - call it at the start of the main layout entry point for both Row and Column
    configurations, before line-building begins
- `lib/ui/layout/stack.lua`
  - add an equivalent pre-pass call using the same guard shape before the
    content-rect measurement loop
- `lib/ui/layout/flow.lua`
  - add an equivalent pre-pass call before the row-building loop
- Implement the guard once (local to `sequential_layout.lua` or as a shared
  helper in `lib/ui/layout/`) rather than duplicating the check in each file

## Constraints

- Only raise when the layout family's own sizing on an axis is `"content"` AND a
  visible child on that axis is `"fill"`. Any other combination is valid.
- Do not change fill-distribution behavior for axes where the parent is not
  content-sized.
- Keep the guard narrowly scoped: no other validation belongs in this pre-pass.

## Acceptance Examples

- `Row { width = "content" }` with a child `{ width = "fill" }` must fail with
  a Hard failure before any layout output is produced.
- `Row { width = "content" }` with a child `{ height = "fill" }` must succeed.
- `Row { width = 200 }` with a child `{ width = "fill" }` must succeed.
- `Column { height = "content" }` with a child `{ height = "fill" }` must fail.
- `Stack { width = "content", height = 100 }` with a child `{ width = "fill" }`
  must fail.
- `Stack { width = "content", height = 100 }` with a child `{ height = "fill" }`
  must succeed.
- `Flow { width = "content" }` with a child `{ width = "fill" }` must fail.

## Exit Criteria

- Tests in `spec/spacing_layout_contract_spec.lua` cover all four layout
  families across both axes (content-sized axis fails, non-content axis passes).
- Hard failure is raised before any layout state is mutated.
- Existing fill-distribution tests for non-content-sized parents are unaffected.
