# Task 02: Control Part Skins And State Variants

## Goal

Wire the documented control part surfaces and stateful skin variant resolution into the controls package.

## Spec Anchors

- `docs/spec/ui-controls-spec.md §8.1 Stable Control Presentational Parts`
- `docs/spec/ui-controls-spec.md §8.3 Stateful Variant Priority Order`
- `docs/spec/ui-controls-spec.md §8.4 Control Structure Versus Appearance Boundary`
- `docs/spec/ui-controls-spec.md §8.12 Stateful Variant Resolution`

## Scope

- Resolve part-specific skins for the documented control parts
- Apply the state priority orders already stabilized by the controls spec
- Support instance-level visual overrides and part skin overrides where documented
- Respect the appearance-versus-structure boundary
- Treat control slots, regions, and helper methods according to the spec’s structural-boundary clarifications

## Required Behavior

- Use the stable presentational parts listed in the controls spec only.
- Do not invent new part names as stable API.
- Preserve the documented priority orders for Button, Checkbox, Switch, TextInput, TextArea, Tabs, Modal, and Alert.
- Keep `Text` limited to its stable `content` part.
- Render focus affordances through documented parts and state variants only; do not create a separate public focus-token family.
- Keep any convenience styling alias or helper surface internal unless the relevant control section explicitly documents it as public API.

## Non-Goals

- No control behavior changes.
- No new public variants.
- No control-local helper wrappers as stable API.

## Acceptance Checks

- Each control resolves the correct active variant for the current state combination.
- Part skins can be overridden without changing control behavior.
- Internal wrappers and decorative layers remain implementation detail.
- Control theming does not imply stable builder methods for slot population, modal open/close helpers, or tab-registration helpers.
