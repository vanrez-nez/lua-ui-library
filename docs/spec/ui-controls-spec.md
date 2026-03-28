# UI Controls Specification

## 1. Version Header

Version: `0.1.2`
Revision type: `additive`
Finalized: `2026-03-27`
Inputs: current `lib/ui` implementation review, LÖVE API review in `docs/research/love-api-related.md`, repository pattern review in `docs/research/repo-ui-patterns/`, and revision decisions captured during specification drafting.

## 2. Changelog Summary

1. Initial publication of the concrete controls standard for the UI library.

## 3. Glossary

All terminology defined in [ui-foundation-spec.md](/Users/vanrez/Documents/game-dev/lua-ui-library/docs/spec/ui-foundation-spec.md) is binding in this document.

`Control`: An interactive component whose primary purpose is to receive input, expose state, or trigger actions.

`Selection control`: A control whose primary purpose is to represent and mutate a selected or enabled state.

`Text-entry control`: A control whose primary purpose is to accept, edit, and expose text.

`Overlay control`: A control rendered above ordinary scene content and governed by overlay and focus-trap rules.

## 4. Scope And Domain

This document defines the concrete control families built on the foundation specification.

This revision owns the following controls:

- `Text`
- `Button`
- `Checkbox`
- `Switch`
- `TextInput`
- `TextArea`
- `Tabs`
- `Modal`
- `Alert`

The foundation contracts for event propagation, focus, responsive rules, runtime layers, render effects, and theming remain authoritative and are not redefined here.

## 5. Design Principles

1. Every stateful control must use controlled consumer-owned state for public stateful behavior.
2. Every concrete control must bind to the foundation event and focus model without inventing a private routing system.
3. Every control must remain skinnable through the foundation render-skin contract.
4. Every control must fail deterministically on invalid prop combinations.
5. Every control must distinguish consumer-observable behavior from implementation detail.

## 6. Component Specifications

### 6.1 Text

**Purpose and contract**

`Text` renders static or externally supplied textual content. `Text` owns measurement, wrapping, alignment, and text styling resolution. `Text` does not own editing behavior.

`Text` must:

- support intrinsic measurement
- support wrapping
- support horizontal alignment
- support token and skin-derived text styling
- prefer native LÖVE font and text primitives where contract-compliant

`Text` may use:

- `love.graphics.newFont`
- `Font:getWrap`
- `love.graphics.print`
- `love.graphics.printf`
- `love.graphics.newText`

**Anatomy**

- `root`: the text node. Required.
- `content`: the text string or rich text payload. Required.

**Props and API surface**

- `text: string | rich text payload`
- `font`
- `fontSize`
- `maxWidth`
- `textAlign`
- `textVariant`
- `color`
- `wrap: boolean`

**State model**

`Text` is stateless unless the consumer changes content or style.

**Accessibility contract**

`Text` contributes readable textual semantics when used by a semantic parent. Standalone text is non-interactive.

### 6.2 Button

**Purpose and contract**

`Button` is an activation control. It owns press, hover, focus, disabled, and activation semantics. `Button` may be visually skinned through tokens, textures, quads, or shaders without changing activation behavior.

`Button` must:

- support controlled pressed state where exposed
- support pointer, touch, keyboard, and programmatic activation
- expose a content slot for text or custom child content
- suppress activation when disabled

**Anatomy**

- `root`: interactive press target. Required.
- `content`: label or consumer-provided subtree. Required.
- `indicator`: optional visual focus or pressed indicator.

**Props and API surface**

- `pressed`
- `onPressedChange`
- `onActivate`
- `disabled`
- `content`

**State model**

STATE idle

  ENTRY:
    1. The effective pressed state is false.

  TRANSITIONS:
    ON pointer or touch press inside target:
      1. Request pressed state `true` through `onPressedChange` when the pressed state is exposed.
      2. Capture activation gesture.
      → pressed

    ON keyboard activate command while focused:
      1. Request pressed state `true` through `onPressedChange` when the pressed state is exposed.
      → pressed

