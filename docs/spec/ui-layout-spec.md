# UI Layout Specification

## 1. Purpose And Authority

This document is the authoritative contract for layout behavior in the UI
library.

It owns:

- spacing semantics for `padding` and `margin`
- spacing interaction rules between child nodes and parents
- `Drawable` box model, content sizing, and internal content alignment semantics
- layout-family common props and common state model
- `Stack`
- `Row`
- `Column`
- `Flow`
- `SafeAreaContainer`

Other specs may name layout props or layout-capable components, but they must
reference this document for behavioral meaning instead of restating layout
behavior.

This document depends on:

- [UI Foundation Specification](./ui-foundation-spec.md) for retained-tree
  composition, transforms, shared value-family shapes, and base primitive
  identity

The shared value-family normalization rules remain owned by Foundation:

- `SideQuad input`
- `CornerQuad input`
- aggregate-plus-flat override rule

This document is authoritative for how those shared value families behave when
used by layout-owned spacing properties.

## 2. Shared Spacing Contract

### 2.1 Scope

This section defines the spacing contract for any component that exposes:

- `padding`
- `paddingTop`, `paddingRight`, `paddingBottom`, `paddingLeft`
- `margin`
- `marginTop`, `marginRight`, `marginBottom`, `marginLeft`

In this revision, that includes:

- `Drawable`
- layout-family components

### 2.2 Public Value Forms

`padding` uses `SideQuad input` from the Foundation specification.

`margin` uses `SideQuad input` from the Foundation specification.

`paddingTop`, `paddingRight`, `paddingBottom`, `paddingLeft` are flat overrides
for the corresponding `padding` members.

`marginTop`, `marginRight`, `marginBottom`, `marginLeft` are flat overrides for
the corresponding `margin` members.

Value constraints:

- `padding` members must be finite and `>= 0`
- `margin` members must be finite and may be positive, zero, or negative

### 2.3 Spacing Ownership And Direction

Spacing responsibilities are explicit in this revision:

- `padding` is internal spacing applied by the node to its own interior
- `margin` is external spacing requested by the child
- a node applies its own `padding`
- a node does not apply its own `margin`
- child `margin` is consumed only by parents whose component contract
  explicitly says they consume child margin
- when a parent does not explicitly consume child margin, child `margin` is
  inert for placement and measurement under that parent

The directional distinction that underpins this model is:

- `padding` is inward. It acts on the node itself. It shrinks the content box
  relative to the border box, contributes to the node's own border-box size,
  and does not require any cooperation from the parent.
- `margin` is outward. It is a request for space outside the node's border
  box. It requires the parent to read and honor it. Without a parent that
  explicitly consumes child margin, margin is inert.

### 2.4 Boxes And Resolution Order

For any node participating in spacing-aware layout:

- `border box`: the node's resolved local bounds
- `content box`: the inner rectangle after insetting the border box by padding
- `margin box` / `outer footprint`: the layout footprint formed by expanding
  the border box by margin

Resolved order:

1. Normalize aggregate and flat spacing props into canonical four-member values.
2. Resolve the node's border box. Sizing mode resolution for explicit numeric
   dimensions, `"fill"`, `"content"`, and percentage sizing, and application of
   `minWidth`, `minHeight`, `maxWidth`, `maxHeight` clamps, is defined in
   [UI Foundation Specification](./ui-foundation-spec.md) §6.1 and §7.3.
3. Resolve the node's content box by insetting the border box by padding.
4. If the parent consumes child margin, resolve the child's outer footprint by
   expanding the child's border box by margin.

Padding therefore resolves on the node itself before any parent-owned margin
consumption is considered.

### 2.5 Parent Contracts

#### Non-Layout Parent Contract

A parent with no explicit layout-placement contract, including plain
`Container` and plain `Drawable`, must follow these rules:

- it does not automatically consume child `margin`
- it does not reserve space for child `margin`
- it does not alter child placement because of child `margin`
- it continues to use normal child transform, anchor, explicit position, and
  component-specific placement rules only

This makes child margin inert under non-layout parents.

#### Margin-Consuming Parent Contract

A parent whose component contract explicitly says it consumes child margin must:

- measure children using their outer footprints
- place children using their outer footprints
- resolve the child border box inside that outer footprint according to the
  child's effective margins
