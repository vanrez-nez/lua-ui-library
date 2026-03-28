# Task 05: Flow Layout

## Goal

Implement `Flow` as the fluid reading-order layout primitive without adding unsupported public props.

## Spec Anchors

- `docs/spec/ui-foundation-spec.md §6.2.7 Flow`
- `docs/spec/ui-foundation-spec.md §6.2.2 Common props`
- `docs/spec/ui-foundation-spec.md §6.2.3 Common state model`

## Scope

- Implement `lib/ui/layout/flow.lua`
- Reading-order placement
- Wrapping to subsequent rows when space is exhausted
- Gap handling using the common layout surface
- Last-row alignment behavior

## Required Behavior

- Flow places children in reading order.
- When `wrap = true`, it wraps to a new row when remaining space is insufficient.
- When `wrap = false`, overflow remains valid without wrapping.
- The last row of a wrapped flow aligns to the `align` value and is not stretched to fill available space.
- Invisible children do not occupy space in the flow.

## Missing Detail Normalization

- Do not expose `gapX` or `gapY` as public props.
- If the implementation needs axis-specific internal gap handling, derive it from the common `gap` contract or keep the extra representation internal.

## Non-Goals

- No strict grid semantics.
- No public axis-specific gap API.

## Acceptance Checks

- A single child wider than the full row occupies its own row and remains unclipped unless clipping is enabled.
- Wrap toggling changes placement behavior without changing the public prop surface.
