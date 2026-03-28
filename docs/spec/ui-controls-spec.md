# UI Controls Specification

## 1. Version Header

Version: `0.1.0`
Revision type: `additive`
Finalized: `2026-03-27`
Inputs: current library implementation review.

## 2. Changelog Summary

1. Initial publication of the concrete controls standard for the UI library.

## 3. Glossary

All terminology defined in [UI Foundation Specification](./ui-foundation-spec.md) is binding in this document.

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

**Anatomy**

- `root`: the text node. Required.
- `content`: the text string or rich text payload. Required.

**Props and API surface**

- `text: string | rich text payload`
- `font`
- `fontSize`
- `maxWidth`
- `textAlign: "start" | "center" | "end"`
- `textVariant`
- `color`
- `wrap: boolean`

**State model**

`Text` is stateless unless the consumer changes content or style. Any content or style change marks the node render-dirty and triggers re-measurement on the next draw preparation.

**Accessibility contract**

`Text` contributes readable textual semantics when used as part of a semantic parent such as a labeled control. Standalone text is non-interactive and does not participate in focus traversal. The consumer is responsible for associating text labels with their corresponding controls when semantic association is required.

**Composition rules**

`Text` may not contain child nodes. `Text` may be placed inside any `Drawable`-derived container. When used as a label inside a control, the containing control's composition rules govern whether the label region participates in activation.

**Behavioral edge cases**

- A `Text` with an empty string must render nothing and must not fail.
- A `Text` with `wrap = true` and no `maxWidth` must wrap at the node's own measured width.
- A `Text` node whose content exceeds its bounds when wrapping is disabled must overflow without clipping unless `clipChildren = true` is set on the parent.
- A `Text` referencing a missing or invalid font must fail deterministically.

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
    2. No pointer is positioned over the target.

  TRANSITIONS:
    ON pointer enter:
      1. Set hover state.
      → hovered

    ON keyboard activate command while focused:
      1. Request pressed state `true` through `onPressedChange` when pressed state is exposed.
      → pressed

STATE hovered

  ENTRY:
    1. A pointer is positioned over the target and the button is not pressed.

  TRANSITIONS:
    ON pointer leave:
      1. Clear hover state.
      → idle

    ON pointer or touch press inside target:
      1. Request pressed state `true` through `onPressedChange` when pressed state is exposed.
      2. Capture activation gesture.
      → pressed

    ON disabled change:
      → disabled

STATE pressed

  ENTRY:
    1. The effective pressed state is true.

  TRANSITIONS:
    ON release inside target and not disabled:
      1. Request pressed state `false` through `onPressedChange` when pressed state is exposed.
      2. Dispatch activation.
      → hovered

    ON release outside target:
      1. Request pressed state `false` through `onPressedChange` when pressed state is exposed.
      → idle

    ON disabled change:
      1. Request pressed state `false` through `onPressedChange` when pressed state is exposed.
      → disabled

STATE disabled

  ENTRY:
    1. Activation is suppressed.
    2. Focus acquisition is suppressed.

  TRANSITIONS:
    ON enabled change:
      → idle

ERRORS:
  - `pressed` without `onPressedChange` when `pressed` is intended to be mutable → invalid configuration and deterministic failure.

**Accessibility contract**

`Button` must expose its disabled state to assistive systems. When focused, `Button` must respond to the standard keyboard activation commands. `Button` must expose its pressed state when it is externally controlled. The consumer is responsible for providing a meaningful label through the content slot; an empty content slot produces an unlabeled button.

**Composition rules**

`Button` may contain text or arbitrary drawable content in its content slot. Nested interactive controls inside a `Button` are unsupported in this revision.

**Behavioral edge cases**

- A `Button` with `disabled = true` must not enter hovered, pressed, or activated states.
- A `Button` that receives pointer enter while pressed due to keyboard activation must not alter the pressed state.
- A `Button` with an empty content slot must remain valid and functional.
- A press gesture that begins inside the target and ends outside must not dispatch activation.

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

`toggleOrder` defines the sequence of states cycled through on each activation as an ordered list of the values `"checked"`, `"unchecked"`, and `"indeterminate"`. When nil, the default order is `unchecked → checked → unchecked`. When provided, the list must contain at least the values `"checked"` and `"unchecked"`. Including `"indeterminate"` is optional. On each activation, the next value in the list after the current state is selected, wrapping from the last entry to the first.

**State model**

