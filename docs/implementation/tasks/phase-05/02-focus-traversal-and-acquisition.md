# Task 02: Focus Traversal And Acquisition

## Goal

Implement sequential and directional traversal plus explicit focus acquisition in a way that matches the settled focus contract while keeping helper method names and metadata internal.

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
- Explicit consumer-requested focus movement is supported as behavior.

## Authority Boundaries

- `docs/spec/ui-foundation-spec.md §3D.4` and `§7.2` settle that explicit focus request support is required, but no concrete public `Stage` method name is standardized.
- If the implementation exposes a helper for tests or runtime plumbing, keep it inside the internal runtime boundary unless a future revision documents it.
- `docs/spec/ui-foundation-spec.md §7.2.6` settles that pointer-focus coupling is a component-contract decision, not a generic foundation property.

## Non-Goals

- No public promise about keyboard event source names beyond the spec's logical inputs.
- No control-specific focus behavior yet.

## Acceptance Checks

- `ui.focus.change` fires only after the focus owner is committed.
- Sequential next/previous traversal wraps deterministically.
- Directional traversal is a no-op when no eligible candidate exists.
- Any explicit-focus helper used by tests is documented as internal harness/runtime support rather than public API.
