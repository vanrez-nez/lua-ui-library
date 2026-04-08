# Task 02: Root Compositing Capability Surface

## Goal

Add the normalized root compositing surface to `Shape` and formalize capability declaration through class-level records instead of family-specific branching.

## Current implementation notes

- `Shape` currently only exposes `opacity` from the shared root surface.
- `Drawable` exposes `shader`, `opacity`, `blendMode`, and `mask`, but there is no explicit class-level capability record.
- The container runtime currently infers support through `_ui_drawable_instance` and `_ui_shape_instance`.

## Work items

- Add a static class-level capability record to each adopting primitive class:
  - `Drawable` declares support for `opacity`, `shader`, and `blendMode`
  - `Shape` declares support for `opacity`, `shader`, and `blendMode`
- Keep `mask` outside this capability record and Drawable-only.
- Extend `lib/ui/core/shape_schema.lua` to accept:
  - `shader`
  - `blendMode`
  - `opacity`
- Normalize root compositing defaults in schema or resolution helpers:
  - `opacity = 1`
  - `blendMode = "normal"`
  - `shader = nil`
- Ensure unsupported capability assignment continues to hard-fail on non-adopting primitives by way of their public prop surface.
- Do not add `background*`, `skin`, or `mask` props to `Shape`.

## Implementation notes

- Reuse the validators from `lib/ui/render/graphics_validation.lua` for `Shape.opacity`, `Shape.blendMode`, and later `Shape.shader` assignment-time checks. Do not reintroduce local schema copies.
- `mask` remains Drawable-only and must stay outside the class capability record even though `Drawable` still exposes it publicly.
- `Shape` must continue rejecting `background*`, `skin`, and `mask`; this task adds only the shared root-compositing surface.

## File targets

- `lib/ui/core/drawable.lua`
- `lib/ui/core/shape.lua`
- `lib/ui/core/drawable_schema.lua`
- `lib/ui/core/shape_schema.lua`
- `lib/ui/core/container.lua`

## Acceptance criteria

- Capability support is declared on the class definition, not inferred only from primitive family flags.
- `Shape` instances accept `shader`, `blendMode`, and `opacity` as direct instance props.
- `Shape` still rejects `mask` and styling-owned `background*` props.
- Default-state nodes resolve to the shared root compositing defaults without extra per-node overrides.