- keep the child's own border box, paint area, and hit area unchanged

Margin consumption is never implicit. Each parent type must opt in explicitly.

### 2.6 Measurement

Spacing affects measurement in two distinct places:

- node self-measurement
- parent child-footprint measurement

This follows the same directional split as the spacing contract: padding
affects the node's own measurement, while margin affects parent-owned child
footprint measurement only when the parent explicitly consumes it.

Rules:

- a node's own `padding` contributes to that node's `"content"` measurement
- a node's own `margin` does not contribute to that node's own `"content"`
  measurement
- a margin-consuming parent includes child outer footprints in its own
  content-based measurement
- a non-margin-consuming parent ignores child margin during measurement
- `Drawable` is a node with an intrinsic `"content"` measurement rule on both
  axes
- when `Drawable` is content-sized on an axis, its resolved border-box size on
  that axis is the measured content extent plus its own padding on that axis
- a layout-family component that is content-sized on an axis must not contain a
  visible child with `"fill"` sizing on that same axis; this configuration
  creates a circular measurement dependency and must fail deterministically; the
  failure mode is a `Hard failure` as defined in
  [UI Foundation Specification](./ui-foundation-spec.md) §3G.1

### 2.7 Hit Testing And Clipping Contract

Spacing must not create hidden interaction or clip regions.

Rules:

- `padding` does not create a hit region outside the node's own bounds
- `margin` never creates hit area outside the node's own bounds
- `margin` never enlarges the node's own clip region
- negative-margin overlap does not merge hit regions between siblings
- hit testing continues to resolve against the node's border box
- clipping continues to resolve against the node's border box and ancestor clip chain

### 2.8 Negative Margin Contract

Negative margins are valid.

Rules:

- a negative margin may reduce a child's outer footprint
- a negative margin may produce overlap between adjacent child border boxes
- overlap caused by negative margins is valid
- negative margins do not alter the child's own border box, paint area,
  hit-test area, or clip area

### 2.9 Visibility Contract

For layout families:

- children with `visible = false` do not occupy layout space
- therefore their margins also do not occupy layout space

For non-layout parents:

- retained-tree visibility behavior remains the same
- child margin is inert there anyway

## 3. Drawable

`Drawable` exposes `padding` and `margin` and participates in the spacing
contract defined here. This section applies the shared spacing contract to
`Drawable`'s own box model, content sizing, and internal alignment behavior.

### 3.1 Box Model Contract

`Drawable` owns a three-region box model:

- `border box`: the node's resolved outer size
- `padding region`: the space between the border box and the content box
- `content box`: the interior region available for child composition

`Drawable` must:

- define a content box inside its padding
- apply its own `padding` when resolving that content box
- resolve `alignX` and `alignY` inside that content box
- not apply its own `margin` to itself
- rely on the parent contract to determine whether `margin` is consumed

The `Drawable` border box is always the content box plus the node's own
padding on each axis. Padding is therefore both a content-box inset and a
contributor to the `Drawable`'s own resolved size. This is a property of the
`Drawable` itself and does not depend on whether the parent is a layout family.

Padding remains internal spacing only. It does not become external spacing, and
it does not alter the node's margin box or any parent-owned margin consumption
rule.

Giving `Drawable` a box model does not make it a layout family. Box-model
ownership and layout-family ownership are separate contracts.

### 3.2 Content Sizing Contract

`Drawable` supports `width = "content"` and `height = "content"` as valid
sizing modes.

When `Drawable` is content-sized on an axis, it must resolve its border-box
size on that axis as:

`border_box[axis] = content_extent[axis] + padding_start[axis] + padding_end[axis]`

For this measurement:

- `content_extent` is the union of visible child border boxes in the
  `Drawable`'s local space after child transforms are resolved
- child `margin` is ignored entirely
- only the positive quadrant relative to the content-box origin contributes to
  `content_extent`; child bounds extending negatively are overflow, not size
  contributors
- a `Drawable` with no visible contributing children resolves `content_extent`
  to zero on that axis

`Drawable` content sizing measures child border boxes, not child padding or
child margin directly. Child padding therefore propagates through the sizing
chain by enlarging the child border box. Child margin does not propagate under
`Drawable` because `Drawable` does not consume child margin.

