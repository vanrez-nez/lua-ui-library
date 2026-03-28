# Task 02: Button Activation And Slotting

## Goal

Implement `Button` with the negotiated pressed-state contract, activation semantics, and documented content slot, without stabilizing imperative builder methods.

## Spec Anchors

- `docs/spec/ui-controls-spec.md:442-549`
- `docs/spec/ui-controls-spec.md:322-326`
- `docs/spec/ui-controls-spec.md:1183-1201`

## Scope

- Implement `lib/ui/controls/button.lua`
- Expose `pressed` and `onPressedChange`
- Expose `onActivate` and `disabled`
- Support the documented `content` slot/region

## Required Behavior

- Pointer, keyboard, and programmatic activation must follow the spec-backed callback ordering.
- Disabled buttons suppress activation and focus acquisition.
- Empty content remains valid and functional.
- Variant priority follows the spec order: `disabled > pressed > hovered > focused > base`.

## Internal-Only Boundaries

- `button:setContent(node)` may exist as an internal helper, but it is not a spec-stabilized public method.
- `pointerFocusCoupling` is a behavior requirement, not a new public prop.

## Non-Goals

- No stable imperative handle/ref surface.
- No theming token resolution yet.
- No nested interactive descendants inside the content slot.

## Acceptance Checks

- Pressed state reflects the last committed authoritative value.
- Pointer release outside the target does not activate.
- Focus and hover semantics remain coherent under disable/enable changes.
