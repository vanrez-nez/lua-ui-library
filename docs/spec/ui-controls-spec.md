# UI Controls Specification

> Version `0.1.1` — additive revision. Release history and change management policy: [UI Evolution Specification](./ui-evolution-spec.md).

## 3. Glossary

All terminology defined in [UI Foundation Specification](./ui-foundation-spec.md), [UI Graphics Specification](./ui-graphics-spec.md), and [UI Motion Specification](./ui-motion-spec.md) is binding in this document.

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
- `Radio`
- `RadioGroup`
- `Switch`
- `Slider`
- `ProgressBar`
- `Select`
- `Option`
- `TextInput`
- `TextArea`
- `Tabs`
- `Modal`
- `Alert`
- `Notification`
- `Tooltip`

The foundation contracts for event propagation, focus, responsive rules, runtime layers, render effects, theming, motion integration, contract stability, and failure semantics remain authoritative and are not redefined here.

## 4A. Control Classification And Identity

The component-model rules in Section 3A of [UI Foundation Specification](./ui-foundation-spec.md) are binding for all controls in this document.

`Boundary type` is normative:

- `fixed` means the consumer may configure or style the control but may not extend what the library treats as the control's correctness boundary
- `extensible through documented slots only` means consumer content may be supplied through named slots or descendants, but the control's owned behavior remains fixed

| Control | Tier | Sole responsibility | Explicitly does not manage | Boundary type |
|---------|------|---------------------|----------------------------|---------------|
| `Text` | Primitive | text measurement, wrapping, alignment, and text-style resolution for supplied content | editing, selection, activation, text-entry lifecycle | fixed |
| `Button` | Composite | activation semantics around one content slot, including disabled, hover, press, and focus behavior | business action side effects, nested interactive coordination, application state ownership | extensible through documented slots only |
| `Checkbox` | Composite | checked, unchecked, and indeterminate state requests plus associated activation semantics | external state storage, form submission orchestration, nested interactive content | extensible through documented slots only |
| `Radio` | Composite | activation semantics for one single-selection option coordinated by an owning `RadioGroup`, including disabled, focus, and associated-label behavior | independent selected-state ownership, multi-select behavior, business action side effects | extensible through documented slots only |
| `RadioGroup` | Composite | one-of-many value coordination, required single selection, roving focus, directional navigation, and descendant radio registration | multi-select behavior, arbitrary option virtualization policy, business state outside the selected value | extensible through documented slots only |
| `Switch` | Composite | binary state requests with tap, drag, and disabled semantics | indeterminate state, settings persistence, nested interactive content | extensible through documented slots only |
| `Slider` | Composite | continuous range input through thumb dragging, track activation, keyboard adjustment, step quantization, and orientation-specific value resolution | multiple thumbs, tick labeling, buffer progress, arbitrary rich content inside the control | fixed |
| `ProgressBar` | Primitive | presentational progress indication for determinate and indeterminate progress values, range normalization, and orientation-specific fill resolution | activation semantics, editable state, buffer progress, built-in text labeling, native platform progress delegation | fixed |
| `Select` | Composite | trigger and popup coordination, single or multiple selection resolution, open-state requests, option registration, placeholder/summary rendering, and popup dismissal policy | native platform picker delegation, search/typeahead, arbitrary popup queueing policy, business state outside the selected value | extensible through documented slots only |
| `Option` | Composite | activation semantics for one selectable value coordinated by an owning `Select`, including disabled, focus, and associated-description behavior | independent selected-state ownership, standalone popup behavior, arbitrary rich interactive descendants | extensible through documented slots only |
| `TextInput` | Composite | single-line text entry, caret, selection, composition, clipboard, and active text-input ownership | multiline editing, rich-text authoring, consumer-managed native text-input lifecycle | fixed |
| `TextArea` | Composite | multiline text entry with internal scrolling on the owned field content | single-line submit semantics, external scroll orchestration on owned axes, rich-text authoring | fixed |
| `Tabs` | Composite | one-to-one trigger and panel coordination, active-value resolution, and roving focus | closable or reorderable tabs, swipe navigation, business state inside panels | extensible through documented slots only |
| `Modal` | Composite | blocking overlay behavior, open-state requests, focus trapping, focus restoration, and backdrop policy | scene navigation, workflow policy, overlay stacking outside the overlay layer contract | extensible through documented slots only |
| `Alert` | Composite | alert-dialog pattern over `Modal`, including title, message, actions, and initial-focus rules | arbitrary modal taxonomies, non-dismissible flows, action side effects | extensible through documented slots only |
| `Notification` | Composite | non-blocking overlay status presentation, edge-based placement, timed or explicit dismissal, and stack participation | modal blocking, focus trapping, arbitrary action regions, queue-management policy beyond one instance's contract | extensible through documented slots only |
| `Tooltip` | Composite | anchored non-modal descriptive overlay presentation, preferred-placement fallback resolution, open-state requests, and trigger-to-surface association | modal blocking, focus trapping, arbitrary interactive popup content, generic overlay-manager policy | extensible through documented slots only |

Additional control identity rules:

- `TextArea` inherits behavior from `TextInput` but remains a distinct component identity with its own multiline and scroll contract.
- `Radio` is not an alias of `Checkbox`; it is a separate single-selection option control coordinated by one owning `RadioGroup`.
- `RadioGroup` is not a generic layout container; it is a state-owning compound root with required descendant `Radio` registration.
- `Option` is not a generic list item; it is a selectable descendant coordinated by one owning `Select`.
- `Select` is not a native-platform abstraction in this revision; it is the canonical custom select control with a trigger and popup surface.
- `Slider` is the canonical continuous-range input control in this revision. No `Trackbar` alias is stabilized.
- `ProgressBar` is a distinct progress-indication control, not an alias of `Drawable` or a theme-only fill helper.
- `Alert` is not an alias of `Modal`; it is a separate composite with a stronger content contract and a distinct accessible role.
- `Notification` is not an alias of `Modal` or `Alert`; it is a separate overlay composite with non-modal status behavior and a single content region.
- `Tooltip` is not an alias of `Notification`, `Select`, or `Modal`; it is a distinct anchored overlay composite with trigger-associated descriptive content.
- The exact control names in this table are the canonical names for this revision. No aliases are stabilized.
- Named anatomy parts and stabilized theming parts are contract surface. Internal helper structure that is not named remains an implementation detail.

## 4B. Control Composition Grammar

The composition-grammar rules in Section 3B of [UI Foundation Specification](./ui-foundation-spec.md) are binding for all controls in this document.

### 4B.1 Control Validity Rules

| Control | Allowed parents | Allowed children or fillers | Prohibited children or fillers | Required children or slots | Standalone validity |
|---------|-----------------|-----------------------------|-------------------------------|----------------------------|--------------------|
| `Text` | any component with an open descendant slot or text-bearing content slot | none | all child nodes | none | valid |
| `Button` | any component with an open descendant slot or action-bearing slot | zero or one `content` subtree composed of text or drawable structure | nested interactive controls inside `content` | `content` slot exists as part of the contract, but it may be empty | valid |
| `Checkbox` | any component with an open descendant slot or action-bearing slot | optional `label`; optional `description` | nested interactive controls inside label or description regions | none | valid |
| `Radio` | only an owning `RadioGroup` root or its required radio container region when such a region is used internally | optional `label`; optional `description` | placement outside an owning `RadioGroup`; nested interactive controls inside label or description regions | `value` prop on the `Radio` instance | invalid when detached from an owning `RadioGroup` |
| `RadioGroup` | any component with an open descendant slot or action-bearing slot | one or more registered `Radio` descendants | direct interactive descendants that are not registered radios; zero registered radios; duplicate radio values | at least one `Radio` | valid only when the required radio set is complete |
| `Switch` | any component with an open descendant slot or action-bearing slot | optional `label`; optional `description` | nested interactive controls inside label or description regions | none | valid |
| `Slider` | any component with an open descendant slot or action-bearing slot | none | all child nodes | none | valid |
| `ProgressBar` | any component with an open descendant slot or presentational content slot | none | all child nodes | none | valid |
| `Option` | only an owning `Select` popup region | optional `label`; optional `description` | placement outside an owning `Select`; nested interactive controls inside label or description regions | `value` prop on the `Option` instance | invalid when detached from an owning `Select` |
| `Select` | any component with an open descendant slot or action-bearing slot | one trigger surface and one or more registered `Option` descendants in the popup region | zero registered options; duplicate option values; direct interactive descendants that are not registered options inside the popup option set | at least one `Option` | valid only when the required option set is complete |
| `TextInput` | any layout or drawable container that permits interactive descendants | none | interactive child nodes; nesting inside another text-entry control | none | valid |
| `TextArea` | any layout or drawable container that permits interactive descendants | none | interactive child nodes; nesting inside another text-entry control; nesting inside a scroll container that intercepts the same owned scroll axis | none | valid |
| `Modal` | only the `overlay layer` owned by `Stage` | one `surface` subtree containing one `content` subtree; optional consumer close controls | placement in the base scene layer; direct interaction with underlying scene content while mounted | `surface`, `content` | invalid when detached from the overlay layer |
| `Alert` | only the `overlay layer` owned by `Stage` as a specialized `Modal` | required `title` and `actions`; optional `message`; optional close controls | absence of any action control; placement outside the overlay layer | `title`, `actions` | invalid when detached from the overlay layer |
| `Notification` | only the `overlay layer` owned by `Stage` | one `surface` subtree containing one `content` subtree; optional library-owned close control when `closeMethod = "button"` | placement in the base scene layer; nested interactive controls inside `content`; backdrop regions; focus-trap ownership | `surface`, `content` | invalid when detached from the overlay layer |
| `Tooltip` | any component with an open descendant slot or action-bearing slot | exactly one `trigger` subtree in ordinary composition; one overlay-mounted `surface` subtree containing one `content` subtree while open | nested interactive controls inside `content`; backdrop regions; focus-trap ownership; detached tooltip surface with no owning trigger | `trigger`, `content` | valid only when the trigger subtree exists |
| `Tabs` | any component with an open descendant slot | one `list` region and one `panels` region containing mapped `trigger` and `panel` sub-parts | unmatched triggers or panels; duplicate trigger values; trigger lists without panels or panels without triggers | `list`, `panels`, at least one mapped `trigger`/`panel` pair | valid only when the required pair structure is complete |

Validity notes:

- `Button`, `Checkbox`, and `Switch` are compositionally open only through their documented content-bearing regions.
- `Radio` is compositionally open only through its documented `label` and `description` regions and must belong to exactly one owning `RadioGroup`.
- `RadioGroup` validity is re-evaluated whenever registered radios are added, removed, disabled, or change value.
- `Slider` exposes named presentational parts but no consumer-fillable descendant slots in this revision.
- `ProgressBar` exposes named presentational parts but no consumer-fillable descendant slots in this revision.
- `Option` is compositionally open only through its documented `label` and `description` regions and must belong to exactly one owning `Select`.
- `Select` validity is re-evaluated whenever registered options are added, removed, disabled, or change value.
- `TextInput` and `TextArea` expose named presentational parts but no consumer-fillable descendant slots in this revision.
- `Modal`, `Alert`, and `Notification` are invalid as ordinary descendants of base-scene layout or control containers because their parent relationship is defined by overlay mounting, not ordinary containment.
- `Tooltip` remains an ordinary descendant through its `trigger` subtree but mounts its owned tooltip surface into the overlay layer while open.
- `Tabs` validity is re-evaluated whenever trigger or panel structure changes; insertion into an arbitrary ancestor does not preserve validity unless the full `Tabs` contract remains satisfied.

### 4B.2 Compound Control Contracts

