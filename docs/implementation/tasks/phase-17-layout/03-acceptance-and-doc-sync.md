# Phase 17 Task 03: Acceptance And Doc Sync

## Goal

Verify the new layout behavior end to end and update stale implementation docs
that still describe the old layout surface.

## Scope

Runtime verification files:

- existing layout specs under `spec/`
- any new focused specs needed for spacing and layout behavior

Documentation targets:

- stale implementation docs that still assume:
  - no negative margins
  - no parent-side child-margin consumption
  - raw layout-node reads are sufficient for `padding*`

## Work

1. Add focused regression coverage for:
   - `Drawable` content-box behavior under padding
   - effective `padding*` reads on layout-family nodes
   - inert child `margin` under plain `Container` and plain `Drawable`
   - `Stack` child-margin placement
   - `Row`/`Column` gap-plus-margin composition
   - `Flow` wrapping with outer footprints
   - `SafeAreaContainer` safe-area-plus-padding-plus-margin composition
   - invisible children contributing no margin footprint
   - negative-margin overlap without hit-region expansion
   Suggested new or updated spec coverage:
   - one focused spacing/layout contract spec for shared spacing behavior
   - keep existing layout-family spec files for family-specific placement
   - avoid hiding all new coverage inside one giant catch-all spec
2. Re-run the focused layout and foundation verification surface.
   Minimum verification set:
   - layout-family specs
   - safe-area specs
   - stage/root layout specs
   - styling specs only where `Drawable` padding/alignment behavior is affected
3. Update or annotate stale implementation docs so the project no longer
   documents the pre-`ui-layout-spec.md` layout behavior as current guidance.

## Concrete Outputs

1. Runtime verification must prove these exact behaviors:
   - `padding` changes content-box geometry but not parent placement
   - non-layout parents ignore child margin
   - layout parents consume child margin
   - `gap` composes between margin boxes
   - negative margins create overlap but do not expand hit regions
   - invisible children contribute no layout footprint
2. Doc sync must at minimum touch:
   - any phase docs that still describe layout spacing in Foundation-owned terms
   - any implementation plans that still assume margin is inert everywhere
   - any notes that still allow negative `gap` or negative `padding`

## Exit Criteria

- Focused runtime/spec coverage exists for the new layout contract.
- The implementation docs do not contradict `docs/spec/ui-layout-spec.md`.
- The code and docs describe the same layout behavior.
