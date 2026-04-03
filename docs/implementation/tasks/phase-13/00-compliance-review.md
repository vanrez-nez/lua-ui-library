# Phase 13 Compliance Review

Source under review: `lib/ui/render/` and the existing draw cycle in `lib/ui/core/drawable.lua`

Task-set authority:

- `docs/spec/ui-styling-spec.md` §6, §7, §8, §9, §11A are authoritative for all paint behavior, paint order, and geometry contracts.

Primary findings:

1. No styling paint pipeline exists in the current codebase.
   Spec anchors: `ui-styling-spec.md §11A`, `ui-styling-spec.md §6`, `ui-styling-spec.md §7`
   Problem: `lib/ui/render/` does not contain a `styling.lua` file. No module currently implements background, border, or shadow painting based on the flat styling properties introduced in Phase 12. The draw cycle in `drawable.lua` calls `_draw_control` for control content but has no hook for styled backgrounds or borders.
   Required addition: create `lib/ui/render/styling.lua` with `Styling.draw` as the single public entry point.

2. No corner radius overflow protection exists anywhere.
   Spec anchor: `ui-styling-spec.md §8`
   Problem: corner radius values set on a node may exceed half the node's bounds (for example, `cornerRadiusTopLeft = 200` on a 100×100 node). No code currently scales radii proportionally to prevent overlap or rendering artifacts. Schema validation (Phase 12) deliberately does not check this because bounds are not known at assignment time.
   Required addition: implement the proportional scale-down algorithm in the styling renderer, computed per draw call from the current bounds.

3. No background painting exists based on the new flat styling properties.
   Spec anchor: `ui-styling-spec.md §6.3`, `ui-styling-spec.md §6.4`, `ui-styling-spec.md §6.5`
   Problem: existing background painting in the library is skin-token-driven and lives inside `_draw_control` for specific control types. No general-purpose background renderer reads `backgroundColor`, `backgroundGradient`, or `backgroundImage` from the node's property table.
   Required addition: implement all three background source variants in the styling renderer with correct source selection priority.

4. No general-purpose border painter exists.
   Spec anchor: `ui-styling-spec.md §7.2`, `ui-styling-spec.md §7.4`
   Problem: border painting in the current library is absent or limited to specific control types via skin tokens. No code reads `borderWidthTop` through `borderWidthLeft` and paints center-aligned per-side borders with LÖVE's line style and join settings.
   Required addition: implement per-side border painting with full line style, join, and miter limit support.

5. Shadow painting is absent.
   Spec anchor: `ui-styling-spec.md §9`
   Problem: no shadow rendering exists in the current library. Neither outer shadow nor inset shadow has an implementation path. The canvas pool from Phase 8 exists and is available, but it is not used for shadow blur.
   Required addition: implement outer and inset shadow rendering using the canvas pool for blur passes.

6. No paint order enforcement exists for the new styling layer.
   Spec anchor: `ui-styling-spec.md §11A`
   Problem: the draw cycle in `drawable.lua` does not have a slot for styling paint before control content. Without explicit ordering, outer shadows could end up on top of background, or inset shadows could be painted before borders.
   Required addition: `Styling.draw` must enforce the sequence outer shadow → background → border → inset shadow internally. Wiring into the draw cycle is covered by Phase 14.

Secondary notes:

- `lib/ui/render/canvas_pool.lua` exists and is usable for shadow blur offscreen passes. Its API should be reviewed before the shadow task to confirm acquire and release patterns.
- The `graphics` adapter used elsewhere in the library wraps `love.graphics.*` calls. All paint operations in `styling.lua` must go through this adapter, not call LÖVE directly.
- No test or demo currently exercises the new styling properties visually. Acceptance verification in task `08-acceptance.md` will require a LÖVE runtime to confirm pixel-level output.
- `reference/color.lua` contains a `lerp` function and gamma conversion algorithms. Only the `lerp` arithmetic may be ported — no import of the reference module.
