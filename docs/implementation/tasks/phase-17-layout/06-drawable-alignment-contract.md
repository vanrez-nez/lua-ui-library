# Phase 17 Task 06: Drawable Alignment Contract

## Goal

Verify and, where needed, correct `Drawable.alignX` / `alignY` to match the
§3.3 contract:

- alignment is applied to the union of visible child border boxes as a single
  unit, not independently per child
- `stretch` spans the full content-box dimension on that axis, applied
  independently to each child because `Drawable` has no layout axis
- the all-negative-offset case is explicitly valid: content_extent resolves to
  zero and children overflow without error

## Scope

Primary files:

- `lib/ui/core/drawable.lua`

Secondary (test coverage):

- `spec/` — new or extended drawable-specific test file

## Work

1. Verify `Drawable:resolveContentRect()` or the equivalent path produces a
   content box by insetting the border box by the effective padding on each
   side. No change if already correct.
2. Verify the alignment path:
   - compute the content extent as the union of visible child border boxes
     in local space (positive quadrant only, consistent with the §3.2 formula)
   - `"start" | "center" | "end"` — shift the entire union as one unit within
     the content box on that axis; each child's relative position within the
     union is unchanged
   - `"stretch"` — each child's resolved extent on that axis is set to the
     full content-box dimension; applied independently per child because
     `Drawable` has no sequencing axis
   Correct only if a behavioral mismatch is found.
3. Verify the all-negative-offset edge case:
   - when all visible children are positioned such that their border boxes fall
     entirely outside the positive quadrant, `content_extent` on the affected
     axis resolves to `0`
   - the resolved border-box size is padding-only; all children overflow
   - no error is raised
   Correct only if the code raises an error or produces a wrong size.
4. Verify the fill-in-content-sized guard:
   - `Drawable { width = "content" }` with a visible child `{ width = "fill" }`
     must raise a Hard failure
   - confirm the existing guard raises an error (not a warning or silent
     fallback)
   Add or correct only if the guard is missing or uses the wrong failure mode.

## Concrete Changes

- `lib/ui/core/drawable.lua`
  - correct alignment logic only if the verification in steps 2–4 exposes a
    mismatch with the spec
  - no structural changes if the existing implementation is already correct
- New test cases (file name based on what already exists in `spec/`):
  - union-alignment: center, end, stretch with two children
  - all-negative-offset: content_extent = 0, no error
  - fill-guard: Hard failure confirmed

## Constraints

- Do not make `Drawable` a layout family.
- Do not add child-margin consumption to `Drawable`.
- Do not change the content_extent formula (`positive quadrant union of visible
  child border boxes`).
- Do not add per-child alignment overrides; `Drawable` has no sequencing axis.

## Acceptance Examples

- `Drawable { alignX = "center", width = 200 }` with two children whose
  combined union spans 80 units must shift the union origin to `x = 60` inside
  the content box.
- `Drawable { alignX = "stretch", width = 200 }` must set each child's
  resolved width to `200` (the full content-box width when padding is zero).
- `Drawable { width = "content" }` with all children at negative x-offsets must
  resolve to `padding_left + padding_right` width with children overflowing.
  No error.
- `Drawable { width = "content" }` with a child `{ width = "fill" }` must fail
  with a Hard failure.

## Exit Criteria

- Alignment behavior verified correct against the §3.3 union contract.
- Stretch behavior verified correct.
- All-negative-offset case has explicit test coverage confirming zero extent and
  no error.
- Fill-guard confirmed as Hard failure with test coverage.