STATE pressed

  ENTRY:
    1. The effective pressed state is true.

  TRANSITIONS:
    ON release inside target and not disabled:
      1. Request pressed state `false` through `onPressedChange` when the pressed state is exposed.
      2. Dispatch activation.
      → idle

    ON release outside target:
      1. Request pressed state `false` through `onPressedChange` when the pressed state is exposed.
      → idle

    ON disabled change:
      1. Request pressed state `false` through `onPressedChange` when the pressed state is exposed.
      → disabled

STATE disabled

  ENTRY:
    1. Activation is suppressed.

ERRORS:
  - `pressed` without `onPressedChange` when `pressed` is intended to be mutable → invalid configuration and deterministic failure.

**Composition rules**

`Button` may contain text or arbitrary drawable content.

Nested interactive controls inside a `Button` are unsupported in this revision.

### 6.3 Checkbox

**Purpose and contract**

`Checkbox` is a selection control representing an on, off, or indeterminate state. It owns checked-state resolution, toggle behavior, focus behavior, disabled behavior, and label-associated activation semantics.

`Checkbox` must:

- support controlled checked state
- support the states `checked`, `unchecked`, and `indeterminate`
- toggle through pointer, touch, keyboard, and programmatic activation
- expose a press target that may include the visual box and associated label region
- suppress state changes when disabled

**Anatomy**

- `root`: the checkbox interactive region. Required.
- `box`: the visual selection indicator. Required.
- `indicator`: the mark representing checked or indeterminate state. Optional.
- `label`: optional associated content that participates in activation.
- `description`: optional assistive or explanatory content.

**Props and API surface**

- `checked: boolean | "indeterminate" | nil`
- `onCheckedChange: function | nil`
- `disabled: boolean`
- `label`
- `toggleOrder: table | nil`

**State model**

STATE unchecked

  ENTRY:
    1. The effective checked state is false.

  TRANSITIONS:
    ON activation and not disabled:
      1. Resolve next state from toggle order.
      2. Emit `onCheckedChange` with the requested next state.
      → checked or indeterminate

STATE checked

  ENTRY:
    1. The effective checked state is true.

  TRANSITIONS:
    ON activation and not disabled:
      1. Resolve next state from toggle order.
      2. Emit `onCheckedChange` with the requested next state.
      → unchecked or indeterminate

STATE indeterminate

  ENTRY:
    1. The effective checked state is mixed.

  TRANSITIONS:
    ON activation and not disabled:
      1. Resolve next state from toggle order.
      2. Emit `onCheckedChange` with the requested next state.
      → checked or unchecked

ERRORS:
  - `checked` without `onCheckedChange` when `checked` is intended to be mutable → invalid configuration and deterministic failure.

### 6.4 Switch

**Purpose and contract**

`Switch` is a binary selection control representing an immediate on or off setting. It shares the controlled state ownership model of `Checkbox` but does not expose an indeterminate state.

`Switch` must:

- support controlled checked state
- support pointer tap, touch tap, drag, keyboard activation, and programmatic activation
- expose distinct visual regions for track and thumb when skinned that way
- suppress state changes when disabled

**Anatomy**

- `root`: the switch interactive region. Required.
- `track`: the background state track. Required.
- `thumb`: the movable state handle. Required.
- `label`: optional associated content.
- `description`: optional associated content.

**Props and API surface**

- `checked: boolean | nil`
- `onCheckedChange: function | nil`
- `disabled: boolean`
- `dragThreshold: number`
- `snapBehavior: "nearest" | "directional"`

**State model**

STATE unchecked

  ENTRY:
    1. Effective checked state is false.

  TRANSITIONS:
    ON tap activation and not disabled:
      1. Request checked state `true`.
      → checked

STATE checked

  ENTRY:
    1. Effective checked state is true.

  TRANSITIONS:
    ON tap activation and not disabled:
      1. Request checked state `false`.
      → unchecked

