# Phase 18 Task 05: Acceptance, Demo, And Doc Sync

## Goal

Verify the `Shape` primitive end to end and update planning/demo surfaces so
the project no longer documents the pre-`Shape` assumption that geometry belongs
on `Drawable`.

## Scope

Runtime verification:

- focused coverage under `spec/` for `Shape`, `RectShape`, `CircleShape`,
  `TriangleShape`, and `DiamondShape`
- any demo or showcase coverage used to verify rendering and input behavior

Documentation review:

- `docs/implementation/phase-18-shape-primitive.md`
- `docs/implementation/tasks/phase-18/*`
- any stale implementation planning docs that still describe shape support as a
  `Drawable` concern

## Work

1. Add regression coverage for:
   - base `Shape` public surface
   - leaf-only composition enforcement
   - transformed `containsPoint` behavior
   - canonical containment for each concrete class
   - rectangular `clipChildren` behavior on `Shape`
2. Add or update demo coverage showing:
   - mixed trees of `Drawable` and `Shape`
   - transformed shape targeting
   - visible alignment between rendered and hittable silhouettes
3. Review current implementation docs for stale guidance that places shape on
   `Drawable` and update or supersede those notes.
4. Leave an explicit note anywhere the project intentionally keeps an older doc
   as historical context rather than current implementation guidance.

## Exit Criteria

- focused verification exists for the full v1 `Shape` contract
- demo coverage exists for the approved concrete shapes
- no current implementation planning doc contradicts the accepted `Shape`
  primitive boundary
