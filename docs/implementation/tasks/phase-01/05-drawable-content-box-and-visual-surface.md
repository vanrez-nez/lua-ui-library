# Task 05: Drawable Content Box And Deferred Visual Surface

## Goal

Implement `Drawable` as the first render-capable primitive with a stable content-box and alignment contract, while keeping later visual systems explicitly deferred.

## Spec Anchors

- `docs/spec/ui-foundation-spec.md §6.1.2 Drawable`
- `docs/spec/ui-foundation-spec.md §3C.6 Derived State`
- `docs/spec/ui-foundation-spec.md §8 Visual Contract And Theming Contract`

## Scope

- Implement `lib/ui/core/drawable.lua`
- Padding and margin normalization
- Local content-box computation
- `alignX` and `alignY` storage and resolution helpers
- Storage for documented visual props that later phases activate

## Required Behavior

- `Drawable` extends `Container`.
- Padding shrinks the local content box.
- Margin remains external layout input and does not change the node's own bounds.
- `getContentRect()` returns a local-space rectangle after padding.
- `alignX` and `alignY` values remain constrained to the documented enum surface.

## Settled Surface Requirements

- `skin`, `shader`, `opacity`, `blendMode`, and `mask` must exist as part of the stable `Drawable` surface.
- Phase 1 may store these without full visual effect application, but it must not rename or postpone the surface itself.
- Do not introduce a public persistent `focused` property on `Drawable`. Focus-derived rendering state belongs to later focus and theming work and should stay internal or contextual until the spec-backed system exists.

## Non-Goals

- No token resolution.
- No render-skin resolution.
- No isolation or shader application yet.

## Acceptance Checks

- Content-box calculations respect normalized padding values.
- Zero-area content boxes clamp to zero area without crashing.
- Deferred visual props can be stored without changing current draw traversal behavior.