STATE unchecked

  ENTRY:
    1. The effective checked state is false.

  TRANSITIONS:
    ON activation and not disabled:
      1. Resolve the next state from the toggle order.
      2. Emit `onCheckedChange` with the requested next state.
      → checked or indeterminate

STATE checked

  ENTRY:
    1. The effective checked state is true.

  TRANSITIONS:
    ON activation and not disabled:
      1. Resolve the next state from the toggle order.
      2. Emit `onCheckedChange` with the requested next state.
      → unchecked or indeterminate

STATE indeterminate

  ENTRY:
    1. The effective checked state is mixed.

  TRANSITIONS:
    ON activation and not disabled:
      1. Resolve the next state from the toggle order.
      2. Emit `onCheckedChange` with the requested next state.
      → checked or unchecked

ERRORS:
  - `checked` without `onCheckedChange` when `checked` is intended to be mutable → invalid configuration and deterministic failure.
  - `toggleOrder` that omits either `"checked"` or `"unchecked"` → invalid configuration and deterministic failure.

**Accessibility contract**

`Checkbox` must expose its current checked state, including the indeterminate state, to assistive systems. It must expose its disabled state. When focused, `Checkbox` must respond to the standard keyboard activation command. The consumer is responsible for providing a meaningful label; an absent label produces an unlabeled control.

**Composition rules**

`Checkbox` may contain a label and a description as defined in its anatomy. The label region may be configured to participate in activation alongside the box region. The description region must not participate in activation. Nested interactive controls are unsupported.

**Behavioral edge cases**

- A `Checkbox` with `disabled = true` must not respond to any activation input.
- A `Checkbox` with no label must remain valid and functional.
- When `toggleOrder` is nil and the current state is `indeterminate`, the next state must be `checked` using the default order.
- A `Checkbox` receiving an activation gesture that begins inside the hit region and ends outside must not change state.

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
    2. Thumb is positioned at the unchecked end of the track.

  TRANSITIONS:
    ON tap activation and not disabled:
      1. Request checked state `true` through `onCheckedChange`.
      → checked

    ON drag start and not disabled:
      1. Capture drag gesture.
      2. Record initial pointer and thumb position.
      → dragging

STATE checked

  ENTRY:
    1. Effective checked state is true.
    2. Thumb is positioned at the checked end of the track.

  TRANSITIONS:
    ON tap activation and not disabled:
      1. Request checked state `false` through `onCheckedChange`.
      → unchecked

    ON drag start and not disabled:
      1. Capture drag gesture.
      2. Record initial pointer and thumb position.
      → dragging

STATE dragging

  ENTRY:
    1. Pointer or touch owns the switch gesture.
    2. Thumb position reflects gesture progress along the track.

  TRANSITIONS:
    ON drag move:
      1. Update thumb progress along the track proportionally to pointer delta.
      → dragging

    ON drag release:
      1. Resolve target state from drag direction, threshold, and snap behavior.
      2. Emit `onCheckedChange` with the requested next state.
      → checked or unchecked

ERRORS:
  - `checked` without `onCheckedChange` when `checked` is intended to be mutable → invalid configuration and deterministic failure.
  - Negative `dragThreshold` → invalid configuration and deterministic failure.

**Accessibility contract**

`Switch` must expose its current checked state and its disabled state to assistive systems. When focused, `Switch` must respond to keyboard activation commands. The consumer is responsible for providing a meaningful label; an absent label produces an unlabeled control.

**Composition rules**

`Switch` may contain a label and a description as defined in its anatomy. Neither the label nor the description participates in the drag gesture. Nested interactive controls are unsupported.

**Behavioral edge cases**

- A `Switch` with `disabled = true` must not respond to tap or drag input.
- A drag gesture that does not exceed `dragThreshold` and ends without crossing the midpoint must resolve to the current state, dispatching no change.
- A drag gesture that crosses the midpoint but does not exceed `dragThreshold` must resolve according to `snapBehavior`: `"nearest"` snaps to the closer end, `"directional"` commits based on the direction of the final gesture movement.
- A drag gesture that begins inside the track and ends outside must still resolve according to the release position relative to the track.

### 6.5 TextInput

**Purpose and contract**

`TextInput` is a single-line text-entry control. It owns editable text value resolution, caret movement, selection, committed text insertion, composition candidate display, clipboard integration, and soft-keyboard activation.

`TextInput` must:

