# UI Foundation Specification

## 1. Version Header

Version: `0.1.0`
Revision type: `additive`
Finalized: `2026-03-27`
Inputs: current library implementation review.

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

`Disabled`: A state in which a component accepts no input events, does not participate in focus traversal, and suppresses all activation behavior. A disabled component remains visible and retains its position in the tree unless additionally hidden.

`Activation`: The event signaling that a control's primary purpose has been fulfilled. The specific gesture or input sequence constituting activation is defined by the component contract.

`Hit test`: The process of determining whether a spatial point falls within a node's interactive bounds. A node passes a hit test when the point falls within its visible, clipped, and enabled interactive region.

`Local space`: The coordinate space relative to a node's own origin, before the node's local transform is applied.

`World space`: The coordinate space of the stage root, produced by composing all ancestor transforms along the path from root to node.

`Layout pass`: A tree traversal during which each dirty node resolves its measurement and child placement according to its layout contract.

## 4. Scope And Domain

This document governs the abstract and non-concrete parts of the UI library: retained structure, rendering behavior, state ownership, event propagation, focus management, responsive layout, runtime orchestration, render effects, and theming.

This document does not define the concrete control contracts in detail. Those are defined in [UI Controls Specification](./ui-controls-spec.md).

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
5. The library must reuse native platform primitives when they satisfy the contract without loss of composability, consistency, or performance.
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
- participate in event propagation when interactive
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

**Accessibility contract**

`Container` does not carry semantic accessibility meaning. It provides structural tree membership that allows descendant focusable nodes to resolve their focus ancestry correctly. `Container` does not require consumer-supplied accessibility attributes. A `Container` that is interactive and enabled must expose its interactive and enabled state so that assistive systems can determine whether the node participates in focus traversal.

**Composition rules**

A `Container` may contain any number of child nodes, including other `Containers` and `Drawable`-derived components. A `Container` must not be placed inside a node that explicitly prohibits children.

Sibling draw order must resolve by:

1. ascending `zIndex`
2. stable insertion order among equal `zIndex` values

Hit testing must resolve in reverse draw order among eligible siblings.

A `Container` that is not interactive does not participate as a hit-test target but still participates as a propagation ancestor for its descendants. Event propagation continues through non-interactive containers in both the capture and bubble phases.

**Behavioral edge cases**

- A `Container` with no children must remain valid and render nothing.
- A `Container` marked `visible = false` must not participate in hit testing, event propagation targeting, or rendering. It must retain its position in the tree and continue to contribute its transform to any descendants that may be independently made visible.
- A `Container` with `clipChildren = true` must clip both rendering and hit testing to its own bounds.
- A `Container` with `width = "fill"` as a direct child of `Stage` resolves against the full viewport width.
- A `Container` with `enabled = false` must not receive activated events and must suppress focus acquisition for itself and its descendants.

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

**Accessibility contract**

`Drawable` inherits the accessibility contract of `Container`. It provides the presentational surface through which visual accessibility cues such as focus indicators may be rendered. `Drawable` does not impose additional accessibility requirements beyond those defined by components that extend it.

**Composition rules**

`Drawable` may contain child nodes. Descendants render within the `Drawable`'s content box unless explicitly positioned outside it through transform or anchor. An effect chain applied to a `Drawable` propagates to its descendants according to the rules in Section 7.4. A `Drawable` that requires isolation draws itself and its descendants into an offscreen target before compositing into the parent context. Nested `Drawable` instances each resolve their own effect chain relative to their parent's resolved chain.

**Behavioral edge cases**

- A `Drawable` with padding that causes the content box to reach zero area must clamp the content box to zero area. Children positioned within a zero-area content box are placed at the content origin.
- A `Drawable` with no skin must render nothing for its background and must not fail.
- A `Drawable` with `opacity = 0` remains in the tree and retains hit-test participation unless additionally marked non-interactive.
- A `Drawable` with a missing or invalid shader must fail deterministically.
- A `Drawable` with a mask that references a missing asset must fail deterministically.

### 6.2 Layout Family

#### 6.2.1 Purpose and contract

Layout primitives place children inside a content box. They own child measurement order, spacing rules, alignment resolution, responsive overrides, and overflow policy. Layout primitives do not own child interaction semantics.

This revision standardizes: `Stack`, `Row`, `Column`, `Flow`, `SafeAreaContainer`.

#### 6.2.2 Common props

- `gap`
- `padding`
- `wrap: boolean`
- `justify: "start" | "center" | "end" | "space-between" | "space-around"`
- `align: "start" | "center" | "end" | "stretch"`
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

