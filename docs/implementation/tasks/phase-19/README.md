# Phase 19 Task Set

Source implementation document for this phase:

- `docs/implementation/phase-19-shape-stroke-opacity.md`

Related incident / spec-patch context:

- `docs/incidents/spec_patch_shape_border_and_opacity_surface.md`

Authority rules for this phase:

- `docs/spec/ui-foundation-spec.md` is authoritative for:
  - the `Shape` public `stroke*` surface
  - `Shape.opacity`
  - center-aligned stroke placement
  - canonical dashed traversal start points
  - the rule that stroke does not affect layout footprint or `containsPoint`
- `docs/spec/ui-styling-spec.md` is authoritative for:
  - the `strokeStyle` versus `strokePattern` semantic split
  - the boundary that `Shape.stroke*` is not part of the `border*` styling
    family
- `docs/incidents/spec_patch_shape_border_and_opacity_surface.md` is the
  implementation intent source for sequencing and verification emphasis

Settled decisions that control this task set:

- `Shape` remains a `Container` subclass parallel to `Drawable`
- `Shape.stroke*` is shape-owned and does not inherit the `border*` contract
- `strokeStyle` means line quality and `strokePattern` means solid versus
  dashed segmentation
- `strokeWidth` is scalar-only
- stroke painting does not alter hit testing or layout footprint
- `Shape.opacity` is whole-node opacity and must use the retained compositing
  path rather than a fill-only alpha shortcut

Implementation conventions for every task in this phase:

- start from the current `lib/ui` implementation, not earlier planning docs
- prefer shared shape helpers over duplicating stroke logic across shape files
- keep rendering and containment aligned to the same canonical local geometry
- do not route `Shape` through `Drawable` styling resolution
- keep `shader`, `mask`, and `blendMode` out of the `Shape` public surface

Task order:

1. `00-compliance-review.md`
2. `01-shape-stroke-surface-and-schema.md`
3. `02-shared-shape-stroke-helpers.md`
4. `03-polygon-shape-stroke-rendering.md`
5. `04-circle-stroke-and-dash-traversal.md`
6. `05-node-opacity-generalization.md`
7. `06-acceptance.md`