| Root | Required sub-parts | Optional sub-parts | Independent meaning outside the root | Structural communication mechanism | Sub-part set |
|------|--------------------|--------------------|--------------------------------------|-----------------------------------|--------------|
| `Button` | `root`, `content` | `indicator` | `content` may contain independent components; `indicator` has no independent meaning outside `Button` | root-owned slot resolution for `content` | closed except for the open `content` slot |
| `Checkbox` | `root`, `box` | `indicator`, `label`, `description` | `label` and `description` may contain independent components; `box` and `indicator` are meaningful only within `Checkbox` | root-owned role resolution of label-participation and activation region | closed except for `label` and `description` content |
| `Radio` | `root`, `indicator` | `label`, `description` | `label` and `description` may contain independent components; `indicator` is meaningful only within `Radio` | structural registration to the owning `RadioGroup` root by `value` and role | closed except for `label` and `description` content |
| `RadioGroup` | `root`, one or more `Radio` | none | registered radios have no group selection meaning outside one owning `RadioGroup` root | structural registration of each `Radio` to the owning `RadioGroup` root by value and role | closed |
| `Switch` | `root`, `track`, `thumb` | `label`, `description` | `label` and `description` may contain independent components; `track` and `thumb` are meaningful only within `Switch` | root-owned role resolution of drag region and associated content | closed except for `label` and `description` content |
| `Slider` | `root`, `track`, `thumb` | none | `track` and `thumb` are meaningful only within `Slider` | root-owned range normalization, drag progression, and step quantization | closed |
| `ProgressBar` | `root`, `track`, `indicator` | none | `track` and `indicator` are meaningful only within `ProgressBar` | root-owned range normalization and fill resolution | closed |
| `Option` | `root` | `label`, `description` | `label` and `description` may contain independent components, but their option role exists only within one owning `Select` | structural registration to the owning `Select` root by `value` and role | closed except for `label` and `description` content |
| `Select` | `root`, `trigger`, `popup`, one or more `Option` | `placeholder` | registered options and the popup role have no select meaning outside one owning `Select` root | root-owned trigger/popup coordination plus structural registration of each `Option` by value and role | closed except for documented content regions |
| `Modal` | `root`, `backdrop`, `surface`, `content` | `close controls` | `content` may contain independent components; the structural roles have no independent overlay meaning outside `Modal` | overlay-layer mounting plus root-owned slot resolution inside `surface` | closed except for the open `content` region |
| `Alert` | `root`, `backdrop`, `surface`, `title`, `actions` | `message`, `close controls` | `title`, `message`, and `actions` may contain independent components, but their alert roles exist only within `Alert` | specialized `Modal` slot resolution with required action-region presence | closed except for documented content regions |
| `Notification` | `root`, `surface`, `content` | `close control` | `content` may contain independent non-interactive components, but its notification role exists only within `Notification` | overlay-layer mounting plus root-owned slot resolution inside `surface` | closed except for the open `content` region |
| `Tooltip` | `root`, `trigger`, `surface`, `content` | none | `trigger` may contain independent components; `content` may contain independent non-interactive components, but the tooltip role exists only within `Tooltip` | root-owned trigger association plus overlay-layer mounting of the `surface` while open | closed except for the open `trigger` and `content` regions |
| `Tabs` | `root`, `list`, `panels`, one or more `trigger`, one or more `panel` | `indicator` | `trigger` and `panel` roles have no valid independent meaning outside one owning `Tabs` root | structural registration of each `trigger` and `panel` to the owning `Tabs` root by mapped value and role | closed |

### 4B.3 Control Slot Declarations

| Control | Slot or region | Multiplicity | Filler constraints | Default content |
|---------|----------------|--------------|--------------------|-----------------|
| `Button` | `content` | zero or one subtree | text or drawable structure; no nested interactive controls | empty content is allowed |
| `Checkbox` | `label` | zero or one subtree | non-interactive associated content | none |
| `Checkbox` | `description` | zero or one subtree | non-interactive associated content | none |
| `Radio` | `label` | zero or one subtree | non-interactive associated content | none |
| `Radio` | `description` | zero or one subtree | non-interactive associated content | none |
| `Switch` | `label` | zero or one subtree | non-interactive associated content | none |
| `Switch` | `description` | zero or one subtree | non-interactive associated content | none |
| `Option` | `label` | zero or one subtree | non-interactive associated content | none |
| `Option` | `description` | zero or one subtree | non-interactive associated content | none |
| `Select` | `placeholder` | zero or one subtree | non-interactive summary fallback content owned by the trigger surface | `"None selected"` when the placeholder prop is not supplied |
| `Modal` | `content` | exactly one subtree | any layout or control components valid in overlay content | none |
| `Alert` | `title` | exactly one subtree | non-interactive heading content | none |
| `Alert` | `message` | zero or one subtree | non-interactive explanatory content | none |
| `Alert` | `actions` | one or more activation controls | controls that provide an explicit dismissal or confirmation path | none |
| `Notification` | `content` | exactly one subtree | non-interactive text, drawable content, or layout structure; no nested interactive controls | none |
| `Tooltip` | `trigger` | exactly one subtree | any single subtree valid in ordinary scene composition; becomes the tooltip anchor region | none |
| `Tooltip` | `content` | exactly one subtree | non-interactive text, drawable content, or layout structure; no nested interactive controls | none |
| `Tabs` | `list` | exactly one region | contains only `trigger` sub-parts for the owning `Tabs` root | none |
| `Tabs` | `panels` | exactly one region | contains only `panel` sub-parts for the owning `Tabs` root | none |

Trace note: documented slots, regions, and structural registration are public composition surface, but they do not imply a stable imperative builder API such as `setContent(...)`, `addTab(...)`, or similar helper methods unless a control section explicitly documents one.

## 4C. Control State Model

The state-model rules in Section 3C of [UI Foundation Specification](./ui-foundation-spec.md) are binding for all controls in this document.

### 4C.1 Shared Control Ownership Rules

All interactive controls in this revision additionally own library-managed interaction state for hover, focus participation, pointer capture, drag progress, and composition-candidate presence when those concepts apply.

That shared interaction state:

- is library-owned unless a control explicitly exposes one of those values as a negotiated public property
- is not readable through a stable imperative API in this revision
- may affect behavior and visual variant resolution without becoming consumer-owned state

### 4C.2 Public State Ownership Matrix

| Control | Public state property | Category | Ownership mode | Controlled signal | Uncontrolled default |
|---------|-----------------------|----------|----------------|-------------------|----------------------|
| `Text` | `text` content | application state | consumer-owned only | `text` prop | none; `Text` does not own mutable public text state |
| `Button` | `pressed` | interaction state | negotiated | `pressed` with `onPressedChange` | `false` |
| `Checkbox` | `checked` | application state | negotiated | `checked` with `onCheckedChange` | `unchecked` |
| `RadioGroup` | `value` | application state | negotiated | `value` with `onValueChange` | first enabled registered radio value |
| `Switch` | `checked` | application state | negotiated | `checked` with `onCheckedChange` | `false` |
| `Slider` | `value` | application state | negotiated | `value` with `onValueChange` | `min` |
| `ProgressBar` | `value` | application state | consumer-owned only | `value` prop | none; `ProgressBar` does not own mutable public progress state |
| `ProgressBar` | `indeterminate` | UI state | consumer-owned only | `indeterminate` prop | `false` |
| `Select` | `value` | application state | negotiated | `value` with `onValueChange` | `nil` |
| `Select` | `open` | UI state | negotiated | `open` with `onOpenChange` | `false` |
| `TextInput` | `value` | application state | negotiated | `value` with `onValueChange` | empty string |
| `TextInput` | `selectionStart` and `selectionEnd` as one property pair | UI state | negotiated | both selection boundaries plus `onSelectionChange` | collapsed selection at end of current value |
| `TextArea` | `value` | application state | negotiated | `value` with `onValueChange` | empty string |
| `TextArea` | `selectionStart` and `selectionEnd` as one property pair | UI state | negotiated | both selection boundaries plus `onSelectionChange` | collapsed selection at end of current value |
| `Modal` | `open` | UI state | negotiated | `open` with `onOpenChange` | `false` |
| `Alert` | `open` | UI state | negotiated through `Modal` | `open` with `onOpenChange` | `false` |
| `Notification` | `open` | UI state | negotiated | `open` with `onOpenChange` | `false` |
| `Tooltip` | `open` | UI state | negotiated | `open` with `onOpenChange` | `false` |
| `Tabs` | `value` | composition state | negotiated | `value` with `onValueChange` | first enabled mapped trigger value, otherwise `nil` |

Hybrid notes:

- `TextInput` and `TextArea` may control `value` and selection independently because those properties have separate ownership signals.
- `Checkbox`, `RadioGroup`, `Switch`, `Slider`, `Select`, `Modal`, `Alert`, `Notification`, `Tooltip`, and `Tabs` expose one or more negotiable public state properties in this revision.
- `Button` exposes negotiable `pressed` state, but hover and focus remain library-owned interaction state.

Trace note: the `Uncontrolled default` column defines the initial uncontrolled state when a control owns that value; it does not by itself standardize a corresponding `default*` prop unless the control's own props section names one explicitly.

### 4C.3 Pending And Uncontrolled Behavior

Pending controlled behavior:

- `Button`, `Checkbox`, `RadioGroup`, `Switch`, `Slider`, `Select`, `Modal`, `Alert`, `Notification`, `Tooltip`, and `Tabs` must continue to render and behave from the last committed controlled value until the consumer updates that value.
- `TextInput` and `TextArea` must continue to render the last committed controlled `value` and controlled selection while allowing library-owned interaction state such as focus and composition candidate presence to continue updating.

Uncontrolled observation:

- no control in this revision exposes a stable imperative getter or setter for uncontrolled public state
- uncontrolled state changes remain observable through change callbacks, accessibility metadata, composition effects, and visible committed output

### 4C.4 Composition-State Scope And Coordination

Composition-state rules for concrete controls:

- `Tabs` is the only concrete control in this revision with public composition state. Its active value is scoped to the nearest `Tabs` root and coordinates registered triggers and panels only within that root.
- `RadioGroup` owns public group-selection state scoped to the nearest `RadioGroup` root and coordinates registered radios only within that root.
- `Select` owns public selection and open state scoped to the nearest `Select` root and coordinates registered options only within that root.
- `Modal` and `Alert` use library-owned focus-trap coordination and overlay ownership state scoped to the mounted overlay subtree. That coordination state is not a consumer-owned public value.
- `Notification` uses library-owned overlay ownership, dismissal timer, and stack-placement coordination scoped to the mounted overlay subtree. That coordination state is not a consumer-owned public value.
- `Tooltip` uses library-owned anchor-geometry, hover and focus observation, and fallback-placement coordination scoped to the owning root and mounted tooltip surface. That coordination state is not a consumer-owned public value.
- `Checkbox` and `Switch` do not automatically coordinate with sibling selection controls in this revision. Any shared checked-value semantics across multiple controls must be provided explicitly by the consumer.

### 4C.5 Control Derived State

| Control | Stable derived state | Derivation rule |
|---------|----------------------|-----------------|
| `Button` | effective pressed state | controlled `pressed` when present, otherwise library-owned press interaction state |
| `Checkbox` | effective checked state | controlled `checked` when present, otherwise the uncontrolled checked value after toggle-order resolution |
| `Radio` | effective selected state, effective disabled state within the group | selected when its `value` matches the owning `RadioGroup` effective value; disabled when the radio is disabled directly or its value is disabled by group policy |
| `RadioGroup` | effective selected value, focused radio candidate | controlled `value` when present, otherwise the first enabled registered radio value after registration and invalid-value repair |
| `Switch` | effective checked state | controlled `checked` when present, otherwise the uncontrolled checked value after tap or drag resolution |
| `Slider` | effective clamped value, effective stepped value, thumb position ratio | clamp `value` into `[min, max]`; quantize to `step` when one is provided; derive thumb position from the resulting normalized ratio |
| `ProgressBar` | effective clamped value, effective normalized progress ratio, effective indeterminate mode | clamp `value` into `[min, max]` when determinate; derive normalized ratio from the clamped value and range; ignore determinate ratio when `indeterminate = true` |
| `Option` | effective selected state, effective disabled state within the select | selected when its `value` is present in the owning `Select` effective selection set; disabled when the option is disabled directly or its value is disabled by select policy |
| `Select` | effective selected value set, effective open state, focused option candidate | controlled `value` and `open` when present, otherwise uncontrolled selection and popup state; in `single` mode the effective selected set contains zero or one value, in `multiple` mode it contains zero or more unique values in option registration order |
| `TextInput` | effective value, effective selection | controlled value and selection when present, otherwise uncontrolled committed text and library-managed selection |
| `TextArea` | effective value, effective selection, effective scrollability | `TextArea` derives the same committed editing values as `TextInput`, plus scrollability from content extent, wrap mode, and visible field size |
| `Modal` | effective open state | controlled `open` when present, otherwise uncontrolled mounted state |
| `Alert` | effective open state | `Alert` uses the `Modal` derivation for `open` |
| `Notification` | effective open state, effective dismissal mode, effective timed duration | controlled `open` when present, otherwise uncontrolled mounted state; `closeMethod` resolves the owned dismissal path; `duration` resolves to `5000` only when `closeMethod = "auto-dismiss"` and no explicit duration is supplied |
| `Tooltip` | effective open state, resolved placement, effective anchor region | controlled `open` when present, otherwise uncontrolled hover or focus driven mounted state according to `triggerMode`; resolve placement from the preferred `placement`, `align`, `offset`, and the anchored-overlay fallback rules in the foundation specification |
| `Tabs` | effective active value, active panel visibility | controlled `value` when present, otherwise uncontrolled active value resolution from the mapped enabled trigger set |

