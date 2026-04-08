# Task 08: Shape Primitive Integration And Fill Motion

## Goal

Wire the new fill-source renderer into all concrete shapes and align the motion surface for shape-owned fill props with the spec contract.

## Current implementation notes

- The concrete shape classes duplicate the same flat-color fill and stroke plumbing today.
- `lib/ui/motion/runtime.lua` does not currently recognize any of the new fill-source props as motion-capable properties.
- Circle stroke rendering already contains special dashed-seam logic that must survive any refactor.

## Work items

- Refactor the concrete shape draw methods so each shape contributes only its geometry-specific data:
  - local silhouette points
  - special stroke behavior where necessary, especially the circle dashed seam logic
- Route shared fill resolution and rendering through the new shape fill renderer from task 07.
- Keep the `Shape` base class free of child-node composition and styling behavior.
- Extend the motion runtime for shape-owned fill props:
  - `fillColor`: continuous color
  - `fillOpacity`: continuous numeric
  - `fillGradient` colors: continuous per-stop color interpolation
  - `fillTexture`: discrete whole-object replacement
  - `fillOffsetX`: continuous numeric
  - `fillOffsetY`: continuous numeric
  - `fillAlignX`: discrete step only
  - `fillAlignY`: discrete step only
  - `fillRepeatX`: not motion-capable
  - `fillRepeatY`: not motion-capable
- Preserve the rule that motion affects property values, not the fill-source priority algorithm itself.

## Implementation notes

- `RectShape`, `TriangleShape`, and `DiamondShape` currently duplicate the same fill/stroke setup. `CircleShape` shares that duplication plus dashed-seam correction that must survive the refactor.
- Keep `Shape` itself leaf-only and styling-free. The integration point is the shared fill resolver / renderer, not new child composition or styling behavior in `Shape`.
- `lib/ui/motion/runtime.lua` still rejects all fill-source props today. Add only the motion-capable props documented here; `fillRepeatX` and `fillRepeatY` must remain rejected.

## File targets

- `lib/ui/shapes/rect_shape.lua`
- `lib/ui/shapes/circle_shape.lua`
- `lib/ui/shapes/triangle_shape.lua`
- `lib/ui/shapes/diamond_shape.lua`
- `lib/ui/core/shape.lua`
- `lib/ui/motion/runtime.lua`

## Acceptance criteria

- All concrete shapes use the same shared fill-source pipeline.
- Circle dashed stroke behavior still works after the refactor.
- Supported fill props can be targeted by motion with the required interpolation rules.
- `fillRepeatX` and `fillRepeatY` remain rejected as motion properties.
