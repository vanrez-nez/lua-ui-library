# Spec Patch: Quad Normalization Model

## Goal

Define one reusable normalization contract for all four-side and four-corner
property families before continuing to add convenience props piecemeal.

This patch is documentation-first.

## Problem

The current spec set expresses the same structural idea in three different ways:

1. `padding` and `margin` exist as aggregate props in
   [UI Foundation Specification](../spec/ui-foundation-spec.md), but their
   accepted normalization forms are not defined there as one reusable contract.
2. `borderWidth` and `cornerRadius` live in
   [UI Styling Specification](../spec/ui-styling-spec.md), but they currently
   use family-specific wording instead of referencing one abstract quad model.
3. The implementation already has a reusable four-side normalizer in
   [`lib/ui/core/insets.lua`](../../lib/ui/core/insets.lua), but the spec does
   not define that pattern once and then reuse it consistently.

The result is an incoherent authoring surface:

- `padding` / `margin`: aggregate prop only
- `borderWidth`: aggregate prop plus per-side props
- `cornerRadius`: per-corner props only

That is difficult to explain and makes future prop design drift likely.

## Intended Outcome

After this patch, the spec should communicate one consistent model:

- four-side property families use one shared normalization contract
- four-corner property families use one shared normalization contract
- aggregate props and flat per-side/per-corner props follow one override rule
- domain specs define semantics, not ad hoc normalization rules
- implementation normalizes all such properties into canonical expanded form

## Proposed Patch

### 1. Add Reusable Value Families To Foundation

Patch [UI Foundation Specification](../spec/ui-foundation-spec.md) to define two
generic input families:

1. `SideQuad input`
2. `CornerQuad input`

`SideQuad input` canonical resolved shape:

```text
{ top, right, bottom, left }
```

`CornerQuad input` canonical resolved shape:

```text
{ topLeft, topRight, bottomRight, bottomLeft }
```

Foundation should own:

- accepted public input forms
- normalization into canonical resolved shape
- merge behavior between aggregate prop and flat override props
- deterministic failure semantics for malformed quad input

Property-specific domains such as "non-negative only" remain owned by the
property family that uses the quad.

### 2. Standardize Accepted Forms For `SideQuad input`

Recommended accepted public forms:

```text
number
{ top = n, right = n, bottom = n, left = n }
{ n, n }               -- vertical, horizontal
{ n, n, n, n }         -- top, right, bottom, left
```

Normalization rules:

- `number` means all four sides equal
- keyed table fills missing sides with `0`
- two-value sequence means vertical, horizontal
- four-value sequence maps to top, right, bottom, left

Invalid shapes fail deterministically.

### 3. Standardize Accepted Forms For `CornerQuad input`

Recommended accepted public forms:

```text
number
{ topLeft = n, topRight = n, bottomRight = n, bottomLeft = n }
{ n, n, n, n }         -- topLeft, topRight, bottomRight, bottomLeft
```

Normalization rules:

- `number` means all four corners equal
- keyed table fills missing corners with `0`
- four-value sequence maps to topLeft, topRight, bottomRight, bottomLeft

No two-value form is recommended for corners in this revision. The semantics are
less obvious than side quads and would invite CSS-style expectations that the
current library does not otherwise use.

### 4. Standardize Aggregate And Flat Override Semantics

Foundation should define one merge rule:

- aggregate prop establishes the family fallback
- flat per-side or per-corner props override the aggregate for their own member
- canonical resolved form is always expanded member-by-member

Examples:

```text
padding = 8
paddingLeft = 16
```

resolves to:

```text
top = 8, right = 8, bottom = 8, left = 16
```

```text
cornerRadius = 10
cornerRadiusTopLeft = 4
```

resolves to:

```text
topLeft = 4, topRight = 10, bottomRight = 10, bottomLeft = 10
```

### 5. Patch Foundation Surfaces That Already Use Side Quads

Foundation should explicitly place these props under the `SideQuad input`
contract:

- `padding`
- `margin`
- `safeAreaInsets`

If the public API is expanded, also add:

- `paddingTop`, `paddingRight`, `paddingBottom`, `paddingLeft`
- `marginTop`, `marginRight`, `marginBottom`, `marginLeft`

That keeps spacing authoring symmetric with border authoring.

### 6. Patch Styling To Reuse Those Foundation Families

Patch [UI Styling Specification](../spec/ui-styling-spec.md) so that:

- `borderWidth` uses `SideQuad input`
- `borderWidthTop`, `borderWidthRight`, `borderWidthBottom`, `borderWidthLeft`
  are flat overrides whose canonical resolved form is still per-side
- `cornerRadius` uses `CornerQuad input`
- `cornerRadiusTopLeft`, `cornerRadiusTopRight`,
  `cornerRadiusBottomRight`, `cornerRadiusBottomLeft` are flat overrides whose
  canonical resolved form is still per-corner

This keeps normalization centralized while leaving border and radius semantics in
the styling spec where they belong.

### 7. Keep Responsibility Boundaries Clean

Foundation should define:

- shape families
- normalization
- override precedence within one family

Styling should define:

- what border width means
- what corner radius means
- how those resolved values affect painting

Controls and component specs should define only which components and parts expose
those property families.

## Recommended Direction

The best cohesive design is:

1. define `SideQuad input` and `CornerQuad input` in Foundation
2. make all current quad-like property families reference those contracts
3. expose aggregate prop plus flat override props consistently
4. normalize to expanded canonical form everywhere internally

That yields one reusable authoring model across:

- `padding`
- `margin`
- `safeAreaInsets`
- `borderWidth`
- `cornerRadius`

## Follow-Up Implementation Impact

If this patch is accepted, implementation should be reviewed in these areas:

1. `lib/ui/core/insets.lua`
   The existing side-quad normalization logic should become the reusable base
   model or be refactored behind a more general helper.
2. `lib/ui/core/drawable_schema.lua`
   Needs aggregate and flat override support for spacing, border, and corner
   families according to the accepted public contract.
3. `lib/ui/layout/layout_node_schema.lua`
   Must stay aligned with the same `padding` normalization behavior used by
   `Drawable`.
4. `lib/ui/scene/stage_schema.lua`
   `safeAreaInsets` should explicitly reuse the same side-quad family contract.
5. `lib/ui/render/styling.lua`
   Should consume only canonical expanded side/corner values after assembly.
6. `lib/ui/render/styling_contract.lua`
   Must include the final public property family definitions after the spec
   patch is accepted.
7. theme/default token tables
   Tokens for aggregate and flat family members need a clear documented policy.
8. implementation planning docs
   Existing phase documents that currently say "no shorthand aliases" become
   stale and need to be updated or superseded.
