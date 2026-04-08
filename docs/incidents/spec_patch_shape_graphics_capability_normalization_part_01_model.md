# Spec Patch: Normalize Graphics Capabilities Across Drawable And Shape

## Part 1: Model And Boundaries

---

## Summary

This document proposes a capability-normalization direction for bringing
shader, texture, alpha, and blend behavior to `Shape` without:

- making `Shape` a subtype of `Drawable`
- expanding `Container`
- introducing a new intermediary class
- unifying `Drawable.border*` with `Shape.stroke*`
- moving `Shape` into the styling or skinning system

The goal is narrower and more reusable:

- extract reusable graphics-capability interfaces
- apply those interfaces to both `Drawable` and `Shape`
- preserve each primitive's own geometry and paint semantics
- normalize how shared graphics capabilities are authored, resolved, animated,
  and composited

This part focuses on the conceptual model, the current primitive boundaries,
and the reusable interface split.

---

## Document Series

This document is Part 1 of a three-part series:

- **Part 1: Model And Boundaries** — this document
- **Part 2: Shared Root Compositing** — closed
- **Part 3: Shape-Owned Fill Sources And Texture** — fill source placement
  semantics, sprite-to-local-space mapping, silhouette clipping, repetition
  implementation scope

---

## What This Part Decides

This part is not only taxonomy. It settles the load-bearing model decisions
needed before Parts 2 and 3 can proceed.

Decisions made and closed in this part:

- root shader is a post-composite node effect, not an individual paint-call
  interceptor
- root blend mode is evaluated when the node's final resolved result is
  composited into its immediate parent composition target
- root opacity scales the node's resolved result before that final blend into
  the parent target
- non-default root blend mode requires subtree isolation or a provably
  equivalent optimization; this is not renderer discretion
- root shader requires access to the node's resolved result; implementations
  may avoid an explicit offscreen pass only when they can prove an inline path
  is semantically identical
- root opacity requires isolation or a provably equivalent optimization whenever
  per-draw application would produce a different result than post-composite
  application
- `mask` is intentionally excluded from the shared root-compositing surface;
  `mask` is a cross-node compositing binding that requires defining both a mask
  source role and a mask recipient role — this is a separate interface family
  and outside the scope of single-node capability normalization; `Shape`'s
  silhouette already defines its geometric visibility boundary and is the
  correct analogue for self-boundary semantics
- `Texture` and `Sprite` are shared graphics source objects, not primitive-local
  value types
- a `Sprite` always represents exactly one rectangular region over a `Texture`;
  the effective source dimensions are always the sub-region dimensions; the
  underlying texture dimensions are never surfaced directly
- assigning an invalid graphics source type is an immediate hard failure with
  no fallback and no prior-value retention
- assigning a normalized capability to a primitive that has not adopted it is
  an immediate hard failure with no silent ignore and no warning-only path
- `Shape` stroke is center-aligned on the silhouette; the full stroke extent,
  both inner and outer halves, is included in the shape-local composited result
  before any root-level effect is applied
- fill source priority for `Shape` is: `fillTexture` overrides `fillGradient`,
  which overrides `fillColor`; at most one source is active at render time
- `fillGradient` uses the gradient value-type contract defined in the Styling
  Document, Section 6.4 as a shared plain-object schema; `Shape` fill does not
  participate in the styling system for this type; no new gradient kinds are
  introduced by this proposal
- shared root compositing props are direct instance props, not styling props,
  and do not participate in ordinary property inheritance
- shape-owned fill-source props are direct instance props, not styling props,
  and do not participate in theming or skinning

Items resolved by Part 2:

- runtime capability declaration mechanism — resolved as a static class-level
  capability table on the primitive class definition, read once per class at
  load time; no per-instance query
- root `blendMode` motion writability — resolved as discrete step only; only
  `to` is meaningful in the property rule; `from`, `duration`, and `easing`
  are ignored; step is applied immediately
