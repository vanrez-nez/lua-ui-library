# Task 01: ScrollableContainer Surface And Roles

## Goal

Implement `ScrollableContainer` as the spec-backed primitive with the correct anatomy and public prop surface, without freezing extra attachment APIs.

## Spec Anchors

- `docs/spec/ui-foundation-spec.md §6.3.1 ScrollableContainer`
- `docs/spec/ui-foundation-spec.md §3B.2 Composition Validity Rules`
- `docs/spec/ui-foundation-spec.md §3B.3 Foundation Compound Component Contract`

## Scope

- Implement `lib/ui/scroll/scrollable_container.lua`
- Root, viewport, content, and scrollbar roles
- Public prop surface
- Content-slot attachment boundary

## Required Behavior

- The component exposes the spec-backed anatomy: `root`, `viewport`, `content`, `scrollbars`.
- `scrollXEnabled`, `scrollYEnabled`, `momentum`, `momentumDecay`, `overscroll`, `scrollStep`, and `showScrollbars` exist as the public prop surface.
- The component remains structurally valid only when the required `content` subtree exists.
- The viewport clips descendant drawing and hit testing.

## Missing Detail Normalization

- Do not stabilize method names such as `addContent` or `getContentContainer` unless the spec is amended.
- If the implementation needs an internal content-attachment helper, keep it internal and route public construction through the existing component surface.

## Non-Goals

- No public scrollbar drag API.
- No exact inertial curve contract.
- No exact keyboard mapping contract.

## Acceptance Checks

- A ScrollableContainer instance can be composed with a required content subtree and optional scrollbar visuals.
- The component rejects or otherwise deterministically handles missing required content.
- Public docs and constructor surfaces do not introduce new attachment methods.
