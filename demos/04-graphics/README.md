# 04-graphics

## Goal

Build the focused graphics demo for retained opacity, blend mode, subtree compositing, and texture-backed graphics surfaces.

Primary authority:

- [UI Graphics Specification](../../docs/spec/ui-graphics-spec.md)
- [UI Foundation Specification](../../docs/spec/ui-foundation-spec.md)
- `docs/spec/ui-foundation-spec.md §6.1.2 Drawable`

## Scope

This demo covers the retained graphics surfaces that are shared across the retained scene graph:

- `opacity`
- `blendMode`
- subtree compositing through retained render effects
- `Drawable.backgroundImage`
- `Shape.fillTexture`
- texture source subregions, placement offsets, and shape tiling controls

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
4. Drawable texture background
5. Shape texture fill

## Demo Notes

- The opacity screen compares overlapping `Drawable` and `CircleShape` nodes under the same opacity presets.
- The blend-mode screen uses the same paired Drawable and CircleShape overlap fixture as opacity, with a shared blend-mode preset and no demo-local compositing simulation.
- The retained render-effects screen demonstrates the visible subtree compositing differences for normal, alpha-reduced, add, and multiply output.
- The Drawable texture-background screen demonstrates `backgroundImage` using the labeled grid texture, with source switching between `Texture` and `Sprite` plus alignment and offset controls.
- The Shape texture-fill screen demonstrates `fillTexture` on `RectShape` and `CircleShape`, including source subregions, repeat mode, alignment, and offsets.