- `shader` motion writability — resolved as whole-object replacement only;
  same discrete-step rules as `blendMode`; per-uniform motion is not supported
  through the motion system

Items deferred to Part 3:

- shape fill placement algorithm
- sprite-region-to-local-space mapping
- silhouette clipping implementation semantics
- whether fill repetition ships in the first implementation pass
- motion semantics for shape-owned fill-source props

---

## Amendments To Foundation Spec

This patch supersedes the following normative statements in
`ui-foundation-spec.md`. The foundation spec must be updated to reflect these
changes when this patch is ratified.

**Section 6.1.3 — Shape, "Shape must not" list:**

Remove:
> expose `Drawable` border styling, shadow styling, skin, **shader**, **mask**,
> **blend-mode**, or shape-aware clipping semantics in this revision

Replace with:
> expose `Drawable` border styling, shadow styling, skin, or shape-aware clipping
> semantics in this revision; expose `mask` semantics in this revision

The exclusion of `shader` and `blendMode` from the "must not" list is lifted by
this patch. `mask` remains excluded.

**Section 3A.3 — Component Responsibility Boundary table, Shape row:**

Remove from the "Explicitly does not manage" column:
> shader or mask participation, blend-mode participation

Replace with:
> mask participation

`shader` and `blendMode` are normalized capabilities adopted by `Shape` through
this patch. `mask` remains outside `Shape`'s contract.

**Section 6.1.3 — Public surface exclusions:**

Remove from the exclusion list:
> no `skin`, `shader`, `blendMode`, or `mask`

Replace with:
> no `skin` or `mask`

---

## Current Primitive Contracts

### Drawable

`Drawable` is a render-capable primitive that owns:

- content box semantics
- padding and margin participation
- alignment inside the content box
- theming and skinning participation
- styling-family properties such as background, border, corner radius, and
  shadow
- node-level render effects

Its current root-level effect surface is:

- `shader`
- `opacity`
- `blendMode`
- `mask`

Its current image-backed paint surface is styling-based:

- `backgroundImage`
- `backgroundRepeatX`
- `backgroundRepeatY`
- `backgroundOffsetX`
- `backgroundOffsetY`
- `backgroundAlignX`
- `backgroundAlignY`

Its edge treatment is styling-based:

- `borderColor`
- `borderOpacity`
- `borderWidth`
- per-side border widths
- border line quality and dash properties

Border geometry is center-aligned on the styled bounds.

This is a broad presentation primitive.

### Shape

`Shape` is a render-capable geometric primitive that owns:

- a silhouette inside its local bounds
- fill rendering
- shape-owned stroke rendering
- silhouette-aware hit testing
- whole-node opacity

Its current public paint surface is:

- `fillColor`
- `fillOpacity`
- `strokeColor`
- `strokeOpacity`
- `strokeWidth`
- `strokeStyle`
- `strokeJoin`
- `strokeMiterLimit`
- `strokePattern`
- `strokeDashLength`
- `strokeGapLength`
- `strokeDashOffset`
- `opacity`

Stroke geometry is center-aligned on the silhouette. Half the stroke width
falls inside the silhouette boundary, half outside. Both halves are included
in the shape-local composited result.

Its current explicit exclusions are:

- no content-box semantics
- no styling-family background props
- no styling-family border props
- no corner-radius props
- no shadow props
- no skin surface
- no shader
- no blend mode
- no mask

This is a narrow geometric primitive.

### Opacity As Precedent

Whole-node opacity is already shared across `Drawable` and `Shape` through the
retained compositing path. `Shape` participates without entering the `Drawable`
styling model.

This demonstrates that capability extraction without inheritance unification
is viable.

Opacity is the simplest possible shared compositing case: one scalar input,
no source-object ownership, no shader parameter model, no ambiguity about
paint-family interception. It supports the direction of this proposal. It does
not imply that shader and blend mode normalization are equivalent in complexity.

---

## Core Problem

The problem is not that `Drawable` and `Shape` have different geometry models.
That difference is correct.

The problem is that the graphics-capability boundary does not align with the
primitive boundary.

