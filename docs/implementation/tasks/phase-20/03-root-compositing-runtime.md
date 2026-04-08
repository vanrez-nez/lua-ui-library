# Task 03: Root Compositing Runtime

## Goal

Generalize the retained compositor so `Drawable` and `Shape` flow through the same root compositing state record and canonical compositing order.

## Current implementation notes

- `lib/ui/core/container.lua` already performs subtree isolation with canvases, shader application, opacity modulation, and blend-mode compositing.
- `resolve_node_effects` currently reads shader and blend mode only for drawables and keeps `mask` in the same effect record.
- Non-default blend mode is represented implicitly as non-`nil`; `"normal"` is not modeled as an explicit default state.

## Work items

- Replace family-specific effect resolution with capability-record-driven resolution.
- Split the shared root compositing state from Drawable-only extras:
  - shared state: `opacity`, `shader`, `blendMode`
  - separate Drawable-only handling: `mask`
- Normalize state resolution so the runtime always resolves an explicit compositing record, even when it ends up matching the default fast path.
- Preserve the canonical order:
  1. node-local paint result
  2. descendant contribution
  3. root shader
  4. root opacity
  5. composite into the immediate parent target using root blend mode
- Preserve nested isolation semantics by continuing to use the existing recursive canvas stack behavior in `container.lua`, but make the code and naming reflect the composition-target-stack model from the spec.
- Treat `"normal"` blend mode and `shader = nil` as the fast path with no isolation or state mutation overhead.
- Keep conservative opacity isolation if needed for correctness, but do not regress the required default-state fast path.

## Implementation notes

- `lib/ui/core/container.lua` already has the retained canvas stack, state save/restore helpers, and composite-back flow. The missing work is capability-record-driven resolution plus splitting `mask` out of the shared state record.
- `resolve_node_effects` currently reads `shader` and `blendMode` only through `_ui_drawable_instance`. Replace that branch with the new class-level capability record instead of adding more family checks.
- Treat explicit `"normal"` exactly like the default fast path: no isolation, no shader install, and no blend-state mutation.

## File targets

- `lib/ui/core/container.lua`
- shared helper module(s) introduced in task 01

## Acceptance criteria

- `Shape` root shader and root blend mode execute through the same retained compositor path as `Drawable`.
- The compositor resolves state from class capability declaration, not from Drawable-vs-Shape special casing.
- `mask` remains outside the shared root compositing state record.
- Nodes in exact default state do not allocate canvases, alter blend state, or install shaders.
