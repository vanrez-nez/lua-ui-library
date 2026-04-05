# Spec Patch: Clarify `Flow` Last-Row Distribution And `space-between` Degeneracy

## Summary

The current `Flow` spec says the last row of a wrapped flow uses `justify` for
main-axis distribution.

The current implementation does not do that. It routes the last wrapped row
through `align`.

That implementation behavior likely came from a real problem, not an accident:
`space-between` on a sparse last row produces visibly poor results.

Examples:

- 1 child on the last row: there are no gaps to distribute, so the child falls
  back to the start edge
- 2 children on the last row: the single gap absorbs all free space, so the two
  children fly to opposite ends

This patch keeps `justify` as the owner of last-row main-axis distribution, but
introduces a narrow `Flow`-specific degenerate rule for pathological
`space-between` last rows.

It does **not** introduce a separate `last-row-align` override.

---

## Dependency Check

The current dependency surface is local to `Flow`.

Relevant public spec clauses:

- `Flow` exposes the common layout props, including `justify` and `align`
- `Flow` wraps children into rows
- the last row currently says it uses `justify`

Relevant implementation behavior:

- [flow.lua](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/layout/flow.lua)
  uses `resolve_last_row_alignment(align, ...)` for the last wrapped row

Related spec precedent:

- [ui-layout-spec.md](/Users/vanrez/Documents/game-dev/lua-ui-library/docs/spec/ui-layout-spec.md#L549)
  already defines a degenerate `space-between` case for `Row`
- [ui-layout-spec.md](/Users/vanrez/Documents/game-dev/lua-ui-library/docs/spec/ui-layout-spec.md#L614)
  does the same for `Column`

So adding an explicit `Flow` degeneracy is consistent with how the layout spec
already handles mathematically awkward `justify` cases elsewhere.

---

## Problem

The current state creates two different failures.

1. The implementation breaks the mental model.

   `justify` appears to govern row distribution, until the final wrapped row,
   where `align` silently takes over.

2. A naive spec-only correction creates a UX failure.

   If `space-between` is applied uniformly to every wrapped row, sparse last
   rows can look visibly broken even though the math is correct.

So the real design question is not simply "spec or implementation". It is:

- should `justify` still own the last row?
- and if yes, how should `Flow` handle the bad `space-between` degeneracies
  without overloading `align`?

---

## Current Disconnect

### Current Spec Direction

The current `Flow` section says:

- children on the last row of a wrapped flow are placed using `justify`
- the last row is not specially stretched regardless of `justify`

That implies `justify` owns main-axis distribution for:

- first wrapped row
- middle wrapped rows
- last wrapped row

### Current Implementation Direction

The implementation currently does this in
[flow.lua](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/layout/flow.lua):

- non-last rows use `resolve_justify(...)`
- the last wrapped row uses `resolve_last_row_alignment(align, ...)`

So the runtime behaves like:

- `justify` for most rows
- `align` for the last row

That is simpler visually in some cases, but it breaks the public contract and
gives `align` a surprising main-axis meaning that the spec does not define.

---

## Proposed Contract

### Keep `justify` As The Last-Row Owner

`justify` continues to govern main-axis distribution for every resolved `Flow`
row, including the last row.

This preserves the mental model:

- `justify` distributes rows
- `align` remains a separate concern

### Do Not Introduce `last-row-align`

This patch rejects a new `last-row-align` or equivalent override prop.

That would solve the visual issue by expanding API surface and by mixing a
special-case override into a layout family that should remain easier to reason
about.

### Add A Narrow Degenerate Rule For `space-between`

For `Flow` only, when all of the following are true:

- `wrap = true`
- the row is the last resolved wrapped row
- `justify = "space-between"`
- the row contains two or fewer children

the last row resolves as `start` instead of using full `space-between`
distribution.

This keeps `justify` ownership intact while explicitly solving the pathological
sparse-last-row case.

### No New Degenerate Rule For `space-around`

`space-around` remains unchanged.

Its last-row math stays visually acceptable:

- one child centers
- two children distribute symmetrically without the single-gap blowout of
  `space-between`

So no extra exception is needed for `space-around` in this revision.

---

## Behavioral Rules

### Normal Wrapped Rows

When `wrap = true` and a row is not the last wrapped row:

- main-axis distribution resolves through `justify`

### Last Wrapped Row

When the last wrapped row is resolved:

- `justify` still owns the main-axis behavior
- there is no `align` takeover

### `space-between` Degenerate Last Row

When the last wrapped row uses `justify = "space-between"`:

- if the row has `0` children, nothing is drawn
- if the row has `1` child, it resolves to `start`
- if the row has `2` children, it resolves to `start`
- if the row has `3` or more children, normal `space-between` math applies

This is a `Flow`-specific edge-case rule, not a generic redefinition of
`space-between`.

### `space-around`

`space-around` remains mathematically uniform on every row, including the last
row.

No extra last-row fallback is introduced.

### `align`

`align` must not be used as a last-row main-axis override.

If `Flow.align` retains any public meaning, it should be documented separately
as an actual `Flow` behavior rather than being inferred from this historical
special case.

---

## Patch Direction

Patch [ui-layout-spec.md](/Users/vanrez/Documents/game-dev/lua-ui-library/docs/spec/ui-layout-spec.md)
in the `Flow` section to clarify:

```text
`justify` governs main-axis distribution for every resolved row in a wrapped
flow, including the last row.

For `justify = "space-between"`, a wrapped last row with two or fewer children
degenerates to `start`.

`align` does not override last-row main-axis distribution.
```

This keeps the public model explicit and avoids silently normalizing the
implementation around an undocumented `align` fallback.

---

## Implementation Note

If this patch is accepted, the runtime should be updated so:

- wrapped `Flow` rows use `resolve_justify(...)` as the main-axis owner
- the last wrapped row no longer routes through
  `resolve_last_row_alignment(...)`
- a narrow `space-between` degeneracy handles the sparse last-row case

This is a follow-up implementation change, not part of the spec patch itself.

---

## Rationale

This patch balances consistency and visual sanity.

It avoids the two bad extremes:

- strict uniform `justify` with ugly `space-between` blowouts on sparse last
  rows
- a hidden `align` override that breaks the public mental model

The result is:

- one clear main-axis owner: `justify`
- one explicit `Flow` edge-case rule
- no new API surface

That is easier to teach and easier to preserve in demos and tests.

---

## Follow-Up

If this patch is accepted:

1. update `Flow` layout resolution in
   [flow.lua](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/layout/flow.lua)
2. update the `Flow` demo to include a wrapped last-row `space-between`
   example
3. add regression tests for:
   - last-row `center`
   - last-row `end`
   - last-row `space-between` with 1 child
   - last-row `space-between` with 2 children
   - last-row `space-between` with 3+ children
