# Incident: `Drawable` Missing Box Model Contract

## Status

Draft — Revised. Refocused on the root cause after design review.
No direct changes have been applied to `docs/spec`.

## Root Cause

`Drawable` has padding semantics but no box model.

Padding is currently implemented as a **rendering offset**: it derives an
inset content rect used for drawing and child alignment, but it does not
contribute to `Drawable`'s own resolved border-box size.

That is the wrong abstraction boundary.

In every settled box model — CSS, Flutter, SwiftUI — padding is a
**sizing contributor** on the primitive itself, not a rendering concern
grafted on top. A `div` does not need to be a flex container for its padding
to affect its own size. Those are orthogonal properties of the same primitive.

Until `Drawable` has a proper box model, padding cannot participate in outer
size without introducing an extra layout-family wrapper. That breaks idiomatic
composition at the foundation of the entire control system.

---

## Problem Statement

`Drawable` is the foundation for all visual controls. Currently it has:

- a border box
- padding
- a content box derived from that padding
- internal alignment through `alignX` and `alignY`
- child composition inside the content box

What it does not have is a contract that makes its own padding contribute to
its own resolved size.

The effect is that authors who want all of the following at once:

- a visual surface
- padding on that surface
- content aligned inside that surface
- the surface sized from its padded content

cannot express that with a single `Drawable`. They are forced to wrap it in a
layout-family node whose only job is to perform the size resolution that
`Drawable`'s box model should have handled directly.

This is the equivalent of requiring an inner element inside every DOM `div`
just to make `align-items` work. It is not a missing layout feature. It is a
missing box model.

---

## Why This Is A Box Model Problem, Not A Layout Problem

Padding and layout are orthogonal concerns.

**Padding** answers: how does this node's interior space relate to its border
box? That is a property of the node itself.

**Layout** answers: how does this node place its children relative to each
other? That is a property of the parent-child relationship.

These two concerns composing independently is the foundational property of
every mature UI box model. Their accidental coupling in the current
implementation is what created this incident.

Making `Drawable` a proper box model primitive does not make it a layout
family. It makes it a node whose padding affects its own size — exactly
as every visual primitive in every major system does.

---

## Consolidated Current Published Contract

### 1. `Container` Public Sizing Surface

The Foundation spec exposes this public sizing surface for `Container`:

- `width`, `height: number | "content" | "fill" | percentage`

It also states:

- `width = "content"` on a node with no intrinsic measurement rule is an
  invalid configuration and must fail deterministically

The public surface already admits content sizing, but only nodes with an
intrinsic measurement rule may use it. `Drawable` currently has none.

### 2. `Drawable` Role In The Library

The Foundation spec describes `Drawable` as:

- the first render-capable primitive
- responsible for presentational surface, content box, alignment, and
  render-effect participation
- not a layout-family placement primitive

It also says `Drawable`:

- defines a content box inside its padding
- may contain child nodes
- renders descendants within its content box

The published role already includes visual containment and content-region
definition. The box model is implied but never made normative.

### 3. Shared Spacing Contract

The Layout spec defines the shared spacing model:

- `padding` is internal spacing applied by the node to its own interior
- `margin` is external spacing requested by the child
- a node applies its own `padding`
- a node does not apply its own `margin`
- child `margin` is consumed only by parents whose contract explicitly
  says so

The directional distinction that underpins this model is:

- **padding is inward** — it acts on the node itself, shrinking the content
  box relative to the border box. It contributes to the node's own border-box
  size. It does not require any cooperation from the parent.
- **margin is outward** — it is a request for space outside the node's border
  box. It requires the parent to read and honor it. Without a parent that
  explicitly consumes child margin, margin is inert.

This means the size propagation chain for nested content-sized nodes follows
naturally from padding alone:

```
Parent Drawable  (width = "content")
└── Child Drawable
      padding: 20    ← expands Child's own border box
      margin: 10     ← inert, Parent does not read it
```

The parent does not read the child's padding. It reads the child's border box,
which is already larger because of that padding. The parent then adds its own
padding on top. Size propagates up the tree entirely through border boxes.
Margin plays no part in this chain under a non-layout parent.

### 4. Plain `Drawable` As A Non-Layout Parent

The Layout spec says a non-layout parent including plain `Drawable`:

- does not automatically consume child `margin`
- does not reserve space for child `margin`
- does not alter child placement because of child `margin`

This is coherent and must remain unchanged.

### 5. The Measurement Gap

The Layout spec states that a node's own padding contributes to its
`"content"` measurement. But the `Drawable` section does not say whether
`Drawable` is such a node. That ambiguity is the gap this incident addresses.

---

## Current Runtime Behavior

The current implementation resolves this ambiguity in the narrowest possible
way:

- `Drawable:getContentRect()` insets the resolved local bounds by effective
  padding — padding used purely as a drawing offset
