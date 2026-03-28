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
- Treat `docs/spec` as the source of truth when the older phase draft suggests a broader public surface

## Required Behavior

- Support the spec-backed naming scheme:
  - `global.<token-class>.<role>`
  - `<component>.<part>.<property>`
  - `<component>.<part>.<property>.<variant>`
- Support the full spec token-class set, including `color`, `spacing`, `radius`, `border`, `font`, `timing`, `texture`, `atlas`, `quad`, `nineSlice`, `shader`, `opacity`, and `blendMode`.
- Keep theme resolution pure and deterministic.
- Keep `Text` styling rooted in the single documented `content` part; presentation variants must flow through the published `textVariant` surface rather than undocumented semantic text-role names.
- Do not infer public helper APIs or extra token bindings from documented slots, regions, or uncontrolled-default tables.
- Allow broad internal fallback coverage if useful, but expose only the documented token bindings as stable contract.

## Non-Goals

- No public CSS-like selector system.
- No implicit token cascade by ancestry.
- No new public role names beyond the specs.

## Acceptance Checks

- Valid token keys resolve according to the documented naming schema.
- Invalid or missing keys fail according to the spec’s missing-token rules.
- Internal authoring conveniences do not leak into the public contract surface.
- `Text` theming remains expressible without stabilizing undocumented semantic role names.
