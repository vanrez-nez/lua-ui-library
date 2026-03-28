# UI Foundation Specification

## 1. Version Header

Version: `0.1.1`
Revision type: `additive`
Finalized: `2026-03-27`
Inputs: current `lib/ui` implementation review, LÖVE API review in `docs/research/love-api-related.md`, repository pattern review in `docs/research/repo-ui-patterns/`, and revision decisions captured during specification drafting.

## 2. Changelog Summary

1. Initial publication of the foundation standard for the UI library.

## 3. Glossary

`Component`: A named UI construct with a defined purpose, contract, anatomy, state model, and composition rules.

`Primitive`: A low-level component intended to be composed by other components. A primitive owns structural or behavioral concerns rather than product-specific meaning.

`Runtime primitive`: A non-visual or app-level primitive that participates in lifecycle, scene ownership, or rendering orchestration.

`Consumer`: The application code using this library.

`Node`: A single retained object in the UI tree.

`Tree`: The parent-child structure used for transforms, visibility, event ancestry, focus ancestry, and z-order scoping.

`Root`: A node with no parent in the UI tree. `Stage` is the top runtime root.

`Slot`: A named child position or named subpart within a component contract.

`Variant`: A supported behavioral or presentational mode defined by the component contract.

`Controlled state`: A state value supplied by the consumer and treated as authoritative by the component. The component may request changes through callbacks but must not treat internal mutation as the source of truth.

`Render effect`: A visual operation applied during drawing, such as a shader, mask, opacity modulation, clipping, or isolated compositing.

`Isolation`: Rendering a subtree into an offscreen target before compositing it into its parent.

`Token`: A consumer-supplied theming value such as a color, spacing value, radius, timing value, texture reference, or shader reference.

`Skin asset`: A presentational asset used to draw a component, including textures, atlas regions, quads, shaders, and nine-slice definitions.

`Breakpoint`: A declarative conditional rule keyed to viewport, orientation, or environment constraints.

`Responsive rule`: A declarative rule that modifies measurement, placement, or variant resolution based on environment or parent space.

`Focusable`: A node eligible to receive logical focus.

`Focused`: The node currently owning logical keyboard or text-entry focus within a focus scope.

`Focus scope`: A bounded subtree within which focus traversal is resolved.

`Propagation`: Ordered delivery of an input event through a target path using capture, target, and bubble phases.

`Scroll container`: A node that owns clipping, scroll offsets, scroll state, and scroll input handling for descendant content.

`Safe area`: The unobstructed region reported by the environment and suitable for critical content placement.

## 4. Scope And Domain

This document governs the abstract and non-concrete parts of the UI library: retained structure, rendering behavior, state ownership, event propagation, focus management, responsive layout, runtime orchestration, render effects, and theming.

This document does not define the concrete control contracts in detail. Those are defined in [ui-controls-spec.md](/Users/vanrez/Documents/game-dev/lua-ui-library/docs/spec/ui-controls-spec.md).

This revision owns the following families:

- Foundational primitives: `Container`, `Drawable`
- Layout primitives: `Stack`, `Row`, `Column`, `Flow`, `SafeAreaContainer`
- Scroll primitive: `ScrollableContainer`
- Runtime primitives: `Stage`, `Scene`, `Composer`
- Cross-cutting contracts: event propagation, focus, controlled state, render effects, responsive rules, theming

The library owns rendering behavior, transform composition, event routing, focus semantics, clipping, shader inheritance, controlled state resolution, and the stable theming interface.

The consumer owns business meaning, application state orchestration, scene registration, token values, skin assets, copy, gameplay integration, and unsupported custom rendering behavior outside the defined extension surfaces.

## 5. Design Principles

1. Every UI object must exist as a retained node in a tree rooted at `Stage`.
2. Every interactive component must participate in true event propagation with capture and bubble phases.
3. Every focusable component must support keyboard focus semantics even in mobile-first environments.
4. Presentation must remain separable from behavior.
5. The library must reuse native LÖVE primitives when they satisfy the contract without loss of composability, consistency, or performance.
6. The library must only wrap or re-implement a native primitive when the wrapper provides normalization, expandability, specification compliance, or measurable performance benefit.
7. Unsupported prop combinations must fail deterministically.
8. Effects and shaders must compose through defined inheritance and isolation rules.
9. Layout and scrolling must be invalidation-driven.
10. Z-order must be explicit and local to siblings.
11. Stateful primitives and controls must use consumer-owned controlled state when they expose mutable public state.