- plain `Drawable` does not enable `width = "content"` or `height = "content"`
- layout-family nodes such as `Stack` implement a content-measurement pass
  that adds `padding + measured child extent`

In other words, padding is a rendering concern inside `Drawable`. It becomes
a sizing concern only when a layout-family parent takes over. The box model
lives in the wrong place.

---

## Proposed Fix: Give `Drawable` A Box Model

The fix is not to add a sizing mode. It is to formalize the box model
contract that `Drawable` should have had from the start.

### Core Statement

`Drawable`'s own padding must contribute to its own resolved border-box size.

This is independent of whether `Drawable` is a layout family. It is a
property of the node's relationship between its interior space and its outer
size. It should hold regardless of whether the parent is a layout family,
and regardless of whether children are present.

### What A Box Model Means For `Drawable`

| Property | Current | With Box Model |
|---|---|---|
| Padding affects drawing offset | yes | yes (unchanged) |
| Padding affects content rect | yes | yes (unchanged) |
| Padding contributes to border-box size | no | **yes** |
| Padding participates in `"content"` sizing | no | **yes** |
| `Drawable` becomes a layout family | no | no (unchanged) |
| Child margin consumed by `Drawable` | no | no (unchanged) |
| Sibling sequencing owned by `Drawable` | no | no (unchanged) |

---

## Normative Semantics

### 1. Box Model Contract

`Drawable` owns a three-region box model:

- **border box** — the node's outer resolved size
- **padding region** — the space between the border box and the content box
- **content box** — the node's interior region available for child composition

The border box is always the sum of the content box plus padding on each axis.
This relationship is normative and holds regardless of how the `Drawable` is
sized.

### 2. Padding And Margin Directional Contract

Padding and margin have opposite directions and must be treated as distinct
in every part of the system.

**Padding is inward.** It acts on the node itself. It shrinks the content box
relative to the border box, and it expands the border box relative to the
content box. It does not require cooperation from any parent. It is always
self-contained.

```
border_box = content_box + padding_start + padding_end  (per axis)
```

**Margin is outward.** It is a request for space outside the node's own border
box. It does not change the node's border box. It requires the parent to read
and honor it. Under a non-layout parent, margin is unconditionally inert — it
has no effect on placement, measurement, or size.

```
border_box = border_box  (margin does not modify this)
```

**Propagation through a content-sized chain.** A content-sized parent reads
the child's border box, not the child's padding directly. Because padding
expands the child's border box, the effect of child padding propagates upward
through the size chain naturally — not because the parent is aware of padding,
but because it sees a larger border box. Margin does not propagate because it
does not affect the border box.

```
Parent Drawable  (width = "content")
└── Child Drawable
      padding: 20    → Child border box grows by 20 on each padded axis
      margin: 10     → Child border box unchanged, Parent does not read it
```

`Drawable`'s own padding must contribute to its own resolved border-box size
under the same rule. When `Drawable` is fixed-sized, the content box is inset
from the border box by padding. When `Drawable` is content-sized, the border
box is derived by expanding the measured content extent outward by padding.
Either way the relationship is the same: border box equals content box plus
padding.

### 3. Content Sizing

`Drawable` supports `width = "content"` and `height = "content"` as valid
sizing modes.

When content-sized on an axis, `Drawable` resolves its border-box size as:

```
border_box[axis] = content_extent[axis] + padding_start[axis] + padding_end[axis]
```

Where `content_extent` is the union of visible child border boxes in the
`Drawable`'s local space after child transforms are resolved.

Rules for content extent measurement:

- only visible children contribute (`visible = false` children are excluded)
- child margin is ignored entirely
- only the positive quadrant relative to the content-box origin contributes;
  child bounds that extend negatively are treated as overflow, not as size
  contributors

### 4. Non-Layout Parent Contract (Unchanged)

`Drawable` with a box model remains a non-layout parent.

Because margin is outward and requires parent cooperation, and `Drawable` does
not provide that cooperation, child margin is unconditionally inert under
`Drawable`. Specifically:

- child `margin` does not affect child placement
- child `margin` does not contribute to content-extent measurement
- child `margin` does not alter the child's border box as seen by `Drawable`

Because padding is inward and self-contained, child `padding` affects the
child's own border box without any action from `Drawable`. A content-sized
`Drawable` therefore responds to child padding indirectly — by seeing a larger
child border box — with no special handling required.

Having a box model and being a layout family are independent properties.
This is the same separation that exists in CSS between the block box model
and flex/grid layout. Formalizing the box model does not change the layout
contract.

### 5. Alignment Contract

`alignX` and `alignY` remain internal-content alignment properties that
apply within the content box.

One consequence must be stated explicitly in the spec:

> When `Drawable` is content-sized on an axis, the content box on that axis
> is exactly as wide as the measured child extent. There is no remaining space
> to align into. `alignX` and `alignY` are valid but inert on any axis where
> `Drawable` is content-sized.

The properties remain legal to allow seamless switching between fixed and
content-sized configurations without requiring authors to remove alignment
declarations. Their no-op status on a content-sized axis is part of the
published contract.

---

## Scope Constraint For This Cut

Content sizing with `fill`-sized children introduces a circular dependency:
the `fill` child needs the parent's resolved size, which needs the child's
contribution. Resolving that cleanly requires a system-level two-pass
measurement protocol (measure pass / layout pass) that is beyond the scope
of this incident.

Therefore:

**`Drawable.width = "content"` is invalid when any visible child has
`width = "fill"`. `Drawable.height = "content"` is invalid when any visible
child has `height = "fill"`. This is a deterministic error.**

This constraint is a scoping decision for the first cut, not a permanent
architectural limit. The upgrade path is documented in the appendix.

---

## Proposed Spec Patch Shape

The `Drawable` section of the spec should be updated to state explicitly:

1. `Drawable` owns a three-region box model: border box, padding region,
   content box.
2. `Drawable`'s own padding always contributes to its own resolved border-box
   size.
3. `Drawable` supports `width = "content"` and `height = "content"`.
4. Content sizing resolves border-box size as child content extent plus
   padding on each axis.
5. Content extent uses visible child border boxes; ignores child margin;
   counts only positive-quadrant bounds.
6. `fill`-sized children on the same axis as a content-sized dimension are
   a deterministic error.
7. `alignX` and `alignY` are inert on content-sized axes; this is part of
   the published contract.
8. Having a box model does not make `Drawable` a layout family. The non-layout
   parent contract is unchanged.

---

## Follow-Up Implementation Impact

1. `lib/ui/core/drawable.lua`
   Implement the box model: make padding a sizing contributor, not only a
   drawing offset. Add content-measurement path for content-sized dimensions.

2. `lib/ui/core/container_schema.lua`
   Allow `Drawable` to opt into `width = "content"` and `height = "content"`.
   Add validation rejecting `fill` children on the same axis.

3. `lib/ui/core/container.lua`
   Ensure the measurement lifecycle supports `Drawable` intrinsic sizing
   without promoting it into a layout family.

4. `lib/ui/core/drawable_schema.lua`
   Recheck validation expectations. Enforce eligibility constraints at the
   schema layer.

5. Control internals built on `Drawable`
   Remove wrapper layout nodes that exist only to make padding affect outer
   size. That use case is now handled directly by `Drawable`.

---

## Follow-Up Test Impact

1. `Drawable` with fixed size and padding — verifies content box is correctly
   inset and that border-box size is not changed (existing behavior preserved)
2. `Drawable` with `width = "content"`, one child at the content origin —
   verifies basic content-plus-padding sizing
3. `Drawable` with `height = "content"` and padding on all sides — verifies
   padding contribution on both axes independently
4. `Drawable` with a child at a positive offset beyond the content origin —
   verifies positive-extent accumulation
5. `Drawable` with a child at a negative offset — verifies negative bounds are
   overflow and do not inflate parent size
6. `Drawable` with child margin set — verifies margin remains inert for
   measurement
7. `Drawable` with `visible = false` children — verifies hidden children do
   not contribute to content size
8. `Drawable` with `width = "content"` and a `fill`-sized child on x-axis —
   verifies deterministic error
9. Nested content-sized `Drawable` — verifies outer size expands from inner
   padded content without a layout-family wrapper
10. Content-sized `Drawable` with `alignX` or `alignY` set — verifies no error
    is thrown and alignment is a documented no-op on the content-sized axis

---

## Demo Impact

Demo-local logic must not simulate margin consumption for plain `Drawable`.
That simulation contradicted the non-layout parent contract and was removed.
Its removal restores spec-aligned behavior but does not solve this incident.
Both fixes are required independently.

---

## Appendix: Two-Pass Protocol Upgrade Path

The `fill`-child constraint above is a scoping decision for this cut. The
clean upgrade path when the system is ready is a formal two-pass measurement
protocol:

**Measure pass.** Each node receives an axis constraint from its parent
(definite, unconstrained, or deferred). A content-sized `Drawable` propagates
unconstrained constraints to its children. `fill`-sized children contribute
their minimum intrinsic size during this pass, not their fill-resolved size.
The `Drawable` accumulates the child extent union, adds padding, and reports
its intrinsic size upward.

**Layout pass.** The parent resolves definite sizes and distributes space.
`fill` children receive their actual resolved size based on the now-definite
parent content box.

When this protocol is in place, the `fill`-child constraint can be relaxed.
This is a system-level change affecting all nodes and should be tracked as a
separate spec incident scoped to the measurement lifecycle.