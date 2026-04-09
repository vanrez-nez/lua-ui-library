# 03-drawable

## Goal

Build the focused `Drawable` demo without repeating behavior already covered by `demos/01-container` or the retained graphics surfaces now isolated in `demos/03-graphics`.

Primary authority:

- [UI Foundation Specification](../../docs/spec/ui-foundation-spec.md)
- `docs/spec/ui-foundation-spec.md §6.1.2 Drawable`

## Scope

This demo covers only the `Drawable` surface that is not already validated by `01-container`:

- `alignX`
- `alignY`
- `padding`
- `margin`
- stack / row / column / flow / page layout on real retained children
- `skin`
- border styling

This demo intentionally does not re-prove:

- retained parent / child tree behavior
- base bounds resolution
- percentage sizing
- clamp behavior
- visibility behavior

Those are already owned by `demos/01-container`.

This demo must use real `Drawable` instances and real `Drawable` behavior.

It must not:

- simulate parent/child layout behavior that `Drawable` does not own
- compose spacing behavior in demo-local code and present it as `Drawable` behavior
- justify gaps with phase language such as "deferred" or "until implemented"

## Screen Set

1. alignment resolution
2. padding and margin
3. stack layout
4. row layout
5. column layout
6. flow layout
7. page layout
8. skin inspection
9. border inspection

## Demo Notes

- Alignment and content-box behavior are directly observable and should be visualized.
- Margin should be shown as external layout input and must not imply that `Drawable` performs sibling layout.
- The nested spacing and retained layout screens must use real `Drawable` nesting only. Child placement may come from the parent `Drawable` content box and layout props, but margin must remain inspectable external input rather than simulated sibling layout.
- Graphics-specific retained compositing behavior now lives in `demos/03-graphics`.
- `skin` belongs here only when the screen is proving observable `Drawable` behavior directly.
- `shader` and `mask` should only be demoed when there is concrete `Drawable` behavior to observe through the real implementation.
