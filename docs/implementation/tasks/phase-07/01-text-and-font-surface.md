# Task 01: Text And Font Surface

## Goal

Implement `Text` as the primitive control with the spec-backed measurement and wrapping contract, while keeping font-loading helpers internal.

## Spec Anchors

- `docs/spec/ui-controls-spec.md:394-440`
- `docs/spec/ui-controls-spec.md:1179-1203`
- `docs/spec/ui-foundation-spec.md:712-896`

## Scope

- Implement `lib/ui/controls/text.lua`
- Keep the public prop surface aligned to `text`, `font`, `fontSize`, `maxWidth`, `textAlign`, `textVariant`, `color`, and `wrap`
- Resolve measurement and wrapping through the `Drawable` content box

## Required Behavior

- Empty text renders nothing and remains valid.
- Wrapping at `maxWidth` follows the spec-backed behavior.
- Horizontal alignment uses `textAlign`, not a new drawable alignment prop.
- Text remains non-interactive and does not own editing behavior.

## Internal-Only Boundaries

- `font_cache.lua` may exist as a helper, but it is not a public control API.
- `fontPath` should not become a stable public prop unless the spec is updated.

## Non-Goals

- No activation or selection semantics.
- No theming-token surface.
- No imperative child-management API.

## Acceptance Checks

- The control measures correctly in both wrapped and unwrapped modes.
- `textVariant` is preserved as part of the public surface even if Phase 7 uses hardcoded visuals.
- Missing or invalid font resolution fails deterministically.
