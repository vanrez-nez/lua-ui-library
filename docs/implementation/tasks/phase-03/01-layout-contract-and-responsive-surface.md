# Task 01: Layout Contract And Responsive Surface

## Goal

Establish the public layout-family surface exactly as the spec defines it, and implement responsive handling according to the now-settled spec relationship between `responsive` and inherited `breakpoints`.

## Spec Anchors

- `docs/spec/ui-foundation-spec.md §6.2 Layout Family`
- `docs/spec/ui-foundation-spec.md §7.3 Responsive Rules`
- `docs/spec/ui-foundation-spec.md §6.1.1 Container`

## Scope

- Define the spec-backed public prop surface for `Stack`, `Row`, `Column`, `Flow`, and `SafeAreaContainer`
- Treat `Container.breakpoints` and layout `responsive` as alternate public entry points into one pre-measure resolution step
- Establish internal-only responsive-rule normalization

## Required Behavior

- Common layout props remain: `gap`, `padding`, `wrap`, `justify`, `align`, `responsive`.
- `Row` adds only `direction`.
- `Column`, `Stack`, and `Flow` add no extra public props beyond the common layout props.
- `SafeAreaContainer` adds only `applyTop`, `applyBottom`, `applyLeft`, `applyRight` plus common layout props.
- `responsive` and inherited `breakpoints` feed the same pre-measure responsive resolution step.
- If a node supplies both `responsive` and `breakpoints`, the configuration is invalid and must fail deterministically.

## Settled Spec Constraints

- The spec now defines the public relationship between `breakpoints` and `responsive`, but it still does not standardize one serialized rule schema.
- This task must define one internal normalization layer that can consume the implementation’s chosen source format without making that format the stable public contract.
- Orientation, safe area, viewport width, viewport height, and parent dimensions must remain allowable responsive inputs because the spec explicitly permits them.
- Percentage sizing must continue to resolve against the effective parent content region for the relevant axis.

## Non-Goals

- No public `gapX` / `gapY` props for `Flow`.
- No public breakpoint-table schema commitment.
- No public commitment to specific default values not named in the spec.

## Acceptance Checks

- Layout-family docs and constructor surfaces match the spec-backed prop sets.
- Responsive resolution is declared before measurement for affected subtrees, regardless of whether the node used `responsive` or inherited `breakpoints`.
- Dual-source `responsive` plus `breakpoints` configuration fails deterministically.
- Internal normalization can evolve without forcing a public API break.
