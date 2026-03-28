# Task 01: Focus State And Scope Contract

## Goal

Implement the logical focus model owned by Stage, while keeping scope metadata aligned with the spec and not freezing unsupported generic props.

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
- Nested focus scope support is available as a runtime behavior, but the public property shape for marking a scope is not stabilized by the spec in this phase.

## Spec Gap Handling

- Do not freeze `focusScope` as a generic `Container` prop surface.
- If implementation needs a scope marker internally, keep it internal until a component contract or spec revision names the public shape.
- `focused` should be derived from focus ownership, not stored as durable node-local public state.

## Non-Goals

- No new public focus-related props.
- No focus restoration policy beyond what the spec names.

## Acceptance Checks

- Stage can identify the current focus owner and active scope chain deterministically.
- Reparented or destroyed nodes cannot retain stale focus ownership state.
- Derived focus state is available to draw-time rendering without mutating public node API.