- support controlled `value`
- support logical focus
- support active text-entry ownership distinct from focus ownership
- enable native text input while active
- consume committed text insertion events for normal text entry
- consume composition events for candidate display
- support caret movement and selection by keyboard and pointer
- support copy, cut, and paste through system clipboard when available
- support placeholder rendering when empty and not composing
- not require consumer-managed text input lifecycle

**Anatomy**

- `root`: the focus and hit-test boundary. Required.
- `field`: the editable text presentation region. Required.
- `placeholder`: optional presentational content shown when the field is empty and unfocused.
- `caret`: the visual insertion point. Required while focused and not read-only.
- `selection`: the visual selection region. Optional.
- `composition`: the visual candidate text region. Optional.

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
    2. Native text input is not active for this field.
    3. Any in-progress composition candidate is cleared.

  TRANSITIONS:
    ON focus acquisition and not disabled:
      1. Resolve initial selection.
      2. Enable native text input for this field's input region.
      → focused

STATE focused

  ENTRY:
    1. The input owns logical focus.
    2. Native text input is active for this field.
    3. Caret is visible unless read-only.

  TRANSITIONS:
    ON committed text received and not readOnly:
      1. Replace current selection with the committed text.
      2. Enforce `maxLength` if defined.
      3. Emit `onValueChange` with the requested next value.
      4. Collapse selection to the end of the inserted text.
      → focused

    ON composition candidate received and not readOnly:
      1. Store the composition candidate text and composition range.
      2. Do not commit the candidate into the value.
      → composing

    ON focus loss:
      1. Disable native text input.
      → unfocused

STATE composing

  ENTRY:
    1. The input owns an active composition candidate.
    2. Committed value remains unchanged.

  TRANSITIONS:
    ON committed text received:
      1. Clear the composition candidate.
      2. Insert committed text using normal insertion rules.
      → focused

    ON focus loss:
      1. Discard the composition candidate without committing it.
      2. Disable native text input.
      → unfocused

ERRORS:
  - `value` without `onValueChange` when `value` is intended to be mutable → invalid configuration and deterministic failure.
  - Controlled selection with only one boundary provided → invalid configuration and deterministic failure.
  - `maxLength < 0` → invalid configuration and deterministic failure.

**Accessibility contract**

`TextInput` must expose its current value, its disabled state, and its read-only state to assistive systems. It must expose its active text-entry ownership so that assistive input systems can route text to the correct field. The consumer is responsible for providing a label through an associated `Text` component or equivalent; an unlabeled text input must not be used in production interfaces. The `inputMode` prop communicates the expected input type and may be used to configure soft keyboards or input method behavior.

**Composition rules**

`TextInput` must not contain interactive child nodes. `TextInput` manages its own focus scope and must not be nested inside another text-entry control. `TextInput` may be placed inside any layout container.

**Behavioral edge cases**

- A `TextInput` with `disabled = true` must not acquire focus and must not respond to any input.
- A `TextInput` with `readOnly = true` must acquire focus and support selection and copy, but must not allow value mutation.
- When `maxLength` is reached and the consumer attempts to insert additional text, the insertion must be silently truncated to fit. No error fires.
- A `TextInput` with `value = ""` and a `placeholder` must render the placeholder only when unfocused.
- A paste operation that would cause the value to exceed `maxLength` must truncate the pasted content to fit.
- A `TextInput` that loses focus while a composition candidate is active must discard the candidate without emitting a value change.

### 6.6 TextArea

**Purpose and contract**

`TextArea` is a multiline text-entry control that inherits the full `TextInput` contract except where multiline behavior replaces single-line behavior.

`TextArea` must:

- support multiline committed value editing
- support newline insertion on confirm command
- support multiline selection geometry
- support internal vertical scrolling
- support horizontal scrolling only when wrapping is disabled

**Anatomy**

- `root`: the focus and hit-test boundary. Required.
- `field`: the editable text presentation region. Required.
- `placeholder`: optional presentational content shown when the field is empty and unfocused.
- `caret`: the visual insertion point. Required while focused and not read-only.
- `selection`: the visual selection region. Optional.
- `composition`: the visual candidate text region. Optional.
- `scroll region`: the internal scrollable content area. Required.

**Props and API surface**

`TextArea` inherits all `TextInput` props and adds:

- `wrap: boolean`
- `rows: integer | nil`
- `scrollXEnabled: boolean`
- `scrollYEnabled: boolean`
- `momentum: boolean`

**State model**

