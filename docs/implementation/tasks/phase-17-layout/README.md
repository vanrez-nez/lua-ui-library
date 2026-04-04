# Phase 17 Task Set

Source authority for this phase:

- `docs/spec/ui-layout-spec.md`

Related source authority:

- `docs/spec/ui-foundation-spec.md`

Implementation target:

- align `lib/ui` layout behavior with the newly extracted layout authority

Authority rules for this phase:

- `docs/spec/ui-layout-spec.md` is authoritative for:
  - spacing semantics for `padding` and `margin`
  - `Drawable` internal content alignment semantics
  - layout-family common behavior
  - `Stack`, `Row`, `Column`, `Flow`, and `SafeAreaContainer`
- `docs/spec/ui-foundation-spec.md` remains authoritative for:
  - shared value-family normalization shapes
  - retained-tree/runtime ownership
  - `ScrollableContainer` and other non-layout primitives

Settled implementation findings from the current codebase:

- layout parents currently consume `padding` but do not consume child `margin`
- layout-node public reads still bypass the effective merged quad values for
  flat `padding*` members
- `padding` validation currently permits values the layout spec no longer
  permits
- `Drawable` internal content alignment already exists, but it should be
  re-verified against the new layout authority
- non-layout parents already leave child `margin` inert in practice because no
  generic parent path consumes it

Settled execution decisions for this phase:

- `gap` should be finite and non-negative
- in `Stack`, negative child margins expand the child's placement region beyond
  the stack content box; visibility is still controlled only by normal clipping
  rules

Task order:

1. `00-compliance-review.md`
2. `01-spacing-surface-alignment.md`
3. `02-layout-margin-consumption.md`
4. `03-acceptance-and-doc-sync.md`
5. `04-flow-direction.md`
6. `05-fill-circular-layout-families.md`
7. `06-drawable-alignment-contract.md`
8. `07-common-prop-validation-gaps.md`

Tasks 04–07 target gaps introduced by the §2.6 / §3.3 / §4.2 / §8.3 spec
update applied after the original task set was written.

Execution policy for this phase:

- prefer adding small shared helpers inside `lib/ui/layout/` or local-module
  helpers over duplicating margin math in each layout file
- do not encode margin by mutating a child's own resolved width, height, local
  bounds, or world bounds
- compute and consume margin as parent-side layout footprint only
- keep parent-side layout offsets as the only placement mutation performed by
  layout parents
- when a task says "outer footprint", use the child's resolved border box plus
  effective margin:
  - `outer_left = border_left - marginLeft`
  - `outer_top = border_top - marginTop`
  - `outer_right = border_right + marginRight`
  - `outer_bottom = border_bottom + marginBottom`
- when a task says "visual distance between adjacent child border boxes", use:
  - previous trailing margin
  - plus parent `gap`
  - plus next leading margin
- a negative resolved distance is valid and means overlap