STATE dragging

  ENTRY:
    1. Pointer or touch owns the switch gesture.
    2. Thumb position reflects gesture progress.

  TRANSITIONS:
    ON drag move:
      1. Update thumb progress.
      → dragging

    ON drag release:
      1. Resolve target state from drag direction, threshold, and snap behavior.
      2. Emit `onCheckedChange` with the requested next state.
      → checked or unchecked

ERRORS:
  - `checked` without `onCheckedChange` when `checked` is intended to be mutable → invalid configuration and deterministic failure.
  - Negative `dragThreshold` → invalid configuration and deterministic failure.

### 6.5 TextInput

**Purpose and contract**

`TextInput` is a single-line text-entry control. It owns editable text value resolution, caret movement, selection, committed text insertion, IME composition display, clipboard integration, and soft-keyboard activation.

`TextInput` must:

- support controlled `value`
- support logical focus
- support active text-entry ownership distinct from focus ownership
- enable native LÖVE text input while active
- consume `love.textinput` for committed text insertion
- consume `love.textedited` for IME candidate display
- support caret movement and selection by keyboard and pointer
- support copy, cut, and paste through LÖVE system clipboard APIs when available
- support placeholder rendering when empty and not composing committed text
- not require consumer-managed text input lifecycle

**Anatomy**

- `root`: the focus and hit-test boundary. Required.
- `field`: the editable text presentation region. Required.
- `placeholder`: optional presentational content.
- `caret`: the visual insertion point. Required while focused and editable.
- `selection`: optional.
- `composition`: optional.

**Props and API surface**

- `value: string | nil`
- `onValueChange: function | nil`
- `selectionStart: integer | nil`
- `selectionEnd: integer | nil`
- `onSelectionChange: function | nil`
- `placeholder: string | nil`
- `disabled: boolean`
- `readOnly: boolean`
- `maxLength: integer | nil`
- `inputMode: "text" | "numeric" | "email" | "url" | "search"`
- `submitBehavior: "blur" | "submit" | "none"`
- `onSubmit: function | nil`

**State model**

STATE unfocused

  ENTRY:
    1. The input does not own active text-entry state.
    2. Native text input must be disabled unless another text-entry control owns it.
    3. Composition text is cleared.

  TRANSITIONS:
    ON focus acquisition and not disabled:
      1. Resolve selection.
      2. Enable native text input for the field region.
      → focused

STATE focused

  ENTRY:
    1. The input owns logical focus.
    2. Native text input is enabled for the field region.
    3. Caret is visible unless read-only.

  TRANSITIONS:
    ON `love.textinput(text)` and not readOnly:
      1. Replace current selection with committed text.
      2. Enforce `maxLength` if defined.
      3. Emit `onValueChange` with the requested next value.
      4. Collapse selection to the end of inserted text.
      → focused

    ON `love.textedited(text, start, length)` and not readOnly:
      1. Store composition text and composition range.
      2. Do not commit the candidate text into the value.
      → composing

STATE composing

  ENTRY:
    1. The input owns IME candidate state.
    2. Committed value remains unchanged.

  TRANSITIONS:
    ON `love.textinput(text)`:
      1. Clear composition candidate.
      2. Insert committed text using normal insertion rules.
      → focused

ERRORS:
  - `value` without `onValueChange` when `value` is intended to be mutable → invalid configuration and deterministic failure.
  - Controlled selection with only one boundary provided → invalid configuration and deterministic failure.
  - `maxLength < 0` → invalid configuration and deterministic failure.

### 6.6 TextArea

**Purpose and contract**

`TextArea` is a multiline text-entry control derived from `TextInput`. It inherits the full single-line editing contract except where multiline behavior replaces single-line behavior.

`TextArea` must:

- support multiline committed value editing
- support newline insertion
- support multiline selection geometry
- support internal vertical scrolling
- support horizontal scrolling only when wrapping is disabled
- support composition with large content without requiring full-text re-layout every frame

**Anatomy**

- `root`
- `field`
- `placeholder`
- `caret`
- `selection`
- `composition`
- `scroll region`

**Props and API surface**

`TextArea` inherits all `TextInput` props and adds:

