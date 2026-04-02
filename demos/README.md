# Demos Plan

## Purpose

This document defines the new demo implementation plan under `demos/`.

The demo system must be:

- component-centered
- behavior-centered
- isolated
- progressive in dependencies
- traceable to current spec contracts

The implementation target is `demos/`.
`test/` is now free for future rebuilt runnable harnesses, but the planning and structure definition belongs in `demos/`.

Primary authority:

- [UI Library Specification](../docs/spec/ui-library-spec.md)
- [UI Foundation Specification](../docs/spec/ui-foundation-spec.md)
- [UI Controls Specification](../docs/spec/ui-controls-spec.md)
- [UI Graphics Specification](../docs/spec/ui-graphics-spec.md)
- [UI Motion Specification](../docs/spec/ui-motion-spec.md)

Reference inputs:

- `docs/implementation/tasks/*/demo-and-acceptance.md`
- `_test/` historical harnesses
- `demos/rules.md`

## Rules

Each demo should:

- own one component or one tightly coupled compound component
- validate one clear contract surface
- avoid mixing unrelated systems
- expose observable acceptance results
- use only real public constructors and documented props

Each demo should not:

- be phase-driven
- be a generic “foundation” or “graphics” bucket
- behave like a kitchen-sink showcase
- imply undocumented helper APIs

## Progressive Dependency Order

The demos should still be progressive, but the unit of progression is the component, not the phase:

1. low-level retained primitives used by many later demos
2. standalone presentational primitives
3. simple interactive controls
4. coordinated compound controls
5. overlay controls
6. cross-cutting motion coverage

## Planned Demo Set

### 01-container

Primary components:

- `Container`

Should test:

- retained-tree parenting
- local versus world bounds
- visibility
- width/height sizing
- percentage sizing against parent
- min/max clamp behavior
- zero-size edge behavior

Should expose:

- resolved bounds
- parent/child relationship inspection

### 02-drawable

Primary components:

- `Drawable`

Should test:

- `alignX` and `alignY`
- padding and margin
- opacity
- skin
- blend mode
- mask
- motion

Should expose:

- assigned bounds versus content box
- aligned content result for active alignment cases
- stored visual-surface props that are stable on `Drawable` even when later render systems are still deferred
- motion requests and resolved visual-state writes for harness-driven motion inspection

Should not retest:

- retained-tree parenting already covered by `01-container`
- local versus world bounds already covered by `01-container`
- base width and height sizing already covered by `01-container`
- percentage sizing already covered by `01-container`
- clamp behavior already covered by `01-container`
- visibility behavior already covered by `01-container`

### 03-stage

Primary components:

- `Stage`

Should test:

- base scene layer versus overlay layer
- reverse draw-order target resolution
- no-target behavior
- two-pass update/draw contract
- layer precedence independent of cross-layer `zIndex`

Should expose:

- resolved hit target
- active layer
- guarded two-pass failure path

### 04-row

Primary components:

- `Row`

Should test:

- main-axis ordering
- gap behavior
- cross-axis alignment
- fill/content/fixed sizing combinations
- overflow behavior
- wrap behavior if part of current `Row` contract

Should expose:

- child order
- resolved child sizes

### 05-column

Primary components:

- `Column`

Should test:

- vertical sequencing
- gap behavior
- cross-axis alignment
- content-height behavior
- fill/content/fixed sizing combinations

Should expose:

- resolved child sizes
- total content height

### 06-flow

Primary components:

- `Flow`

Should test:

- reading-order placement
- wrapping to additional rows
- last-row behavior
- overflow behavior when wrapping is disabled

Should expose:

- item positions
- row breaks

### 07-safe-area-container

Primary components:

- `SafeAreaContainer`

Should test:

- safe-area-aware insetting
- resize and safe-area change re-evaluation
- child bounds inside safe-area region

Should expose:

- viewport bounds
- safe-area bounds
- resolved inset child bounds

### 08-scrollable-container

Primary components:

- `ScrollableContainer`

