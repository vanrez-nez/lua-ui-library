# Task 01: Layout Contract And Responsive Surface

## Goal

Establish the public layout-family surface exactly as the spec defines it, and isolate unresolved responsive-rule schema decisions behind an internal normalization boundary.

## Spec Anchors

- `docs/spec/ui-foundation-spec.md §6.2 Layout Family`
- `docs/spec/ui-foundation-spec.md §7.3 Responsive Rules`
- `docs/spec/ui-foundation-spec.md §6.1.1 Container`

## Scope

- Define the spec-backed public prop surface for `Stack`, `Row`, `Column`, `Flow`, and `SafeAreaContainer`
- Reconcile `Container.breakpoints` with layout `responsive` handling
- Establish internal-only responsive-rule normalization

## Required Behavior

- Common layout props remain: `gap`, `padding`, `wrap`, `justify`, `align`, `responsive`.
- `Row` adds only `direction`.
- `Column`, `Stack`, and `Flow` add no extra public props beyond the common layout props.
- `SafeAreaContainer` adds only `applyTop`, `applyBottom`, `applyLeft`, `applyRight` plus common layout props.

## Spec Gap Handling

- The spec names both `breakpoints` and `responsive` but does not define a single public schema for them.
- This task must define one internal normalization layer that can consume the implementation’s chosen source format without making that format the stable public contract.
- Orientation, safe area, viewport width, viewport height, and parent dimensions must remain allowable responsive inputs because the spec explicitly permits them.

## Non-Goals

- No public `gapX` / `gapY` props for `Flow`.
- No public breakpoint-table schema commitment.
- No public commitment to specific default values not named in the spec.

## Acceptance Checks

- Layout-family docs and constructor surfaces match the spec-backed prop sets.
- Responsive resolution is declared before measurement for affected subtrees.
- Internal normalization can evolve without forcing a public API break.