#### 6.2.4 Stack

**Purpose and contract**

`Stack` places all children within the same content box, layered by z-order. It is the default composition primitive for overlays, layered visuals, and positioned content.

`Stack` must:

- apply the common layout state model
- allow each child to resolve its own alignment and anchor independently
- not impose a sequential axis on children

**Anatomy**

- `root`: the stack node. Required.
- `children`: zero or more layered child nodes. Optional.

**Props and API surface**

`Stack` does not define additional props beyond the common layout props.

**State model**

`Stack` uses the common layout state model defined in Section 6.2.3.

**Accessibility contract**

`Stack` is a non-interactive structural container. It does not add or require semantic accessibility attributes. Focusable descendants participate in traversal in tree order.

**Composition rules**

`Stack` may contain any number of child nodes. Children resolve their own alignment and position within the stack's content box independently. Overlapping children are drawn in ascending z-order. Hit testing resolves in reverse draw order.

**Behavioral edge cases**

- An empty `Stack` renders nothing and must not fail.
- A `Stack` whose children are all `visible = false` behaves as an empty stack.
- When `clipChildren = true`, children extending beyond the stack bounds are clipped in both rendering and hit testing.

#### 6.2.5 Row

**Purpose and contract**

`Row` places children sequentially along the horizontal axis. It resolves cross-axis alignment vertically. `Row` is the primary horizontal composition primitive.

`Row` must:

- apply the common layout state model
- place children left to right in insertion order when `direction = "ltr"`
- resolve gap spacing between children
- resolve cross-axis alignment for each child

**Anatomy**

- `root`: the row node. Required.
- `children`: ordered child sequence along the horizontal axis. Optional.

**Props and API surface**

- `direction: "ltr" | "rtl"`

Plus all common layout props.

**State model**

`Row` uses the common layout state model defined in Section 6.2.3.

**Accessibility contract**

`Row` is a non-interactive structural container. It does not add or require semantic accessibility attributes. Focusable descendants participate in traversal in insertion order.

**Composition rules**

`Row` may contain any number of children. Children that are themselves layout primitives are measured before placement. When `wrap = true`, overflow children are placed on subsequent rows. `Row` must not be nested inside itself in a way that creates a circular measurement dependency.

**Behavioral edge cases**

- An empty `Row` renders nothing and must not fail.
- When total child measurement exceeds available width with `wrap = false`, the overflow policy applies. The default overflow policy allows overflow without clipping unless `clipChildren = true`.
- A single child in a `Row` with `justify = "space-between"` resolves to the start position.

#### 6.2.6 Column

**Purpose and contract**

`Column` places children sequentially along the vertical axis. It resolves cross-axis alignment horizontally. `Column` is the primary vertical composition primitive.

`Column` must:

- apply the common layout state model
- place children top to bottom in insertion order
- resolve gap spacing between children
- resolve cross-axis alignment for each child

**Anatomy**

- `root`: the column node. Required.
- `children`: ordered child sequence along the vertical axis. Optional.

**Props and API surface**

`Column` does not define additional props beyond the common layout props.

**State model**

`Column` uses the common layout state model defined in Section 6.2.3.

**Accessibility contract**

`Column` is a non-interactive structural container. It does not add or require semantic accessibility attributes. Focusable descendants participate in traversal in insertion order.

**Composition rules**

`Column` may contain any number of children. Children that are themselves layout primitives are measured before placement. `Column` must not be nested inside itself in a way that creates a circular measurement dependency.

**Behavioral edge cases**

- An empty `Column` renders nothing and must not fail.
- When total child measurement exceeds available height with `wrap = false`, the overflow policy applies. The default overflow policy allows overflow without clipping unless `clipChildren = true`.
- A single child in a `Column` with `justify = "space-between"` resolves to the start position.

#### 6.2.7 Flow

**Purpose and contract**

`Flow` places children in reading order across the primary axis, wrapping to a new line when remaining space on the current line is insufficient. It is intended for fluid responsive placement and not for strict grid semantics.

`Flow` must:

- apply the common layout state model
- place children in reading order
- wrap to a new row when `wrap = true` and remaining space is exhausted
- resolve gap spacing between children across and along the primary axis

**Anatomy**

- `root`: the flow node. Required.
- `children`: ordered child nodes placed in reading order. Optional.

**Props and API surface**

`Flow` does not define additional props beyond the common layout props.

**State model**

`Flow` uses the common layout state model defined in Section 6.2.3.

**Accessibility contract**

