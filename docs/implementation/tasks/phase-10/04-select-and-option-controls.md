# Task 04: Select And Option Controls

## Goal

Implement `Select` and `Option` strictly on the published custom-popup selection contract, including single and multiple selection modes.

## Spec Anchors

- `docs/spec/ui-controls-spec.md §6.9 Option`
- `docs/spec/ui-controls-spec.md §6.10 Select`
- `docs/spec/ui-controls-spec.md §4B.1 Control Validity Rules`
- `docs/spec/ui-controls-spec.md §4B.2 Compound Control Contracts`
- `docs/spec/ui-controls-spec.md §4C.2 Public State Ownership Matrix`
- `docs/spec/ui-controls-spec.md §4D.1 Control Input-To-Callback Mapping`
- `docs/spec/ui-motion-spec.md §4I Family Adoption Matrix`

## Scope

- `lib/ui/controls/select.lua`
- `lib/ui/controls/option.lua`
- Trigger and popup coordination
- Registered option ownership and duplicate-value validation
- `selectionMode = "single" | "multiple"`
- `placeholder` and summary behavior
- Modal and non-modal popup behavior
- Motion-surface adoption for popup open/close/placement phases

## Implementation Guidance

- Follow the same class construction pattern used elsewhere in `lib/ui`: `lib/cls`, explicit base-class constructor calls, `new(opts)`, and `rawset` for internal retained state.
- Reuse `ControlUtils.base_opts(...)` and `ControlUtils.assert_controlled_pair(...)` for base prop forwarding and negotiated `value` / `open` handling.
- Validate public props and mode-specific value shapes through `lib/ui/utils/schema.lua`, `assert.lua`, and `types.lua`; do not build a second validation DSL local to `Select`.
- Keep `Option` as a registered coordinated descendant only. Avoid public imperative helpers such as `open()`, `close()`, `selectValue()`, `toggleValue()`, or `registerOption()`.
- The popup surface should be implemented as part of the `Select` contract and may reuse existing overlay/focus patterns from `Modal`, but it must not become a generic public overlay manager.
- Summary rendering should be driven from the effective registered option order so multiple-selection summaries stay aligned with the spec's registration-order semantics.
- Motion adoption should plug into the shared phase-10 motion boundary rather than reusing old per-control timing props or private easing fields.

## Required Behavior

- `Select` supports negotiated `value` and negotiated `open`.
- `Option` participates only through an owning `Select`.
- Single-select mode accepts `string | nil`; multi-select mode accepts ordered unique value tables or `nil`.
- Single-select closes on selection by default.
- Multi-select remains open on selection by default.
- The popup may be modal or non-modal according to `modal`.
- At least one option is required and duplicate option values fail deterministically.
- Option content remains limited to `label` and `description` in this revision.

## Settled Boundaries

- This control does not delegate to native platform pickers.
- Search, typeahead, and virtualization remain out of scope.
- Motion support must flow through `motionPreset` / `motion`, not through new select-local animation props.

## Non-Goals

- No native select fallback path.
- No arbitrary rich interactive descendants inside `Option`.
- No public popup manager or option-builder API.

## Acceptance Checks

- Trigger summary renders correctly for empty, single, and multiple selection states.
- Popup open/close behavior respects `modal` and the published dismissal rules.
- Multiple mode preserves registration-order summary semantics.
- Invalid selected values are omitted from the effective selected set without hard failure.
- The implementation uses the existing class, schema, and overlay/focus conventions already established in the codebase.
