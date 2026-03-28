# Task 03: Checkbox And Switch Selection Controls

## Goal

Implement `Checkbox` and `Switch` with the spec-backed ownership, toggle, and drag semantics.

## Spec Anchors

- `docs/spec/ui-controls-spec.md:551-733`
- `docs/spec/ui-controls-spec.md:1210-1212`

## Scope

- Implement `lib/ui/controls/checkbox.lua`
- Implement `lib/ui/controls/switch.lua`
- Keep the public state and callback surfaces aligned to the spec

## Required Behavior

- `Checkbox` uses negotiated `checked` plus `onCheckedChange`.
- `Checkbox` uses `toggleOrder` to define the activation cycle, including the indeterminate case.
- `Switch` uses negotiated `checked` plus `onCheckedChange`.
- `Switch` exposes `dragThreshold` and `snapBehavior`.
- Labels and descriptions are structural content, not string-only convenience props.

## Internal-Only Boundaries

- `defaultChecked`, `allowIndeterminate`, and midpoint-only drag resolution are not spec-stabilized public API.
- Any helper methods for wiring label or description content should remain internal if they are not part of the documented contract.

## Non-Goals

- No nested interactive content inside label or description regions.
- No theming-token or skin-resolution surface yet.

## Acceptance Checks

- Disabled controls reject activation and drag input.
- Checkbox toggles follow the configured order, including the default order.
- Switch drag release honors threshold and snap behavior rather than a fixed midpoint heuristic.
