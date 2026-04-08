# Task 00: Compliance Review

## Goal

Produce a concrete gap analysis between the phase-20 spec patches and the current `lib/ui` implementation before modifying runtime behavior.

## Current implementation notes

- `lib/ui/core/shape_schema.lua` exposes `fillColor`, `fillOpacity`, stroke props, and `opacity`, but not `shader`, `blendMode`, `fillGradient`, `fillTexture`, `fillRepeat*`, `fillOffset*`, or `fillAlign*`.
- `lib/ui/core/drawable_schema.lua` exposes `shader`, `opacity`, `blendMode`, `mask`, background gradient, and background image props, but `blendMode` is currently an unvalidated string and shader has no explicit contract validation.
- `lib/ui/core/container.lua` resolves retained effects through `resolve_node_effects`, but shader and blend mode are still gated on `_ui_drawable_instance`, and `mask` is mixed into the same record even though the spec keeps it outside the shared root-compositing surface.
- `lib/ui/shapes/rect_shape.lua`, `circle_shape.lua`, `triangle_shape.lua`, and `diamond_shape.lua` duplicate flat-color fill and stroke setup with no shared fill-source pipeline.
- `lib/ui/render/styling.lua` already owns gradient mesh generation, texture and sprite draw-source resolution, tiling, alignment, and stencil clipping for rounded rectangles.
- `lib/ui/motion/runtime.lua` does not currently accept `blendMode`, `shader`, `fillColor`, `fillTexture`, `fillOffset*`, or `fillAlign*` as motion properties.

## Status key

- `satisfied`: the current repo already has the required contract or helper.
- `partial`: some semantics exist, but the surface, ownership, or failure behavior still diverges from the patch.
- `absent`: no current implementation path exists.

## Requirement Matrix

### Shared Root Compositing And Boundaries

| Requirement | Concrete file(s) | Status | Notes / downstream owner |
|---|---|---|---|
| Shared root surface is `opacity`, `shader`, `blendMode`; `mask` stays outside it | `lib/ui/core/drawable_schema.lua`, `lib/ui/core/shape_schema.lua`, `lib/ui/core/container.lua` | partial | `Drawable` still owns `mask`, and `container.lua` still mixes `mask` into the same retained effects record. Tasks `02-04` must split the shared record from Drawable-only mask handling. |
| Root compositing props are direct instance props and not styling props | `lib/ui/core/drawable_schema.lua`, `lib/ui/core/shape_schema.lua` | partial | `Drawable` already treats `shader` / `opacity` / `blendMode` as direct props. `Shape` still only exposes `opacity`. Task `02` extends the shared surface without introducing styling or skinning. |
| Capability declaration is class-level, not family-flag inference | `lib/ui/core/drawable.lua`, `lib/ui/core/shape.lua`, `lib/ui/core/container.lua` | absent | `container.lua` still branches on `_ui_drawable_instance` / `_ui_shape_instance`. Task `02` adds the class record; task `03` consumes it. |
| Explicit shared default state is `{ opacity = 1, blendMode = "normal", shader = nil }` | `lib/ui/render/graphics_validation.lua`, `lib/ui/core/container.lua` | partial | Task `01` introduces the normalized `blendMode` enum and the `"normal"` default constant, but `container.lua` still treats `nil` as the retained fast path. Task `03` must resolve an explicit compositing record without regressing the fast path. |
| Root shader is post-composite node effect | `lib/ui/core/container.lua` | partial | The retained isolation path already applies shader after subtree draw for `Drawable`, but `Shape` does not yet adopt the surface and assignment-time shader validation is still missing. Tasks `02-04`. |
| Root blend mode is applied when compositing back into the immediate parent target | `lib/ui/core/container.lua` | partial | The isolated subtree path already composites back with blend state, but the reference frame is implicit, the state record is Drawable-specific, and `"normal"` is not yet a no-op fast path. Task `03`. |
| Root opacity is whole-node, post-composite alpha | `lib/ui/core/container.lua`, `spec/shape_opacity_spec.lua` | partial | The retained opacity path is already semantically correct for `Drawable` and `Shape`, but it is still resolved through family-specific branching instead of the shared capability record. Tasks `02-03`. |
| Graphics state save/restore is unconditional around compositing changes | `lib/ui/core/container.lua` | absent | State is restored on the success path only. Errors during isolated draw can still leak canvas, shader, blend, scissor, stencil, color, or pooled canvas ownership. Task `04`. |
| Invalid shader assignment fails at assignment time | `lib/ui/core/drawable_schema.lua`, `lib/ui/core/shape_schema.lua` | absent | `Drawable.shader` is still `type = "any"` and `Shape` still rejects `shader` entirely. Task `04`. |
| Invalid `blendMode` assignment fails at assignment time | `lib/ui/render/graphics_validation.lua`, `lib/ui/core/drawable_schema.lua` | satisfied | Task `01` now normalizes accepted values to `"normal"`, `"add"`, `"subtract"`, `"multiply"`, and `"screen"`. Shape adoption remains task `02`. |

