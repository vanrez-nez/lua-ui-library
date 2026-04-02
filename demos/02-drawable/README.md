# 02-drawable

## Goal

Build the focused `Drawable` demo without repeating behavior already covered by `demos/01-container`.

Primary authority:

- [UI Foundation Specification](../../docs/spec/ui-foundation-spec.md)
- [UI Motion Specification](../../docs/spec/ui-motion-spec.md)
- `docs/spec/ui-foundation-spec.md §6.1.2 Drawable`
- `docs/implementation/tasks/phase-01/05-drawable-content-box-and-visual-surface.md`

## Scope

This demo covers only the `Drawable` surface that is not already validated by `01-container`:

- `alignX`
- `alignY`
- `padding`
- `margin`
- `opacity`
- `skin`
- `blendMode`
- `mask`
- `motion`

This demo intentionally does not re-prove:

- retained parent / child tree behavior
- base bounds resolution
- percentage sizing
- clamp behavior
- visibility behavior

Those are already owned by `demos/01-container`.

## Screen Set

1. alignment resolution
2. padding and margin
3. opacity storage
4. skin storage
5. blend-mode storage
6. mask storage
7. motion inspection

## Demo Notes

- Alignment and content-box behavior are directly observable and should be visualized.
- Margin should be shown as external layout input and must not imply that `Drawable` performs sibling layout.
- `opacity`, `skin`, `blendMode`, and `mask` are stable public props on `Drawable`, but the current runtime still treats most of them as deferred visual surface storage.
- `shader` exists on the public surface but is not visually applied by the current runtime, so this demo does not present it as a working rendered feature.
- The motion screen may use a demo-local harness trigger to inspect the shared motion contract because bare `Drawable` does not own a built-in interaction phase.