`TextArea` inherits the `TextInput` state model. The scroll region participates in the `ScrollableContainer` state model defined in the foundation specification, scoped to the internal field content.

**Accessibility contract**

`TextArea` inherits the `TextInput` accessibility contract. It must additionally expose that it is a multiline control to assistive systems. The consumer is responsible for providing a label.

**Composition rules**

`TextArea` must not contain interactive child nodes. `TextArea` manages its own internal scroll behavior and must not be nested inside a `ScrollableContainer` that intercepts the same scroll axis. `TextArea` may be placed inside any layout container.

**Behavioral edge cases**

`TextArea` inherits all `TextInput` behavioral edge cases. In addition:

- When `wrap = true`, horizontal scrolling is suppressed regardless of `scrollXEnabled`.
- When `rows` is specified, the visible height defaults to that number of rows. Content beyond the visible height is accessible through vertical scrolling.
- A newline insertion command in `TextArea` inserts a newline into the value rather than triggering `onSubmit`.
- When the content height is less than or equal to the visible area, the scroll region behaves as a non-scrolling container.

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

- `root`: the modal subtree root. Required.
- `backdrop`: the blocking region that fills the viewport behind the surface. Required.
- `surface`: the visible content container. Required.
- `content`: the consumer-provided modal body. Required.
- `close controls`: optional consumer-provided dismissal actions within the surface.

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

  ENTRY:
    1. The modal subtree is not mounted in the overlay layer.
    2. The backdrop is not active.
    3. Focus belongs to the base scene layer.

  TRANSITIONS:
    ON open request:
      1. Record the previously focused node when focus restoration is enabled.
      2. Mount the modal subtree into the active overlay layer.
      3. Activate backdrop blocking.
      4. Activate focus trap when `trapFocus = true`.
      5. Move focus into the modal subtree.
      → open

STATE open

  ENTRY:
    1. The modal subtree is mounted and visible.
    2. The backdrop blocks interaction with underlying content.
    3. Focus is restricted to the modal scope when `trapFocus = true`.

  TRANSITIONS:
    ON backdrop activation and `dismissOnBackdrop = true`:
      1. Emit `onOpenChange(false)`.
      → closing

    ON escape command and `dismissOnEscape = true`:
      1. Emit `onOpenChange(false)`.
      → closing

    ON explicit close request:
      1. Emit `onOpenChange(false)`.
      → closing

STATE closing

  ENTRY:
    1. A close has been requested. The consumer has not yet committed the change.

  TRANSITIONS:
    ON close commit:
      1. Remove the modal subtree from the overlay layer.
      2. Deactivate the focus trap.
      3. Restore the previously focused node when `restoreFocus = true` and the node is still valid.
      4. Clear the recorded prior focus.
      → closed

ERRORS:
  - `open` without `onOpenChange` when `open` is intended to be mutable → invalid configuration and deterministic failure.

**Accessibility contract**

`Modal` must define a focus scope that traps traversal when `trapFocus = true`. The surface must be announced to assistive systems as a dialog region. The consumer is responsible for providing a title or label for the modal surface; an unlabeled modal surface must not be used in production interfaces. When the modal opens, focus must move into the surface in a predictable location. When the modal closes and `restoreFocus = true`, focus must return to the element that had focus before the modal opened.

**Composition rules**

`Modal` is an overlay control. Its subtree is mounted in the overlay layer defined by `Stage`, not in the base scene layer. `Modal` may contain any layout or control components. Nested `Modal` instances are supported; each additional modal mounts above the previous overlay and maintains its own focus trap and focus restoration record. The `backdrop` region must intercept all pointer events to prevent interaction with the content beneath it.

**Behavioral edge cases**

- A `Modal` with `trapFocus = true` must not allow focus to escape to the base scene layer while open.
- A `Modal` with `restoreFocus = true` where the previously focused node has been destroyed must not fail. It must simply not restore focus.
- A `Modal` that opens with no focusable content in its surface must not fail. Focus must remain in the modal scope.
- A `Modal` with `dismissOnBackdrop = false` must not dismiss when the backdrop receives a pointer event.
- A `Modal` with `open = false` that receives an explicit close request must take no action.

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

- `root`: the alert subtree root. Required.
- `backdrop`: the blocking region. Required.
- `surface`: the visible alert container. Required.
- `title`: the prominent alert heading. Required.
- `message`: the explanatory body text. Optional.
- `actions`: the container for dismissal and confirmation controls. Required.
- `close controls`: optional secondary dismissal path within the surface.