## 6. Component Specifications

### 6.1 Foundation Family

#### 6.1.1 Container

**Purpose and contract**

`Container` is the foundational retained node. It owns tree membership, transforms, visibility, event ancestry, focus ancestry, sibling-local z-order, and spatial bounds. `Container` does not own presentation by itself.

`Container` must:

- participate in parent-child composition
- resolve local and world transforms
- expose hit-testable bounds
- participate in event propagation when enabled
- participate in focus ancestry
- support responsive rule resolution
- support explicit sibling-local `zIndex`

**Anatomy**

- `root`: the `Container` instance itself. Required.
- `children`: ordered child nodes. Optional.

**Props and API surface**

- `tag: string | nil`
- `visible: boolean`
- `interactive: boolean`
- `enabled: boolean`
- `focusable: boolean`
- `clipChildren: boolean`
- `zIndex: number`
- `anchorX`, `anchorY: number`
- `pivotX`, `pivotY: number`
- `x`, `y: number`
- `width`, `height: number | "content" | "fill" | percentage`
- `minWidth`, `minHeight`, `maxWidth`, `maxHeight: number | nil`
- `scaleX`, `scaleY: number`
- `rotation: number`
- `skewX`, `skewY: number`
- `breakpoints: table | nil`

**State model**

STATE clean

  ENTRY:
    1. Local measurement and transform caches are current.
    2. World transform and bounds are current.

  TRANSITIONS:
    ON geometry mutation:
      1. Mark local measurement or transform state invalid.
      2. Mark descendant world state invalid where required.
      → dirty

    ON tree mutation:
      1. Update parent-child references.
      2. Mark ordering and world state invalid.
      → dirty

    ON breakpoint resolution change:
      1. Re-resolve responsive inputs.
      2. Mark measurement and transform state invalid.
      → dirty

STATE dirty

  ENTRY:
    1. Cached geometry or transform values are stale.

  TRANSITIONS:
    ON next layout or draw pass:
      1. Resolve responsive inputs.
      2. Resolve measurement.
      3. Resolve local transform.
      4. Resolve world transform from parent state.
      5. Resolve bounds.
      → clean

ERRORS:
  - `width = "content"` on a node with no intrinsic measurement rule → invalid configuration and deterministic failure.
  - Cyclic parenting attempt → invalid configuration and deterministic failure.

**Composition rules**

Sibling order must resolve by:

1. ascending `zIndex`
2. stable insertion order among equal `zIndex` values

Hit testing must resolve in reverse draw order among eligible siblings.

#### 6.1.2 Drawable

**Purpose and contract**

`Drawable` is the first render-capable primitive. It extends `Container` with presentation, content box calculation, and render-effect participation. `Drawable` owns no control-specific behavior by itself.

`Drawable` must:

- define a content box inside its padding
- resolve alignment inside its content box
- participate in the theming and skinning contract
- participate in inherited render effects
- provide isolation hooks when required by the render pipeline

**Anatomy**

- `root`: the drawable node. Required.
- `content box`: the inner rectangle after padding. Required.
- `skin`: the presentational surface resolved from tokens and skin assets. Optional.
- `effects`: local render effects applied before descendant composition. Optional.

**Props and API surface**

- `padding`
- `margin`
- `alignX: "start" | "center" | "end" | "stretch"`
- `alignY: "start" | "center" | "end" | "stretch"`
- `skin`
- `shader`
- `opacity: number`
- `blendMode`
- `mask`

**State model**

STATE render_clean

  ENTRY:
    1. Skin, padding, content alignment, and effect chain are resolved.

  TRANSITIONS:
    ON token change:
      1. Re-resolve presentational inputs.
      → render_dirty

    ON local effect change:
      1. Re-resolve effect chain.
      2. Re-evaluate isolation requirement.
      → render_dirty

STATE render_dirty

  ENTRY:
    1. Presentation or effect data is stale.

  TRANSITIONS:
    ON next draw preparation:
      1. Resolve inherited effect chain.
      2. Resolve local skin assets.
      3. Resolve whether inline drawing is valid.
      4. Resolve whether isolation is required.
      → render_clean