`Drawable.width = "content"` is invalid when any visible child has
`width = "fill"`. `Drawable.height = "content"` is invalid when any visible
child has `height = "fill"`. These configurations must fail deterministically.
The failure mode is a `Hard failure` as defined in
[UI Foundation Specification](./ui-foundation-spec.md) §3G.1.

A `Drawable` whose visible children are all positioned such that their border
boxes fall entirely outside the positive quadrant resolves `content_extent` to
zero on each affected axis. The resolved border-box size is therefore the
padding width and height only, and all children overflow. This is valid.

This content-sizing rule gives `Drawable` an intrinsic measurement contract. It
does not make `Drawable` a layout family, and it does not give `Drawable`
ownership of sibling sequencing or child-margin consumption.

### 3.3 Internal Alignment Contract

`Drawable.alignX` and `Drawable.alignY` are internal content-alignment props.
They define how content resolves inside the `Drawable` content box. They do not
place the `Drawable` in its parent.

"Content" for alignment purposes is the union of visible child border boxes in
the `Drawable`'s local space — the same `content_extent` defined in §3.2.
Alignment shifts this union as a whole within the content box. When `Drawable`
contains multiple children, alignment is not applied independently per child;
it is applied to the aggregate content union.

Rules:

- `alignX` and `alignY` apply only to content resolved inside the `Drawable`
  content box
- `alignX` and `alignY` do not place the `Drawable` in its parent
- parent-driven child placement remains owned by the parent contract
- `alignX = "stretch"` and `alignY = "stretch"` stretch the content union to
  span the full corresponding content-box dimension on that axis
- `alignX = "start" | "center" | "end"` and
  `alignY = "start" | "center" | "end"` place the content union within the
  corresponding content-box axis without changing the `Drawable` border box
- on any axis where `Drawable` is content-sized, the corresponding alignment
  property remains valid but is inert because the content extent already
  determines that axis of the content box and leaves no remaining space for
  alignment
- when padding collapses an axis of the content box to zero, content placement
  on that axis resolves at the content origin and stretch resolves to zero size

### 3.4 Behavioral Edge Cases

- a `Drawable` with padding that causes the content box to reach zero area must
  clamp the content box to zero area
- children positioned within a zero-area content box are placed at the content
  origin
- `Drawable.alignX` and `Drawable.alignY` remain internal-content alignment
  properties and do not become parent-layout placement properties under any
  layout-family parent
- a `Drawable` under a parent that does not explicitly consume child margin must
  treat its own margin as inert for placement and measurement under that parent
- a `Drawable` whose negative margins produce overlap under a margin-consuming
  parent does not enlarge its own render bounds, hit-test bounds, or clip
  region

## 4. Layout Family

### 4.1 Purpose And Contract

Layout primitives place children inside a content box. They own child
measurement order, spacing rules, alignment resolution, responsive overrides,
and overflow policy. Layout primitives do not own child interaction semantics.

This revision standardizes:

- `Stack`
- `Row`
- `Column`
- `Flow`
- `SafeAreaContainer`

### 4.2 Common Props

- `gap: number`
- `padding`
- `paddingTop`, `paddingRight`, `paddingBottom`, `paddingLeft`
- `wrap: boolean`
- `justify: "start" | "center" | "end" | "space-between" | "space-around"`
- `align: "start" | "center" | "end" | "stretch"`
- `responsive`
- `clipChildren: boolean` — inherited from `Container`
  ([UI Foundation Specification](./ui-foundation-spec.md) §6.1); when `true`,
  clips both rendering and hit testing to the component's border box

`padding` in layout-family common props uses `SideQuad input`.

`paddingTop`, `paddingRight`, `paddingBottom`, `paddingLeft` are flat overrides
for the corresponding `padding` members when a layout-family component exposes
them.

`gap` must be finite and `>= 0`. Negative `gap` is not valid in this revision.

Common spacing rules:

- parent `padding` reduces the parent's content box
- child `margin` is consumed only when the specific layout-family component says
  it consumes child margin
- when consumed, child `margin` affects layout footprint only
- child `margin` never enlarges the child's own hit region, clip region, or
  paint region
- if a consumed negative margin produces a negative resolved distance between
  adjacent child border boxes, overlap is valid

Ownership note:

- `responsive` appears here because layout-family components expose it as part
  of their common prop surface
