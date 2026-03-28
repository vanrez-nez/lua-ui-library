# Task 01: Focus State And Scope Contract

## Goal

Implement the Stage-owned logical focus model and active-scope bookkeeping in a way that follows the settled spec contract and keeps unnamed marker surfaces internal.

## Spec Anchors

- `docs/spec/ui-foundation-spec.md §7.2 Focus`
- `docs/spec/ui-foundation-spec.md §3D.4 Focus Model`
- `docs/spec/ui-foundation-spec.md §3C.6 Derived State`

## Scope

- Stage-owned focus owner tracking
- Active focus scope chain tracking
- Internal trap history bookkeeping
- Derived focus ownership state for draw-time use

## Required Behavior

- Stage remains the single owner of logical focus state.
- Exactly one node may own logical focus within the active focus scope chain at a time.
- Root focus scope is Stage.
- Nested focus scopes are supported behavior when a component or runtime contract requires bounded traversal.

## Authority Boundaries

- `docs/spec/ui-foundation-spec.md §7.2.1` settles the behavior boundary: nested scope support is required, but a generic `Container` marker schema is still intentionally not standardized.
- If implementation needs a scope marker internally, keep it inside the runtime boundary until a component or runtime contract names the public shape.
- `focused` should be derived from focus ownership, not stored as durable node-local public state.

## Non-Goals

- No new generic public focus-related props.
- No focus restoration policy beyond what the spec names.

## Acceptance Checks

- Stage can identify the current focus owner and active scope chain deterministically.
- Reparented or destroyed nodes cannot retain stale focus ownership state.
- Derived focus state is available to draw-time rendering without adding durable public node state.
