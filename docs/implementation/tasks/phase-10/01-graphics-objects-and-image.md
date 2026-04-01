# Task 01: Graphics Objects And Image

## Goal

Implement the first-class graphics-object surface and the retained `Image` primitive exactly as the published graphics spec defines them.

## Spec Anchors

- `docs/spec/ui-graphics-spec.md §4A Graphics Object Classification And Identity`
- `docs/spec/ui-graphics-spec.md §4B.1 Texture Contract`
- `docs/spec/ui-graphics-spec.md §4B.2 Atlas Contract`
- `docs/spec/ui-graphics-spec.md §4B.3 Sprite Contract`
- `docs/spec/ui-graphics-spec.md §4B.4 Region Contract`
- `docs/spec/ui-graphics-spec.md` sections for `Texture`, `Atlas`, `Sprite`, and `Image`
- `docs/spec/ui-foundation-spec.md §8.10 Graphics Asset Interoperability Contract`

## Scope

- First-class `Texture` object
- First-class `Atlas` object
- First-class `Sprite` object
- Retained `Image` primitive
- Source-region clipping and warning behavior
- Shader-, texture-, atlas-, quad-, and nine-slice-compatible integration where the graphics spec requires it

## Concrete Module Targets

- Add a spec-owned graphics namespace under `lib/ui/graphics/`.
- Implement `lib/ui/graphics/texture.lua`.
- Implement `lib/ui/graphics/atlas.lua`.
- Implement `lib/ui/graphics/sprite.lua`.
- Implement `lib/ui/graphics/image.lua`.
- Add internal helpers only when they remove duplication across those four modules; do not collapse the public objects into one catch-all asset module.

## Implementation Guidance

- Use `lib/cls` for `Texture`, `Atlas`, and `Sprite` so they are first-class runtime objects with explicit identity and predictable type checks.
- Implement `Image` as a retained `Drawable`-based primitive, not as a control and not as a plain data wrapper around `Texture` or `Sprite`.
- Follow the current class pattern already used by `Drawable`, `Container`, and existing controls: explicit `:constructor(...)`, explicit parent-constructor calls, and a `.new(...)` convenience constructor.
- Reuse `lib/ui/utils/assert.lua` and `lib/ui/utils/types.lua` for deterministic argument and source validation.
- Reuse `lib/ui/utils/common.lua` for copy semantics where source-region or descriptor tables need to be cloned before storage.
- If `Image` introduces public props such as `source`, `fit`, `align`, `sampling`, `decorative`, or `accessibleName`, validate them through schema tables merged in the same style as `Drawable._schema`, not with ad hoc setters only.
- Treat warning emission for clipped out-of-bounds regions as an internal diagnostic concern; keep the diagnostic path internal and do not freeze a public logger API in this task.
- Preserve the responsibility split from the spec: `Texture` owns source identity and intrinsic dimensions, `Atlas` owns named region lookup, `Sprite` owns one effective texture plus one effective region, and `Image` owns retained presentation.

## Required Behavior

- `Texture` exposes intrinsic dimensions and remains independent from one mandatory loading identity such as a file path.
- `Atlas` resolves named regions to one effective texture-backed region without implying retained drawing behavior.
- `Sprite` resolves to exactly one backing texture plus one effective source region and exposes intrinsic dimensions derived from that region.
- `Image` renders either a full `Texture` or a `Sprite`.
- `Image` supports documented fit, alignment, accessibility, and sampling behavior.
- Out-of-bounds source regions are clipped and produce a warning diagnostic; non-positive region size fails deterministically.
- No graphics object in this task owns animation playback.

## Non-Goals

- No public asset-loader registry.
- No animated-sprite playback.
- No public tiling or repeat-surface contract beyond what the graphics spec already names.

## Acceptance Checks

- `Texture`, `Atlas`, `Sprite`, and `Image` exist as distinct public objects with their published responsibility boundaries.
- `Sprite` region resolution follows the documented clipping and failure rules.
- `Image` behaves correctly with both full-texture and region-backed sources.
- No control-specific assumptions leak into the graphics-object surface.
- The implementation uses the existing class and schema infrastructure rather than inventing a parallel object or validation model.
