# Task 02: Focus Traversal And Acquisition

## Goal

Implement sequential and directional traversal plus explicit focus acquisition in a way that follows the spec and avoids freezing helper APIs.

## Spec Anchors

- `docs/spec/ui-foundation-spec.md §7.2.2 Focus acquisition rules`
- `docs/spec/ui-foundation-spec.md §7.2.3 Sequential traversal rules`
- `docs/spec/ui-foundation-spec.md §7.2.4 Directional traversal rules`
- `docs/spec/ui-foundation-spec.md §3D.4 Focus Model`

## Scope

- Sequential traversal
- Directional traversal
- Explicit focus requests
- `ui.focus.change` dispatch after committed focus change

## Required Behavior

- Sequential traversal resolves by depth-first pre-order tree order unless a family explicitly binds focus to visual order.
- Directional traversal evaluates candidates within the active focus scope and prefers nearest eligible candidates in the requested direction.
- `ui.focus.change` is non-cancellable and target-only on the new focus owner.
- Pointer activation may change focus only when the component contract allows pointer-focus coupling.

## Missing Detail Normalization

- The spec requires explicit focus request support but does not standardize a concrete `Stage` method name.
- If the implementation exposes a helper for tests or internal use, keep it inside the runtime boundary unless a future spec revision standardizes it.
- Pointer-focus coupling is a component-contract decision, not a generic foundation property.

## Non-Goals

- No public promise about keyboard event source names beyond the spec's logical inputs.
- No control-specific focus behavior yet.

## Acceptance Checks

- `ui.focus.change` fires only after the focus owner is committed.
- Sequential next/previous traversal wraps deterministically.
- Directional traversal is a no-op when no eligible candidate exists.