`Flow` is a non-interactive structural container. Focusable descendants participate in traversal in insertion order.

**Composition rules**

`Flow` may contain any number of children. Children with `visible = false` do not occupy space in the flow. `Flow` may be placed inside any other layout container.

**Behavioral edge cases**

- An empty `Flow` renders nothing and must not fail.
- When `wrap = false` and children exceed available width, the overflow policy applies without wrapping.
- The last row of a wrapped flow aligns to the `align` value and is not stretched to fill available space.
- A single child wider than the full flow row occupies that row alone and is not clipped unless `clipChildren = true`.

#### 6.2.8 SafeAreaContainer

**Purpose and contract**

`SafeAreaContainer` measures and positions its content region against the safe area bounds reported by the environment rather than against full viewport bounds. It is the designated container for content that must avoid device-level obstructions such as notches, status bars, and home indicators.

`SafeAreaContainer` must:

- derive its content area from the current safe area bounds
- update its content area when safe area bounds change
- support opt-in inset application per edge

**Anatomy**

- `root`: the safe area container node. Required.
- `content`: the inset content region. Required.

**Props and API surface**

- `applyTop: boolean`
- `applyBottom: boolean`
- `applyLeft: boolean`
- `applyRight: boolean`

Plus all common layout props.

**State model**

`SafeAreaContainer` uses the common layout state model defined in Section 6.2.3.

In addition:

  TRANSITIONS:
    ON safe area bounds change:
      1. Re-derive content region from updated safe area bounds.
      2. Mark layout invalid.
      → layout_dirty

**Accessibility contract**

`SafeAreaContainer` is a non-interactive structural container. It does not add or require accessibility attributes.

**Composition rules**

`SafeAreaContainer` may contain any layout or drawable descendants. It must be placed in the tree where full safe-area context is available. Multiple nested `SafeAreaContainer` instances each apply insets relative to the same environment-reported safe area, not relative to the parent container's insets.

**Behavioral edge cases**

- When the environment reports no safe area insets, `SafeAreaContainer` renders identically to a plain container of the same dimensions.
- When all `apply*` props are false, the container applies no inset adjustment.
- `SafeAreaContainer` always queries the environment-reported safe area bounds regardless of where it appears in the tree.

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
      2. Record initial pointer position and current offset.
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
      1. Seed inertial velocity from the recorded velocity estimate.
      → inertial

STATE inertial

  ENTRY:
    1. Offset advances each frame from the retained velocity.

  TRANSITIONS:
    ON frame update:
      1. Integrate velocity into offset.
      2. Apply configured decay to velocity.
      3. Clamp or resolve overscroll return.
      4. When velocity falls to the stop threshold, transition to idle.
      → idle

**Accessibility contract**

When focused, `ScrollableContainer` must respond to keyboard scroll commands as defined in the state model. Scrollbar parts, when present, must be non-focusable decorations. The consumer is responsible for configuring any semantic region labels for the scrollable content area.

**Composition rules**

`ScrollableContainer` must contain exactly one content child subtree. Additional children outside the content slot are unsupported. `ScrollableContainer` may be nested; each nested instance manages its own offset, gesture capture, and clipping independently. A nested scroll container must not propagate scroll events to its ancestor when the inner container still has remaining scroll range in the requested direction.

**Behavioral edge cases**

- When content extent is less than or equal to the viewport size along a given axis, scrolling on that axis must be suppressed regardless of `scrollXEnabled` or `scrollYEnabled`.
- When `overscroll = false`, scroll offset must be clamped to the valid range at all times.
- When `momentum = false`, releasing a drag immediately clamps the offset without entering the inertial state.
- An empty content subtree results in zero content extent. The container must remain valid and not enter any scroll state.
- When both `scrollXEnabled = false` and `scrollYEnabled = false`, the container must not respond to any scroll input.

### 6.4 Runtime Family

#### 6.4.1 Stage

**Purpose and contract**

`Stage` is the runtime root for the UI tree. It owns viewport bounds, safe area bounds, root-level event dispatch entry, and root-level environment synchronization.

`Stage` must:

- reflect current viewport dimensions at all times
- expose full viewport bounds as a queryable rectangle
- expose safe area bounds as a queryable rectangle
- provide the root event dispatch entry point for all input types
- provide the root focus scope
- propagate viewport resize to the full tree

**Anatomy**

- `root`: the stage node. Required.
- `base scene layer`: the layer hosting the active scene. Required.
- `overlay layer`: the layer above the base scene, used for modal and overlay rendering. Required.

