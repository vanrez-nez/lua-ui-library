# Task 03: Radio And RadioGroup Controls

## Goal

Implement `Radio` and `RadioGroup` as the published single-selection coordinated control family.

## Spec Anchors

- `docs/spec/ui-controls-spec.md §6.4 Radio`
- `docs/spec/ui-controls-spec.md §6.5 RadioGroup`
- `docs/spec/ui-controls-spec.md §4B.1 Control Validity Rules`
- `docs/spec/ui-controls-spec.md §4B.2 Compound Control Contracts`
- `docs/spec/ui-controls-spec.md §4C.2 Public State Ownership Matrix`
- `docs/spec/ui-controls-spec.md §4D.2 Focus And Pointer-Coupling Rules By Control Family`

## Scope

- `lib/ui/controls/radio.lua`
- `lib/ui/controls/radio_group.lua`
- Structural registration from `Radio` to `RadioGroup`
- Negotiated group value ownership
- Required one-of-many selection repair
- Group roving focus and directional navigation
- `label` and `description` regions

## Implementation Guidance

- Implement both controls with `lib/cls` by extending the nearest existing base class rather than creating plain tables with free functions.
- Mirror the current control style used by `Button`, `Tabs`, `Modal`, and `Alert`: `ControlUtils.base_opts(...)`, explicit parent-constructor calls, `rawset` for internal state, and a `new(opts)` helper.
- Use `lib/ui/utils/schema.lua`, `assert.lua`, and `types.lua` for public prop validation and deterministic failure behavior.
- `Radio` should remain a coordinated child control with internal registration hooks only; do not add public `select()`, `setSelected()`, or registration APIs.
- `RadioGroup` should own negotiated `value` using the same controlled/uncontrolled pattern already present in `Tabs`, `Button`, and `Modal`.
- Build `label` and `description` as explicit regions/slots in the same structural style used by existing controls with owned child regions. Do not allow arbitrary interactive descendants in those regions.
- Registration, duplicate-value detection, and selection repair should happen from retained-tree synchronization points so structural changes and destruction follow the same lifecycle discipline as the existing container/control code.

## Required Behavior

- `Radio` has no standalone selected-state ownership; selection derives from the owning `RadioGroup`.
- `RadioGroup` owns exactly one selected enabled value when one exists.
- Group focus movement stops at the ends and does not wrap.
- Focus movement alone does not change the selected value.
- Activation proposes the focused or targeted radio’s value through the owning group.
- Duplicate radio values fail deterministically.

## Non-Goals

- No multi-select behavior.
- No standalone `Radio` usage outside an owning group.
- No generic list-item or option abstraction beyond the published control family.

## Acceptance Checks

- One enabled radio is selected by default when the group is uncontrolled.
- Disabled radios are skipped during focus movement and selection repair.
- Activation changes selection; focus movement alone does not.
- Detached radios fail according to the published validity rules.
- The implementation uses shared control/schema utilities and matches the prevailing class conventions in `lib/ui`.