- the responsive rule model, timing, resolution semantics, and the relationship
  between `responsive` and the `Container`-inherited `breakpoints` prop are
  owned by [UI Foundation Specification](./ui-foundation-spec.md) §7.3; if both
  `responsive` and `breakpoints` are supplied on the same node, the
  configuration is invalid and must fail deterministically

Common prop defaults when a prop is omitted:

- `gap`: `0`
- `wrap`: `false`
- `justify`: `"start"`
- `align`: `"start"`
- `clipChildren`: `false`
- `responsive`: `nil` (no responsive rules active)

### 4.3 Common State Model

STATE layout_clean

  ENTRY:
    1. Child measurements and placements are current.

  TRANSITIONS:
    ON child addition, removal, size mutation, visibility mutation, or breakpoint change:
      1. Mark layout invalid.
      → layout_dirty

STATE layout_dirty

  ENTRY:
    1. Child measurements or placements are stale.

  TRANSITIONS:
    ON next layout pass:
      1. Resolve own content box.
      2. Resolve each eligible child measurement.
      3. Place children according to layout family rules.
      4. Resolve overflow policy.
      → layout_clean

Eligibility: a child is eligible for measurement and placement if and only if
`visible = true` at the time of the layout pass. Children with `visible = false`
are skipped entirely in both measurement and placement.

Size mutation: mutations that mark layout dirty include changes to `width`,
`height`, `minWidth`, `maxWidth`, `minHeight`, `maxHeight`, `padding`,
`paddingTop`, `paddingRight`, `paddingBottom`, `paddingLeft`, and any child prop
whose change alters that child's resolved measurement. Changes that do not
affect any node's resolved measurement do not mark layout dirty.

## 5. Stack

### 5.1 Purpose And Contract

`Stack` places all children within the same content box, layered by z-order. It
is the default composition primitive for overlays, layered visuals, and
positioned content.

`Stack` must:

- apply the common layout state model
- allow each child to resolve its own alignment and anchor independently
- not impose a sequential axis on children

### 5.2 Anatomy

- `root`: the stack node. Required.
- `children`: zero or more layered child nodes. Optional.

### 5.3 Props And API Surface

`Stack` does not define additional props beyond the common layout props.

### 5.4 State Model

`Stack` uses the common layout state model defined in Section 4.3.

### 5.5 Accessibility Contract

`Stack` is a non-interactive structural container. It does not add or require
semantic accessibility attributes. Focusable descendants participate in
traversal in tree order.

### 5.6 Composition Rules

`Stack` may contain any number of child nodes. `Stack` consumes child margin.
Children resolve their own alignment and position within the stack's content box
independently, but each child's available placement region is the stack content
box inset by that child's effective margins. Child margins do not create
sibling spacing in `Stack`; they only adjust each child's own placement region.
Overlapping children are drawn in ascending `zIndex` order; among siblings with
equal `zIndex`, draw order is stable insertion order. Hit testing resolves in
reverse draw order. `zIndex` is a `Container`-inherited integer prop defined in
[UI Foundation Specification](./ui-foundation-spec.md) §6.1. Its default value
is `0`.

Authoring note: child `margin` in `Stack` acts as an inset against the stack
edges — it shrinks each child's individual placement region. This is different
from `Row` and `Column`, where child `margin` contributes to sequential spacing
footprints between adjacent children. Authors writing components intended to be
placed in either a `Stack` or a sequential layout must account for this
behavioral difference.

### 5.7 Behavioral Edge Cases

- an empty `Stack` renders nothing and must not fail
- a `Stack` whose children are all `visible = false` behaves as an empty stack
- a `Stack` child with negative margins may overlap siblings or extend outside
  its nominal placement region; this is valid and does not enlarge the child's
  own hit or clip region
- when `clipChildren = true`, children extending beyond the stack bounds are
  clipped in both rendering and hit testing

## 6. Row

### 6.1 Purpose And Contract

`Row` places children sequentially along the horizontal axis. It resolves
cross-axis alignment vertically. `Row` is the primary horizontal composition
primitive.

`Row` must:

- apply the common layout state model
- place children left to right in insertion order when `direction = "ltr"`
- resolve gap spacing between children
- resolve cross-axis alignment for each child

### 6.2 Anatomy

- `root`: the row node. Required.
- `children`: ordered child sequence along the horizontal axis. Optional.

### 6.3 Props And API Surface