**Props and API surface**

`Alert` inherits all `Modal` props and adds:

- `title`
- `message`
- `actions`
- `variant: "default" | "destructive" | "success" | "warning"`
- `initialFocus: action identifier | nil`

**State model**

`Alert` inherits the full `Modal` state model.

**Accessibility contract**

`Alert` inherits the `Modal` accessibility contract. Additionally, `Alert` must be announced to assistive systems as an alert dialog. The title must be the accessible name of the surface. When `initialFocus` is specified, focus must move to the identified action on open. When `initialFocus` is not specified, focus must move to the first action in the actions container.

**Composition rules**

`Alert` is an overlay control and follows the `Modal` composition rules. The title and message are non-interactive content. The actions container must contain at least one activation control. Nested interactive controls within the actions container are supported.

**Behavioral edge cases**

`Alert` inherits all `Modal` behavioral edge cases. In addition:

- An `Alert` with no actions must not be used; the absence of any dismissal path creates an inescapable state.
- An `Alert` where `initialFocus` references a non-existent action must fall back to the first action in the container.
- An `Alert` with `variant = "destructive"` must present the destructive variant skin without altering behavior.

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
    2. Trigger focus may rest on the active trigger or on another enabled trigger.
    3. Only the active panel participates in visible presentation and ordinary focus traversal.

  TRANSITIONS:
    ON trigger focus move:
      1. Resolve the next enabled trigger according to orientation, traversal direction, and `loopFocus`.
      2. Move roving focus to that trigger.
      3. Do not change the active value.
      → idle

    ON trigger activation by pointer, touch, or confirm key:
      1. Resolve the trigger value.
      2. Ignore the event if the trigger value is disabled.
      3. Emit `onValueChange` with the requested next value.
      4. Treat the associated panel as active only after the consumer updates `value`.
      → idle

    ON active value becomes invalid because the mapped trigger or panel is removed or disabled:
      1. Resolve the next enabled mapped value by sibling order.
      2. Emit `onValueChange` with the requested replacement value when a replacement exists.
      3. Emit `onValueChange(nil)` when no valid mapped value remains and empty selection is permitted.
      → idle

ERRORS:
  - Duplicate trigger values within one `Tabs` root → invalid configuration and deterministic failure.
  - A trigger without a matching panel, or a panel without a matching trigger → invalid configuration and deterministic failure.
  - `activationMode` other than `"manual"` in this revision → invalid configuration and deterministic failure.
  - `value` without `onValueChange` when `value` is intended to be mutable → invalid configuration and deterministic failure.

**Accessibility contract**

`Tabs` must expose semantic trigger-to-panel association metadata so assistive systems can navigate between a trigger and its corresponding panel. The control must expose which trigger is active, which triggers are disabled, and which panel is currently visible. Keyboard behavior must follow the manual-activation roving-focus pattern: directional keys move focus among enabled triggers; the confirm key activates the focused trigger. Tab key traversal must move focus out of the trigger list into the active panel, not cycle among triggers.

**Composition rules**

`Tabs` composes a trigger list and a panel region inside one shared root. The trigger list may be implemented with scrollable composition when overflow exists, but scrolling must not change the active value. Each trigger value must map to exactly one panel within the same `Tabs` root. Interactive content inside the active panel is supported. Inactive panels must not participate in ordinary focus traversal or pointer targeting.

**Behavioral edge cases**

- A `Tabs` instance with no triggers or no panels must not be used; the specification requires a one-to-one mapping.
- When all triggers are disabled, no active value can be resolved. The component must remain valid and must not fail.
- When `loopFocus = true` and focus is on the last enabled trigger, the next focus movement wraps to the first enabled trigger.
- When `loopFocus = false` and focus is on the last enabled trigger, the next focus movement in that direction takes no action.
- When the active `value` does not match any trigger, no panel is considered active and the component must not fail.
- A `Tabs` instance with a single trigger must remain valid. Focus movement commands take no action when there is only one enabled trigger.

## 7. Composition And Interaction Patterns

All concrete controls in this document inherit the event propagation, focus, responsive, render-effects, and theming contracts defined in [UI Foundation Specification](./ui-foundation-spec.md).

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
- `Modal`: `backdrop`, `surface`, `content`, `close controls`
- `Alert`: `backdrop`, `surface`, `title`, `message`, `actions`

## 9. Deferred Items

- Additional concrete control families
  Reason: this revision is limited to the current bedrock control set.
