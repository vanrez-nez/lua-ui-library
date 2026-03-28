# Task 01: Theme Token Model And Stable Surface

## Goal

Implement the stable theming surface exactly as the foundation and controls specs define it.

## Spec Anchors

- `docs/spec/ui-foundation-spec.md §8.2 Visual Property Taxonomy`
- `docs/spec/ui-foundation-spec.md §8.4 Token Model`
- `docs/spec/ui-foundation-spec.md §8.7 Token Classes`
- `docs/spec/ui-controls-spec.md §8.1 Stable Control Presentational Parts`

## Scope

- Implement the theme object and token storage model
- Preserve the documented naming schema
- Normalize token lookups to documented component-part-property bindings
- Keep theme resolution independent from undocumented selectors or implicit cascading

## Required Behavior

- Support the spec-backed naming scheme:
  - `global.<token-class>.<role>`
  - `<component>.<part>.<property>`
  - `<component>.<part>.<property>.<variant>`
- Support the full spec token-class set, including `color`, `spacing`, `radius`, `border`, `font`, `timing`, `texture`, `atlas`, `quad`, `nineSlice`, `shader`, `opacity`, and `blendMode`.
- Keep theme resolution pure and deterministic.

## Spec Gap Handling

- Do not freeze any extra public role taxonomy for `Text`.
- If the implementation wants convenience aliases for authoring, keep them internal and map them onto the documented `content` part or other spec-backed bindings.

## Non-Goals

- No public CSS-like selector system.
- No implicit token cascade by ancestry.
- No new public role names beyond the specs.

## Acceptance Checks

- Valid token keys resolve according to the documented naming schema.
- Invalid or missing keys fail according to the spec’s missing-token rules.
- Internal authoring conveniences do not leak into the public contract surface.