Some capabilities are primitive-specific:

- `Drawable.border*`
- `Shape.stroke*`
- `Drawable` content-box alignment
- `Shape` silhouette containment

Some capabilities are not primitive-specific:

- whole-node opacity
- subtree blend compositing
- subtree shader compositing
- graphics-backed paint sources
- motion targeting of root visual properties

Shared capabilities must not live as ad hoc exceptions inside one primitive
family. That does not scale.

The correct model is:

- `Drawable` and `Shape` remain separate primitives
- each primitive adopts selected reusable graphics-capability interfaces
- each capability defines its own semantics, defaults, motion rules, and
  compositing behavior
- primitive-specific paint families remain primitive-specific

---

## Design Goal

Normalize graphics capability usage across `Drawable` and `Shape` while
preserving:

- distinct geometry contracts
- distinct paint-family vocabularies
- distinct layout participation semantics
- distinct theming and styling boundaries

In this document, "interface" means a reusable contract and internal hook
boundary, not a new public base class.

The implementation target is:

- one capability model
- multiple carriers
- no forced geometry unification

---

## Non-Goals

This patch does not aim to:

- make `Shape` inherit from `Drawable`
- move `Shape` into the styling system
- alias `stroke*` to `border*`
- expand `Container` into a visual primitive
- add consumer child composition to `Shape`
- define a new intermediary public class
- unify all rendering code into one paint family
- make shape clipping or masking part of this initiative
- normalize vocabulary where the underlying semantics differ

Specifically excluded from normalization:

- `Drawable.borderWidth` and `Shape.strokeWidth` must remain distinct
- `Drawable.backgroundImage` must not be copied onto `Shape`
- `Shape` must not grow padding, alignments, skins, or named presentational
  parts as a side effect of gaining graphics capability

---

## Design Principles

### 1. Normalize capabilities, not primitives

The stable unit of reuse is the capability surface, not the primitive type.

### 2. Keep geometry vocabularies separate

Geometry-specific paint families are owned by their primitive:

- `border*` belongs to styled boxes
- `stroke*` belongs to silhouettes

### 3. Separate compositing from paint sourcing

Shader and blend mode are subtree compositing concerns.
Texture is a paint-source concern.
Opacity spans both.

These are three distinct families, not one undifferentiated effects blob.

### 4. Capability adoption is explicit

A primitive participates in a shared capability only when its public contract
declares that capability.

Explicit adoption means both:

- the primitive's public contract declares the capability surface
- the runtime queries the primitive through a dedicated capability hook or
  declaration table, not by inferring support from primitive family membership

The runtime mechanism is defined in Part 2 as a static class-level capability
table on the primitive class definition, read once per class at load time.
The enforcement boundary is defined here: assigning a normalized capability to
a primitive that has not adopted it is an immediate hard failure.

### 5. Motion follows documented visual surfaces

If a capability is on the shared root visual surface, motion targeting works
identically on every primitive that adopts it.

### 6. Generalize internals without widening the public surface casually

Internal hooks may be generalized aggressively.
Public props are added only where semantics are stable and fully specified.

---

## Resolution Scope

Shared root compositing props:

- are direct instance props
- are not styling props
- do not participate in ordinary property inheritance
- propagate only through the retained effect chain at draw time
- `opacity` is motion-capable with continuous numeric interpolation
- `blendMode` is motion-capable as a discrete step; only `to` is meaningful;
  `from`, `duration`, and `easing` are ignored; resolved in Part 2
- `shader` is motion-capable as whole-object replacement only; same
  discrete-step rules as `blendMode`; resolved in Part 2

Shape-owned fill-source props:

- are direct instance props
- are not styling props
- do not participate in theming or skinning
- motion semantics are deferred to Part 3

Without these restrictions, capability normalization silently becomes a
styling-system expansion.

---

## Capability Taxonomy

Graphics behavior is split into three families.

### A. Root Compositing Capabilities

These affect the composited subtree result of a node:

