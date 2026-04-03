# Phase 16: Quad Normalization Consolidation

## Purpose

Introduce one coherent normalization model for all four-side and four-corner
property families used by Foundation and Styling.

This phase is not a renderer-only change. It is a cross-cutting contract cleanup
that aligns public props, schema validation, styling resolution, and shared
geometry helpers.

## Authority

- [UI Foundation Specification](../spec/ui-foundation-spec.md)
- [UI Styling Specification](../spec/ui-styling-spec.md)
- [Spec Patch: Quad Normalization Model](../incidents/spec_patch_quad_normalization_model.md)

This document is sequencing and scoping context only.

---

## Scope

This phase covers:

- reusable side-quad normalization
- reusable corner-quad normalization
- schema alignment for Foundation and Styling props
- styling-resolution expansion into canonical per-side and per-corner values
- focused regression coverage

This phase does not change the visual semantics of borders, corner radii,
padding, or margins. It changes how their public inputs are normalized and
resolved.

---

## Target Contract

### Side-Quad Families

These property families should share one normalization path:

- `padding`
- `margin`
- `safeAreaInsets`
- `borderWidth`

If flat override props are accepted publicly, the same merge rule applies to all
of them:

- aggregate prop establishes the fallback
- flat override props win for their own side
- canonical resolved form is `{ top, right, bottom, left }`

### Corner-Quad Families

These property families should share one normalization path:

- `cornerRadius`

Flat override props:

- `cornerRadiusTopLeft`
- `cornerRadiusTopRight`
- `cornerRadiusBottomRight`
- `cornerRadiusBottomLeft`

Merge rule:

- aggregate prop establishes the fallback
- flat override props win for their own corner
- canonical resolved form is `{ topLeft, topRight, bottomRight, bottomLeft }`

---

## File Plan

### 1. Shared Quad Helpers

Preferred new modules:

- `lib/ui/core/side_quad.lua`
- `lib/ui/core/corner_quad.lua`

`side_quad.lua` should own:

- aggregate side-quad normalization
- sequence/keyed-table parsing
- canonical `{ top, right, bottom, left }` output
- merge of aggregate prop with flat side overrides

`corner_quad.lua` should own:

- aggregate corner-quad normalization
- keyed-table and four-value parsing
- canonical `{ topLeft, topRight, bottomRight, bottomLeft }` output
- merge of aggregate prop with flat corner overrides

`lib/ui/core/insets.lua` should either:

- become a thin semantic wrapper over `side_quad.lua`, or
- remain as-is but delegate normalization to the shared side-quad helper

The second option is lower-risk for the current codebase.

### 2. Foundation Schema Surfaces

Update:

- `lib/ui/core/drawable_schema.lua`
- `lib/ui/layout/layout_node_schema.lua`
- `lib/ui/scene/stage_schema.lua`

Required outcomes:

- `padding` and `margin` continue to accept current aggregate forms
- `safeAreaInsets` continues to accept side-quad forms
- if flat spacing props are added publicly, they must be validated through the
  same shared helper rather than one-off schema code

### 3. Styling Schema Surfaces

Update:

- `lib/ui/core/drawable_schema.lua`

Required outcomes:

- `borderWidth` accepts side-quad aggregate forms supported by the accepted
  spec patch
- `borderWidthTop/Right/Bottom/Left` remain valid flat overrides
- `cornerRadius` accepts corner-quad aggregate forms
- `cornerRadiusTopLeft/TopRight/BottomRight/BottomLeft` remain valid flat
  overrides

Property-specific domains still apply:

- border widths: finite, non-negative
- corner radii: finite, non-negative

### 4. Styling Resolution

Update:

- `lib/ui/render/styling_contract.lua`
- `lib/ui/render/styling.lua`

Required outcomes:

- public styling key lists match the accepted spec surface
- assembly may accept aggregate styling props
- renderer receives canonical expanded per-side and per-corner values
- per-side/per-corner overrides win over aggregate values at the same
  precedence layer

The renderer should not need to understand multiple public authoring forms. It
should operate only on canonical expanded props.

### 5. Theme And Token Surface

Review:

- `lib/ui/themes/default.lua`
- any token lookup assumptions in theme/runtime resolution

Required policy decision:

- whether aggregate token keys such as `button.surface.borderWidth` and
  `button.surface.cornerRadius` are public documented tokens
- whether flat token members remain the canonical stored form

This must be documented, not guessed from implementation convenience.

### 6. Docs Sync

Update or supersede stale planning docs that currently assume:

- no `borderWidth` shorthand
- no `cornerRadius` shorthand
- no shared quad-family abstraction

At minimum review:

- `docs/implementation/phase-12-styling-schema.md`
- `docs/implementation/tasks/phase-12/*`
- `docs/implementation/tasks/phase-14/01-styling-keys-constant.md`

---

## Recommended Execution Order

1. Patch Foundation spec with `SideQuad input` and `CornerQuad input`
2. Patch Styling spec to reference those families
3. Add shared quad helpers in code
4. Refactor `Insets` to reuse the side-quad helper
5. Update schema validation surfaces
6. Update styling assembly to expand aggregate props into canonical members
7. Update token/default tables if the spec documents aggregate token keys
8. Add focused tests
9. Sync stale implementation planning docs

---

## Verification

Minimum verification after implementation:

- `padding = 8` and `paddingLeft = 12` resolve coherently if flat spacing
  overrides are part of the accepted public patch
- `margin = { 4, 8 }` normalizes to top/bottom `4`, left/right `8`
- `safeAreaInsets = { top = 10, bottom = 20 }` fills missing sides with `0`
- `borderWidth = 2` expands to all four border sides
- `borderWidth = { top = 4, left = 1 }` expands correctly if side-quad table
  form is accepted for styling
- `borderWidth = 2` plus `borderWidthLeft = 6` resolves left to `6` and all
  other sides to `2`
- `cornerRadius = 10` expands to all four corners
- `cornerRadius = { topLeft = 2, bottomRight = 8 }` fills missing corners with
  `0`
- `cornerRadius = 10` plus `cornerRadiusTopLeft = 3` resolves top-left to `3`
  and the remaining corners to `10`
- invalid quad shapes fail deterministically

---

## Risks

1. Backward compatibility
   Public shorthand acceptance changes the authoring surface and token surface.
2. Mixed normalization logic
   If `Insets`, styling schema, and renderer each keep their own parsing logic,
   drift will continue.
3. Silent precedence bugs
   Aggregate-plus-flat merges must be deterministic and tested.
4. Stale planning docs
   Existing phase documents still encode the earlier "flat-only styling" model.
