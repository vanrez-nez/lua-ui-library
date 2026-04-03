# Incident: Spacing Box Model Patch Draft

## Status

Draft only. No direct changes have been applied to `docs/spec`.

## Problem

The current Foundation spec defines `padding`, `margin`, and their flat
override members as accepted public props, but it does not fully specify their
runtime behavior.

What is currently clear:

- `padding` and `margin` both use `SideQuad input`
- flat member props override their aggregate family member
- `Drawable` defines its content box inside padding
- layout-family nodes expose `padding`

What is still underspecified:

- whether `margin` is external spacing consumed by parents or only stored state
- whether all parents consume `margin`, or only layout-family parents
- whether `margin` affects measurement, placement, hit testing, clipping, or
  rendering bounds
- how `gap` composes with child margins in `Row`, `Column`, and `Flow`
- how `Stack` should treat child margins
- whether negative margins are allowed

This leaves the public surface looking more complete than the behavioral
contract really is.

## Goals

Define one cohesive spacing model that:

- keeps `padding` as internal spacing applied by the node to its own interior
- defines `margin` as external spacing requested by the child but consumed only
  by parents that opt into layout placement rules
- makes layout measurement and placement deterministic
- avoids silent layout differences between layout families
- does not force non-layout parents to invent automatic margin behavior

## Proposed Decision

Adopt an explicit box-model contract:

- `padding` is internal spacing applied by the node to its own interior.
- `margin` is external layout spacing requested by the child.
- `padding` affects the node's content box.
- `margin` affects only parent-driven layout placement and layout-driven
  measurement.
- `margin` does not change the node's own local bounds, render bounds, border
  box, background paint area, hit-test bounds, or clipping bounds.
- `margin` is consumed only by parents whose contract explicitly says they
  consume child margin.
- In this revision, the parents that consume child margin are:
  - `Stack`
  - `Row`
  - `Column`
  - `Flow`
  - `SafeAreaContainer`
- Plain `Container` and plain `Drawable` do not automatically consume child
  margin.

## Proposed Value Constraints

To keep the contract simple and deterministic:

- `padding` members must be finite and `>= 0`
- `margin` members must be finite and may be positive, zero, or negative

Rationale:

- negative padding is nonsensical under the current content-box model
- negative margin is a valid and useful layout tool when its effects are
  described explicitly

This is intentionally more explicit than the current implementation. If
accepted, implementation work will be required to align validation and layout
consumption.

## Proposed Normative Semantics

### 0. Entity Contracts

This section makes the spacing responsibilities explicit for every participant.

#### 0.1 Child Node Contract

Any node exposing `padding` or `margin` must follow these rules:

- the node owns its own effective `padding` values
- the node owns its own effective `margin` values
- the node applies `padding` to its own interior behavior when its component
  contract defines an interior content box
- the node does not apply `margin` to itself
- the node does not change its own local bounds because of `margin`
- the node does not enlarge its own render, clip, or hit region because of
  `margin`

In short:

- `padding` is self-applied
- `margin` is parent-consumed only when the parent contract says so

#### 0.2 Non-Layout Parent Contract

A parent with no explicit layout-placement contract, including plain
`Container` and plain `Drawable`, must follow these rules:

- it does not automatically consume child `margin`
- it does not reserve space for child `margin`
- it does not alter child placement because of child `margin`
- it continues to use normal child transform, anchor, explicit position, and
  component-specific placement rules only

This makes child margin inert under non-layout parents.

#### 0.3 Layout Parent Contract

A parent whose component contract explicitly defines child placement is a
margin-consuming parent only if its component section says so.

When a layout parent consumes child margin, it must:

- measure children using their outer footprints
- place children using their outer footprints
- resolve the child border box inside that outer footprint according to the
  child's effective margins
- keep the child's own border box, paint area, and hit area unchanged

#### 0.4 Parent-Specific Opt-In Rule

Margin consumption is never implicit.

Each parent type must be in one of two states:

- `margin-consuming parent`
- `non-margin-consuming parent`

This status must be stated directly in the parent's spec section. There is no
global fallback that automatically makes every parent margin-consuming.

#### 0.5 Layout Child Footprint Contract

When a margin-consuming parent reasons about a child, it must distinguish:

- `border box`: the real node bounds
- `content box`: the node interior after padding
- `outer footprint` / `margin box`: the layout footprint used by the parent

The parent uses the outer footprint for layout only.
The child still renders, clips, and hit-tests using its real node bounds.

#### 0.6 Hit Testing Contract

Spacing must not create hidden hit regions.

Rules:

- `padding` does not create a hit region outside the node's own bounds
- `margin` never creates hit area outside the node's own bounds
- overlap caused by negative margins does not merge hit regions between
  siblings
- hit testing continues to resolve against real node bounds in normal draw
  order / reverse draw order as applicable