- `opacity`
- `shader`
- `blendMode`

Normalized across every render-capable primitive that adopts them.

### B. Paint Source Capabilities

These define what kind of source is painted inside a primitive's own geometry:

- flat color
- gradient
- texture-backed source

These share source-type and alpha rules, but not property names.

### C. Geometry-Family Capabilities

These depend on the primitive's geometry model:

- `border*` for styled rectangular or rounded-rect boxes
- `stroke*` for silhouette-based shapes

These are not unified.

---

## Interface 1: Root Compositing Surface

This interface defines the shared root visual-capability surface for any
render-capable node that adopts subtree compositing features.

Normalized capabilities:

- `opacity`
- `shader`
- `blendMode`

Adoptable by:

- `Drawable`
- `Shape`

Adoption does not imply:

- styling participation
- content-box participation
- skin participation
- named-part participation

### Root Shader Semantics

Root shader is a post-composite node effect.

It does not intercept individual paint calls.
It does not separately target fill or stroke.

On `Shape`:

- the node's local paint result is the fill-and-stroke composited result
- fill is resolved first, stroke second, both combined into one shape-local
  visual result
- the root shader then operates on that combined result

On `Drawable`:

- the root shader operates on the drawable root's resolved local result
  including all descendants

The semantic unit is the node result, not any individual paint family.

### Root Compositing Order

The canonical compositing order for both `Drawable` and `Shape` is:

1. resolve the node's own local paint result
   - for `Shape`: fill first, stroke second, both combined before any
     root-level effect; the full stroke extent, inner and outer halves, is
     included
   - for `Drawable`: background, border, and content combined as the local
     paint result
2. resolve descendant contribution into the node-local result according to
   retained draw order; for `Shape` this step is vacuous with respect to
   consumer content — `Shape` exposes no consumer descendant slot; internal
   implementation nodes, if any, contribute here as an implementation detail
   not visible through the public contract
3. apply root shader to that result, if present
4. apply root opacity to that result
5. composite the opacity-scaled result into the immediate parent composition
   target using the node's root blend mode

This order is canonical. The Opacity And Blend Order section in Interface 3
is a direct consequence of this order, not an independent rule.

### Blend Reference Frame

`blendMode` is evaluated relative to the immediate parent composition target.

That target is:

- the parent's offscreen target if the parent subtree is currently isolated
- otherwise the active render target receiving the parent subtree

A child with root blend mode resolves first into its own node result, then
blends once into its parent target. If the parent also has root compositing
state, the parent's state applies later to the parent's own resolved result.

When `Shape` is a child of a `Drawable`, `Shape` resolves its own root
compositing surface first, producing a fully composited node result. The parent
`Drawable`'s effect chain then operates on that result as an opaque composited
unit. The parent's `shader`, `opacity`, and `blendMode` do not penetrate into
`Shape`'s internal fill and stroke draw calls.

### Isolation Rule

Subtree isolation is not renderer discretion when isolation changes visible
semantics. The following rules are mandatory.

**For non-default root `blendMode`:**
Requires subtree isolation or a provably equivalent optimization.

**For root `shader`:**
Requires access to the node's resolved result. An implementation may avoid an
explicit offscreen pass only when it can prove the inline path is semantically
identical.

**For root `opacity`:**
Requires isolation or a provably equivalent optimization when applying opacity
separately to individual draws would produce a different result than applying
opacity once to the already-composited node result. The concrete case is a
node whose subtree contains overlapping or interacting layers. When no such
case exists, a cheaper equivalent path is permitted.

### Motion Scope For Root Compositing

All three root-compositing properties are motion-capable. The full motion
contract is defined in Part 2.

Summary:
- `opacity` — continuous numeric interpolation
- `blendMode` — discrete step; only `to` is meaningful; step applied immediately
- `shader` — discrete whole-object replacement; only `to` is meaningful

