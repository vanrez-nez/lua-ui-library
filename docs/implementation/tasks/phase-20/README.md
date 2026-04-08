# Phase 20: Shape Graphics Capability Normalization

This phase translates the following incident spec patches into implementation tasks:

- `docs/incidents/spec_patch_shape_graphics_capability_normalization_part_01_model.md`
- `docs/incidents/spec_patch_shape_graphics_capability_normalization_part_02_root_compositing.md`
- `docs/incidents/spec_patch_shape_graphics_capability_normalization_part_03_fill_sources.md`

The work is scoped to the current `lib/ui` implementation. The phase assumes:

- `lib/ui/core/container.lua` already owns retained subtree isolation and compositing for node-level effects, but its runtime is still partially Drawable-specific.
- `lib/ui/core/shape_schema.lua` and the concrete shape classes only expose flat-color fill, stroke, and `opacity`.
- `lib/ui/render/styling.lua` already contains reusable gradient, texture, sprite, alignment, tiling, and stencil logic that should be extracted or shared instead of duplicated.
- `Shape` must gain normalized graphics capabilities without becoming a `Drawable`, entering the styling system, or adopting `mask`.
- `Drawable.border*` and `Shape.stroke*` stay separate in this phase; the work is capability normalization, not primitive-surface unification.

Task order:

1. `00-compliance-review.md`
2. `01-shared-graphics-capability-helpers.md`
3. `02-root-compositing-capability-surface.md`
4. `03-root-compositing-runtime.md`
5. `04-root-compositing-motion-failure-and-state-restore.md`
6. `05-shape-fill-source-surface-and-priority.md`
7. `06-shape-fill-placement-and-source-resolution.md`
8. `07-shape-fill-renderer-and-silhouette-clipping.md`
9. `08-shape-primitive-integration-and-fill-motion.md`
10. `09-acceptance-and-doc-sync.md`

Exit criteria for the phase:

- `Drawable` and `Shape` both resolve root compositing through the same capability-driven runtime surface for `opacity`, `shader`, and `blendMode`.
- `Shape` exposes direct-instance fill source props for color, gradient, and texture-backed fill, with correct priority and placement semantics.
- Shape fill remains shape-owned and does not reuse `background*` props or styling participation.
- `Drawable.border*` remains Drawable-owned and `Shape.stroke*` remains Shape-owned.
- The retained renderer preserves fast paths for default root compositing state and flat-color shape fill.
- Tests and demos cover the new root compositing and fill source behavior, including failure paths.
