# Phase 18 Task Set

Source implementation document for this phase:

- `docs/implementation/phase-18-shape-primitive.md`

Related incident / spec-patch context:

- `docs/incidents/spec_patch_drawable_shape_surface.md`

Authority rules for this phase:

- `docs/spec/ui-foundation-spec.md` is authoritative for:
  - `Shape` as a foundation primitive
  - the `Shape` public surface
  - `containsPoint(x, y)` and `_contains_local_point(local_x, local_y)`
  - canonical geometry for the four approved concrete classes
  - rectangular layout footprint and rectangular clipping behavior
- `docs/incidents/spec_patch_drawable_shape_surface.md` is the implementation
  intent source for why `Shape` is parallel to `Drawable` and must remain
  narrow in v1

Settled decisions that control this task set:

- `Shape` extends `Container`, not `Drawable`
- `Shape` is render-capable but outside the `Drawable` styling/effects system
- the v1 public surface is fill-only:
  - `fillColor`
  - `fillOpacity`
- `RectShape`, `CircleShape`, `TriangleShape`, and `DiamondShape` are the only
  approved concrete shape classes in this phase
- the implementation must reuse the existing Stage targeting vocabulary rather
  than inventing a new shape-specific hit-test path
- `Shape` remains leaf-only in this phase
- `clipChildren` on `Shape` remains rectangular even for non-rect silhouettes

Implementation conventions for every task in this phase:

- prefer a dedicated `Shape` base class over hollowing out `Drawable`
- keep rendering and containment aligned to the same local-space silhouette
- keep geometry evaluation local-space and transform-aware
- do not widen the public API beyond the accepted spec surface
- keep each concrete task single-purpose; do not fold acceptance or doc sync
  into earlier runtime tasks

Task order:

1. `00-compliance-review.md`
2. `01-shape-primitive-surface.md`
3. `02-rect-shape-and-fill-rendering.md`
4. `03-containment-and-stage-targeting.md`
5. `04-concrete-nonrect-shapes.md`
6. `05-acceptance-demo-and-doc-sync.md`

Historical note:

- Tasks `00` through `05` are retained as the implementation record for Phase
  18.
- Once the phase is implemented, use `docs/spec/ui-foundation-spec.md` and
  `docs/implementation/phase-18-shape-primitive.md` as the current guidance.
- `docs/incidents/spec_patch_drawable_shape_surface.md` remains useful as
  historical rationale for the `Shape` boundary, not as the live implementation
  checklist.