### Shared Graphics Source Contracts And Helper Reuse

| Requirement | Concrete file(s) | Status | Notes / downstream owner |
|---|---|---|---|
| Gradient value contract is shared and plain-object-based | `lib/ui/render/graphics_validation.lua`, `lib/ui/core/drawable_schema.lua` | satisfied | Task `01` extracted the validator out of `drawable_schema.lua`. Task `05` must attach the same validator to `Shape.fillGradient`. |
| `Texture` and `Sprite` are shared graphics source objects | `lib/ui/graphics/texture.lua`, `lib/ui/graphics/sprite.lua` | satisfied | The object model already exists and remains the source of truth for fill/background reuse. |
| `Sprite` effective dimensions are always its sub-region dimensions | `lib/ui/graphics/sprite.lua`, `lib/ui/render/graphics_source.lua` | satisfied | `Sprite` still clips to texture bounds with a warning and stores width/height from the clipped region. Task `06` must preserve that placement basis. |
| Invalid `Texture | Sprite` source type fails immediately | `lib/ui/render/graphics_validation.lua`, `lib/ui/core/drawable_schema.lua` | partial | Task `01` extracted the shared validator for `backgroundImage`, but `Shape.fillTexture` does not exist yet. Task `05` must reuse the same validator rather than re-implement it. |
| Shared intrinsic-dimension access exists for `Texture` and `Sprite` | `lib/ui/graphics/texture.lua`, `lib/ui/graphics/sprite.lua`, `lib/ui/render/graphics_source.lua` | satisfied | Task `01` added neutral intrinsic-dimension helpers so later shape placement code does not read `Drawable` background internals directly. |
| Shared draw-source resolution exists for `Texture` and `Sprite`, including sprite quads | `lib/ui/render/graphics_source.lua`, `lib/ui/render/styling.lua` | satisfied | Task `01` removed the Drawable-private copy from `styling.lua`. Task `06` should consume this helper for shape fill source resolution. |
| Draw-time unusable texture detection exists | `lib/ui/render/graphics_source.lua`, `lib/ui/render/styling.lua` | absent | Current source resolution still silently returns `nil` when the backing drawable is unavailable. Task `07` must hard-fail for active shape fill sources instead of sampling undefined data or falling back. |
| Unsupported renderer path for gradient / textured silhouette fill hard-fails | `lib/ui/render/styling.lua`, `lib/ui/shapes/draw_helpers.lua` | absent | Styling has rounded-rect-only paths. No current shape renderer can raise the required hard failure because the shape fill surface does not exist yet. Tasks `06-07`. |

### Shape-Owned Fill Surface

| Requirement | Concrete file(s) | Status | Notes / downstream owner |
|---|---|---|---|
| `Shape` keeps its own geometry, stroke, and hit testing without becoming `Drawable` | `lib/ui/core/shape.lua`, `lib/ui/shapes/*.lua` | satisfied | The current primitive boundary is already correct. Later tasks must preserve it while adding graphics capabilities. |
| `Shape` adopts root `shader` and `blendMode` without adopting `mask` | `lib/ui/core/shape_schema.lua`, `lib/ui/core/shape.lua` | absent | `Shape` still rejects `shader`, `blendMode`, `mask`, and all `background*` props. Task `02`. |
| Fill-source prop surface (`fillGradient`, `fillTexture`, `fillRepeat*`, `fillOffset*`, `fillAlign*`) exists as direct instance props | `lib/ui/core/shape_schema.lua` | absent | Task `05`. |
| Active fill-source priority is `fillTexture` > `fillGradient` > `fillColor` | `lib/ui/core/shape.lua`, new shared fill resolver module(s) | absent | No fill-source resolver exists today. Task `05`. |
| Placement resolves from shape-local bounds AABB | new shape fill resolver module(s) | absent | Current shapes only emit flat-color polygon fill with no source-placement semantics. Task `06`. |
| Stretch mode / tiling mode / align / offset semantics exist | `lib/ui/render/styling.lua` as reference only | absent | Drawable background placement is useful reference code, but it is not shape-local and cannot be reused verbatim. Task `06`. |
| Gradient fill spans local bounds with horizontal/vertical mapping | new shape fill resolver / renderer | absent | Styling already has a gradient mesh path, but it is bounds-rectangle paint, not shape-local fill. Tasks `06-07`. |
| Non-flat fill is clipped to the silhouette and stroke draws after fill | `lib/ui/shapes/draw_helpers.lua`, `lib/ui/shapes/*.lua` | absent | Flat-color fill exists; gradient/texture fill plus silhouette clipping do not. Task `07`, then `08` for concrete-shape integration. |
| Shape fill stays out of styling, theming, and skinning | `lib/ui/core/shape_schema.lua`, `lib/ui/core/shape.lua` | satisfied | Current exclusions already enforce this. Tasks `05-09` must preserve that boundary. |
| Shared fill pipeline is used across all concrete shapes | `lib/ui/shapes/rect_shape.lua`, `lib/ui/shapes/circle_shape.lua`, `lib/ui/shapes/triangle_shape.lua`, `lib/ui/shapes/diamond_shape.lua` | absent | Fill and stroke setup is currently duplicated across all concrete shape classes. Task `08`. |

