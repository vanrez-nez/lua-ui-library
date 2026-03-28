# Task 04: Listener Surface And Error Semantics

## Goal

Implement the minimum listener-routing surface needed by the event system while keeping the exact listener API provisional and preserving deterministic error behavior.

## Spec Anchors

- `docs/spec/ui-foundation-spec.md §7.1 Event Propagation`
- `docs/spec/ui-foundation-spec.md §3G.3 Diagnostic Signal Contract`
- `docs/spec/ui-foundation-spec.md §3G.6 Undefined Behavior Declaration`

## Scope

- Listener registration and removal for propagation phases
- Listener ordering on a single node
- Propagation mutation behavior during active delivery
- Error propagation from listener bodies

## Required Behavior

- Listener errors propagate upward and halt the current event delivery.
- Duplicate registration of the same listener function results in duplicate invocation if the chosen internal listener model supports it.
- Listener changes during active propagation take effect on the next delivery.

## Normalization Rules

- Do not present `on`, `off`, `capture`, and `bubble` as spec-stabilized API unless later documentation promotes them.
- Do not add de-duplication or implicit listener normalization that would change the documented propagation behavior.
- Keep any helper objects or registration bookkeeping internal.

## Non-Goals

- No public promise about the exact listener storage structure.
- No public promise about hover notifications.

## Acceptance Checks

- Listener exceptions stop the current dispatch and bubble up.
- Listener mutation during dispatch is deferred to the next event.
- Multiple registrations of the same function are preserved according to the chosen internal semantics.