The `shaderParameter` motion property defined in the Motion Specification §4C
provides the mechanism for shader-bound motion on shader-capable surfaces. With
`Shape`'s adoption of the root shader surface established by this patch,
`shaderParameter` targeting is available on `Shape` through that existing
mechanism without further motion spec changes.

---

## Interface 2: Graphics Source Contract

This interface defines the accepted source objects for graphics-backed paint.

Accepted source types:

- `Texture`
- `Sprite`

Definitions:

- `Texture`: a shareable resolved image-source object with intrinsic width and
  height
- `Sprite`: a shareable resolved rectangular region view over exactly one
  `Texture` source. A `Sprite` always defines a sub-region, even when that
  region equals the full texture bounds. The effective source dimensions of a
  `Sprite` are always its sub-region dimensions. The underlying texture
  dimensions are never surfaced directly.

These are library graphics objects, not host-runtime primitive values.

Shared behavior:

- both expose a resolved drawable source
- both expose effective source dimensions
- `Sprite` exposes its sub-region bounds as its effective geometry
- invalid source types fail immediately as a hard error

Shared by:

- image-backed `Drawable` background paint
- shape-owned textured fill
- any future retained paint source that consumes library graphics objects

Not defined here:

- how the primitive places the source within its geometry
- whether repetition is supported
- how the source is clipped to a rounded rectangle or to a silhouette
- whether the source stretches, tiles, aligns, or maps to geometry

Those semantics are owned by the consuming paint family and fully specified
in Part 3.

### Deterministic Failure Rule

Invalid source assignment must fail immediately:

- reject on property assignment or resolution
- raise a hard error
- do not substitute a default source
- do not retain a previous valid source
- do not downgrade to a warning-only condition

### Unsupported Capability Failure Rule

Assigning a normalized graphics capability to a primitive that has not adopted
it in its public contract must fail immediately:

- raise an unsupported capability error
- do not silently ignore the assignment
- do not warn and continue

This is consistent with the deterministic failure model above.

Runtime enforcement uses the static class-level capability table defined in
Part 2. The renderer reads this table through the node's class identity to
determine whether a capability is declared. No per-instance query is performed.

### Source Ownership And Lifetime

- `Texture` and `Sprite` are shareable by multiple nodes simultaneously
- nodes hold references to source objects; they do not own them
- replacing a node's source is an explicit property change on that node
- live source mutation and reverse invalidation from asset to node are out
  of scope for this proposal

---

## Interface 3: Paint Alpha Contract

The normalized alpha rule across all paint sources:

- **local paint alpha** = source alpha × local paint-family opacity
- **final rendered result alpha** = composited local result × node opacity

"Source alpha" is the source's effective alpha contribution at sampling time,
not the raw storage value of its backing pixels. The renderer may use straight
or premultiplied alpha internally; that is an implementation detail.

**Behavioral note for `Shape.opacity`:** The existing foundation spec formula
`strokeColor.alpha * strokeOpacity * opacity` bundles `opacity` as a per-draw
multiplier. This patch supersedes that formula. The correct model is: per-draw
alpha is `strokeColor.alpha * strokeOpacity`; node `opacity` is then applied
once to the fully composited fill-and-stroke result. This is an intentional
correctness fix — the bundled-per-draw model produces incorrect results when
fill and stroke overlap at the silhouette boundary, as the overlap region would
double-apply the node opacity. The post-composite model eliminates this.
`Shape.opacity` is the same prop re-framed under Interface 1; no second prop
is introduced.

Source alpha by source family:

- **flat color**: the alpha channel of the color input value
- **gradient**: the resolved alpha of the gradient at the sampled point, after
  color interpolation
- **texture or sprite**: the effective sampled alpha of the source at the
  sampled point

For `Drawable`:

- background: source alpha × `backgroundOpacity`
- border: source alpha × `borderOpacity`
- node opacity applies to the full composited subtree result

For `Shape`:

- fill: source alpha × `fillOpacity`
- stroke: source alpha × `strokeOpacity`
- node opacity applies to the full composited shape result, which includes the
  full stroke extent

### Opacity And Blend Order