Should test:

- viewport clipping
- scroll extents
- vertical and horizontal scrolling where supported
- nested scroll ownership
- momentum and overscroll where implemented

Should expose:

- scroll offsets
- content extent
- visible viewport

### 09-texture

Primary components:

- `Texture`

Should test:

- intrinsic dimensions
- valid source construction
- deterministic failure for invalid backing source

Should expose:

- source identity
- intrinsic size

### 10-atlas

Primary components:

- `Atlas`

Should test:

- region registration
- region lookup
- invalid region data failure
- region metadata consistency against the backing texture

Should expose:

- registered region names
- region coordinates and sizes

### 11-sprite

Primary components:

- `Sprite`

Should test:

- atlas-backed region resolution
- direct texture-region construction where supported
- intrinsic sprite dimensions from region data
- clipped/out-of-bounds region behavior if the current graphics spec allows a warning/fallback path

Should expose:

- source texture
- resolved region
- intrinsic sprite size

### 12-image

Primary components:

- `Image`

Should test:

- full-texture rendering
- sprite-backed rendering
- `contain`, `cover`, and `stretch`
- alignment inside its assigned box
- sampling mode behavior where visible

Should expose:

- source type
- resolved draw region
- fit mode

### 13-text

Primary components:

- `Text`

Should test:

- `font`
- `fontSize`
- `lineHeight`
- `textAlign`
- `textVariant`
- wrapping with and without `maxWidth`
- explicit newline measurement
- intrinsic remeasurement after content change
- deterministic invalid font and invalid `lineHeight` handling

Should expose:

- measured width/height
- pass/fail checks for wrap and line-height behavior

### 14-button

Primary components:

- `Button`

Should test:

- content slot behavior
- pointer activation
- keyboard activation
- disabled suppression
- negotiated pressed state
- focused versus hovered versus pressed behavior

Should expose:

- activation count
- effective pressed state
- focus owner

### 15-checkbox

Primary components:

- `Checkbox`

Should test:

- checked, unchecked, and indeterminate behavior
- negotiated checked state
- toggle order
- disabled handling
- label/description content structure where applicable

Should expose:

- requested checked state
- effective checked state

### 16-switch

Primary components:

- `Switch`

Should test:

- checked-state behavior
- tap behavior
- drag-threshold and snap behavior
- disabled handling

Should expose:

- requested checked state
- effective checked state

### 17-radio-group

Primary components:

- `Radio`
- `RadioGroup`

Reason for pairing:

- `Radio` is not meaningful without `RadioGroup` coordination in this spec revision

Should test:

- registration
- single-value coordination
- roving focus
- disabled option behavior
- traversal edge behavior
- invalid duplicate value failure

Should expose:

- current value
- focused radio

### 18-slider

Primary components:

- `Slider`

Should test:

- clamping
- stepping
- pointer dragging
- track activation
- orientation behavior if implemented

Should expose:

- requested value
- effective clamped value
- normalized ratio

### 19-progress-bar

Primary components:

- `ProgressBar`

Should test:

- determinate progress
- indeterminate mode
- orientation behavior if implemented
- range normalization

Should expose:

- effective value
- effective normalized ratio
- indeterminate state

### 20-text-input

Primary components:

- `TextInput`

Should test:

- controlled value
- controlled selection
- placeholder rules
- submit behavior
- read-only versus disabled behavior
- composition plumbing as observable logical behavior

Should expose:

- current value
- current selection
- focus owner

### 21-text-area

Primary components:

- `TextArea`

Should test:

- multiline editing behavior
- internal scrolling
- wrap behavior
- newline insertion
- scroll behavior when wrapping is disabled
- read-only versus disabled behavior

Should expose:

- current value
- current selection
- scroll offsets

### 22-tabs

Primary components:

- `Tabs`

Should test:

- trigger/panel mapping
- active value behavior
- roving focus
- manual activation
- disabled-trigger skipping
- invalid value recovery

Should expose:

