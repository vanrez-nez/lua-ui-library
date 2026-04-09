# 03-graphics

## Goal

Build the focused graphics demo for retained opacity, blend mode, and subtree compositing behavior.

Primary authority:

- [UI Graphics Specification](../../docs/spec/ui-graphics-spec.md)
- [UI Foundation Specification](../../docs/spec/ui-foundation-spec.md)
- `docs/spec/ui-foundation-spec.md §6.1.2 Drawable`

## Scope

This demo covers the retained graphics surfaces that are shared across the retained scene graph:

- `opacity`
- `blendMode`
- subtree compositing through retained render effects

This demo intentionally does not re-prove:

- retained parent / child tree behavior
- base bounds resolution
- `Drawable` content layout behavior
- skin and border styling
- motion inspection

Those remain in the component-focused demos.

## Screen Set

1. opacity inspection
2. blend-mode inspection
3. retained render effects

## Demo Notes

- The opacity screen compares overlapping `Drawable` and `CircleShape` nodes under the same opacity presets.
- The blend-mode screen uses the same paired Drawable and CircleShape overlap fixture as opacity, with a shared blend-mode preset and no demo-local compositing simulation.
- The retained render-effects screen demonstrates the visible subtree compositing differences for normal, alpha-reduced, add, and multiply output.
