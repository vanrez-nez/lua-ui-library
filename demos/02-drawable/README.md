# 02-drawable

## Goal

Build the focused `Drawable` demo without repeating behavior already covered by `demos/01-container`.

Primary authority:

- [UI Foundation Specification](../../docs/spec/ui-foundation-spec.md)
- [UI Motion Specification](../../docs/spec/ui-motion-spec.md)
- `docs/spec/ui-foundation-spec.md §6.1.2 Drawable`

## Scope

This demo covers only the `Drawable` surface that is not already validated by `01-container`:

- `alignX`
- `alignY`
- `padding`
- `margin`
- `opacity`
- `skin`
- `blendMode`
- `motion`

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
3. nested spacing interaction
4. opacity inspection
5. skin inspection
6. blend-mode inspection
7. retained render effects
8. motion inspection

## Demo Notes

- Alignment and content-box behavior are directly observable and should be visualized.
- Margin should be shown as external layout input and must not imply that `Drawable` performs sibling layout.
- The nested spacing screen must use real `Drawable` nesting only. Child placement may come from the parent `Drawable` content box and `resolveContentRect()`, but margin must remain inspectable external input rather than simulated child layout.
- `opacity` and `blendMode` now participate in the shared retained render path through subtree isolation and compositing.
- The dedicated opacity and blend-mode screens keep those configured props inspectable without duplicating the heavier visual comparison setup.
- The retained render-effects screen demonstrates the visible subtree compositing differences with shared layered content.
- `skin` belongs here only when the screen is proving observable `Drawable` behavior directly.
- `shader` and `mask` should only be demoed when there is concrete `Drawable` behavior to observe through the real implementation.
- Motion coverage here must stay tied to real `Drawable` motion surfaces and must not invent extra behavior outside the component contract.