#### 0.7 Clipping Contract

Spacing must not silently alter clipping semantics.

Rules:

- parent padding affects the content rect available for placement
- child margin does not enlarge any clip rect
- if negative margin causes a child to visually extend outside the nominal flow
  position, clipping still depends only on real node bounds and the ancestor
  clip chain

#### 0.8 Measurement Contract

Spacing affects measurement in two distinct places:

- node self-measurement
- parent child-footprint measurement

Rules:

- a node's own `padding` contributes to that node's `"content"` measurement
- a node's own `margin` does not contribute to that node's own `"content"`
  measurement
- a margin-consuming parent includes child outer footprints in its own
  content-based measurement
- a non-margin-consuming parent ignores child margin during measurement

#### 0.9 Visibility Contract

Visibility must interact with spacing consistently.

Rules:

- if a child does not participate in layout, its margin footprint does not
  participate either
- for layout families in this revision, `visible = false` means the child does
  not occupy layout space
- non-layout parents keep their normal retained-tree visibility behavior;
  child margin remains inert there anyway

#### 0.10 Safe-Area Contract

Safe-area behavior must compose with spacing without redefining it.

Rules:

- safe-area adjustment defines the parent placement region
- parent padding then reduces that placement region further
- child margin is consumed only after those two earlier reductions
- safe area, padding, and margin are distinct spacing layers and must not be
  collapsed into one semantic bucket

### 1. Shared Terms

For any node participating in spacing-aware layout:

- `border box`: the node's resolved local bounds before child padding is applied
- `content box`: the inner rectangle after subtracting effective padding from
  the border box
- `margin box`: the rectangle formed by expanding the border box outward by the
  node's effective margins

Resolved order:

1. Normalize aggregate and flat spacing props into canonical four-member values.
2. Resolve the node's border box from normal measurement rules.
3. Resolve the node's content box by insetting the border box by padding.
4. If the parent consumes child margin, resolve the child's margin box by
   expanding the child's border box outward by margin.

### 2. Padding

`padding` is internal spacing applied by the node to its own interior.

Rules:

- `padding` reduces available space for descendant content.
- `padding` contributes to the node's own `"content"` measurement.
- `padding` does not move the node relative to its parent.
- `padding` does not change sibling spacing directly.
- `padding` does not expand the node's paint or hit-test area; it is inside the
  node's bounds.

Implications:

- A `Drawable` paints its own surface in its border box.
- Descendant placement for `Drawable` happens inside the content box.
- A layout-family node places its children inside its content box.
- If padding collapses the content box below zero size, each axis clamps to
  zero.

### 3. Margin

`margin` is external spacing requested by the child and consumed only by
margin-aware parents.

Rules:

- `margin` does not change the node's own border box.
- `margin` does not change the node's own content box.
- `margin` does not expand rendering, clipping, or hit testing for the node.
- `margin` does not affect child placement for descendants of the node itself.
- `margin` only affects how a margin-aware parent measures and places that node.
- `margin` members may be negative.

For parents that do not explicitly consume child margin:

- child `margin` is inert for placement and measurement
- child `x`, `y`, transform, anchor, and parent-specific placement rules remain
  the only placement drivers

### 4. Layout Consumption Rule

A parent that consumes child margin must treat the child's layout footprint as
the child's `margin box`, not just the child's border box.

This means:

- layout measurement uses the child's outer footprint
- layout placement reserves space for the child's outer footprint
- the child border box is then placed inside that reserved outer footprint by
  the resolved margins

Negative-margin rule:

- the child's outer footprint may be smaller than its border box when one or
  more margins are negative
- the resolved distance between two adjacent child border boxes may be negative
- a negative resolved distance means the child border boxes overlap
- this overlap is valid
- negative margins do not alter the child's own border box, paint area, clip
  area, or hit-test area

### 5. Stack Rules

`Stack` consumes child margin.

Rules:

- each child resolves within the stack content box
- effective child placement space for the child's border box is the stack
  content box inset by the child's effective margins
- child alignment, anchor, and explicit local offsets position the child border
  box inside that margin-adjusted space
- child margins do not create sibling interaction in `Stack`; they only reduce
  each child's available placement area
- stack `"content"` measurement uses the largest child outer footprint on each
  axis

### 6. Row Rules

`Row` consumes child margin.

Rules:

- along the main axis, layout advances by each child's outer width
- along the cross axis, cross-size alignment uses the child's outer height
- `gap` is inserted between adjacent child margin boxes
- the visual distance between two child border boxes is:
  - previous child's end margin
  - plus `gap`
  - plus next child's start margin
- that resolved distance may be negative, which means the border boxes overlap
- row `"content"` measurement includes:
  - each child outer width
  - plus row gaps between participating children
- row cross-size measurement is the maximum participating child outer height