**Props and API surface**

- `width: number`
- `height: number`
- `safeAreaInsets: { top, bottom, left, right }`

**State model**

STATE synchronized

  ENTRY:
    1. Viewport dimensions match the environment-reported window size.
    2. Safe area insets reflect the current environment-reported values.

  TRANSITIONS:
    ON viewport resize:
      1. Update width and height to new dimensions.
      2. Update safe area insets if they changed.
      3. Mark the full tree dirty for layout resolution.
      → synchronized

ERRORS:
  - Attempting to assign a parent to `Stage` → invalid configuration and deterministic failure.
  - Creating more than one `Stage` instance → invalid configuration and deterministic failure.

**Accessibility contract**

`Stage` is the root of the application's accessible component tree. It does not carry a semantic role itself. It provides the root focus scope for all traversal. The consumer is responsible for any application-level accessibility metadata outside the component tree.

**Composition rules**

`Stage` contains exactly two logical layers: the base scene layer and the overlay layer. The overlay layer always renders above the base scene layer. Event resolution must check the overlay layer before the base scene layer. `Stage` must have no parent. Exactly one `Stage` must exist per application runtime.

**Behavioral edge cases**

- `Stage` must remain valid when no active scene is present. It renders nothing in this state.
- When the overlay layer is empty, event resolution falls through to the base scene layer without additional cost.

#### 6.4.2 Scene

**Purpose and contract**

`Scene` is a runtime primitive representing a screen-level subtree with lifecycle hooks. It provides the boundary at which the consumer controls creation, activation, deactivation, and destruction of a screen's content tree.

`Scene` must:

- own a full-screen or stage-sized subtree by default
- expose creation, enter, leave, and destruction lifecycle hooks
- integrate with `Composer`
- receive input forwarded by `Composer` and dispatch it into its subtree

**Anatomy**

- `root`: the scene subtree root. Required.
- `content`: consumer-provided child subtree. Optional.

**Props and API surface**

- `params: table | nil`

**State model**

STATE inactive

  ENTRY:
    1. The scene subtree exists but is not the active scene.
    2. The scene receives no input events.

  TRANSITIONS:
    ON activation by `Composer`:
      1. Fire the enter-before lifecycle hook.
      2. Become the current active scene.
      3. Fire the enter-after lifecycle hook.
      → active

STATE active

  ENTRY:
    1. The scene is the current active scene.
    2. Input events are forwarded to this scene's subtree.

  TRANSITIONS:
    ON deactivation by `Composer`:
      1. Fire the leave-before lifecycle hook.
      2. Yield active scene status.
      3. Fire the leave-after lifecycle hook.
      → inactive

**Accessibility contract**

`Scene` is a structural runtime container. It does not impose accessibility requirements beyond those of its content. When a scene becomes active, its focusable descendants become eligible for traversal within the base scene focus scope.

**Composition rules**

`Scene` must be registered with and managed by `Composer`. A `Scene` must not manage other scenes directly. `Scene` may contain any layout or control components as descendants. Consumer lifecycle hooks must not invoke `Composer` navigation during the enter or leave phases of the same transition.

**Behavioral edge cases**

- A `Scene` with no content must remain valid and render nothing.
- If a consumer-supplied lifecycle hook produces an error, `Composer` must handle it deterministically rather than leaving the tree in an indeterminate activation state.

#### 6.4.3 Composer

**Purpose and contract**

`Composer` owns scene registration, scene caching, scene transition sequencing, and scene activation.

`Composer` must:

- register scenes by stable name
- activate one scene at a time in the base scene layer
- expose and manage the active overlay layer above the base scene layer
- support transitions
- support deterministic scene lifecycle sequencing
- forward root input into the active runtime subtree

**Anatomy**

- `root`: the composer runtime. Required.
- `stage`: the owned `Stage` node. Required.
- `scene registry`: the named scene store. Required.
- `transition state`: active transition context. Optional, present only during transitioning.

**Props and API surface**

- `defaultTransition`
- `defaultTransitionDuration`

**State model**

STATE stable

  ENTRY:
    1. Exactly one scene is active in the base scene layer.
    2. No transition is running.

  TRANSITIONS:
    ON gotoScene(target):
      1. Resolve or create the target scene.
      2. Fire the current scene leave-before hook if a current scene exists.
      3. Fire the target scene enter-before hook.
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
      1. Fire the outgoing scene leave-after hook.
      2. Remove the outgoing scene from the active layer.
      3. Fire the incoming scene enter-after hook.
      4. Set the incoming scene as current.
      5. Clear transition state.
      → stable

    ON new navigation request during transition:
      1. Cancel the active visual transition.
      2. Commit the current incoming scene as the stable current scene.
      3. Clear transition state.
      4. Process the new navigation request from the resulting stable state.
      → transitioning or stable