The following remain implementation detail and are not stable derived-state API:

- hover timers, drag velocity estimates, pointer-capture bookkeeping, and inertial decay accumulators
- text composition candidate storage beyond the documented composing mode
- cached layout dirtiness or visual-variant bookkeeping used only to render from committed authoritative state

## 4D. Control Interaction Model

The interaction-model rules in Section 3D of [UI Foundation Specification](./ui-foundation-spec.md) are binding for all controls in this document.

### 4D.1 Control Input-To-Callback Mapping

| Control | Logical inputs recognized | Public callback or event surface | Default action when not cancelled |
|---------|---------------------------|----------------------------------|-----------------------------------|
| `Text` | none | none | no interaction default action |
| `Button` | `Activate`, pointer-derived hover transitions | `onActivate`, `onPressedChange` when `pressed` is exposed | request pressed-state changes and dispatch activation |
| `Checkbox` | `Activate` | `onCheckedChange` | resolve the next checked state from `toggleOrder` and propose it |
| `Radio` | `Activate` | `onValueChange` on the owning `RadioGroup` | propose the radio's value through the owning group when the target radio is enabled and not already selected |
| `RadioGroup` | `Navigate`, `Activate` through registered radios | `onValueChange` | move roving focus among enabled radios on navigation and propose a new selected value only on activation |
| `Switch` | `Activate`, `Drag` | `onCheckedChange` | toggle on tap activation or resolve final checked state at drag release |
| `Slider` | `Activate`, `Drag`, `Navigate` | `onValueChange` | resolve the next clamped or stepped value from track activation, thumb drag, or keyboard adjustment and propose it |
| `ProgressBar` | none | none | no interaction default action |
| `Option` | `Activate` | `onValueChange` on the owning `Select`; `onOpenChange` when selection commits close the popup | propose the option's value through the owning select according to `selectionMode` and close behavior |
| `Select` | `Activate` on the trigger, `Dismiss`, `Navigate`, `Activate` through registered options | `onValueChange`, `onOpenChange` | toggle or open the popup from the trigger; move focus among enabled options on navigation; propose selection changes through registered option activation; dismiss the popup according to popup policy |
| `TextInput` | `Activate`, `Navigate`, `TextInput`, `TextCompose`, `Submit`, pointer selection gestures | `onValueChange`, `onSelectionChange`, `onSubmit` | acquire focus, update selection, propose committed text insertion, update composition candidate, or submit according to `submitBehavior` |
| `TextArea` | `Activate`, `Navigate`, `TextInput`, `TextCompose`, `Scroll`, `Submit`, pointer selection gestures | `onValueChange`, `onSelectionChange`, `onSubmit` | same as `TextInput`, plus internal scroll handling and newline insertion rules |
| `Modal` | `Dismiss`, `Activate` on explicit close actions, `Activate` on backdrop when configured | `onOpenChange` | propose `open = false` when dismissal policy allows |
| `Alert` | `Dismiss`, `Activate` on explicit actions, `Activate` on backdrop when configured | `onOpenChange` plus action-control callbacks supplied by the consumer | same as `Modal`, plus action activation inside the actions region |
| `Notification` | `Dismiss` on owned close control when configured; timer expiry when `closeMethod = "auto-dismiss"` | `onOpenChange` | propose `open = false` when the owned dismissal path resolves |
| `Tooltip` | `Dismiss`, pointer-derived hover transitions, focus transitions, and explicit open or close requests | `onOpenChange` | propose `open = true` or `open = false` according to `triggerMode`, explicit control requests, and tooltip visibility rules |
| `Tabs` | `Navigate`, `Activate` | `onValueChange` | move roving focus on navigation and propose a new active value only on activation |

### 4D.2 Focus And Pointer-Coupling Rules By Control Family

| Control or family | Pointer-focus coupling | Focus movement responsibility | Notes |
|-------------------|------------------------|-------------------------------|-------|
| `Button`, `Checkbox`, `Switch` | focuses before default action | library-managed through ordinary focus traversal | pointer or touch activation may establish focus on the target control |
| `RadioGroup` and registered `Radio` controls | focus moves among enabled radios in group order; activation may establish focus on the target radio before value proposal | library-managed roving focus within the owning group | directional focus movement alone must not change the group's selected value |
| `Slider` | focuses before drag or keyboard adjustment | library-managed through ordinary focus traversal | directional keys adjust the value when focused; pointer drag may establish focus before value changes |
| `ProgressBar` | no pointer-focus coupling | no focus movement responsibility in this revision | the control is presentational and non-interactive |
| `Select` and registered `Option` controls | trigger activation may move focus into the popup when opened; option focus moves among enabled options in popup order | library-managed within the trigger and popup surfaces; `modal = true` may trap focus while open | option focus movement alone must not change the selected value set |
| `TextInput`, `TextArea` | focuses before text-entry activation | library-managed plus platform text-entry activation cooperation | focus acquisition must establish active text-entry ownership |
| `Modal`, `Alert` | opening moves focus into the overlay scope; backdrop activation does not move focus into underlying content | library-managed with trapping and restoration | dismissal may restore prior focus when configured |
| `Notification` | opening does not move focus; close-control activation follows ordinary control focus rules only when that control is focused directly | library-managed through ordinary base-scene and overlay traversal without trapping | the notification surface is non-modal and must not redirect focus on open |
| `Tooltip` | opening does not move focus; trigger focus follows the trigger subtree's own control contract rather than the tooltip surface | library-managed through ordinary trigger focus plus overlay-mounted surface positioning without trapping | the tooltip surface is non-modal, does not participate in ordinary focus traversal, and must not redirect focus on open |
| `Tabs` trigger list | focus moves independently of activation | library-managed roving focus within the trigger list | focus movement alone must not activate a tab |

### 4D.3 Control-Specific Dismissal And Submission Rules

- `Modal` and `Alert` recognize `Dismiss` through escape-like commands and backdrop activation only when the corresponding dismissal props allow it.
- `RadioGroup` recognizes directional navigation and activation as group-selection inputs. Focus movement alone must not change the selected value.
- `Slider` recognizes directional navigation, page-step commands, home/end commands, track activation, and drag as value-adjustment inputs.
- `Select` recognizes `Dismiss` through outside activation when allowed, escape, and selection-commit close rules. It recognizes directional navigation and activation while the popup is open. Focus movement alone must not change the selected value set.
- `Notification` recognizes `Dismiss` only through the owned close path selected by `closeMethod`. It does not recognize backdrop dismissal or escape dismissal in this revision.
- `Tooltip` recognizes `Dismiss` through trigger hover loss, trigger focus loss when `triggerMode` allows it, and explicit close requests. It does not recognize backdrop dismissal or focus trapping in this revision.
- `TextInput` recognizes `Submit` according to `submitBehavior`: `blur` proposes blur after submit, `submit` invokes `onSubmit`, and `none` takes no submit default action.
- `TextArea` consumes `Submit` as newline insertion when multiline editing rules require it; it must not treat the newline command as `onSubmit` unless a future component revision explicitly adds that behavior.
- `Tabs` does not recognize `Dismiss` as a tab-state-changing input in this revision.

### 4D.4 Event Ordering And Cancellation At Control Level

- For `Button`, `Checkbox`, `RadioGroup`, `Switch`, `Slider`, `Select`, `Tabs`, `Modal`, `Alert`, `Notification`, and `Tooltip`, cancellable interaction events must finish listener delivery before the library proposes any state change through the documented callback.
- Cancelling `ui.activate` on `Button`, `Checkbox`, `Switch`, or `Tabs` prevents the default action and therefore prevents the associated callback proposal for that activation.
- Cancelling `ui.activate` on `Radio` or the owning `RadioGroup` prevents the associated `onValueChange` proposal for that activation.
- Cancelling `ui.activate`, `ui.drag`, or `ui.navigate` on `Slider` prevents the associated `onValueChange` proposal for that interaction.
- Cancelling `ui.activate` on `Option` or the owning `Select` prevents the associated `onValueChange` proposal for that activation.
- Cancelling `ui.dismiss` on `Select` prevents the associated `onOpenChange(false)` proposal for that dismissal attempt.
- Cancelling `ui.dismiss` on `Modal` or `Alert` prevents the `onOpenChange(false)` proposal for that dismissal attempt.
- Cancelling `ui.dismiss` on `Notification` prevents the `onOpenChange(false)` proposal for the corresponding close-control activation.
- Cancelling `ui.open`, `ui.close`, or `ui.dismiss` on `Tooltip` prevents the associated `onOpenChange(...)` proposal for that visibility transition attempt.
- Cancelling `ui.text.input`, `ui.text.compose`, or `ui.submit` on `TextInput` or `TextArea` prevents the associated insertion, composition update, or submit default action for that interaction.

## 4E. Control Behavioral Completeness

The behavioral-completeness rules in Section 3E of [UI Foundation Specification](./ui-foundation-spec.md) are binding for all controls in this document.

### 4E.1 Empty And Null State Behavior By Control

| Control | No-content or empty case | Library-provided empty state | Observable empty-state transition |
|---------|---------------------------|------------------------------|-----------------------------------|
| `Text` | empty string renders nothing and remains valid | none | no |
| `Button` | empty `content` slot remains valid and interactive | none | no |
| `Checkbox` and `Switch` | absent `label` or `description` remains valid and interactive | none | no |
| `Slider` | any finite range and value pair remains valid after clamping and optional step quantization | none | yes, when the clamped or stepped value changes |
| `ProgressBar` | any finite range and value pair remains valid; indeterminate mode remains valid with no meaningful determinate value | none | yes, when `indeterminate` changes or the clamped ratio changes |
| `Radio` | absent `label` or `description` remains valid and interactive | none | no |
| `RadioGroup` | zero registered radios is structurally invalid per the composition contract, not an empty-but-valid interactive state | none | no |
| `Option` | absent `label` or `description` remains valid and interactive | none | no |
| `Select` | zero registered options is structurally invalid per the composition contract; empty selection with one or more options is valid | placeholder is consumer-provided or defaults to `"None selected"` | yes, when the selected set transitions between empty and non-empty |
| `TextInput` and `TextArea` | empty value remains valid; placeholder behavior follows the existing component contract | placeholder is consumer-provided content, not library-injected fallback | no |
| `Modal` | no focusable content remains valid; the overlay still mounts and traps focus when configured | none | no |
| `Alert` | missing `message` is valid; missing `actions` is prohibited by the component contract | none | no |
| `Notification` | compact content remains valid; empty or omitted `content` is prohibited by the component contract | none | no |
| `Tooltip` | compact content remains valid; empty or omitted `content` is prohibited by the component contract | none | no |
| `Tabs` | zero valid trigger/panel pairs is structurally invalid per the composition contract, not an empty-but-valid interactive state | none | no |

### 4E.2 Overflow And Constraint Behavior By Control Family