### 6.2 Layout Family

#### 6.2.1 Purpose and contract

Layout primitives place children inside a content box. They own child measurement order, spacing rules, alignment resolution, responsive overrides, and overflow policy. Layout primitives do not own child interaction semantics.

This revision standardizes:

- `Stack`
- `Row`
- `Column`
- `Flow`
- `SafeAreaContainer`

#### 6.2.2 Common props and API surface

- `gap`
- `padding`
- `wrap: boolean`
- `justify`
- `align`
- `responsive`

#### 6.2.3 Common state model

STATE layout_clean

  ENTRY:
    1. Child measurements and placements are current.

  TRANSITIONS:
    ON child addition, removal, size mutation, visibility mutation, or breakpoint change:
      1. Mark layout invalid.
      → layout_dirty

STATE layout_dirty

  ENTRY:
    1. Child measurements or placements are stale.

  TRANSITIONS:
    ON next layout pass:
      1. Resolve own content box.
      2. Resolve each eligible child measurement.
      3. Place children according to layout family rules.
      4. Resolve overflow policy.
      → layout_clean

#### 6.2.4 Family-specific rules

`Stack`

- places children in the same content box
- uses child anchor, alignment, and z-order to resolve overlap
- is the default composition primitive for overlays and layered visuals

`Row`

- places children along the horizontal axis
- resolves cross-axis alignment vertically

`Column`

- places children along the vertical axis
- resolves cross-axis alignment horizontally

`Flow`

- places children in reading order across the primary axis
- wraps to a new line when wrapping is enabled and remaining width is insufficient
- is intended for fluid responsive placement, not strict grid semantics

`SafeAreaContainer`

- measures against safe area bounds instead of full viewport bounds
- is opt-in

### 6.3 Scroll Primitive

#### 6.3.1 ScrollableContainer

**Purpose and contract**

`ScrollableContainer` is a structural primitive that clips descendant content and exposes scroll state. It is not a layout family peer of `Row` or `Column`, though it may host layout containers as descendants.

`ScrollableContainer` must:

- own a viewport rectangle
- own content extent measurement
- own scroll offsets
- clip descendant drawing and hit testing to the viewport
- capture and interpret scroll input
- support touch, wheel, keyboard, and programmatic scrolling
- support configurable direct drag and configurable momentum behavior

**Anatomy**

- `root`: the scroll node. Required.
- `viewport`: the visible region. Required.
- `content`: the scrollable child subtree. Required.
- `scrollbars`: optional visual indicators and drag handles.

**Props and API surface**

- `scrollXEnabled: boolean`
- `scrollYEnabled: boolean`
- `momentum: boolean`
- `momentumDecay: number`
- `overscroll: boolean`
- `scrollStep: number`
- `showScrollbars: boolean`

**State model**

STATE idle

  ENTRY:
    1. Scroll offset is stable.
    2. No active gesture owns the container.

  TRANSITIONS:
    ON pointer drag start within viewport:
      1. Capture scroll gesture.
      2. Record initial pointer and offset.
      → dragging

    ON wheel input:
      1. Adjust scroll offset by configured step.
      2. Clamp or overscroll according to policy.
      → idle

    ON keyboard scroll command while focused:
      1. Adjust scroll offset by configured step or page amount.
      2. Clamp or overscroll according to policy.
      → idle

STATE dragging

  ENTRY:
    1. Active pointer owns the scroll gesture.

  TRANSITIONS:
    ON pointer move:
      1. Update offset from pointer delta.
      2. Update velocity estimate when momentum is enabled.
      → dragging

    ON pointer release with momentum disabled:
      1. Clamp final offset.
      → idle

    ON pointer release with momentum enabled:
      1. Seed inertial velocity.
      → inertial

STATE inertial

  ENTRY:
    1. Offset updates from retained velocity.

  TRANSITIONS:
    ON frame update:
      1. Integrate velocity.
      2. Apply decay.
      3. Clamp or resolve overscroll return.
      4. If velocity reaches stop threshold, finish.
      → idle

### 6.4 Runtime Family

#### 6.4.1 Stage

**Purpose and contract**

`Stage` is the runtime root for the UI tree. It owns viewport bounds, safe area bounds, root-level event dispatch entry, and root-level environment synchronization with LÖVE.

