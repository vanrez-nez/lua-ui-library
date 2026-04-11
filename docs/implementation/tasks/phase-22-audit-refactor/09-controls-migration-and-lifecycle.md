# Task 09: Controls Migration And Lifecycle

## Goal

Migrate every file in `lib/ui/controls/` onto the new object model and close the control-related source-audit findings in the same pass so each control is touched once. This task wraps up the full Container hierarchy migration — after task 09, no base class or concrete class in `lib/ui/` still depends on `_public_values`/`_effective_values`/`_set_public_value`.

## Scope

In scope:

- migrate `button.lua`, `checkbox.lua`, `switch.lua`, `radio.lua`, `radio_group.lua`, `slider.lua`, `progress_bar.lua`, `select.lua`, `option.lua`, `text_input.lua`, `text_area.lua`, `tabs.lua`, `modal.lua`, `alert.lua`, `notification.lua`, `tooltip.lua` to the migrated Container base; each constructor calls `self.schema:define(...)` with its Rule-backed schema (merging with the base schema as needed)
- introduce `_control_schema` Rule-builder tables on `slider`, `select`, `radio_group`, `checkbox` for constructor-argument validation, validated via `self.schema:define(self._control_schema)` or an equivalent bulk call
- add `ControlUtils.controlled_value(prop_name, default)` factory (`CS-06`) and consume it from `slider`, `switch`, `radio_group`, `tabs`, `select`, `text_input`, `checkbox`; delete the local `effective_value` / `request_value` copies
- standardize the `_destroyed` guard via `ControlUtils._destroyed_guard` (or equivalent) (`CS-07`) across every control's event callbacks
- implement `destroy()` on `slider`, `progress_bar`, `radio_group`, `radio`, `button`, `checkbox`, `switch` that removes listeners registered in the constructor and delegates to `Container:destroy()` (`ML-04`)
- extract overlay attach/detach into `ControlUtils.overlay_mixin` (`RE-01`) and consume it from `tooltip`, `select`, `modal`, `notification`
- add control migration specs for representative round-trips on the largest controls

Out of scope:

- `lib/ui/controls/text.lua` — already migrated in task 08
- GPU / frame-hot caching — task 10
- any public API change on controls
- dispatcher-level `_destroyed` filtering (flagged as possible future follow-up in the acceptance summary)

## Spec anchors

- [audits/source_code_audit_findings.md](/Users/vanrez/Documents/game-dev/lua-ui-library/audits/source_code_audit_findings.md) — `CS-06`, `CS-07`, `CS-08`, `RE-01`, `ML-04`
- Task 00 compliance review — control migration is `spec-sensitive`; constructor-argument validation on Slider/Select/RadioGroup/Checkbox is a behavior unification, not a contract change.

## Current implementation notes

- `lib/ui/controls/control_utils.lua` already owns some shared helpers. Task 09 extends it with `controlled_value`, `_destroyed_guard`, and `overlay_mixin`.
- Today, the "controlled value" pattern (`effective_value` uses the `value` prop when present, falling back to `_internal_value`; `request_value` calls `onValueChange` if present, otherwise writes `_internal_value`) is copy-pasted across `slider`, `switch`, `radio_group`, `tabs`, `select`, `text_input`, `checkbox`. Seven copies of the same 10–20 line block.
- Several controls currently guard event callbacks with `if self._destroyed then return end`, but not uniformly. `CS-07` standardizes the guard via a helper.
- `Slider`, `Select`, `RadioGroup`, `Checkbox` currently validate their constructor arguments with inline `Assert.fail` calls that produce error messages observed by existing specs. Migrating to Rule builders via `_control_schema` must preserve those messages exactly.
- `tooltip`, `select`, `modal`, `notification` each implement an overlay attach/detach path that stages the overlay into the Stage's overlay layer. `RE-01` calls for extracting the shared logic into a mixin.
- `ML-04` notes that `slider`, `progress_bar`, `radio_group`, `radio`, `button`, `checkbox`, `switch` register event listeners in their constructors but do not always remove them on destroy, causing listener leaks when controls are detached.

## Work items

- **Base migration per control.** For each file in `lib/ui/controls/`:
  1. `Foo:constructor(opts)` delegates to `Container:constructor(opts)` (or the appropriate migrated base).
  2. Call `self.schema:define(FooSchema)` where a Foo-specific schema exists; otherwise the base schema from Container/Drawable covers it.
  3. Remove any direct `_public_values` / `_effective_values` access; route through normal assignment for public writes and `Reactive:raw_set` for controller-internal writes.
  4. Consume `ControlUtils.controlled_value(prop_name, default)` for the seven controls listed above (see next bullet).
  5. Wrap every event callback registered in the constructor with `ControlUtils._destroyed_guard` (see bullet below).
- **`ControlUtils.controlled_value` (`CS-06`).** Add a factory to `control_utils.lua` that returns a pair `(get_effective, request)` for a given prop name and default:
  - `get_effective()` returns `self[prop_name]` if present, otherwise the internal fallback stored on `self` under a known private key.
  - `request(new_value)` calls `self.onValueChange(new_value)` if present, otherwise writes the internal fallback via `Reactive:raw_set(self, private_key, new_value)` and triggers the control's redraw path.
  Update `slider.lua`, `switch.lua`, `radio_group.lua`, `tabs.lua`, `select.lua`, `text_input.lua`, `checkbox.lua` to consume the factory and delete their local copies. Error messages and public behavior stay identical.