| Control or family | Default overflow behavior | Minimum functional contract | Response to post-mount constraint changes |
|-------------------|---------------------------|-----------------------------|-------------------------------------------|
| `Text` | wrap when configured, otherwise overflow without clipping unless an ancestor clips | remains valid at zero or tiny width but may render no visible glyphs | re-measure on the next draw preparation |
| `Button`, `Checkbox`, `Radio`, `Switch` | content may visually overflow, clip through ancestors, or compress according to skin geometry; no implicit scroll region is created | activation region remains valid even when text or indicator art no longer fits fully | recompute part layout from the latest bounds on the next pass |
| `RadioGroup` | group overflow follows the consumer-owned layout containing its registered radios; no implicit scroll region is created | selection, focus movement, and activation remain valid so long as one enabled radio exists | re-resolve radio ordering, roving focus targets, and selected-value repair on the next pass |
| `Slider` | track and thumb may visually compress according to current bounds; no implicit scroll region is created | drag, tap-to-set, and keyboard adjustment remain valid so long as the track and thumb exist | recompute normalized thumb geometry, orientation-specific placement, and stepped value mapping on the next pass |
| `ProgressBar` | track and indicator may visually compress according to current bounds; no implicit scroll region is created | the track and indicator remain renderable at any finite size, though the indicator may become visually minimal | recompute normalized fill geometry and orientation-specific indicator bounds on the next pass |
| `Select` and `Option` | trigger summary may overflow according to trigger bounds; popup width defaults to content width and popup overflow follows the popup content layout with no implicit search or virtualization region | trigger activation, popup dismissal, and option activation remain valid so long as the trigger and at least one option exist | recompute trigger summary, popup placement, popup width, option ordering, and selected-value presentation on the next pass |
| `TextInput` | single-line content does not wrap; overflow is handled by selection/caret movement within the field contract rather than by multiline reflow | remains focusable and editable so long as the field region exists | recompute selection geometry and visible insertion region from the new field size |
| `TextArea` | vertical overflow is handled by the internal scroll region; horizontal overflow is suppressed when `wrap = true` and allowed when wrapping is disabled | remains editable at any finite size, though visible text area may collapse to a minimal viewport | recompute wrapping, content extent, and internal scroll range |
| `Tabs` | overflow in the trigger list may be handled by scrollable composition when enabled; panel overflow follows the panel content contract | trigger activation and focus movement remain valid even when the list is partially offscreen | re-resolve trigger list overflow and active panel layout |
| `Modal` and `Alert` | surface content may overflow according to the layout content placed inside the surface; backdrop always fills the viewport | overlay remains dismissable and focus-managed even when surface content cannot fully fit | recompute surface placement and safe-area-aware bounds on the next pass |
| `Notification` | surface content may overflow according to the layout content placed inside the surface; no implicit scroll region is created | notification dismissal and placement remain valid so long as the surface exists | recompute edge placement, safe-area-aware bounds, and stack offsets on the next pass |
| `Tooltip` | surface content may overflow according to the layout content placed inside the surface; no implicit scroll region is created | tooltip association and visibility remain valid so long as the trigger subtree exists | recompute anchor geometry, preferred-versus-fallback placement, and effective visible-region fitting on the next pass |

### 4E.3 Rapid And Concurrent Input Behavior By Control Family

| Control or family | Queueing or arbitration policy | Consistency guarantee |
|-------------------|--------------------------------|-----------------------|
| `Button`, `Checkbox`, `Radio`, `Switch` | each activation attempt is processed independently in arrival order; gesture ownership determines which pointer sequence may finish a press or drag | committed state remains coherent after each completed activation or drag release |
| `RadioGroup` | navigation and activation inputs are processed independently in arrival order; navigation never retroactively changes the selected value | roving focus and selected value remain coherent and do not diverge within one `RadioGroup` root |
| `Slider` | drag movement, repeated key adjustment, and track activation are processed in arrival order with the latest uncancelled proposal winning | the committed value remains coherent with the latest clamped and stepped adjustment |
| `ProgressBar` | rapid authoritative value changes are processed in arrival order with no throttled behavioral side effect | visible progress remains coherent with the latest committed clamped value or indeterminate mode |
| `Select` | trigger activation, popup dismissal, navigation, and option activation are processed in arrival order; once a close has been proposed, additional close requests before commit do not create a second distinct close state | selected values, popup open state, and focused option remain coherent within one `Select` root |
| `TextInput` and `TextArea` | committed text and composition updates are processed in arrival order while the field owns active text-entry state | committed value and selection reflect a consistent committed pair after each processed logical input |
| `Modal` and `Alert` | dismissal requests are processed in arrival order; once a close has been proposed, additional close requests before commit do not create a second distinct close state | open-state proposals remain coherent and focus-trap ownership does not split across concurrent dismiss inputs |
| `Notification` | timer completion, explicit close activation, and authoritative external close requests are processed in arrival order; once a close has been proposed, additional close requests before commit do not create a second distinct close state | open-state proposals, timer ownership, and stack-placement ownership remain coherent across concurrent close inputs |
| `Tooltip` | hover transitions, focus transitions, and authoritative external open-state requests are processed in arrival order with the latest uncancelled visibility proposal winning | open-state proposals, trigger association, and fallback-placement ownership remain coherent across concurrent visibility inputs |
| `Tabs` | navigation and activation inputs are processed independently in arrival order; navigation never retroactively activates a tab | roving focus and active value remain coherent and do not diverge within one `Tabs` root |

No control in this revision declares a built-in throttle or debounce policy.

### 4E.4 Transition Interruption And Destruction During Activity

| Control or family | Interrupted activity | Resolution rule |
|-------------------|----------------------|-----------------|
| `Button` | press interaction interrupted by disable, release outside, or destruction | clear press ownership, emit no activation, and leave only the last committed authoritative pressed value |
| `Checkbox` and `Switch` | activation or drag interrupted by disable, focus loss, or destruction | abandon the in-progress gesture; only a completed uncancelled activation or drag release may propose a new checked value |
| `Radio` and `RadioGroup` | activation or roving-focus movement interrupted by disable, radio removal, or destruction | abandon the obsolete target reference; preserve the last authoritative selected value or repair to the next enabled radio when the selected radio becomes invalid |
| `Slider` | drag or keyboard adjustment interrupted by disable, focus loss, or destruction | abandon the in-progress gesture or adjustment sequence and preserve the last authoritative committed value |
| `ProgressBar` | determinate-to-indeterminate or range changes during active rendering | resolve to the latest authoritative clamped value and mode on the next draw preparation pass |
| `Option` and `Select` | trigger activation, popup dismissal, or option focus movement interrupted by disable, option removal, or destruction | abandon the obsolete target reference; preserve the last authoritative selected values and close the popup when the owning select is destroyed |
| `TextInput` and `TextArea` | text composition interrupted by focus loss or destruction | discard the composition candidate without committing it and release active text-entry ownership |
| `Modal` and `Alert` | open or close flow interrupted by a new authoritative `open` value or destruction | resolve to the latest authoritative open state; if destroyed while open, release focus trap ownership and stop further dismissal proposals from that instance |
| `Notification` | open or close flow interrupted by a new authoritative `open` value, timer expiry race, or destruction | resolve to the latest authoritative open state; if destroyed while open, release timer ownership and stop further dismissal proposals from that instance |
| `Tooltip` | open or close flow interrupted by a new authoritative `open` value, hover or focus state change, trigger removal, or destruction | resolve to the latest authoritative open state; if the trigger subtree is removed or destroyed while open, close the tooltip and stop further visibility proposals from that instance |
| `Tabs` | trigger or panel structure changes while focus or activation is in progress | re-resolve the next valid mapped value or focused trigger according to the existing `Tabs` contract and discard obsolete target references |

### 4E.5 Loading And Async Support

No concrete control in this revision defines a public asynchronous loading contract.

Therefore:

- there is no standardized loading placeholder, progress event, load failure state, or retry API for any control in this revision
- any async content displayed inside `Text`, `Tabs` panels, `Modal` bodies, or other control regions is consumer-owned behavior layered on top of these components

## 4F. Control Contract Stability

The contract-stability rules in Section 3F of [UI Foundation Specification](./ui-foundation-spec.md) are binding for all controls in this document.

### 4F.1 Canonical Control Identity Tiers

| Control | Tier | Current tier since | Deprecated? | Removal version | Replacement |
|---------|------|--------------------|-------------|-----------------|-------------|
| `Text` | `Stable` | `0.1.0` | no | n/a | n/a |
| `Button` | `Stable` | `0.1.0` | no | n/a | n/a |
| `Checkbox` | `Stable` | `0.1.0` | no | n/a | n/a |
| `Radio` | `Stable` | `0.1.0` | no | n/a | n/a |
| `RadioGroup` | `Stable` | `0.1.0` | no | n/a | n/a |
| `Switch` | `Stable` | `0.1.0` | no | n/a | n/a |
| `Slider` | `Stable` | `0.1.0` | no | n/a | n/a |
| `ProgressBar` | `Stable` | `0.1.0` | no | n/a | n/a |
| `Select` | `Stable` | `0.1.0` | no | n/a | n/a |
| `Option` | `Stable` | `0.1.0` | no | n/a | n/a |
| `TextInput` | `Stable` | `0.1.0` | no | n/a | n/a |
| `TextArea` | `Stable` | `0.1.0` | no | n/a | n/a |
| `Tabs` | `Stable` | `0.1.0` | no | n/a | n/a |
| `Modal` | `Stable` | `0.1.0` | no | n/a | n/a |
| `Alert` | `Stable` | `0.1.0` | no | n/a | n/a |
| `Notification` | `Stable` | `0.1.0` | no | n/a | n/a |
| `Tooltip` | `Stable` | `0.1.0` | no | n/a | n/a |

### 4F.2 Control Public Surface Classification

Unless this section explicitly says otherwise, every documented control surface in this document is `Stable` as of `0.1.0`.

| Control | Documented props and public state | Documented callbacks and event payload contracts | Documented slots or compound regions | Documented named visual parts | Undocumented helpers and private coordination state |
|---------|-----------------------------------|--------------------------------------------------|--------------------------------------|-------------------------------|-----------------------------------------------------|
| `Text` | `Stable` since `0.1.0` | no public callback surface in this revision | none | `Stable` since `0.1.0` | `Internal` |
| `Button` | `Stable` since `0.1.0` | `Stable` since `0.1.0` | `content` slot is `Stable` since `0.1.0` | `Stable` since `0.1.0` | `Internal` |
| `Checkbox` | `Stable` since `0.1.0` | `Stable` since `0.1.0` | `label` and `description` regions are `Stable` since `0.1.0` | `Stable` since `0.1.0` | `Internal` |
| `Radio` | `Stable` since `0.1.0` | coordinated through `RadioGroup` `onValueChange`, stable since `0.1.0` | `label` and `description` regions are `Stable` since `0.1.0` | `Stable` since `0.1.0` | `Internal` |
| `RadioGroup` | `Stable` since `0.1.0` | `Stable` since `0.1.0` | registered `Radio` structure is `Stable` since `0.1.0` | `Stable` since `0.1.0` | `Internal` |
| `Switch` | `Stable` since `0.1.0` | `Stable` since `0.1.0` | `label` and `description` regions are `Stable` since `0.1.0` | `Stable` since `0.1.0` | `Internal` |
| `Slider` | `Stable` since `0.1.0` | `Stable` since `0.1.0` | no consumer-fillable descendant slots in this revision | `Stable` since `0.1.0` | `Internal` |
| `ProgressBar` | `Stable` since `0.1.0` | no public callback surface in this revision | no consumer-fillable descendant slots in this revision | `Stable` since `0.1.0` | `Internal` |
| `Select` | `Stable` since `0.1.0` | `Stable` since `0.1.0` | `trigger`, `popup`, `placeholder`, and registered `Option` structure are `Stable` since `0.1.0` | `Stable` since `0.1.0` | `Internal` |
| `Option` | coordinated through `Select` `onValueChange`, stable since `0.1.0` | coordinated through `Select` `onValueChange`, stable since `0.1.0` | `label` and `description` regions are `Stable` since `0.1.0` | `Stable` since `0.1.0` | `Internal` |
| `TextInput` | `Stable` since `0.1.0` | `Stable` since `0.1.0` | no consumer-fillable descendant slots in this revision | `Stable` since `0.1.0` | `Internal` |
| `TextArea` | `Stable` since `0.1.0` | `Stable` since `0.1.0` | no consumer-fillable descendant slots in this revision | `Stable` since `0.1.0` | `Internal` |
| `Tabs` | `Stable` since `0.1.0` | `Stable` since `0.1.0` | `list`, `panels`, `trigger`, and `panel` structure is `Stable` since `0.1.0` | `Stable` since `0.1.0` | `Internal` |
| `Modal` | `Stable` since `0.1.0` | `Stable` since `0.1.0` | `surface`, `content`, and documented close-control regions are `Stable` since `0.1.0` | `Stable` since `0.1.0` | `Internal` |
| `Alert` | `Stable` since `0.1.0` | `Stable` since `0.1.0` | `title`, `message`, `actions`, and documented close-control regions are `Stable` since `0.1.0` | `Stable` since `0.1.0` | `Internal` |
| `Notification` | `Stable` since `0.1.0` | `Stable` since `0.1.0` | `surface`, `content`, and documented close-control region are `Stable` since `0.1.0` | `Stable` since `0.1.0` | `Internal` |
| `Tooltip` | `Stable` since `0.1.0` | `Stable` since `0.1.0` | `trigger`, `content`, and overlay-mounted `surface` structure are `Stable` since `0.1.0` | `Stable` since `0.1.0` | `Internal` |