ERRORS:
  - Unknown scene name → deterministic failure.

**Accessibility contract**

`Composer` does not carry semantic accessibility meaning. When a scene transition completes, the incoming scene's focusable descendants become available for traversal. `Composer` must not leave focus in an indeterminate state after any transition.

**Composition rules**

`Composer` owns one `Stage` and must not share stage ownership with other `Composer` instances. Scene activation is exclusively managed through the defined navigation interface. Consumer code must not directly manipulate the scene tree during an active transition.

**Behavioral edge cases**

- When `gotoScene` is called with the currently active scene name, `Composer` must treat it as a full navigation request with complete lifecycle hook execution, not as a no-op.
- When `gotoScene` is called before any scene has been activated, no outgoing scene exists and no leave hooks fire.
- A transition interrupted by a second navigation request must complete the leave lifecycle for the outgoing scene and the enter lifecycle for the final incoming scene. No intermediate scene should execute enter or leave hooks.

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
- `x`, `y` in stage space when the source is spatial
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

### 8.3 Render skin resolution

The library must treat presentation as a resolved render skin rather than as ad hoc draw behavior embedded in each control.

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

### 8.4 Texture and atlas contract

A texture-backed skin may reference:

- a full image
- an atlas texture plus region metadata
- a precomputed quad region
- a nine-slice definition over either a full image or a quad region

### 8.5 Nine-slice contract

A nine-slice definition divides a texture region into nine rectangular cells using two horizontal and two vertical cut lines, each measured as an inset from the corresponding edge of the source texture region.

The four corner cells do not stretch. They are drawn at their natural pixel size. The four edge cells stretch along one axis only: horizontal edges stretch horizontally; vertical edges stretch vertically. The center cell stretches along both axes.

A nine-slice definition must specify the four edge inset measurements that define the cut positions.

When the component's drawn size along an axis is smaller than the sum of the two opposing corner insets along that axis, the corners must scale down proportionally to fit. In this condition the edge and center cells for that axis are omitted.

### 8.6 Stateful variant resolution

A component resolves its active skin variant by evaluating its current state flags in a defined priority order. Each component that exposes state-driven presentation must document the priority order of its states in its specification.

When multiple states are simultaneously active, the highest-priority state determines which variant skin is selected.

When no state-specific variant is defined for the currently active state, the component must fall back to the base variant skin.

When no base variant skin is defined, the component must apply any available default token values. If a required token is absent and no default exists, the component must fail deterministically.

### 8.7 Shader contract

A shader applied at the node level executes over the node's rendered output, after the node draws and before its descendants draw, unless the composition requires isolation.

A shader applied at the part level executes only for that part's draw operation and does not affect sibling parts or descendants.

Shaders in the inherited effect chain compose in tree order. A node whose shader cannot compose inline with its ancestor chain must trigger isolation for its subtree.

A component must fail deterministically if a shader is invalid or if the shader requires rendering capabilities unavailable in the current context.

### 8.8 Isolation rules

Isolation requires drawing a subtree to an offscreen target and compositing the result into the parent using the subtree root's opacity and blend mode.

Isolation is required when:

- a node applies opacity or a blend mode that would produce incorrect results if applied individually to each descendant during inline drawing
- a node applies a shader that requires the fully composited subtree as its input
- a node applies a mask whose correct appearance depends on the composited result of the entire subtree rather than the masked sum of individual draw calls

Isolation carries a performance cost and must not be applied speculatively when inline drawing satisfies the contract.

### 8.9 Performance rules

The implementation should:

- prefer native image, quad, font, text object, canvas, shader, and batch draw primitives where contract-compliant
- avoid per-frame recomputation of skin geometry when inputs are unchanged
- cache part-level quads, nine-slice geometry, text measurement, and resolved render descriptions when safe

Batch draw primitives are an implementation optimization and are not part of the public component contract.

### 8.10 Missing or invalid skin inputs

If a token is absent, the component may fall back to a stable default token. If no default token exists, the component must fail deterministically.

If a skin asset or shader is invalid, the component must fail deterministically.

## 9. Deferred Items

- `Grid`
  Reason: omitted from this revision to keep the first layout standard narrow and invalidation-friendly. Grid semantics require a two-axis measurement model that is not yet standardized here.