- `wrap: boolean`
- `rows: integer | nil`
- `scrollXEnabled: boolean`
- `scrollYEnabled: boolean`
- `momentum: boolean`

**State model**

`TextArea` inherits `TextInput` states and adds multiline scroll ownership.

### 6.7 Modal

**Purpose and contract**

`Modal` is a blocking overlay control that presents content above the base scene layer and prevents interaction with underlying content while open. `Modal` owns open state, backdrop behavior, focus trapping, focus restoration, dismissal policy, and safe-area-aware content placement.

`Modal` must:

- support controlled open state
- request open-state changes through `onOpenChange`
- prevent interaction with underlying content while the effective open state is true
- trap focus when configured
- restore prior focus when configured and when the prior node remains valid

**Anatomy**

- `root`
- `backdrop`
- `surface`
- `content`
- `dismiss controls`

**Props and API surface**

- `open: boolean | nil`
- `onOpenChange: function | nil`
- `dismissOnBackdrop: boolean`
- `dismissOnEscape: boolean`
- `trapFocus: boolean`
- `restoreFocus: boolean`
- `safeAreaAware: boolean`
- `backdropDismissBehavior: "close" | "ignore"`

**State model**

STATE closed

  TRANSITIONS:
    ON open request:
      1. Record previously focused node if focus restoration is enabled.
      2. Mount modal subtree into the active overlay layer.
      3. Activate backdrop blocking.
      4. Activate focus trap if enabled.
      5. Move focus into the modal subtree.
      → open

STATE open

  TRANSITIONS:
    ON backdrop activation and `dismissOnBackdrop = true`:
      1. Request close.
      → closing

    ON escape command and `dismissOnEscape = true`:
      1. Request close.
      → closing

    ON explicit close request:
      1. Request close.
      → closing

STATE closing

  TRANSITIONS:
    ON close commit:
      1. Remove modal subtree from overlay layer.
      2. Deactivate focus trap.
      3. Restore previously focused node when enabled and still valid.
      4. Clear recorded prior focus.
      → closed

ERRORS:
  - `open` without `onOpenChange` when `open` is intended to be mutable → invalid configuration and deterministic failure.

### 6.8 Alert

**Purpose and contract**

`Alert` is a dismissable modal pattern built on `Modal`. It presents urgent or decision-requiring content with explicit user acknowledgment or dismissal pathways.

`Alert` must:

- satisfy the full `Modal` contract unless this section defines a stronger rule
- provide a content surface for title, message, and actions
- support dismissal through explicit actions
- support optional dismissal through backdrop or escape according to configuration
- default to safe-area-aware centered placement

**Anatomy**

- `root`
- `backdrop`
- `surface`
- `title`
- `message`
- `actions`
- `dismiss control`

**Props and API surface**

`Alert` inherits modal props and adds:

- `title`
- `message`
- `actions`
- `variant: "default" | "destructive" | "success" | "warning"`
- `initialFocus: action identifier | nil`

**State model**

`Alert` inherits the `Modal` open and closing states.

### 6.9 Tabs

**Purpose and contract**

`Tabs` is a single-selection navigation control that coordinates a tab trigger list with a one-to-one set of associated panels. `Tabs` owns active tab resolution, roving focus among tab triggers, manual activation semantics, disabled-tab skipping, and panel visibility resolution.

`Tabs` must:

- support exactly one active tab value at a time
- support controlled active value resolution
- support horizontal and vertical orientation
- support manual activation through pointer, touch, and confirm keys
- keep tab trigger focus movement separate from tab activation
- support an overflowable tab list through scrollable composition
- associate each tab trigger with exactly one panel
- skip disabled tabs during sequential and directional trigger traversal

`Tabs` must not:

- activate a tab only because trigger focus moved
- require swipe gestures for panel switching in this revision
- support closable, reorderable, or multi-select tabs in this revision

**Anatomy**

- `root`: the tabs subtree root. Required.
- `list`: the tab trigger container. Required.
- `trigger`: the interactive element representing one tab value. Required and repeated.
- `indicator`: optional visual marker of the active trigger.
- `panels`: the panel container. Required.
- `panel`: the content region associated with one trigger value. Required and repeated.