Additional control-surface rulings:

- unsupported nested-interactive patterns, prohibited parent relationships, and invalid structural pairings are part of the stable contract as prohibitions; making an unsupported pattern supported later is non-breaking, but making a supported pattern unsupported is breaking
- this revision defines no stable imperative handle, ref, or method surface for any control
- no control or control-scoped API surface is `Experimental` or `Deprecated` in this revision

Breaking change rulings for controls and the full stability scope declaration are governed by [UI Evolution Specification](./ui-evolution-spec.md).

## 4G. Control Failure Semantics

The failure-semantics rules in Section 3G of [UI Foundation Specification](./ui-foundation-spec.md) are binding for all controls in this document.

### 4G.1 Control Invalid-Usage Response Assignment

| Category | Typical control conditions | Detectable point | Failure mode | Control-specific rule |
|----------|----------------------------|------------------|--------------|-----------------------|
| structural invalidity | `Tabs` trigger/panel mismatches, duplicate trigger values, `RadioGroup` duplicate or missing radio values, `Select` duplicate or missing option values, `Modal`, `Alert`, or `Notification` detached from the overlay layer, `Tooltip` with no required trigger subtree, prohibited child nodes in `Text`, `TextInput`, or `TextArea` | when the control structure is mounted, registered, or next reconciled | `Hard failure` | no control-specific structural repair is attempted |
| type or value invalidity | negative `dragThreshold`, `maxLength < 0`, invalid `toggleOrder`, unsupported `activationMode`, missing required font or skin asset where no fallback exists | immediately when the value is set if knowable, otherwise on first use | `Hard failure` unless the control section explicitly names a fallback | controls do not coerce invalid values into a nearby valid value unless the contract says so |
| state contract violation | mutable controlled value without the required change callback, incomplete controlled selection pair, controlled/uncontrolled ownership switch after first commit | when control ownership is reconciled | `Hard failure` | the control preserves the last valid committed state and rejects the invalid ownership transition |
| lifecycle violation | no stable imperative control method surface exists in this revision | n/a | no separate control-specific surface in this revision | runtime-managed destruction behavior is covered by Behavioral Completeness, not failure semantics |
| composition boundary violation | unsupported nested interactive controls inside prohibited slots or regions, mounting overlay controls in ordinary layout containment | when the boundary violation becomes knowable | `Hard failure` | the library does not remount or reparent the control automatically |
| out-of-scope usage | relying on undocumented helper parts, mutating internal control bookkeeping, or consuming internal-only control symbols | not required to be detected | `Undefined` or `Passthrough` | no control-specific guarantee is made |

### 4G.2 Control Diagnostics And Fallback Contract

Control-specific fallback rules in this revision:

| Condition | Mode | Fallback behavior | Contract status |
|-----------|------|-------------------|-----------------|
| text insertion beyond `maxLength` in `TextInput` or `TextArea` | `Silent fallback` | truncate the insertion to the greatest prefix that still satisfies `maxLength`; emit no diagnostic | stable degraded-but-valid output |
| missing optional label, description, message, or content region where the composition contract permits omission | not a failure condition | render the region as absent | governed by Behavioral Completeness rather than failure semantics |
| missing optional visual token or skin input when the visual contract defines a fallback | `Silent fallback` | use the fallback defined by the foundation visual contract | stable degraded-but-valid output |
| deprecated control-specific API use | `Soft failure with signal` when such an API exists | execute deprecated behavior under Section 3G.5 | no control-specific deprecated surface exists in this revision |
| all other detected invalid control usage | `Hard failure` | no fallback | fail-stop for the invalid control operation |

Rejected invalid control updates must not emit the ordinary change callback for the rejected state change.

### 4G.3 Deprecated Control API Runtime Behavior

No control, control prop, control callback, or control slot is marked `Deprecated` in this revision.

If a future revision deprecates a control-specific surface, runtime use must follow Section 3G.5 exactly.

### 4G.4 Undefined Control Behavior Declaration

The following control-specific usages are intentionally undefined in this revision:

- direct consumer mutation of undocumented internal text-layout, gesture, selection, focus-restoration, or registration state
- reliance on undocumented helper wrappers or decorative layers inside a control's named visual parts
- importing or invoking internal-only control helpers that are not declared as public API

Future revisions may define some of these cases, but this revision makes no stability commitment about them.

### 4G.5 Control Graceful Degradation Contract

In addition to the foundation degradation guarantees:

- one control failing validation must not corrupt sibling controls or unrelated runtime roots
- a control that enters a documented fallback path must remain renderable and behaviorally coherent within that fallback
- invalid `Tabs`, `Modal`, `Alert`, or `Tooltip` operations must not leave split active-value ownership, split focus-trap ownership, partially committed overlay state, or stale anchored-placement ownership across unrelated roots
- if a control operation hard-fails and the error is caught by the consumer, the last valid committed control state remains authoritative

## 5. Design Principles

1. Every stateful control must declare each public state property as consumer-owned or negotiated and must define the controlled and uncontrolled contracts when negotiation is allowed.
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
- support consumer-configurable line spacing
- support token and skin-derived text styling

**Anatomy**

- `root`: the text node. Required.
- `content`: the text string or rich text payload. Required.

**Props and API surface**

- `text: string | rich text payload`
- `font`
- `fontSize`
- `lineHeight: number`
- `maxWidth`
- `textAlign: "start" | "center" | "end"`
- `textVariant`
- `color`
- `wrap: boolean`

`lineHeight` defines a positive multiplier applied to the font's intrinsic line box for both wrapped and unwrapped text measurement and rendering. When omitted, the default line-height multiplier is `1`.

`textVariant` selects among visual variants for the single stable `Text.content` part. This revision does not standardize a library-wide text-role taxonomy such as `heading`, `body`, or `caption`; any such aliases remain internal unless separately documented.

Trace note: the public text-style surface is the set listed here. Font caches, asset-path helpers, or other convenience loaders may exist internally, but they are not stable public props unless documented in this section.

Trace note: clarified `textVariant` so Phase 8 theming can vary text presentation without turning undocumented semantic text-role names into stable public API.

Trace note: `lineHeight` is part of the stable public `Text` style surface because it changes observable measurement and glyph-line placement, not merely an internal draw heuristic.

**State model**

`Text` is stateless unless the consumer changes content or style. Any content or style change, including `lineHeight`, marks the node render-dirty and triggers re-measurement on the next draw preparation.

**Accessibility contract**

`Text` contributes readable textual semantics when used as part of a semantic parent such as a labeled control. Standalone text is non-interactive and does not participate in focus traversal. The consumer is responsible for associating text labels with their corresponding controls when semantic association is required.

**Composition rules**

`Text` may not contain child nodes. `Text` may be placed inside any `Drawable`-derived container. When used as a label inside a control, the containing control's composition rules govern whether the label region participates in activation.

**Behavioral edge cases**

- A `Text` with an empty string must render nothing and must not fail.
- A `Text` with `wrap = true` and no `maxWidth` must wrap at the node's own measured width.
- A `Text` node whose content exceeds its bounds when wrapping is disabled must overflow without clipping unless `clipChildren = true` is set on the parent.
- A `Text` with `lineHeight <= 0` must fail deterministically.
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

Trace note: `content` names the documented slot/region, not a stable imperative setter surface. Any helper used to populate the slot remains internal unless separately documented.

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

### 6.4 Radio

**Purpose and contract**

`Radio` is a single-selection option control coordinated by an owning `RadioGroup`. It owns activation behavior, focus behavior, disabled behavior, and associated-label activation semantics for one candidate value inside that group.

`Radio` must:

- participate in exactly one owning `RadioGroup`
- expose one candidate `value` to that group
- support pointer, touch, keyboard, and programmatic activation
- request selection through the owning group's `onValueChange`
- suppress value proposals when disabled or already selected

**Anatomy**

- `root`: the radio interactive region. Required.
- `indicator`: the visual selection indicator. Required.
- `label`: optional associated content that participates in activation.
- `description`: optional assistive or explanatory content.

**Props and API surface**

- `value: string`
- `disabled: boolean`
- `label`
- `description`

Trace note: `Radio` does not own public selected state in this revision. Selection is derived from the owning `RadioGroup` value. Helper registration or mutation methods remain internal unless separately documented.

**State model**

STATE unselected

  ENTRY:
    1. The radio's value does not match the owning `RadioGroup` effective value.

  TRANSITIONS:
    ON activation and not disabled:
      1. Propose this radio's `value` through the owning group's `onValueChange`.
      → selected

STATE selected

  ENTRY:
    1. The radio's value matches the owning `RadioGroup` effective value.

  TRANSITIONS:
    ON activation and not disabled:
      1. Take no action.
      → selected

ERRORS:
  - Missing `value` on a `Radio` instance → invalid configuration and deterministic failure.
  - A `Radio` outside an owning `RadioGroup` → invalid configuration and deterministic failure.

**Accessibility contract**

`Radio` must expose its selected state and disabled state to assistive systems. It must expose group association semantics through the owning `RadioGroup`. When focused, `Radio` must respond to standard keyboard activation commands. The consumer is responsible for providing a meaningful label; an absent label produces an unlabeled control.

**Composition rules**

`Radio` may contain a `label` and a `description` as defined in its anatomy. The label region may participate in activation alongside the indicator region. The description region must not participate in activation. Nested interactive controls are unsupported. `Radio` has no valid standalone meaning outside one owning `RadioGroup`.

**Behavioral edge cases**

- A disabled `Radio` must not propose selection.
- A selected `Radio` receiving activation must not emit a second selection proposal.
- A `Radio` with no label must remain valid and functional.

### 6.5 RadioGroup

**Purpose and contract**

`RadioGroup` is a single-selection control that coordinates one or more registered `Radio` descendants. It owns selected-value resolution, required one-of-many selection, directional roving focus, disabled-option skipping, and invalid-selection repair.

`RadioGroup` must:

- support exactly one selected radio value at a time
- support controlled selected-value resolution
- always resolve to one selected enabled radio when at least one enabled radio exists
- support horizontal and vertical orientation
- support pointer, touch, keyboard, and programmatic activation through registered radios
- move focus among enabled radios without changing selection until activation
- stop directional focus movement at the ends in this revision

`RadioGroup` must not:

- allow empty selection when one or more enabled radios exist
- support multi-select behavior
- wrap focus from last to first or first to last in this revision

**Anatomy**

- `root`: the radio-group subtree root. Required.
- `radio`: the registered option control representing one candidate value. Required and repeated.

**Props and API surface**

- `value: string | nil`
- `onValueChange: function | nil`
- `orientation: "horizontal" | "vertical"`
- `disabledValues: table | nil`

Trace note: the public `RadioGroup` surface is structural and value-driven. Helper registration or mutation methods remain internal unless this section is amended to name them.

**State model**

