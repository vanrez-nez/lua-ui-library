# Task 02: Button Activation And Slotting

## Goal

Implement `Button` with its settled activation, disabled, and negotiated pressed-state contract while keeping content population structural rather than imperative.

## Authority

- `docs/spec/ui-controls-spec.md §6.2 Button`
- `docs/spec/ui-controls-spec.md §4B.3 Control Slot Declarations`
- `docs/spec/ui-controls-spec.md §8.1-§8.3`
- `docs/spec/ui-foundation-spec.md §3D`

## Settled Contract Points

- The public `Button` surface is `pressed`, `onPressedChange`, `onActivate`, `disabled`, and `content`.
- `content` is a documented slot or region, not a stable imperative setter API.
- `Button` supports pointer, touch, keyboard, and programmatic activation.
- Disabled buttons suppress hover, pressed, focus-acquisition, and activation behavior.
- The Phase 07 rendering path must preserve the stable state priority order `disabled > pressed > hovered > focused > base`.

## Implementation Guardrails

- A helper that attaches content may exist internally, but it must not be documented as public API.
- Nested interactive controls inside the content slot remain unsupported in this revision.
- Event ordering must stay spec-shaped: cancellable activation delivery finishes before any callback-driven state proposal.
- Controlled pressed-state behavior must render from the last committed authoritative value, not from speculative internal mutation.

## Acceptance Checks

- Releasing outside the target clears the press without dispatching activation.
- Cancelling the activation event suppresses the default action and the associated activation outcome.
- `pressed` without `onPressedChange` is treated as invalid mutable configuration.
- Empty content remains valid and does not break interaction.