`Stage` must:

- reflect current viewport dimensions
- expose full viewport bounds
- expose safe area bounds
- provide the root event boundary
- provide the root focus scope

#### 6.4.2 Scene

**Purpose and contract**

`Scene` is a runtime primitive representing a screen-level subtree with lifecycle hooks. `Scene` is not a control primitive.

`Scene` must:

- own a full-screen or stage-sized subtree by default
- expose creation, enter, leave, and destruction hooks
- integrate with `Composer`

#### 6.4.3 Composer

**Purpose and contract**

`Composer` owns scene registration, scene caching, scene transition sequencing, and scene activation.

`Composer` must:

- register scenes by stable name
- activate one current scene at a time in the base scene layer
- expose and manage the active overlay layer above the base scene layer
- support transitions
- support deterministic scene lifecycle sequencing
- forward root input into the active runtime subtree

**State model**

STATE stable

  ENTRY:
    1. Exactly one current scene is active in the base scene layer.
    2. No transition is running.

  TRANSITIONS:
    ON gotoScene(target):
      1. Resolve or create target scene.
      2. Fire current scene leave-before hook if current scene exists.
      3. Fire target scene enter-before hook.
      4. If transition is disabled, commit immediately.
      5. If transition is enabled, initialize transition state.
      → transitioning or stable

STATE transitioning

  ENTRY:
    1. Outgoing and incoming scenes are both known.
    2. Transition clock is initialized.

  TRANSITIONS:
    ON frame update before completion:
      1. Advance transition clock.
      2. Update transition progress.
      3. Draw outgoing and incoming scenes through transition composition.
      → transitioning

    ON transition completion:
      1. Fire outgoing leave-after hook.
      2. Remove outgoing scene from active layer.
      3. Fire incoming enter-after hook.
      4. Set incoming scene as current.
      5. Clear transition state.
      → stable

    ON new navigation request during transition:
      1. Cancel the active visual transition.
      2. Commit the current incoming scene as the stable current scene.
      3. Clear transition state.
      4. Process the new navigation request from the resulting stable state.
      → transitioning or stable

ERRORS:
  - Unknown scene name → fail deterministically.

## 7. Composition And Interaction Patterns

### 7.1 Event propagation

The library must implement three ordered propagation phases:

1. capture
2. target
3. bubble

Each dispatched input event must resolve a target path from `Stage` to the deepest eligible target.

Backdrop-based blocking for overlays must work through normal propagation semantics.

The active overlay layer must be considered before ordinary scene content during target resolution.

#### 7.1.1 Event object contract

Every dispatched event must expose at least:

- `type`
- `phase`
- `target`
- `currentTarget`
- `path`
- `timestamp`
- `defaultPrevented`
- `propagationStopped`
- `immediatePropagationStopped`
- `pointerType` when the source is pointer-derived
- `x`, `y` in stage-space when the source is spatial
- `localX`, `localY` relative to the `currentTarget` when the source is spatial

The event object must provide:

- `stopPropagation()`
- `stopImmediatePropagation()`
- `preventDefault()`

#### 7.1.2 Target resolution rules

Target resolution must occur in this order:

1. active overlay layer, from highest eligible sibling-local z-order to lowest
2. active base scene layer, from highest eligible sibling-local z-order to lowest
3. within any sibling set, reverse draw order among hit-test-eligible descendants

#### 7.1.3 Default actions

For a component with a defined default action:

1. capture listeners fire
2. target listeners fire
3. bubble listeners fire
4. if `defaultPrevented = false`, the component default action executes

### 7.2 Focus

The library must maintain a logical focus model independent of pointer hover.

Focus traversal must support:

- explicit focus request
- next and previous traversal
- directional traversal where the component family defines it
- focus restoration when modals close

#### 7.2.1 Focus scopes

`Stage` defines the root focus scope.

A component or runtime primitive may define a nested focus scope when it needs bounded traversal, including:

- `Modal`
- `Alert`

Exactly one node may own logical focus within the active focus scope chain at a time.

#### 7.2.2 Focus acquisition rules

Focus may be acquired by:

- explicit consumer request
- pointer activation when the component contract allows pointer-focus coupling
- sequential traversal commands
- directional traversal commands
- modal or alert opening rules

