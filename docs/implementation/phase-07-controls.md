# Phase 7 — Controls

## Goals

Implement the full set of concrete controls defined in the spec: Text, Button, Checkbox, Switch, TextInput, TextArea, and Tabs. These are all written from scratch. The existing Button and Text implementations in `lib/ui/components/` are reference material only. Controls are built on top of the foundation (Container, Drawable), the event system, and the focus model. They do not yet use the theming token system — visual appearance is handled via hardcoded defaults that Phase 8 will replace with theme-resolved skin tokens.

---

## Dependencies

Requires Phase 5 (Focus system, event propagation, Navigate, Dismiss, Activate events) and Phase 6 (ScrollableContainer, used internally by TextArea). Phase 6 may be built in parallel with Phase 7 if the TextArea is implemented last.

---

## Shared Utilities Introduced

### lib/ui/text/font_cache.lua
Centralized font management shared by Text, TextInput, TextArea, and any control that renders text.
- `FontCache:get(path, size)` — returns a Love2D Font object, loading and caching it on first request. Path is resolved relative to the project root.
- `FontCache:getDefault(size)` — returns a Love2D default font at the given size.
- The cache is a module-level table; fonts are never evicted (they are used for the lifetime of the application).

---

## Controls

### lib/ui/controls/text.lua

**Classification:** Primitive control — static text rendering. No activation semantics. No interaction state.

**Behavior**
- Renders a text string using a Love2D Font.
- `text` prop is consumer-owned. When the text prop changes, the control reflows on the next update pass (marks layout dirty).
- `font` prop — a Love2D Font object or nil (uses default). When nil, the default font at `fontSize` is used.
- `fontSize` prop — used with the FontCache to load or retrieve the font. Default is 16.
- `fontPath` prop — file path for a custom font. Combined with `fontSize` for FontCache lookup.
- `color` prop — RGBA table. Default: {1, 1, 1, 1}.
- `alignX` prop — "start", "center", "end". Controls horizontal text alignment within the content box.
- `wrap` prop (default false) — when true, text wraps at the content box width using Love2D's `printf`.
- `maxWidth` prop — sets the content box width for wrapping purposes. Ignored when `wrap = false`.

**Measurement**
Text measures its own content: when `wrap = false`, width is `font:getWidth(text)`; height is `font:getHeight()`. When `wrap = true`, width is `maxWidth`, height is computed via `font:getWrap(text, maxWidth)`.

**Draw**
Uses `love.graphics.print` (no wrap) or `love.graphics.printf` (wrap). Color and transform applied from parent Container state.

---

### lib/ui/controls/button.lua

**Classification:** Composite control — activation semantics with content slot.