- active tab value
- focused trigger

### 23-select

Primary components:

- `Select`
- `Option`

Reason for pairing:

- `Option` is meaningful only as a coordinated descendant of `Select`

Should test:

- single-select behavior
- multi-select behavior
- placeholder rendering
- summary rendering
- popup open/close
- disabled option behavior
- duplicate option failure path

Should expose:

- effective selection
- open state
- focused option

### 24-modal

Primary components:

- `Modal`

Should test:

- negotiated open state
- backdrop dismissal behavior
- escape dismissal behavior
- focus trapping
- focus restoration
- overlay-layer mounting

Should expose:

- open state
- focus owner
- restoration target

### 25-alert

Primary components:

- `Alert`

Should test:

- required title and actions
- optional message
- `initialFocus`
- alert-specific validation failures
- inherited modal behavior that remains part of the public alert contract

Should expose:

- focused action
- open state
- guarded failure results

### 26-notification

Primary components:

- `Notification`

Should test:

- open/close behavior
- explicit dismissal
- auto-dismiss timing
- stack participation where implemented
- placement behavior

Should expose:

- open state
- dismissal mode
- resolved placement

### 27-tooltip

Primary components:

- `Tooltip`

Should test:

- trigger modes: hover, focus, manual
- anchored placement
- fallback placement near edges
- open-state behavior

Should expose:

- open state
- resolved placement
- anchor region summary

### 28-motion

Primary components:

- motion integration across documented component surfaces

Should test:

- `motionPreset`
- explicit `motion`
- valid target restrictions
- valid property restrictions
- adapter boundary behavior
- interruption behavior where observable

Minimum surfaces to cover:

- one control surface
- one overlay surface
- one value-driven surface
- one graphics-capable surface

Should expose:

- active phase
- active target
- active properties

## Component Ownership Summary

Each component should have one primary demo home:

- `Container`: `01-container`
- `Drawable`: `02-drawable`
- `Stage`: `03-stage`
- `Row`: `04-row`
- `Column`: `05-column`
- `Flow`: `06-flow`
- `SafeAreaContainer`: `07-safe-area-container`
- `ScrollableContainer`: `08-scrollable-container`
- `Texture`: `09-texture`
- `Atlas`: `10-atlas`
- `Sprite`: `11-sprite`
- `Image`: `12-image`
- `Text`: `13-text`
- `Button`: `14-button`
- `Checkbox`: `15-checkbox`
- `Switch`: `16-switch`
- `Radio` and `RadioGroup`: `17-radio-group`
- `Slider`: `18-slider`
- `ProgressBar`: `19-progress-bar`
- `TextInput`: `20-text-input`
- `TextArea`: `21-text-area`
- `Tabs`: `22-tabs`
- `Select` and `Option`: `23-select`
- `Modal`: `24-modal`
- `Alert`: `25-alert`
- `Notification`: `26-notification`
- `Tooltip`: `27-tooltip`
- motion integration: `28-motion`

## Rebuild Order

Recommended implementation order inside `demos/` and later `test/` harnesses:

1. `01-container`
2. `02-drawable`
3. `03-stage`
4. `04-row`
5. `05-column`
6. `06-flow`
7. `07-safe-area-container`
8. `08-scrollable-container`
9. `09-texture`
10. `10-atlas`
11. `11-sprite`
12. `12-image`
13. `13-text`
14. `14-button`
15. `15-checkbox`
16. `16-switch`
17. `17-radio-group`
18. `18-slider`
19. `19-progress-bar`
20. `20-text-input`
21. `21-text-area`
22. `22-tabs`
23. `23-select`
24. `24-modal`
25. `25-alert`
26. `26-notification`
27. `27-tooltip`
28. `28-motion`

## Non-Goals

This plan intentionally does not:

- preserve old phase demo grouping
- use generic buckets like “Foundation” or “Graphics” as demo homes
- treat `_test/` as the current truth
- merge unrelated controls into a single large acceptance harness

`_test/` is historical reference only.