**Props and API surface**

- `value: string | nil`
- `onValueChange: function | nil`
- `orientation: "horizontal" | "vertical"`
- `activationMode: "manual"`
- `listScrollable: boolean`
- `loopFocus: boolean`
- `disabledValues: table | nil`

**State model**

STATE idle

  ENTRY:
    1. One tab value is resolved as active when a valid value is available.
    2. Trigger focus may rest on the active trigger or another enabled trigger.
    3. Only the active panel participates in visible presentation and ordinary focus traversal.

  TRANSITIONS:
    ON trigger focus move:
      1. Resolve the next enabled trigger according to orientation, traversal direction, and `loopFocus`.
      2. Move roving focus to that trigger.
      3. Do not change the active value.
      → idle

    ON trigger activation by pointer, touch, `Enter`, or `Space`:
      1. Resolve the trigger value.
      2. Ignore the event if the trigger value is disabled.
      3. Emit `onValueChange` with the requested next value.
      4. Treat the associated panel as active only after the consumer updates `value`.
      → idle

    ON active value becomes invalid because the mapped trigger or panel is removed or disabled:
      1. Resolve the next enabled mapped value by sibling order.
      2. Emit `onValueChange` with the requested replacement value when a replacement exists.
      3. Emit `onValueChange(nil)` when no valid mapped value remains and empty selection is permitted by the consumer.
      → idle

ERRORS:
  - Duplicate trigger values within one `Tabs` root → invalid configuration and deterministic failure.
  - A trigger without a matching panel, or a panel without a matching trigger → invalid configuration and deterministic failure.
  - `activationMode` other than `"manual"` in this revision → invalid configuration and deterministic failure.
  - `value` without `onValueChange` when `value` is intended to be mutable → invalid configuration and deterministic failure.

**Accessibility contract**

`Tabs` must expose semantic tab relationships through stable trigger-to-panel association metadata. The control must expose which trigger is selected, which triggers are disabled, and which panel is currently active. Keyboard behavior must follow the manual-activation roving-focus pattern defined for tab interfaces: arrow keys move focus among enabled triggers, and `Enter` or `Space` activates the focused trigger.

**Composition rules**

`Tabs` composes a trigger list and a panel region inside one shared root. The trigger list may be implemented with scrollable composition when overflow exists, but scrolling must not change the active value by itself. Each trigger value must map to exactly one panel value within the same `Tabs` root.

Interactive content inside the active panel is supported. Inactive panels must not participate in ordinary focus traversal or pointer targeting.

## 7. Composition And Interaction Patterns

All concrete controls in this document inherit the event propagation, focus, responsive, render-effects, and theming contracts defined in [ui-foundation-spec.md](/Users/vanrez/Documents/game-dev/lua-ui-library/docs/spec/ui-foundation-spec.md).

Additional shared control rules for this revision:

- controls with a defined default action must execute that action only after listener delivery unless prevented
- controls that expose associated labels must define whether the label participates in activation
- controls that own text entry must own native text input lifecycle through the foundation runtime model
- overlay controls must bind to the overlay layer and focus-trap rules defined in the foundation specification
- tab-family controls must use roving focus within the trigger list and must not activate on focus movement in this revision
- stateful controls must render from consumer-owned state and may only request state changes through their change callbacks

## 8. Token And Theming Contract

Concrete controls inherit the foundation theming contract.

This document stabilizes control part names used by skins:

- `Button`: `surface`, `border`, `content`, `indicator`
- `Checkbox`: `box`, `indicator`, `label`
- `Switch`: `track`, `thumb`, `label`
- `TextInput`: `field`, `placeholder`, `selection`, `caret`
- `Tabs`: `list`, `trigger`, `indicator`, `panel`
- `Modal`: `backdrop`, `surface`, `content`
- `Alert`: `backdrop`, `surface`, `title`, `message`, `actions`

## 9. Deferred Items

- Additional concrete control families
  Reason: this revision is limited to the current bedrock control set.
