# Task 04: Root Compositing Motion, Failure, And State Restore

## Goal

Align the motion runtime and failure behavior for the shared root compositing surface, and make graphics-state restore unconditional around isolated rendering.

## Current implementation notes

- `lib/ui/motion/runtime.lua` currently whitelists `opacity` but not `blendMode` or `shader`.
- The retained isolation path in `lib/ui/core/container.lua` saves canvas, color, shader, blend mode, scissor, and stencil state, but it does not currently guarantee restore if an error is raised during isolated subtree draw.
- Shader validation is currently just `type = "any"` on Drawable and absent on Shape.

## Work items

- Extend motion property validation and application rules for root compositing:
  - `opacity`: continuous numeric
  - `blendMode`: discrete step only
  - `shader`: discrete whole-object replacement only
- Ignore `from`, `duration`, and `easing` for `blendMode` and `shader` motion descriptors in the same way the spec requires.
- Define assignment-time shader validation rules for the supported shader object contract used by this library.
- Differentiate failure stages:
  - configuration failure at assignment time for invalid shader objects
  - capability failure at draw time when shader or compositing requirements cannot be executed
- Wrap isolated rendering and composite-back logic in a protected restore path so the following are always restored even if draw fails:
  - active canvas
  - color
  - shader
  - blend mode
  - scissor
  - stencil test
  - pooled canvas ownership
- Update error text so it no longer refers only to Drawable when the shared root compositor is handling Shape too.

## Implementation notes

- `lib/ui/motion/runtime.lua` still whitelists only `opacity` from the shared root surface. `blendMode` and `shader` need to be added here rather than ad hoc in control-specific motion code.
- Shader validation still does not exist at the schema boundary. Task `04` owns the assignment-time shader contract for both `Drawable` and `Shape`.
- The retained compositor currently restores graphics state only on the success path. Protected restore must also release any pooled canvas before re-raising the error.

## File targets

- `lib/ui/motion/runtime.lua`
- `lib/ui/core/container.lua`
- `lib/ui/core/drawable_schema.lua`
- `lib/ui/core/shape_schema.lua`

## Acceptance criteria

- Motion descriptors can target `opacity`, `blendMode`, and `shader` on both `Drawable` and `Shape`.
- Discrete-step semantics are enforced for `blendMode` and `shader`.
- Invalid shader values fail at assignment time with no fallback or prior-value retention.
- Draw-time compositor failures restore all graphics state before re-raising the error.