- `direction: "ltr" | "rtl"` — default `"ltr"`

Plus all common layout props.

### 6.4 State Model

`Row` uses the common layout state model defined in Section 4.3.

### 6.5 Accessibility Contract

`Row` is a non-interactive structural container. It does not add or require
semantic accessibility attributes. Focusable descendants participate in
traversal in insertion order.

### 6.6 Composition Rules

`Row` may contain any number of children. `Row` consumes child margin. Children
that are themselves layout primitives are measured before placement. Along the
main axis, layout advances by each child's outer footprint. `gap` is inserted
between adjacent child margin boxes. The resolved visual distance between
adjacent child border boxes is: previous child's end margin, plus `gap`, plus
next child's start margin. That resolved distance may be negative, which means
overlap is valid. When `wrap = true`, overflow children are placed on
subsequent rows. `Row` must not be nested inside itself in a way that creates a
circular measurement dependency.

### 6.7 Behavioral Edge Cases

- an empty `Row` renders nothing and must not fail
- when total child measurement exceeds available width with `wrap = false`, the
  overflow policy applies; the default overflow policy allows overflow without
  clipping unless `clipChildren = true`
- a single child in a `Row` with `justify = "space-between"` resolves to the
  start position
- negative child margins may reduce spacing or create overlap between adjacent
  child border boxes, but they do not enlarge any child's own hit or clip
  region
- when one or more children consume remaining horizontal space through a
  fill-sized width, `Row` must resolve those widths deterministically and apply
  `minWidth` and `maxWidth` clamps as defined in
  [UI Foundation Specification](./ui-foundation-spec.md) §6.1; this revision
  does not standardize a specific sibling allocation algorithm

Trace note: this revision intentionally does not freeze one fill-distribution
policy, such as equal-share allocation, as public contract.

## 7. Column

### 7.1 Purpose And Contract

`Column` places children sequentially along the vertical axis. It resolves
cross-axis alignment horizontally. `Column` is the primary vertical composition
primitive.

`Column` must:

- apply the common layout state model
- place children top to bottom in insertion order
- resolve gap spacing between children
- resolve cross-axis alignment for each child

### 7.2 Anatomy

- `root`: the column node. Required.
- `children`: ordered child sequence along the vertical axis. Optional.

### 7.3 Props And API Surface

`Column` does not define additional props beyond the common layout props.

### 7.4 State Model

`Column` uses the common layout state model defined in Section 4.3.

### 7.5 Accessibility Contract

`Column` is a non-interactive structural container. It does not add or require
semantic accessibility attributes. Focusable descendants participate in
traversal in insertion order.

### 7.6 Composition Rules

`Column` may contain any number of children. `Column` consumes child margin.
Children that are themselves layout primitives are measured before placement.
Along the main axis, layout advances by each child's outer footprint. `gap` is
inserted between adjacent child margin boxes. The resolved visual distance
between adjacent child border boxes is: previous child's bottom margin, plus
`gap`, plus next child's top margin. That resolved distance may be negative,
which means overlap is valid. `Column` must not be nested inside itself in a
way that creates a circular measurement dependency.

### 7.7 Behavioral Edge Cases

- an empty `Column` renders nothing and must not fail
- when total child measurement exceeds available height with `wrap = false`,
  the overflow policy applies; the default overflow policy allows overflow
  without clipping unless `clipChildren = true`
- a single child in a `Column` with `justify = "space-between"` resolves to the
  start position
- negative child margins may reduce spacing or create overlap between adjacent
  child border boxes, but they do not enlarge any child's own hit or clip
  region
- when one or more children consume remaining vertical space through a
  fill-sized height, `Column` must resolve those heights deterministically and
  apply `minHeight` and `maxHeight` clamps as defined in
  [UI Foundation Specification](./ui-foundation-spec.md) §6.1; this revision
  does not standardize a specific sibling allocation algorithm

Trace note: this revision intentionally does not freeze one fill-distribution
policy, such as equal-share allocation, as public contract.

## 8. Flow

### 8.1 Purpose And Contract

`Flow` places children in reading order across the primary axis, wrapping to a
new line when remaining space on the current line is insufficient. It is
intended for fluid responsive placement and not for strict grid semantics.

`Flow` must:

- apply the common layout state model
- place children in reading order
- wrap to a new row when `wrap = true` and remaining space is exhausted
- resolve gap spacing between children across and along the primary axis