- **`_control_schema` for Slider / Select / RadioGroup / Checkbox.** Each of the four controls adds a `_control_schema` Rule-builder table describing its constructor arguments (e.g. Slider: `min`, `max`, `step`, `orientation`, `value`, `onValueChange`). The constructor calls `self.schema:define(self._control_schema)` or an equivalent bulk validation pass before returning. Error messages from the new Rule builders must match the current inline `Assert.fail` messages byte-for-byte — task 04 already ensured Rule builders can reproduce these messages, so this is a wiring change, not a message change.
- **`ControlUtils._destroyed_guard` (`CS-07`).** Add a helper that wraps a function so it early-returns when `self._destroyed` is true. Usage pattern: `listener = ControlUtils._destroyed_guard(self, function(...) ... end)`. Apply to every event listener registered in a control constructor. The destroyed flag is set in `destroy()` (see next bullet) before the listener cleanup runs.
- **`destroy()` implementations (`ML-04`).** Each of `slider`, `progress_bar`, `radio_group`, `radio`, `button`, `checkbox`, `switch` adds a `Foo:destroy()` method that:
  1. Sets `self._destroyed = true`.
  2. Removes every listener it registered in its constructor from the dispatcher or target instance. Store listener references on the instance during constructor so `destroy()` can find them.
  3. Calls `Container:destroy(self)` (or delegates via the class chain).
  If `Container:destroy()` already removes any remaining listeners, document that and keep the control-level cleanup as a safety net. If not, add the cleanup there as well.
- **`ControlUtils.overlay_mixin` (`RE-01`).** Extract the overlay attach/detach logic from `tooltip`, `select`, `modal`, `notification` into a mixin with methods `_attach_overlay()`, `_detach_overlay()`, and any shared state setup. Each of the four controls consumes the mixin instead of reimplementing the pattern.
- **Control migration specs.** Add targeted specs for:
  - Slider constructor rejects an invalid `min`/`max`/`step` combination with the same error message as before
  - Select constructor rejects a missing `options` arg with the same message as before
  - Checkbox `destroy()` removes its registered listeners (verify by observing listener count on the dispatcher before and after)
  - Tooltip `_attach_overlay` / `_detach_overlay` behave identically through the mixin

## File targets

- `lib/ui/controls/control_utils.lua` (new helpers: `controlled_value`, `_destroyed_guard`, `overlay_mixin`)
- `lib/ui/controls/button.lua`
- `lib/ui/controls/checkbox.lua`
- `lib/ui/controls/switch.lua`
- `lib/ui/controls/radio.lua`
- `lib/ui/controls/radio_group.lua`
- `lib/ui/controls/slider.lua`
- `lib/ui/controls/progress_bar.lua`
- `lib/ui/controls/select.lua`
- `lib/ui/controls/option.lua`
- `lib/ui/controls/text_input.lua`
- `lib/ui/controls/text_area.lua`
- `lib/ui/controls/tabs.lua`
- `lib/ui/controls/modal.lua`
- `lib/ui/controls/alert.lua`
- `lib/ui/controls/notification.lua`
- `lib/ui/controls/tooltip.lua`
- `spec/controls_proxy_migration_spec.lua` (new; or integrated into existing controls spec layout)

## Testing

Required runtime verification:

- an interactive demo exercising Slider, ProgressBar, TextInput, Checkbox, Switch, Select, RadioGroup, Tabs, Button renders and behaves identically
- a demo exercising Tooltip, Modal, Notification overlay attach/detach renders identically
- destroying a control in a demo does not leave dangling listeners (observable via a simple dispatcher-count check or console log)

Required spec verification:

- every existing `spec/*control*` or `spec/*slider*` / `spec/*select*` / `spec/*checkbox*` / `spec/*text_input*` / etc. spec passes unchanged
- the new control migration spec
- full `spec/` suite green with zero edits to existing spec files

## Acceptance criteria

- Every file in `lib/ui/controls/` constructs through the migrated Container base; zero references to `_public_values`, `_effective_values`, `_set_public_value`, or `_allowed_public_keys` remain anywhere in `lib/ui/controls/`.
- `ControlUtils.controlled_value` exists and is consumed by slider, switch, radio_group, tabs, select, text_input, checkbox; the seven local copies of `effective_value`/`request_value` are deleted.
- `ControlUtils._destroyed_guard` exists and is consumed by every control that registers an event listener in its constructor.
- Slider, Select, RadioGroup, Checkbox each declare a `_control_schema` Rule-builder table and validate constructor arguments through it; error messages match the pre-migration messages byte-for-byte.
- `slider`, `progress_bar`, `radio_group`, `radio`, `button`, `checkbox`, `switch` each implement `destroy()` that removes their registered listeners before delegating to `Container:destroy()`.
- `ControlUtils.overlay_mixin` is consumed by `tooltip`, `select`, `modal`, `notification`; the duplicated overlay attach/detach code is gone.
- Every controls spec passes with zero edits.