**Parts:** `root` (the button's full bounds Drawable), `content` (inner content slot, a single child Container aligned within the root).

**State machine**
Interaction states (library-owned):
- `hovered` — mouse pointer is over the button; set/cleared by Stage hover tracking.
- `pressed` — pointer is held down on the button (between press and release); set when Activate dragPhase="start" fires on this button, cleared on release.

UI states (negotiated or library-set):
- `focused` — set by Stage during draw pass when this button is the focus owner.
- `disabled` — consumer prop. When `disabled = true`, the button does not receive events (`interactive = false`) and renders in the disabled visual state.

**Priority order for skin variant selection (Phase 8):** disabled > pressed > hovered > focused > base.

In Phase 7 (pre-theming), the button draws a distinct background color for each active state, hardcoded in the draw method. These will be replaced by token-resolved skin colors in Phase 8.

**Activation semantics**
- Pointer activation: `ui.activate` with pointer source fires the `onActivate` callback after propagation (if not `defaultPrevented`). Focus moves to the button before the event dispatches (pointer-focus coupling = "before").
- Keyboard activation: when focused, Space or Enter fires `ui.activate` with keyboard source, which fires `onActivate`.

**Content slot**
- `button:setContent(node)` — sets the single content child node.
- The content child is positioned and aligned within the button's content box (after padding).
- If no content node is set, the button renders with no child content.

**Properties**
- `onActivate` — callback function `function()`. Called after propagation if not prevented.
- `disabled` — boolean (default false).
- `pointerFocusCoupling = "before"` — hardcoded; button always acquires focus on pointer activation.

---

### lib/ui/controls/checkbox.lua

**Classification:** Composite control — tri-state selection.

**Parts:** `root`, `box` (the checkbox indicator area), `indicator` (the checkmark or indeterminate mark), optional `label` (Text), optional `description` (Text).

**State machine**
- `checked` state: "unchecked", "checked", or "indeterminate". Negotiated.
- Interaction states: `hovered`, `focused`, `disabled`.

**Controlled mode:** consumer provides `checked` value (one of "unchecked", "checked", "indeterminate") and `onCheckedChange(newValue)` callback. Library proposes a new value via the callback; the component reflects `checked` only after the consumer commits the new value externally.

**Uncontrolled mode:** library owns the `checked` value. Starts at "unchecked" or the provided `defaultChecked` value.

**Toggle order**
- Default: "unchecked" → "checked" → "unchecked" (two-state).
- When `indeterminate = true` is a possible state (consumer provides "indeterminate" as current or sets `allowIndeterminate = true`): "unchecked" → "checked" → "indeterminate" → "unchecked".

**Activation**
- Pointer or keyboard (Space) activation proposes the next state in the toggle order via `onCheckedChange`.

**Properties**
- `checked` — "unchecked", "checked", or "indeterminate" (controlled mode). Nil = uncontrolled.
- `defaultChecked` — initial value in uncontrolled mode (default "unchecked").
- `onCheckedChange(newValue)` — callback for controlled mode.
- `allowIndeterminate` — boolean (default false). When true, indeterminate is a valid toggle state.
- `label` — string or nil. Displayed to the right of the box.
- `description` — string or nil. Displayed below the label in a smaller style.
- `disabled` — boolean (default false).

---

### lib/ui/controls/switch.lua

**Classification:** Composite control — binary selection with drag activation.

**Parts:** `root`, `track` (the background rail), `thumb` (the sliding indicator), optional `label`, optional `description`.

**State machine**
- `checked` state: true or false. Negotiated.
- Interaction states: `hovered`, `focused`, `disabled`, `dragging`.

**Controlled and uncontrolled modes** — same pattern as Checkbox. `onCheckedChange(newValue)` callback.

**Tap activation**
Pointer press and release on the switch (no drag) proposes the toggled value.

**Drag activation**
- On pointer press: record the initial thumb X position. Set state to `dragging`.
- On pointer move: compute the displacement from press origin. Move the visual thumb position by the displacement, clamped to [0, trackWidth - thumbWidth].
- On pointer release: if the thumb's visual position is past 50% of the available track range, propose `checked = true`. Otherwise propose `checked = false`. Snap the thumb to the committed position.

**Thumb animation**
In the update pass (not draw pass), the thumb's rendered X position is lerped toward its target X position at a configurable speed. When `checked = true`, target is the right end of the track. When `checked = false`, target is the left end. During drag, the target is overridden by the drag position. The lerp speed is fast enough to feel snappy (e.g., 0.12 seconds to complete).

**Properties**
- `checked` — boolean (controlled). Nil = uncontrolled.
- `defaultChecked` — boolean (default false).
- `onCheckedChange(newValue)` — callback.
- `label` — string or nil.
- `description` — string or nil.
- `disabled` — boolean (default false).

---

### lib/ui/controls/text_input.lua

**Classification:** Composite control — single-line text entry.

**Parts:** `root`, `field` (the text rendering area), `placeholder` (hint text shown when value is empty), `selection` (highlight behind selected text range), `caret` (blinking insertion point).

**State machine**
Interaction states: `focused`, `disabled`, `readOnly`, `composing`.
- `composing` is true when a TextCompose event has an active candidate (IME in progress).

**Controlled mode:** `value` prop + `onValueChange(newValue)` callback. Library never writes the `value` prop. While awaiting the consumer's update, the component reflects the last committed consumer value. Interaction state (caret position, selection) is still library-owned.

**Uncontrolled mode:** library owns the text buffer. `defaultValue` sets the initial content.

**Text input mode**
- When the TextInput gains focus, Stage calls `love.keyboard.setTextInput(true)` automatically.
- When focus leaves, Stage calls `love.keyboard.setTextInput(false)`.
- This is handled by Stage in response to `ui.focus.change` events: Stage checks whether the new focus owner (or previous focus owner) is a TextInput or TextArea, and issues the platform call accordingly.

**Text buffer (uncontrolled) or reflected value (controlled)**
The internal text buffer stores the current displayed string. In controlled mode it is synchronized to the `value` prop at the start of each update pass. In uncontrolled mode it is the authoritative state.

**Caret and selection**
- `_caretPos` — byte position within the string (0-indexed, before the character at this position).
- `_selectionStart`, `_selectionEnd` — byte range of the current selection. When equal to `_caretPos`, no selection is active.
- Negotiated: consumer may provide `selectionStart` and `selectionEnd` props plus `onSelectionChange(start, end)` callback.

**Keyboard handling (via ui.text.input and ui.navigate events)**
- Printable text from `ui.text.input`: insert at caret, advance caret, clear selection.
- Backspace (treated as a special Navigate or by checking the raw key in the text input mode): delete selection or character before caret.
- Delete: delete selection or character after caret.
- Arrow left/right: move caret one character; with Shift, extend selection.
- Home/End: move caret to line start/end; with Shift, extend selection.
- Ctrl+A: select all.
- Ctrl+C: copy selection to clipboard via `love.system.setClipboardText`.
- Ctrl+X: cut selection (copy + delete).
- Ctrl+V: paste from clipboard via `love.system.getClipboardText`, insert at caret.

**IME composition**
- `ui.text.compose` event arrives with `text` (candidate string), `rangeStart`, `rangeEnd`.
- While composing, the candidate string is displayed at the caret position with an underline decoration.
- The caret does not blink during composition.
- When the composition commits (a `ui.text.input` event with the final text arrives after a compose sequence), the candidate is replaced by the committed text.
- When composition is cancelled, the candidate is cleared with no text inserted.

**Caret blink**
The caret blinks on a configurable interval. In Phase 7 the interval is hardcoded at 0.5 seconds on / 0.5 seconds off. Phase 8 will read this from a timing token. The blink state resets to "on" whenever the caret position changes.

**Submit behavior**
- `"blur"` — when Enter is pressed, focus moves away from the field (focus cleared or moves to next sequential item).
- `"submit"` — when Enter is pressed, `onSubmit(value)` is called; focus stays in the field.
- `"none"` — Enter is ignored in the field.
Default: `"blur"`.

**Properties**
- `value` — string (controlled). Nil = uncontrolled.
- `defaultValue` — string (default "").
- `onValueChange(newValue)` — callback.
- `selectionStart`, `selectionEnd` — number (controlled selection). Nil = uncontrolled selection.
- `onSelectionChange(start, end)` — callback.
- `onSubmit(value)` — callback for submitBehavior="submit".
- `placeholder` — string or nil. Shown when value is empty and the field is not focused.
- `maxLength` — number or nil. Limits the maximum byte length of the value.
- `disabled` — boolean (default false).
- `readOnly` — boolean (default false). Allows focus and selection but not value changes.
- `submitBehavior` — "blur", "submit", or "none" (default "blur").

---

### lib/ui/controls/text_area.lua

**Classification:** Composite control — multiline text entry. Inherits TextInput contract.

**Differences from TextInput**
- The text buffer is multiline. Lines are separated by newline characters.
- Enter/Return inserts a newline character into the buffer (does not trigger submit behavior regardless of `submitBehavior`).
- `wrap` prop (default true) — when true, text wraps at the content-box width. When false, lines extend beyond the content-box width and horizontal scrolling is active.
- Internal scrolling is implemented by wrapping the field contents in a ScrollableContainer (Phase 6). The ScrollableContainer's `scrollYEnabled` is always true; `scrollXEnabled` is true only when `wrap = false`.
- The caret position is tracked as a 2D position (line, column) in addition to the flat byte offset.
- Page Up/Down while focused scrolls the visible area by one viewport height.

**Properties (additional beyond TextInput)**
- `wrap` — boolean (default true).
- `rows` — number or nil. If set, the TextArea configures its height to display approximately this many rows of text (at the current font's line height). If nil, the TextArea takes the height assigned by its parent layout.

---

### lib/ui/controls/tabs.lua

**Classification:** Composite control — single-selection navigation with trigger list and panel mapping.

**Parts:** `root`, `list` (the trigger list container, a Row), `triggers` (individual trigger Drawables, one per tab), `indicator` (active-trigger highlight), `panel` (the currently active panel container), `panels` (all panel Drawables, only one visible at a time).

**Structure**
- Consumer registers tabs via `tabs:addTab(value, triggerContent, panelContent)`:
  - `value` — unique identifier for this tab (string).
  - `triggerContent` — a node displayed inside the trigger button area.
  - `panelContent` — a node displayed when this tab is active.
- Every trigger must have a matching panel (same `value`). Registering a trigger without a matching panel is a hard failure at registration time.

**State machine**
- `value` — the currently active tab's value. Negotiated.
- Controlled mode: `value` prop + `onValueChange(newValue)` callback.
- Uncontrolled mode: library owns value, defaults to the first registered tab's value.

**Roving focus**
- The trigger list uses roving focus: exactly one trigger is in the sequential focus order at a time (the currently active trigger). Directional navigation (left/right arrow keys) moves the roving focus indicator among triggers without activating them.
- Activation (Space or Enter on the roving-focused trigger): activates that tab (proposes via `onValueChange`).
- This means that from outside the Tabs, pressing Tab moves into the trigger list; once inside, left/right navigate triggers; Tab moves out to the panel or next focusable element.

**Panel visibility**
Only the panel matching the active `value` is visible (`visible = true`). All other panels are hidden (`visible = false`) but remain in the tree (they are not destroyed). This preserves uncontrolled state within panels between activations.

**Disabled triggers**
Individual triggers can be disabled: `tabs:setTriggerDisabled(value, true)`. Disabled triggers are skipped by roving focus navigation and cannot be activated.

**Properties**
- `value` — string (controlled). Nil = uncontrolled.
- `defaultValue` — string or nil. Used in uncontrolled mode; defaults to first tab's value.
- `onValueChange(newValue)` — callback.

---

## Test

**Location:** `test/phase7/`

**Navigation:** Left/right arrow keys switch screens. Chrome drawn with raw Love2D.

**Screen 1 — Text variants**
Five Text controls arranged vertically:
1. Heading-size text (32px bold via font settings).
2. Body text (16px).
3. Caption text (12px).
4. A long paragraph with `wrap = true` and `maxWidth = 300`, demonstrating word wrap and multi-line layout.
5. A Text whose content is updated every 2 seconds to a new random string (demonstrates reflow on content change). A "Change font size" button (raw Love2D) cycles through three font sizes; the Text control relays out live.

**Screen 2 — Button states**
A 5-column grid of Buttons, one column per state: normal, hovered (mouse forced over it with a raw cursor indicator), pressed (held), focused (Tab to it), disabled. Each Button has a click counter label as its content child. Pressing Tab cycles focus through the Buttons; Space/Enter on a focused button increments its counter. The currently focused button shows the focus ring. Disabled buttons show no counter change and no hover/press response.

**Screen 3 — Checkbox and Switch**
Left column: five Checkboxes — unchecked (uncontrolled), checked (uncontrolled), indeterminate (uncontrolled with `allowIndeterminate = true`), disabled unchecked, disabled checked. Right column: five Switches — off (uncontrolled), on (uncontrolled), drag-to-switch (uncontrolled with a wide track to make drag visible), disabled off, disabled on. A "controlled" row at the bottom shows a Checkbox and Switch both in controlled mode where the state only flips when a counter (auto-incrementing every 3 seconds) is divisible by 3.

**Screen 4 — TextInput scenarios**
Six TextInput controls stacked vertically:
1. Default: empty, placeholder "Type here".
2. Pre-filled value (uncontrolled).
3. `maxLength = 20` — prevents typing beyond 20 characters; length counter shown.
4. `disabled = true` — no focus, no typing.
5. `readOnly = true` — can focus and select; cannot type.
6. Submit behavior = "submit" — Enter fires `onSubmit` and logs the value in a side panel.
All fields: caret visible when focused, selection via Shift+arrow, clipboard Ctrl+C/X/V. If the system supports IME, composition candidates are shown underlined.

**Screen 5 — TextArea scenarios**
Two TextAreas side by side:
- Left: `wrap = true`, tall height; Enter inserts newlines; vertical scroll activates when content exceeds height.
- Right: `wrap = false`, medium height; long lines extend horizontally; horizontal scroll bar visible. Both show caret and selection. A counter below each shows the current line and column position.

**Screen 6 — Tabs**
Three tabs: "Home", "Settings", "Profile". Each panel has distinct content:
- Home: a few Text nodes.
- Settings: a Column of Switches.
- Profile: a TextInput.

Tab trigger list at top. Tab key enters the trigger list; left/right navigate triggers without activating; Space/Enter activates. The panel updates to show the active tab's content. A "Controlled variant" toggle at the bottom switches to a controlled Tabs instance driven by three raw Love2D buttons, demonstrating the value + onValueChange ownership model. Disabling the "Settings" trigger is demonstrated with a "D" key.

---

## Hard Failures in This Phase

- `tabs:addTab` called with a `value` that already exists must raise a hard error (duplicate tab values are forbidden).
- Activating a TextInput or TextArea after the Stage has been destroyed must not crash — it must silently do nothing.
- A Checkbox in controlled mode with an `onCheckedChange` callback that returns the same value (no state change) must not create a visual inconsistency — the control must reflect the last committed consumer value, not the proposed value.
- A Button with `disabled = true` must have `interactive = false` set automatically; manually setting `interactive = true` on a disabled Button must be overridden back to false at the next update pass.
- TextInput with `maxLength` set and a paste operation that would exceed the limit must truncate the pasted text at the limit boundary, not crash or silently accept the overflow.