### 8.2 Anatomy

- `root`: the flow node. Required.
- `children`: ordered child nodes placed in reading order. Optional.

### 8.3 Props And API Surface

- `direction: "ltr" | "rtl"` — default `"ltr"`

Plus all common layout props.

### 8.4 State Model

`Flow` uses the common layout state model defined in Section 4.3.

### 8.5 Accessibility Contract

`Flow` is a non-interactive structural container. Focusable descendants
participate in traversal in insertion order.

### 8.6 Composition Rules

`Flow` may contain any number of children. `Flow` consumes child margin.
Wrapping decisions use each child's outer footprint. The wrapping condition is:
a child is placed on the current row if its outer footprint width fits within
the remaining available width on that row, where remaining width equals total
available width minus the sum of all already-placed children's outer footprints
on the current row minus the accumulated `gap` widths between them. When a
child does not fit and `wrap = true`, it begins a new row. A child whose outer
footprint exceeds the full available width occupies its own row alone and is not
clipped unless `clipChildren = true`. `gap` is inserted between adjacent child
margin boxes within a row. Negative margins may reduce spacing or create overlap
between neighboring child border boxes, but wrapping decisions still use
resolved outer footprints. Children with `visible = false` do not occupy space
in the flow and therefore contribute no margin footprint. `Flow` may be placed
inside any other layout container.

Reading order follows the `direction` prop: `"ltr"` places children left to
right; `"rtl"` places children right to left.

### 8.7 Behavioral Edge Cases

- an empty `Flow` renders nothing and must not fail
- when `wrap = false` and children exceed available width, the overflow policy
  applies without wrapping
- children on the last row of a wrapped flow are placed using the `justify`
  value for main-axis distribution; the last row is not specially stretched to
  fill available main-axis space regardless of the `justify` value
- negative margins may cause overlap within or between wrapped rows, but they do
  not enlarge any child's own hit or clip region
- a single child wider than the full flow row occupies that row alone and is
  not clipped unless `clipChildren = true`

## 9. SafeAreaContainer

### 9.1 Purpose And Contract

`SafeAreaContainer` measures and positions its content region against the safe
area bounds reported by the environment rather than against full viewport
bounds. It is the designated container for content that must avoid device-level
obstructions such as notches, status bars, and home indicators.

`SafeAreaContainer` must:

- derive its content area from the current safe area bounds
- update its content area when safe area bounds change
- support opt-in inset application per edge

### 9.2 Anatomy

- `root`: the safe area container node. Required.
- `content`: the inset content region. Required.

### 9.3 Props And API Surface

- `applyTop: boolean`
- `applyBottom: boolean`
- `applyLeft: boolean`
- `applyRight: boolean`

Plus all common layout props.

### 9.4 State Model

`SafeAreaContainer` uses the common layout state model defined in Section 4.3.

In addition:

  TRANSITIONS:
    ON safe area bounds change:
      1. Re-derive content region from updated safe area bounds.
      2. Mark layout invalid.
      → layout_dirty

### 9.5 Accessibility Contract

`SafeAreaContainer` is a non-interactive structural container. It does not add
or require accessibility attributes.

### 9.6 Composition Rules

`SafeAreaContainer` may contain any layout or drawable descendants.
`SafeAreaContainer` consumes child margin with stack-like semantics. It first
resolves the safe-area-adjusted content region, then applies its own padding,
then consumes child margins against the resulting placement region.

Trace note: `SafeAreaContainer` remains bounds-based even when an
implementation derives per-edge inset distances from those bounds internally.
The public contract is not an insets-only environment API.

### 9.7 Behavioral Edge Cases

- when the environment reports no safe area insets, `SafeAreaContainer` renders
  identically to a plain container of the same dimensions
- when all `apply*` props are false, the container applies no inset adjustment
- negative child margins may pull children beyond the nominal safe-area
  placement region, but do not enlarge the child's own hit or clip region
- `SafeAreaContainer` always queries the environment-reported safe area bounds
  regardless of where it appears in the tree
- multiple nested `SafeAreaContainer` instances each apply insets relative to
  the same environment-reported safe area bounds, not relative to the parent
  container's already-inset placement region; nesting two
  `SafeAreaContainer` instances does not double-apply insets