STATE idle

  ENTRY:
    1. Exactly one enabled registered radio value is resolved as selected when any enabled radio exists.
    2. Focus may rest on the selected radio or on another enabled radio.

  TRANSITIONS:
    ON directional focus move:
      1. Resolve the next enabled radio according to orientation and traversal direction.
      2. Stop at the first or last enabled radio when no further radio exists in that direction.
      3. Move roving focus to that radio.
      4. Do not change the selected value.
      → idle

    ON radio activation by pointer, touch, or confirm key:
      1. Resolve the activated radio value.
      2. Ignore the event if the radio is disabled or already selected.
      3. Emit `onValueChange` with the requested next value.
      → idle

    ON selected value becomes invalid because the selected radio is removed or disabled:
      1. Resolve the next enabled radio value by sibling order.
      2. Emit `onValueChange` with the requested replacement value.
      → idle

ERRORS:
  - Duplicate radio values within one `RadioGroup` root → invalid configuration and deterministic failure.
  - Zero registered radios within one `RadioGroup` root → invalid configuration and deterministic failure.
  - `value` without `onValueChange` when `value` is intended to be mutable → invalid configuration and deterministic failure.

**Accessibility contract**

`RadioGroup` must expose group semantics, the currently selected radio, and disabled radio state to assistive systems. Keyboard behavior must follow the standard radio-group pattern: directional keys move focus among enabled radios according to group orientation; the confirm key activates the focused radio. Focus movement alone must not change the selected value.

**Composition rules**

`RadioGroup` coordinates one or more registered `Radio` descendants inside one shared root. Each radio value must be unique within the group. At least one radio must be present. When one or more enabled radios exist, the group must always resolve exactly one selected value. Disabled radios do not participate in roving focus targets or selection repair candidates.

**Behavioral edge cases**

- A `RadioGroup` with a single enabled `Radio` must remain valid and keep that radio selected.
- When the focused radio is the last enabled radio in the traversal direction, the next directional focus movement in that direction takes no action.
- When the selected `value` does not match any enabled radio, the group must repair selection to the next enabled radio by sibling order and must not fail.
- When all registered radios are disabled, no enabled selected value can be resolved. The group must remain structurally valid and must not fail.

### 6.6 Switch

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

### 6.7 Slider

**Purpose and contract**

`Slider` is a continuous range input control. It owns value adjustment through thumb dragging, track activation, keyboard adjustment, step quantization, and orientation-specific value resolution.

`Slider` must:

- support controlled `value`
- support configurable minimum and maximum range bounds
- clamp values into the declared range
- support optional `step` quantization
- support horizontal and vertical orientation
- support pointer, touch, keyboard, and programmatic adjustment
- support direct track activation that moves the value toward the activated position

`Slider` must not:

- expose multiple thumbs in this revision
- require built-in tick marks or text labeling
- expose a separate commit callback distinct from `onValueChange` in this revision

**Anatomy**

- `root`: the slider subtree root. Required.
- `track`: the background value track. Required.
- `thumb`: the draggable value handle. Required.

**Props and API surface**

- `value: number | nil`
- `onValueChange: function | nil`
- `min: number`
- `max: number`
- `step: number | nil`
- `orientation: "horizontal" | "vertical"`
- `disabled: boolean`

Default values:

- `min = 0`
- `max = 1`
- `step = nil`
- `orientation = "horizontal"`
- `disabled = false`

When `step` is provided, value proposals must be quantized to the nearest valid stepped value within `[min, max]`.

**State model**

STATE idle

  ENTRY:
    1. The effective value is clamped into `[min, max]`.
    2. The thumb position resolves from the normalized ratio of the effective value.

  TRANSITIONS:
    ON track activation and not disabled:
      1. Resolve the target ratio from the activation position.
      2. Convert the ratio into a range value.
      3. Clamp and quantize it when `step` is provided.
      4. Emit `onValueChange` with the requested next value.
      → idle

    ON keyboard adjustment and not disabled:
      1. Resolve the next value from orientation, direction, and step policy.
      2. Emit `onValueChange` with the requested next value.
      → idle

    ON drag start and not disabled:
      1. Capture the drag gesture.
      2. Record the initial pointer and thumb position.
      → dragging

STATE dragging

  ENTRY:
    1. Pointer or touch owns the slider gesture.
    2. Thumb position follows gesture progress along the track axis.

  TRANSITIONS:
    ON drag move:
      1. Resolve the target ratio from the current pointer position.
      2. Convert the ratio into a range value.
      3. Clamp and quantize it when `step` is provided.
      4. Emit `onValueChange` with the requested next value.
      → dragging

    ON drag release:
      1. Release gesture ownership.
      → idle

ERRORS:
  - `value` without `onValueChange` when `value` is intended to be mutable → invalid configuration and deterministic failure.
  - `max <= min` → invalid configuration and deterministic failure.
  - `step <= 0` when provided → invalid configuration and deterministic failure.
  - `orientation` outside the documented enum set → invalid configuration and deterministic failure.

**Accessibility contract**

`Slider` must expose its current value, range bounds, disabled state, and orientation to assistive systems. When focused, `Slider` must respond to standard adjustable-control keyboard commands: directional keys adjust by one step or the implementation default increment when `step = nil`; page-step commands adjust by a larger increment; home and end move to `min` and `max`.

**Composition rules**

`Slider` is a closed range-input control with no consumer-fillable descendant slots in this revision. It may be placed inside any component that permits interactive descendants.

**Behavioral edge cases**

- A `Slider` with `value` less than `min` must clamp to `min` and must not fail.
- A `Slider` with `value` greater than `max` must clamp to `max` and must not fail.
- A disabled `Slider` must not respond to track activation, drag, or keyboard adjustment.
- A `Slider` with `step = nil` must adjust continuously within the declared range.
- A `Slider` at zero or tiny size must remain valid, though the thumb may render minimally or movement precision may be visually limited.

### 6.8 ProgressBar

**Purpose and contract**

`ProgressBar` is a presentational progress-indication control. It owns determinate range normalization, indeterminate-mode presentation, and orientation-specific fill resolution for a single progress value.

`ProgressBar` must:

- support determinate and indeterminate progress presentation
- support configurable minimum and maximum range bounds
- clamp determinate values into the declared range
- support horizontal and vertical orientation
- remain non-interactive in this revision

`ProgressBar` must not:

- expose activation or editable behavior
- require built-in text labeling
- expose buffer or secondary-progress state in this revision

**Anatomy**

- `root`: the progress-bar subtree root. Required.
- `track`: the background progress track. Required.
- `indicator`: the filled or animated progress indicator. Required.

**Props and API surface**

- `value: number | nil`
- `min: number`
- `max: number`
- `indeterminate: boolean`
- `orientation: "horizontal" | "vertical"`
- `motionPreset`
- `motion`

Default values:

- `min = 0`
- `max = 1`
- `indeterminate = false`
- `orientation = "horizontal"`

When `indeterminate = true`, the determinate fill ratio is ignored for visual progress resolution.

When present, `motionPreset` and `motion` follow the contracts defined in [UI Motion Specification](./ui-motion-spec.md). In this revision, `ProgressBar` may raise motion phases including `value` and `indeterminate`, typically targeting `indicator`.

**State model**

STATE determinate

  ENTRY:
    1. `indeterminate = false`.
    2. The effective value is clamped into `[min, max]`.
    3. The indicator length resolves from the normalized progress ratio.

  TRANSITIONS:
    ON value or range change:
      1. Clamp the effective value into the current range.
      2. Recompute the normalized ratio.
      3. Recompute orientation-specific indicator geometry.
      → determinate

    ON `indeterminate = true`:
      1. Stop determinate ratio presentation.
      2. Resolve indeterminate visual presentation.
      → indeterminate

STATE indeterminate

  ENTRY:
    1. `indeterminate = true`.
    2. The indicator presents indeterminate progress with no committed determinate ratio.

  TRANSITIONS:
    ON `indeterminate = false`:
      1. Clamp the effective value into the current range.
      2. Resolve determinate indicator geometry from the normalized ratio.
      → determinate

ERRORS:
  - `max <= min` → invalid configuration and deterministic failure.
  - `orientation` outside the documented enum set → invalid configuration and deterministic failure.

**Accessibility contract**

`ProgressBar` must expose whether it is determinate or indeterminate to assistive systems. In determinate mode, it must expose the current value and range bounds after clamping. In indeterminate mode, it must expose that progress is ongoing without a committed fraction. `ProgressBar` does not participate in focus traversal in this revision.

**Composition rules**

`ProgressBar` is a closed presentational control with no consumer-fillable descendant slots in this revision. It may be placed inside any component that permits presentational descendants.

**Behavioral edge cases**

- A `ProgressBar` with `value` less than `min` must clamp to `min` and must not fail.
- A `ProgressBar` with `value` greater than `max` must clamp to `max` and must not fail.
- A `ProgressBar` with `indeterminate = true` must remain valid regardless of `value`.
- A `ProgressBar` at zero or tiny size must remain valid, though the indicator may render minimally or not visibly.

### 6.9 Option

**Purpose and contract**

`Option` is a selectable descendant coordinated by an owning `Select`. It owns activation behavior, focus behavior, disabled behavior, and associated-description presentation for one candidate value inside that select.

`Option` must:

- participate in exactly one owning `Select`
- expose one candidate `value` to that select
- support pointer, touch, keyboard, and programmatic activation
- request selection through the owning select's `onValueChange`
- suppress value proposals when disabled

**Anatomy**

- `root`: the option interactive region. Required.
- `label`: optional associated content that participates in activation.
- `description`: optional assistive or explanatory content.

**Props and API surface**

- `value: string`
- `disabled: boolean`
- `label`
- `description`

Trace note: `Option` does not own public selected state in this revision. Selection is derived from the owning `Select` value according to `selectionMode`.

**State model**

STATE unselected

  ENTRY:
    1. The option's value is not present in the owning `Select` effective value.

  TRANSITIONS:
    ON activation and not disabled:
      1. Propose this option's `value` through the owning select's `onValueChange`.
      → selected or unselected depending on authoritative commit

STATE selected

  ENTRY:
    1. The option's value is present in the owning `Select` effective value.

  TRANSITIONS:
    ON activation and not disabled:
      1. In `single` mode, take no action because the selected option remains selected.
      2. In `multiple` mode, propose removal of this option's value through the owning select's `onValueChange`.
      → selected or unselected depending on authoritative commit

ERRORS:
  - Missing `value` on an `Option` instance → invalid configuration and deterministic failure.
  - An `Option` outside an owning `Select` → invalid configuration and deterministic failure.

**Accessibility contract**

`Option` must expose its selected state and disabled state to assistive systems. It must expose association with the owning `Select`. When focused, `Option` must respond to standard keyboard activation commands.

**Composition rules**

`Option` may contain a `label` and a `description` as defined in its anatomy. Both are non-interactive associated content. Nested interactive controls are unsupported. `Option` has no valid standalone meaning outside one owning `Select`.

**Behavioral edge cases**

- A disabled `Option` must not propose selection changes.
- In `single` mode, activating the already selected `Option` must not emit a second selection proposal.
- In `multiple` mode, activating a selected `Option` toggles it out of the selected set.

### 6.10 Select

**Purpose and contract**

`Select` is a custom popup selection control that coordinates a trigger surface with a registered set of `Option` descendants. It owns selected-value resolution, open-state requests, placeholder and summary rendering, popup dismissal policy, and single-versus-multiple selection behavior.

`Select` must:

- support controlled selection value and controlled open state
- support `selectionMode = "single" | "multiple"`
- support no selection as a valid state
- expose a trigger that opens and closes the popup
- coordinate one or more registered `Option` descendants
- support a `placeholder` when the selected set is empty
- support modal or non-modal popup behavior according to configuration
- default popup width to content width

`Select` must not:

- delegate to a native platform picker in this revision
- require search or typeahead behavior in this revision
- permit nested interactive descendants inside `Option` content

**Anatomy**

- `root`: the select subtree root. Required.
- `trigger`: the collapsed interactive surface that opens or closes the popup. Required.
- `placeholder`: optional fallback content region rendered by the trigger when the selected set is empty.
- `popup`: the open options surface. Required while open.
- `option`: the registered selectable descendant. Required and repeated.

**Props and API surface**