### 7. Column Rules

`Column` consumes child margin.

Rules:

- along the main axis, layout advances by each child's outer height
- along the cross axis, cross-size alignment uses the child's outer width
- `gap` is inserted between adjacent child margin boxes
- the visual distance between two child border boxes is:
  - previous child's bottom margin
  - plus `gap`
  - plus next child's top margin
- that resolved distance may be negative, which means the border boxes overlap
- column `"content"` measurement includes:
  - each child outer height
  - plus column gaps between participating children
- column cross-size measurement is the maximum participating child outer width

### 8. Flow Rules

`Flow` consumes child margin.

Rules:

- wrapping decisions use each child's outer width
- row height uses the maximum participating child outer height in that row
- `gap` is inserted between adjacent child margin boxes in a row
- negative horizontal margins may produce overlap between neighboring child
  border boxes; wrapping still uses the resolved outer footprints
- row-to-row spacing uses:
  - previous row's effective row-bottom outer edge
  - plus flow vertical gap
  - plus next row's effective row-top outer edge
- the resolved distance between rows may be negative, which means rows may
  overlap
- flow `"content"` measurement uses the union of participating child outer
  footprints after wrapping

### 9. SafeAreaContainer Rules

`SafeAreaContainer` consumes child margin.

Rules:

- first resolve the safe-area-adjusted content box
- then apply child margin consumption against that content box the same way
  `Stack` does
- safe-area insets and child margins are additive spacing layers, not aliases

### 10. Visibility And Participation

For layout families:

- children with `visible = false` do not occupy layout space
- therefore their margins also do not occupy layout space

For non-layout parents:

- visibility rules follow the normal retained-tree contract
- margin remains inert if the parent does not consume it

### 11. Overflow, Clipping, And Hit Testing

`margin` does not enlarge the node's own clip or hit region.

Rules:

- clipping is still based on the node's own resolved bounds and any ancestor
  clip chain
- hit testing is still based on the node's effective target bounds, not its
  outer margin box
- overflow checks in layout families may use outer footprints for placement, but
  actual rendering overflow is still determined by real node bounds and clipping

### 12. Content Measurement

When a node resolves `width = "content"` or `height = "content"`:

- its own `padding` contributes to that measurement
- its own `margin` does not

When a layout parent resolves `"content"` sizing from its children:

- it uses child outer footprints if that layout consumes child margin
- it uses child border-box footprints otherwise

This preserves the rule that margin is external spacing requested by the child
but realized only by the parent.

## Proposed Patch Targets

If accepted, the spec patch should touch:

- `docs/spec/ui-foundation-spec.md`

Recommended patch areas:

1. Section 3B quad-family definitions:
   - add spacing-family value constraints for `padding` and `margin`
   - add the parent-consumption opt-in rule for `margin`
2. Section 6.1.2 `Drawable`:
   - define border box, content box, and margin semantics
3. Section 6.2.2 common layout props:
   - define that layout families consume child margin only where stated
4. `Stack`, `Row`, `Column`, `Flow`, and `SafeAreaContainer` composition rules:
   - add child-margin consumption behavior
5. behavioral edge cases:
   - zero-area padding collapse
   - inert child margin under non-layout parents
   - invisible children contribute no margin footprint
   - negative-margin overlap does not alter hit or clip ownership

## Proposed Follow-Up Implementation Work

If this draft is accepted, implementation should follow in a separate phase:

1. tighten spacing validators to reject negative `padding` and allow finite
   positive or negative `margin`
2. implement child-margin consumption in:
   - `Stack`
   - `Row`
   - `Column`
   - `Flow`
   - `SafeAreaContainer`
3. add focused specs for:
   - drawable content-box behavior under padding
   - inert margin under plain `Container` and plain `Drawable`
   - sequential layout placement with margins plus gaps
   - wrapped flow footprint behavior
   - safe-area plus margin composition
   - negative-margin overlap without hit-region expansion

## Open Questions

These should be resolved before the draft becomes normative:

1. Should `Stack` consume child margin at all, or should margin be sequential-only?
2. Should `SafeAreaContainer` be specified as stack-like for child margins, or
   should it delegate to its current single-slot placement language?
3. Negative margins are accepted in this draft. The remaining question is
   whether any extra guardrails are needed beyond "finite numbers only."
4. Should `Drawable` continue exposing `margin` publicly if non-layout parents
   leave it inert?

## Recommendation

Accept this draft direction, with one key design principle:

`padding` is always internal spacing applied by the node to its own interior and
remains non-negative; `margin` is always external spacing requested by the
child, may be negative, and is consumed only by parents with explicit layout
contracts.

That gives a clean model, avoids hidden parent behavior in plain retained nodes,
and closes the current spec gap without inventing CSS-like behavior where the
library has not standardized it.