#### 7.2.3 Sequential traversal rules

Within a focus scope, the default sequential order must resolve by:

1. tree order among focusable descendants
2. sibling-local `zIndex` only when the component family explicitly binds focus order to visual order

If no component family overrides the rule, traversal must use depth-first pre-order tree order over focusable descendants.

#### 7.2.4 Directional traversal rules

Directional traversal is optional per component family, but when supported it must:

- evaluate candidate focusable nodes within the active focus scope
- prefer candidates in the requested direction
- break ties through nearest-distance stable ordering

#### 7.2.5 Focus and overlays

When an overlay with `trapFocus = true` becomes active:

1. record the previously focused node
2. move focus into the overlay according to overlay-specific rules
3. restrict traversal to the overlay scope

#### 7.2.6 Pointer and focus coupling

Pointer activation does not automatically imply focus for every component.

The component contract must define whether pointer activation:

- focuses before default action
- focuses after default action
- does not change focus

### 7.3 Responsive rules

Responsive behavior must be declarative.

Responsive rules may depend on:

- viewport width
- viewport height
- orientation
- safe area
- parent dimensions

Responsive rules must resolve before measurement and layout for the affected subtree.

This revision supports:

- fluid percentages
- min and max clamps
- declarative breakpoints

### 7.4 Render effects and shaders

Effects inherit from parent to child by default.

The effective effect chain must be resolved in tree order.

The renderer may draw inline when the full chain can be applied without violating the contract.

The renderer must isolate a subtree when required by:

- shader composition rules
- masking rules
- clipping rules that cannot be expressed inline
- opacity or blend behavior that requires offscreen composition

### 7.5 Render Skin Resolution

The library must treat presentation as a resolved render skin rather than as ad hoc draw code embedded in each control.

A render skin may be composed from:

- scalar tokens
- color tokens
- textures
- atlas regions
- quads
- nine-slice definitions
- shaders
- opacity and blend settings
- state-dependent part visibility

Each render-capable component must expose named presentational parts that can be skinned independently.

## 8. Token And Theming Contract

The theming contract is the stable interface between the library and the consumer's design system.

This revision standardizes:

- scalar tokens: spacing, radii, border widths, timing values
- color tokens
- font tokens
- texture references
- atlas references
- quad references
- nine-slice definitions
- shader references
- stateful variants per component state

### 8.1 Token classes

This revision standardizes these token classes:

- `color`
- `spacing`
- `radius`
- `border`
- `font`
- `timing`
- `texture`
- `atlas`
- `quad`
- `nineSlice`
- `shader`
- `opacity`
- `blendMode`

### 8.2 Part-level skin contract

Each skinnable component part may resolve one of these render modes:

- solid fill
- stroked shape
- texture draw
- quad draw
- nine-slice draw
- text draw
- shader-modified draw
- fully custom consumer renderer through a defined extension slot

### 8.3 Texture and atlas contract

A texture-backed skin may reference:

- a full `Image`
- an atlas texture plus region metadata
- a precomputed `Quad`
- a nine-slice definition over either a full texture or a quad region

### 8.4 Nine-slice contract

The specification supports nine-slice presentation for scalable textured surfaces.

### 8.5 Stateful variant resolution

Variant resolution must be deterministic.

### 8.6 Shader contract

The specification supports shader-backed presentation at the node and part levels.

### 8.7 Isolation rules

The renderer must isolate a subtree when effect composition cannot be applied inline without changing semantics.

### 8.8 Performance rules

The implementation should:

- prefer native `Image`, `Quad`, `Font`, `Text`, `Canvas`, `Shader`, and `SpriteBatch` primitives where contract-compliant
- avoid Lua-heavy per-frame recomputation of skin geometry when inputs are unchanged
- cache part-level quads, nine-slice geometry, text measurement, and resolved render descriptions when safe

`SpriteBatch` is an implementation optimization, not a public component contract.

### 8.9 Missing or invalid skin inputs

If a token is absent, the component may fall back to a stable default token or fail deterministically if no default exists.

If a skin asset or shader is invalid, the component must fail deterministically.

## 9. Deferred Items

- `Grid`
  Reason: omitted from revision `0.1.0` to keep the first layout standard narrow and invalidation-friendly.