- `value: string | table | nil`
- `onValueChange: function | nil`
- `open: boolean | nil`
- `onOpenChange: function | nil`
- `selectionMode: "single" | "multiple"`
- `placeholder: string | nil`
- `modal: boolean`
- `disabled: boolean`
- `disabledValues: table | nil`
- `motionPreset`
- `motion`

Default values:

- `selectionMode = "single"`
- `placeholder = "None selected"`
- `modal = false`
- `disabled = false`

`value` semantics:

- when `selectionMode = "single"`, `value` is `string | nil`
- when `selectionMode = "multiple"`, `value` is `table | nil` containing unique string values

When `selectionMode = "multiple"`, selected values are resolved and rendered in option registration order, not selection time order.

Trigger summary rules:

- when the selected set is empty, render the `placeholder`
- when `selectionMode = "single"` and one option is selected, render that option's label
- when `selectionMode = "multiple"` and one or more options are selected, render `"N selected"`

Trace note: the public `Select` surface is the prop set listed here plus the documented structure. Helper methods for opening, closing, or imperatively selecting options remain internal unless separately documented.
When present, `motionPreset` and `motion` follow the contracts defined in [UI Motion Specification](./ui-motion-spec.md). In this revision, `Select` may raise motion phases including `open`, `close`, and placement-related popup motion.

**State model**

STATE closed

  ENTRY:
    1. The popup is not visible.
    2. The trigger reflects the current selected set summary.

  TRANSITIONS:
    ON trigger activation and not disabled:
      1. Emit `onOpenChange(true)`.
      → opening

STATE opening

  ENTRY:
    1. An open has been requested. The consumer has not yet committed the change.

  TRANSITIONS:
    ON open commit:
      1. Mount or reveal the popup.
      2. Move focus into the popup according to popup focus policy.
      → open

STATE open

  ENTRY:
    1. The popup is visible.
    2. Enabled options participate in focus movement and activation.

  TRANSITIONS:
    ON directional focus move:
      1. Resolve the next enabled option in popup order.
      2. Move focus to that option.
      3. Do not change the selected set.
      → open

    ON option activation:
      1. Resolve the next selected value or value set according to `selectionMode`.
      2. Emit `onValueChange` with the requested next value.
      3. When `selectionMode = "single"`, emit `onOpenChange(false)`.
      4. When `selectionMode = "multiple"`, keep the popup open.
      → open or closing

    ON trigger activation while open:
      1. Emit `onOpenChange(false)`.
      → closing

    ON outside activation or escape:
      1. Emit `onOpenChange(false)`.
      → closing

STATE closing

  ENTRY:
    1. A close has been requested. The consumer has not yet committed the change.

  TRANSITIONS:
    ON close commit:
      1. Hide or unmount the popup.
      2. Return focus according to popup focus policy.
      → closed

ERRORS:
  - Duplicate option values within one `Select` root → invalid configuration and deterministic failure.
  - Zero registered options within one `Select` root → invalid configuration and deterministic failure.
  - `value` without `onValueChange` when `value` is intended to be mutable → invalid configuration and deterministic failure.
  - `open` without `onOpenChange` when `open` is intended to be mutable → invalid configuration and deterministic failure.
  - `selectionMode` outside the documented enum set → invalid configuration and deterministic failure.
  - `value` provided as a table when `selectionMode = "single"` → invalid configuration and deterministic failure.
  - `value` provided as a scalar when `selectionMode = "multiple"` and not `nil` → invalid configuration and deterministic failure.

**Accessibility contract**

`Select` must expose its current expanded or collapsed state, selected value or values, disabled state, and association between the trigger and popup options to assistive systems. When `modal = true`, the popup behaves as a modal popup surface for focus purposes while open. When `modal = false`, the popup remains non-modal and must not block focus traversal outside its owned popup interactions. Keyboard navigation must move focus among enabled options without changing the selected set until activation.

**Composition rules**

`Select` coordinates one trigger surface and one popup surface inside one shared root. Each registered `Option` value must be unique within the select. At least one option must be present. `Option` descendants may contain only `label` and `description` associated content in this revision. The popup may be rendered as modal or non-modal according to `modal`, but it remains part of the `Select` contract rather than a separate public overlay control.

**Behavioral edge cases**

- A disabled `Select` must not open and must not respond to trigger or option activation.
- A `Select` with an empty selected set must remain valid and render the placeholder summary.
- In `single` mode, selecting one option closes the popup by default.
- In `multiple` mode, selecting or deselecting one option keeps the popup open by default.
- Outside activation and escape must close the popup when it is open.
- When the selected `value` references missing or disabled options, the invalid entries are omitted from the effective selected set and the control must not fail.

### 6.11 TextInput

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

Trace note: the public text-entry surface is the set listed here together with the ownership rules above. Raw host key handling, clipboard plumbing, and native text-input activation wiring remain internal beneath the logical input contract, and this revision does not add a separate `defaultValue` prop.

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

### 6.12 TextArea

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

### 6.13 Modal

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
- `motionPreset`
- `motion`

Trace note: the public `Modal` surface is the prop set listed here plus the documented structure. Convenience methods such as `open()` or `close()` may exist internally, but they are not stable public API unless this section is amended to name them.
When present, `motionPreset` and `motion` follow the contracts defined in [UI Motion Specification](./ui-motion-spec.md). In this revision, `Modal` may raise motion phases including `open` and `close`, typically targeting `backdrop` and `surface`.

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

### 6.14 Alert

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

Trace note: `Alert` is specified through these props and required regions, not through one constructor signature or list-building API. Any constructor helpers, title/message coercion helpers, or action-registration helpers remain internal unless separately documented.
When present through the inherited modal surface, `motionPreset` and `motion` follow the contracts defined in [UI Motion Specification](./ui-motion-spec.md). In this revision, `Alert` uses the same motion phases as `Modal`.

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

### 6.15 Notification

**Purpose and contract**

`Notification` is a non-blocking overlay control that presents transient status content above the base scene layer without trapping focus or preventing interaction outside its own hit region.

`Notification` must:

- support controlled open state
- request open-state changes through `onOpenChange`
- support exactly one owned dismissal path selected by `closeMethod`
- support edge-based placement with cross-axis alignment
- support stacking of multiple open notifications
- default to safe-area-aware placement
- remain non-modal and non-blocking outside the notification surface

**Anatomy**

- `root`: the notification subtree root. Required.
- `surface`: the visible notification container. Required.
- `content`: the consumer-provided notification body. Required.
- `close control`: optional library-owned dismissal control present only when `closeMethod = "button"`.

**Props and API surface**

- `open: boolean | nil`
- `onOpenChange: function | nil`
- `closeMethod: "button" | "auto-dismiss"`
- `duration: number | nil`
- `stackable: boolean`
- `edge: "top" | "bottom" | "left" | "right"`
- `align: "start" | "center" | "end"`
- `safeAreaAware: boolean`
- `motionPreset`
- `motion`

Default values:

- `closeMethod = "button"`
- `duration = 5000`
- `stackable = true`
- `edge = "top"`
- `align = "center"`
- `safeAreaAware = true`

When `closeMethod = "auto-dismiss"` and `duration` is `nil`, the effective duration is `5000`.

Trace note: the public `Notification` surface is the prop set listed here plus the documented structure. Helper methods such as `show()`, `hide()`, queue-management helpers, or imperative stack APIs may exist internally, but they are not stable public API unless this section is amended to name them.
`duration` is dismissal timing, not a general visual motion timing surface. When present, `motionPreset` and `motion` follow the contracts defined in [UI Motion Specification](./ui-motion-spec.md). In this revision, `Notification` may raise motion phases including `enter`, `exit`, and `reflow`.

**State model**

STATE closed

  ENTRY:
    1. The notification subtree is not mounted in the overlay layer.
    2. No dismissal timer is active for this instance.

  TRANSITIONS:
    ON open request:
      1. Mount the notification subtree into the active overlay layer.
      2. Resolve placement from `edge`, `align`, safe area, and active stack peers.
      3. Start the dismissal timer when `closeMethod = "auto-dismiss"`.
      → open

STATE open

  ENTRY:
    1. The notification subtree is mounted and visible.
    2. The notification participates in stack placement according to `stackable`.
    3. Underlying content remains interactive outside the notification hit region.

  TRANSITIONS:
    ON timer completion and `closeMethod = "auto-dismiss"`:
      1. Emit `onOpenChange(false)`.
      → closing

    ON explicit close activation and `closeMethod = "button"`:
      1. Emit `onOpenChange(false)`.
      → closing

STATE closing

  ENTRY:
    1. A close has been requested. The consumer has not yet committed the change.

  TRANSITIONS:
    ON close commit:
      1. Remove the notification subtree from the overlay layer.
      2. Release any timer owned by the instance.
      3. Recompute placement for remaining notifications in the same stack group.
      → closed

ERRORS:
  - `open` without `onOpenChange` when `open` is intended to be mutable → invalid configuration and deterministic failure.
  - `closeMethod` outside the documented enum set → invalid configuration and deterministic failure.
  - `edge` outside the documented enum set → invalid configuration and deterministic failure.
  - `align` outside the documented enum set → invalid configuration and deterministic failure.
  - `duration <= 0` when `closeMethod = "auto-dismiss"` → invalid configuration and deterministic failure.

**Accessibility contract**

`Notification` must be announced to assistive systems as a status surface. Opening a `Notification` must not move focus. `Notification` must not trap focus and must not prevent focus traversal in the base scene layer. The close control, when present, must be focusable and expose dismissal semantics to assistive systems.

**Composition rules**

`Notification` is an overlay control. Its subtree is mounted in the overlay layer defined by `Stage`, not in the base scene layer. `Notification` contains exactly one `content` subtree. The `content` subtree may contain text, drawable content, and layout structure appropriate for compact notification presentation. Nested interactive controls inside `content` are unsupported in this revision.

Placement rules:

- `edge = "top"`: notifications are placed against the top edge and stack downward.
- `edge = "bottom"`: notifications are placed against the bottom edge and stack upward.
- `edge = "left"`: notifications are placed against the left edge and stack rightward.
- `edge = "right"`: notifications are placed against the right edge and stack leftward.

Cross-axis alignment uses the documented `align` vocabulary:

- when `edge = "top"` or `edge = "bottom"`, `align` resolves horizontally
- when `edge = "left"` or `edge = "right"`, `align` resolves vertically

`stackable = true` causes notifications with the same effective `edge` and `align` to participate in shared stack offset resolution. `stackable = false` removes the notification from stack offset accumulation and may allow overlap with other notifications in the same placement group.

**Behavioral edge cases**

- A `Notification` with `closeMethod = "button"` must not start a dismissal timer.
- A `Notification` with `closeMethod = "auto-dismiss"` must not render a close control.
- A `Notification` with `stackable = true` and the same effective `edge` and `align` as its siblings must not overlap them by default.
- A `Notification` with `stackable = false` may overlap other notifications in the same placement group.
- A `Notification` that closes while stacked with siblings must not leave stale gaps after the next placement pass.
- A `Notification` must not block pointer interaction outside its own visible hit region.

### 6.16 Tooltip

**Purpose and contract**

`Tooltip` is a non-modal anchored overlay control that presents brief descriptive content associated with one owning trigger subtree. It supports preferred placement with automatic fallback resolution to remain as visible as possible within the effective visible region.

`Tooltip` must:

- support controlled open state
- request open-state changes through `onOpenChange`
- support hover-driven, focus-driven, combined hover-focus, and manual visibility modes
- position its surface relative to one owning trigger region
- honor a preferred placement while falling back when that placement would place the tooltip offscreen or materially clipped
- remain non-modal and non-blocking outside the tooltip surface
- not trap focus

**Anatomy**

- `root`: the tooltip coordination root. Required.
- `trigger`: the ordinary-scene subtree that owns the tooltip association and anchor geometry. Required.
- `surface`: the visible tooltip container mounted while open. Required while open.
- `content`: the consumer-provided tooltip body. Required.

**Props and API surface**

- `open: boolean | nil`
- `onOpenChange: function | nil`
- `placement: "top" | "bottom" | "left" | "right"`
- `align: "start" | "center" | "end"`
- `offset: number`
- `triggerMode: "hover" | "focus" | "hover-focus" | "manual"`
- `safeAreaAware: boolean`
- `motionPreset`
- `motion`