This is a direct consequence of the canonical compositing order in Interface 1.

- root opacity scales the node's resolved result before that result is blended
  into the parent target
- root blend mode defines how the opacity-scaled result composites into the
  parent target

---

## Interface 4: Shape Fill Source

This is a shape-owned interface. It is not a shared property alias and it does
not reuse `background*` names.

Shape fill source surface:

- `fillColor`
- `fillOpacity`
- `fillGradient`
- `fillTexture`
- `fillRepeatX`
- `fillRepeatY`
- `fillOffsetX`
- `fillOffsetY`
- `fillAlignX`
- `fillAlignY`

### Fill Source Priority

At most one fill source is active at render time. Priority is:

1. `fillTexture`, if assigned and valid — overrides all others
2. `fillGradient`, if assigned and valid — overrides `fillColor`
3. `fillColor` — base default

Priority is resolved at render time, not at assignment time. All three
properties may be set simultaneously; only the highest-priority valid source
is rendered.

### Value Domains

| Property | Domain |
|---|---|
| `fillColor` | color input per the standard color contract |
| `fillOpacity` | finite number, 0.0–1.0 inclusive |
| `fillGradient` | gradient object per Styling Document Section 6.4 |
| `fillTexture` | `Texture \| Sprite` |
| `fillRepeatX` | boolean |
| `fillRepeatY` | boolean |
| `fillOffsetX` | finite number in shape local-space units |
| `fillOffsetY` | finite number in shape local-space units |
| `fillAlignX` | `"start" \| "center" \| "end"` |
| `fillAlignY` | `"start" \| "center" \| "end"` |

### Gradient Contract Reference

`fillGradient` accepts the gradient value-type contract defined in the Styling
Document, Section 6.4 as a shared plain-object schema. `Shape` fill does not
participate in the styling system's ownership, resolution, or inheritance for
this type — only the object structure is shared. That structure defines:

- `kind`: `"linear"` only in this revision
- `direction`: `"horizontal" \| "vertical"`
- `colors`: ordered list, minimum two entries, evenly distributed across the
  painted area

No new gradient kinds are introduced by this proposal. Radial gradients require
separate design treatment and are not part of this normalization effort.

Gradient distribution is computed against the shape's local bounding box.
The silhouette acts as a clip applied to the gradient result — it is not the
gradient domain. `direction: "horizontal"` always means left-to-right across
the full local bounds width, regardless of silhouette shape. Part 3 defines
how silhouette clipping is applied to the gradient result.

### Default Values

| Property | Default |
|---|---|
| `fillColor` | implementation-defined; no fill painted when absent |
| `fillOpacity` | `1` |
| `fillGradient` | absent (`nil`) |
| `fillTexture` | absent (`nil`) |
| `fillRepeatX` | `false` |
| `fillRepeatY` | `false` |
| `fillOffsetX` | `0` |
| `fillOffsetY` | `0` |
| `fillAlignX` | `"center"` |
| `fillAlignY` | `"center"` |

`fillAlignX` and `fillAlignY` default to `"center"` to match the `Image`
primitive defaults in the graphics spec. `fillRepeatX` and `fillRepeatY`
default to `false` — tiling is opt-in.

### Naming Rationale

`fill*` names are intentionally parallel to `background*` names on `Drawable`
but are not aliases. `background*` is styling vocabulary for styled box
surfaces. `fill*` is shape-owned vocabulary for silhouette paint. The symmetry
is a consumer affordance; the ownership is distinct.

### Placement Semantics

Placement semantics for fill sources are fully owned by Part 3 and must be
defined there concretely. The following are out of scope for Part 1:

- whether the source stretches to local bounds by default
- how intrinsic-size placement is resolved
- whether repetition ships in the first implementation pass
- how sprite sub-region dimensions map into local shape space
- how silhouette clipping is applied semantically

No implementation should treat these as renderer-local discretion.

---

## Why Border And Stroke Stay Separate

`Drawable.border*` and `Shape.stroke*` differ in fundamental, irreconcilable
ways:

- `Drawable.borderWidth` accepts per-side values; `Shape.strokeWidth` is scalar
- `Drawable` border geometry is box- and radius-based
- `Shape` stroke geometry follows a canonical silhouette
- Both are center-aligned on their respective geometry, but center-aligned on
  a rounded rect and center-aligned on an arbitrary silhouette are different
  operations

Unifying them would distort the semantics of one or both.

The shared layer between them is correctly located at:

- alpha concepts
- compositing infrastructure
- graphics-source contracts

Not at the edge-treatment vocabulary level.

---

## Recommendation

Proceed with normalization under the following explicit split:

1. shared root compositing capability extraction
2. shared graphics-source and alpha contracts
3. shape-owned fill-source expansion
4. no border and stroke unification

Part 2 is closed. Continue to Part 3 for shape fill placement, sprite-to-local-space
mapping, silhouette clipping semantics, and fill repetition scope.

---

## Final Amends Per File

These are the concrete edits to apply to each spec file when this patch is
ratified. Each amendment includes the file, the located target, and the exact
replacement.

---

### `docs/spec/ui-foundation-spec.md`

**Amendment F-1 — Section 3A.3, Shape row, "Explicitly does not manage" column**

Locate the Shape row in the Component Responsibility Boundary table.

Replace:

> `Drawable` box-model semantics, styling families, named-part skinning, shader
> or mask participation, blend-mode participation, child-layout semantics

With:

> `Drawable` box-model semantics, styling families, named-part skinning, mask
> participation, child-layout semantics

---

**Amendment F-2 — Section 6.1.3, "Shape must not" list, second bullet**

Locate the second bullet in the `Shape must not` list.

Replace:

> expose `Drawable` border styling, shadow styling, skin, shader, mask,
> blend-mode, or shape-aware clipping semantics in this revision

With:

> expose `Drawable` border styling, shadow styling, skin, or shape-aware
> clipping semantics in this revision; expose `mask` semantics in this revision

---

**Amendment F-3 — Section 6.1.3, Props and API surface**

After the line `- opacity: number`, append the following props:

```
- `shader`
- `blendMode`
- `fillGradient`
- `fillTexture`
- `fillRepeatX: boolean`
- `fillRepeatY: boolean`
- `fillOffsetX: number`
- `fillOffsetY: number`
- `fillAlignX: "start" | "center" | "end"`
- `fillAlignY: "start" | "center" | "end"`
```

---

**Amendment F-4 — Section 6.1.3, Default values**

After the existing `fillOpacity = 1` default line, append the following
defaults:

```
- `fillGradient = absent`
- `fillTexture = absent`
- `fillRepeatX = false`
- `fillRepeatY = false`
- `fillOffsetX = 0`
- `fillOffsetY = 0`
- `fillAlignX = "center"`
- `fillAlignY = "center"`
```

---

**Amendment F-5 — Section 6.1.3, Public surface exclusions**

Locate the public surface exclusions list.

Replace:

> no `skin`, `shader`, `blendMode`, or `mask`

With:

> no `skin` or `mask`

---

**Amendment F-6 — Section 6.1.3, Shape-owned stroke and opacity contract**

Locate the alpha formula rule in the stable rules list.

Replace:

> final stroke alpha is `strokeColor.alpha * strokeOpacity * opacity`

With:

> final stroke alpha is `strokeColor.alpha * strokeOpacity`

Add a normative note immediately after that line:

> node `opacity` is applied once to the fully composited fill-and-stroke
> result, not per-draw; bundling `opacity` into the per-draw formula produces
> incorrect results when fill and stroke overlap at the silhouette boundary

---

### `docs/spec/ui-graphics-spec.md`

**Amendment G-1 — Section 4B.3, Sprite Contract, "Sprite must not" list**

Locate the `Sprite must not` list.

Append:

> surface the underlying `Texture` dimensions directly; the effective source
> dimensions of a `Sprite` are always its sub-region dimensions
