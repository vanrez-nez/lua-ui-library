# Task 01: STYLING_KEYS Constant

## Goal

Define `STYLING_KEYS` as a module-level constant — a sequential table listing all 29 styling property names introduced in Phase 12. This constant drives the props assembly loop in the next task and must be complete, ordered by property group, and accurate.

## Spec Anchors

- `docs/spec/ui-styling-spec.md §6.2` — background property list
- `docs/spec/ui-styling-spec.md §7.1` — border property list
- `docs/spec/ui-styling-spec.md §8` — corner radius property list
- `docs/spec/ui-styling-spec.md §9.1` — shadow property list

## Scope

- Modify `lib/ui/render/styling.lua` (preferred) or `lib/ui/core/drawable.lua`
- Co-locate `STYLING_KEYS` with the props assembly function (Task 02)

## Concrete Module Targets

- `lib/ui/render/styling.lua` — modified to add the constant

## Implementation Guidance

**Placement:**

Define `STYLING_KEYS` as a local constant at the module level, before any function definitions that use it.

**Contents:**

The constant must contain exactly these 29 keys, in this order (grouped by property family):

Background (10):
`backgroundColor`, `backgroundOpacity`, `backgroundGradient`, `backgroundImage`,
`backgroundRepeatX`, `backgroundRepeatY`, `backgroundOffsetX`, `backgroundOffsetY`,
`backgroundAlignX`, `backgroundAlignY`

Border (9):
`borderColor`, `borderOpacity`, `borderWidthTop`, `borderWidthRight`,
`borderWidthBottom`, `borderWidthLeft`, `borderStyle`, `borderJoin`, `borderMiterLimit`

Corner radius (4):
`cornerRadiusTopLeft`, `cornerRadiusTopRight`, `cornerRadiusBottomRight`, `cornerRadiusBottomLeft`

Shadow (6):
`shadowColor`, `shadowOpacity`, `shadowOffsetX`, `shadowOffsetY`, `shadowBlur`, `shadowInset`

**No additional keys:**

Do not add keys not defined in Phase 12. Do not include general layout properties (`padding`, `margin`, `alignX`, etc.) — those are not styling properties.

## Required Behavior

- `#STYLING_KEYS == 29`
- All 29 property names from Phase 12 are present
- No duplicates
- No keys from outside the Phase 12 property set

## Non-Goals

- No iteration or resolution logic in this task — that is Task 02.
- No ordering constraint beyond grouping — the order within each group does not affect correctness.

## Acceptance Checks

- `#STYLING_KEYS == 29`
- Each expected key is found in the table (manual cross-check against the Phase 12 schema).
- The constant is accessible by the props assembly function.