Default values:

- `placement = "top"`
- `align = "center"`
- `offset = 8`
- `triggerMode = "hover-focus"`
- `safeAreaAware = true`

Trace note: the public `Tooltip` surface is the prop set listed here plus the documented `trigger` and `content` regions. Internal geometry observers, hover-delay timers, and overlay-mount helpers remain implementation detail unless a later revision documents them explicitly.
When present, `motionPreset` and `motion` follow the contracts defined in [UI Motion Specification](./ui-motion-spec.md). In this revision, `Tooltip` may raise motion phases including `open`, `close`, and placement-related motion.

**State model**

STATE closed

  ENTRY:
    1. The tooltip surface is not mounted in the overlay layer.
    2. The trigger subtree remains in ordinary scene composition.

  TRANSITIONS:
    ON open request:
      1. Resolve the current trigger anchor region.
      2. Mount the tooltip surface into the active overlay layer.
      3. Resolve placement from the preferred `placement`, `align`, `offset`, and anchored-overlay fallback rules.
      → open

    ON a qualifying trigger-entry condition according to `triggerMode`:
      1. Emit `onOpenChange(true)`.
      → open

STATE open

  ENTRY:
    1. The tooltip surface is mounted and visible.
    2. The surface is positioned relative to the trigger region using the resolved placement.
    3. Underlying content remains interactive outside the tooltip surface.

  TRANSITIONS:
    ON all qualifying trigger conditions cease according to `triggerMode`:
      1. Emit `onOpenChange(false)`.
      → closing

    ON explicit close request:
      1. Emit `onOpenChange(false)`.
      → closing

    ON trigger geometry, safe area, viewport, or clipping-region change while open:
      1. Re-resolve placement using the anchored-overlay fallback rules.
      → open

STATE closing

  ENTRY:
    1. A close has been requested. The consumer has not yet committed the change.

  TRANSITIONS:
    ON close commit:
      1. Remove the tooltip surface from the overlay layer.
      2. Clear transient placement bookkeeping.
      → closed

ERRORS:
  - `open` without `onOpenChange` when `open` is intended to be mutable → invalid configuration and deterministic failure.
  - `placement` outside the documented enum set → invalid configuration and deterministic failure.
  - `align` outside the documented enum set → invalid configuration and deterministic failure.
  - `triggerMode` outside the documented enum set → invalid configuration and deterministic failure.
  - `offset < 0` → invalid configuration and deterministic failure.

**Accessibility contract**

`Tooltip` must be announced as descriptive associated content for its owning trigger, not as a modal or independent dialog surface. Opening a `Tooltip` must not move focus. When `triggerMode` includes focus, the tooltip must remain associated with the currently focused trigger for assistive systems while visible. The tooltip surface must not participate in ordinary focus traversal in this revision.

**Composition rules**

`Tooltip` coordinates one ordinary-scene `trigger` subtree and one overlay-mounted `surface` subtree inside one shared root. The `content` subtree may contain text, drawable content, and layout structure appropriate for compact descriptive presentation. Nested interactive controls inside `content` are unsupported in this revision. The surface must be positioned according to the anchored-overlay placement contract in the foundation specification and may resolve to a fallback placement when the preferred placement would exceed the effective visible region.

Cross-axis alignment uses the documented `align` vocabulary:

- when `placement = "top"` or `placement = "bottom"`, `align` resolves horizontally
- when `placement = "left"` or `placement = "right"`, `align` resolves vertically

`triggerMode` controls automatic visibility requests:

- `"hover"`: hover opens and closes the tooltip; focus alone does not
- `"focus"`: focus opens and closes the tooltip; hover alone does not
- `"hover-focus"`: either hover or focus may open the tooltip, and it remains open while at least one qualifying condition holds
- `"manual"`: ordinary hover and focus do not change visibility; only controlled `open` changes visibility

**Behavioral edge cases**

- A `Tooltip` in `manual` mode may remain visible without hover or focus.
- A `Tooltip` must not extend its surface outside the effective visible region when a valid fallback placement exists.
- When no placement fits fully, a `Tooltip` must use the placement that maximizes visible area and minimizes clipping.
- A `Tooltip` must not render a backdrop.
- A `Tooltip` must not trap focus or intercept pointer interaction outside its own visible hit region.
- A `Tooltip` whose trigger subtree is removed while open must close without failure on the next synchronization pass.

### 6.17 Tabs

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
- `motionPreset`
- `motion`

Trace note: the public `Tabs` surface is structural and value-driven. Helper registration or mutation methods such as `addTab(...)` or `setTriggerDisabled(...)` may exist internally, but they are not stable public API unless this section is amended to name them.
When present, `motionPreset` and `motion` follow the contracts defined in [UI Motion Specification](./ui-motion-spec.md). In this revision, `Tabs` may raise value-related motion, typically targeting `indicator` and `panel`.

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

All concrete controls in this document inherit the interaction, event propagation, focus, responsive, render-effects, and theming contracts defined in [UI Foundation Specification](./ui-foundation-spec.md).

Additional shared control rules for this revision:

- controls with a defined default action must execute that action only after listener delivery unless prevented
- controls that expose associated labels must define whether the label participates in activation
- controls that own text entry must own native text input lifecycle through the foundation runtime model
- overlay controls must bind to the overlay layer and focus-trap rules defined in the foundation specification
- anchored overlay controls must use the anchored-overlay placement contract defined in the foundation specification
- tab-family, radio-group, and select-popup controls must use roving focus within the owning root and must not activate on focus movement in this revision
- stateful controls must render from their authoritative committed state and may only propose public state changes through their documented callbacks

## 8. Visual Contract And Theming Contract

Concrete controls inherit the foundation visual and theming contract.

### 8.1 Stable Control Presentational Parts

This document stabilizes these control part names used by skins:

| Control | Stable presentational parts |
|---------|----------------------------|
| `Text` | `content` |
| `Button` | `surface`, `border`, `content`, `indicator` |
| `Checkbox` | `box`, `indicator`, `label`, `description` |
| `Radio` | `indicator`, `label`, `description` |
| `RadioGroup` | `radio` |
| `Switch` | `track`, `thumb`, `label`, `description` |
| `Slider` | `track`, `thumb` |
| `ProgressBar` | `track`, `indicator` |
| `Select` | `trigger`, `placeholder`, `popup`, `summary` |
| `Option` | `label`, `description` |
| `TextInput` | `field`, `placeholder`, `selection`, `caret` |
| `TextArea` | `field`, `placeholder`, `selection`, `caret`, `scroll region` |
| `Tabs` | `list`, `trigger`, `indicator`, `panel` |
| `Modal` | `backdrop`, `surface`, `content`, `close controls` |
| `Alert` | `backdrop`, `surface`, `title`, `message`, `actions`, `close controls` |
| `Notification` | `surface`, `content`, `close control` |
| `Tooltip` | `surface`, `content` |

### 8.2 Control Visual Surfaces

| Control or family | Library-owned visual structure | Shared overridable appearance surface | Consumer-owned surface |
|-------------------|--------------------------------|--------------------------------------|------------------------|
| `Text` | existence of one `content` part and text measurement boundary | font selection, color, alignment treatment, wrapping presentation | supplied text content |
| `Button`, `Checkbox`, `Radio`, `Switch` | required part split between press region and indicators such as `surface`, `box`, `indicator`, `track`, `thumb`, and label-bearing regions | part skins, border treatment, typography, indicator art, focus styling, disabled styling | content supplied through open content-bearing regions |
| `RadioGroup` | required coordination boundary between the group root and registered radio option roles | group-level spacing and orientation treatment, disabled-option styling, selected-option styling through registered radio parts | radio labels and descriptions supplied through registered radios |
| `Slider` | required separation of `track` and `thumb` roles | track fill, thumb styling, disabled styling, orientation treatment, focused styling | consumer-supplied value and range |
| `ProgressBar` | required separation of `track` and `indicator` roles | track fill, indicator fill, orientation treatment, and motion treatment for `value` and `indeterminate` phases | consumer-supplied value and range |
| `Select` and `Option` | required separation of trigger, popup, summary, placeholder, and option label/description roles | trigger chrome, popup chrome, selected-option styling, disabled-option styling, summary typography, placeholder typography, modal-versus-non-modal popup treatment | option labels and descriptions supplied through registered options |
| `TextInput`, `TextArea` | field-versus-content separation, caret/selection/placeholder part roles, internal editable region ownership | field chrome, placeholder styling, caret styling, selection styling, read-only and disabled skins | input value text supplied by consumer state |
| `Tabs` | required separation of `list`, `trigger`, `indicator`, and `panel` roles | trigger chrome, indicator treatment, panel chrome, disabled and active trigger skins | panel content and trigger content |
| `Modal`, `Alert` | required separation of `backdrop`, `surface`, content regions, and alert title/action roles | backdrop fill, surface chrome, title/message typography, action-region styling, close-control styling | modal body content and alert action content |
| `Notification` | required separation of `surface`, `content`, and optional close-control roles | surface chrome, content typography, icon treatment within consumer-owned content, close-control styling, and motion treatment for `enter`, `exit`, and `reflow` phases | notification content supplied through the `content` region |
| `Tooltip` | required separation of the ordinary-scene trigger association from the overlay-mounted `surface` and `content` roles | surface chrome, content typography, optional callout treatment, open-state styling, placement-dependent chrome treatment | tooltip content supplied through the `content` region and trigger content supplied through the `trigger` region |

Focus styling in this table is expressed through the documented part surfaces and their stateful variants. This revision does not standardize a separate focus-indicator token family distinct from the documented part/property bindings.

Trace note: clarified the focus-styling boundary so Phase 8 theming can render focus affordances through documented parts without inventing a new public token taxonomy.

### 8.3 Stateful Variant Priority Order

These priority orders satisfy Section 8.12 of the foundation specification:

- `Button`: `disabled > pressed > hovered > focused > base`
- `Checkbox`: `disabled > indeterminate > checked > focused > base`
- `Radio`: `disabled > selected > focused > base`
- `Switch`: `disabled > dragging > checked > focused > base`
- `Slider`: `disabled > dragging > focused > base`
- `ProgressBar`: `indeterminate > determinate`
- `Select` trigger parts: `disabled > open > focused > base`
- `Select` popup and option parts: `disabled > selected > focused > base`
- `TextInput`: `disabled > readOnly > composing > focused > base`
- `TextArea`: `disabled > readOnly > composing > focused > base`
- `Tabs` trigger parts: `disabled > active > focused > base`
- `Tabs` panel parts: `active > inactive`
- `Modal` and `Alert` do not define additional stateful skin priority beyond mounted versus unmounted presence in this revision
- `Notification` does not define additional stateful skin priority beyond mounted versus unmounted presence in this revision
- `Tooltip` does not define additional stateful skin priority beyond mounted versus unmounted presence in this revision

### 8.4 Control Structure Versus Appearance Boundary

The following are structural and therefore stable:

- the presentational part names in Section 8.1
- required role separation such as `backdrop` versus `surface`, `list` versus `panel`, and `field` versus `caret` and `selection`
- the existence of indicator-bearing regions such as `Checkbox.indicator`, `Radio.indicator`, `Switch.thumb`, and `Tabs.indicator` when those parts are named by the control contract
- the required separation of `Slider.track` and `Slider.thumb`
- the required separation of `Tooltip.surface` and `Tooltip.content`
- the required separation of `ProgressBar.track` and `ProgressBar.indicator`
- the required separation of `Select.trigger`, `Select.popup`, `Select.summary`, and `Select.placeholder`

The following are appearance and therefore overridable through the documented visual surface:

- colors, fonts, textures, border widths, radii, shadows, opacity values, shader choice, and decorative indicator art
- whether a stable part renders via solid fill, texture, quad, nine-slice, text draw, or custom renderer slot
- exact spacing and decorative geometry inside a stable part so long as the structural role of the part remains intact

The following remain implementation detail and are not stable API:

- undocumented helper wrappers or draw-only layers inside a control
- exact draw-call decomposition, batching, and cache strategy
- any internal ordering between undocumented decorative layers within a single named part

## 9. Deferred Items

- Additional concrete control families
  Reason: this revision is limited to the current bedrock control set.
