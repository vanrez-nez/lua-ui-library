# Spec Patch: Shape Pivot Centroid Contract

## Goal

Add a spec-defined way for `Shape` instances to use their visible geometric
centroid as the pivot source without changing the existing `Container`
`pivotX` / `pivotY` contract.

## Affected Spec Surface

Patch:

- [docs/spec/ui-foundation-spec.md](/Users/vanrez/Documents/game-dev/lua-ui-library/docs/spec/ui-foundation-spec.md)

Follow-up implementation planning update:

- [docs/implementation/phase-18-shape-primitive.md](/Users/vanrez/Documents/game-dev/lua-ui-library/docs/implementation/phase-18-shape-primitive.md)
- [docs/implementation/tasks/phase-18/04-concrete-nonrect-shapes.md](/Users/vanrez/Documents/game-dev/lua-ui-library/docs/implementation/tasks/phase-18/04-concrete-nonrect-shapes.md)
- [docs/implementation/tasks/phase-18/05-acceptance-demo-and-doc-sync.md](/Users/vanrez/Documents/game-dev/lua-ui-library/docs/implementation/tasks/phase-18/05-acceptance-demo-and-doc-sync.md)

## Required Spec Edits

### 1. Preserve The Existing Pivot Contract

In `Container`, keep the existing rule:

- `pivotX` and `pivotY` remain normalized local-space coefficients
- `0.5, 0.5` remains the bounds midpoint
- this meaning does not change for `Shape` or any `Shape` subclass

### 2. Add A Shape Centroid Pivot Entry Point

In `Shape`, add one public centroid-pivot entry point with this contract:

- it resolves the shape's current local geometric centroid from the current
  resolved bounds
- it converts that centroid into normalized pivot coefficients
- it assigns `pivotX` and `pivotY` once at call time
- it is not a live binding and does not auto-update after later resize
- if the resolved bounds are degenerate, it performs no pivot assignment

### 3. Add A Shape-Local Centroid Contract

In `Shape`, define a shape-local centroid resolution contract used by the
centroid-pivot entry point.

Rules:

- the centroid is evaluated in local node space
- the centroid is derived from the shape's canonical geometry under the current
  resolved bounds
- the default centroid is the local bounds center
- built-in shapes do not remap pivot defaults through this helper
- custom shapes may override or extend this centroid helper path when their
  canonical geometry differs from the local bounds center

### 4. Preserve Built-In Shape Default Pivot Behavior

The approved concrete shapes keep the inherited bounds-relative pivot behavior:

- `RectShape`
- `CircleShape`
- `DiamondShape`
- `TriangleShape`

This patch does not make any built-in shape map default pivot behavior to its
visible centroid.

### 5. Add A Custom-Shape Centroid Helper Path

The centroid helper path exists so shapes with custom canonical geometry can
calculate a geometry-derived centroid when the author explicitly requests it.

This path may be implemented by overriding or extending the shape-local centroid
resolution contract.

### 6. Add Authoring Timing Rule

The centroid-pivot entry point is valid only after the shape has resolved the
bounds used to derive its canonical geometry.

The spec must state:

- authors use the centroid-pivot entry point after sizing is resolved
- later size changes do not rebind the pivot automatically

## Entry Points For Modification

### Foundation Spec

In [docs/spec/ui-foundation-spec.md](/Users/vanrez/Documents/game-dev/lua-ui-library/docs/spec/ui-foundation-spec.md):

- `§6.1.1 Container`
  Add one explicit sentence under anchor and pivot semantics that `Shape`
  inherits the same bounds-relative pivot meaning with no geometry remapping.
- `§6.1.3 Shape` props and API surface
  Add the centroid-pivot entry point and the shape-local centroid contract.
- `§6.1.3 Shape` canonical geometry / containment area
  Add one explicit note that built-in shapes keep the inherited bounds-center
  pivot meaning by default and do not remap default pivot behavior through
  centroid logic.
- `§6.1.3 Shape` behavioral edge cases
  Add the degenerate-bounds no-op rule for centroid-pivot assignment.

### Phase 18 Planning

In [docs/implementation/phase-18-shape-primitive.md](/Users/vanrez/Documents/game-dev/lua-ui-library/docs/implementation/phase-18-shape-primitive.md):

- add centroid-pivot support as part of the `Shape` primitive contract rollout
- state that centroid resolution is an explicit helper path, not a default pivot
  remapping path

In [docs/implementation/tasks/phase-18/04-concrete-nonrect-shapes.md](/Users/vanrez/Documents/game-dev/lua-ui-library/docs/implementation/tasks/phase-18/04-concrete-nonrect-shapes.md):

- keep non-rect shape geometry aligned for draw and containment only
- do not introduce triangle-specific default pivot remapping
- leave centroid-helper customization to the explicit helper path

In [docs/implementation/tasks/phase-18/05-acceptance-demo-and-doc-sync.md](/Users/vanrez/Documents/game-dev/lua-ui-library/docs/implementation/tasks/phase-18/05-acceptance-demo-and-doc-sync.md):

- add acceptance checks for explicit centroid-pivot assignment without changing
  the default pivot behavior of built-in shapes
- add a check that default `pivotX = 0.5` and `pivotY = 0.5` still mean bounds
  center on all shapes
- add a check that centroid-pivot assignment does not auto-update after later
  resize unless called again

## Scope Boundary

This patch does not:

- change `pivotX` or `pivotY` defaults
- change `anchorX` or `anchorY`
- remap normalized pivot coefficients through shape geometry
- introduce live centroid tracking
- make `TriangleShape` use centroid pivoting by default
- introduce arbitrary polygon centroid rules beyond the approved concrete shape
  set