### Motion And Verification Surface

| Requirement | Concrete file(s) | Status | Notes / downstream owner |
|---|---|---|---|
| `Drawable` and `Shape` motion can target root `opacity`, `blendMode`, and `shader` | `lib/ui/motion/runtime.lua` | absent | Only `opacity` is currently whitelisted from the shared root surface. Task `04`. |
| Shape fill motion matches the spec contract | `lib/ui/motion/runtime.lua` | absent | No fill-surface props are motion-capable yet because the props themselves do not exist. Task `08`. |
| Automated specs cover shared root compositing and shape fill behavior | `spec/` | partial | Existing specs already cover `Drawable` root effects, `Shape` opacity, shape surface, and background source resolution. Tasks `04`, `07`, and `09` extend them for the new surface and failure paths. |

## Semantically Correct But Previously Drawable-Private

- The retained opacity compositor in `lib/ui/core/container.lua` is already the proof that `Shape` can share root compositing without becoming a `Drawable`.
- The gradient object contract and `Texture | Sprite` source contract were already semantically correct in `lib/ui/core/drawable_schema.lua`; task `01` extracted them into `lib/ui/render/graphics_validation.lua`.
- The sprite-region draw-source plumbing, intrinsic dimensions, alignment, offset, and tiling behavior in `lib/ui/render/styling.lua` were already semantically correct for drawable backgrounds; task `01` extracted the source-resolution part into `lib/ui/render/graphics_source.lua`.
- `lib/ui/graphics/sprite.lua` already satisfies the spec-sensitive region behavior: out-of-bounds regions clip with a warning, and non-positive dimensions fail hard.

## Reuse Targets

- `lib/ui/render/graphics_validation.lua` is the shared home for root opacity validation, root blend-mode validation, gradient validation, numeric source offsets, source alignment enums, and `Texture | Sprite` source validation.
- `lib/ui/render/graphics_source.lua` is the shared home for intrinsic dimensions and draw-source resolution for `Texture` and `Sprite`.
- `lib/ui/render/styling.lua` remains the reference implementation for gradient mesh generation, tiling loops, alignment math, and stencil-state management. Later shape tasks should extract only the geometry-agnostic parts and avoid importing Drawable styling ownership into `Shape`.
- `lib/ui/core/container.lua` already owns the retained canvas stack, state save/restore helpers, and composite-back flow that tasks `03-04` must generalize.
- `lib/ui/shapes/draw_helpers.lua` and the concrete shape classes are the current flat-color and stroke entry points that tasks `07-08` must replace with a shared non-flat fill pipeline.

## Remaining Spec-Sensitive Failure Gaps

- Invalid `blendMode` assignment is now covered at assignment time by the shared validator from task `01`.
- Invalid shader assignment is still missing entirely.
- Unsupported renderer path for shape gradient or texture fill is still missing entirely.
- Draw-time unusable texture-source detection is still missing entirely.
- Guaranteed graphics-state restore on error during isolated rendering is still missing entirely.

## Downstream Notes Applied

- Short implementation-notes sections have been added to tasks `01` through `09` so the remaining work can consume the review findings directly.

## Work items

- Build a requirement-to-code matrix for every normative item in the three patch documents.
- Identify which requirements are already satisfied, partially satisfied, or absent in the current code.
- Call out behavior that is already semantically correct but implemented under Drawable-specific naming or branching.
- Record the files that should be reused instead of duplicated, especially schema validation, draw-source resolution, stencil helpers, and retained isolation helpers.
- Record the spec-sensitive failure paths that do not currently exist:
  - invalid `blendMode` assignment
  - invalid shader assignment
  - unsupported renderer path for shape gradient or texture fill
  - draw-time unusable texture source detection
  - guaranteed graphics-state restore on error during isolated rendering

## Deliverable

Add a short implementation notes section to each downstream task in this phase that references the relevant gaps from this review, so later work does not re-discover them ad hoc.

## Acceptance criteria

- Every requirement from the three incident specs is mapped to a concrete file or module in `lib/ui`.
- The review distinguishes shared-capability work from shape-owned fill work.
- The review explicitly notes that `mask` stays Drawable-only and out of the shared root-compositing surface.
- The review explicitly notes that `Shape` must not join the styling or skinning system as part of this phase.
