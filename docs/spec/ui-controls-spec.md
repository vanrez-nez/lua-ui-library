# UI Controls Specification

> Version `0.1.0` — initial publication. Release history and change management policy: [UI Evolution Specification](./ui-evolution-spec.md).

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

The foundation contracts for event propagation, focus, responsive rules, runtime layers, render effects, theming, contract stability, and failure semantics remain authoritative and are not redefined here.

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
| `Switch` | Composite | binary state requests with tap, drag, and disabled semantics | indeterminate state, settings persistence, nested interactive content | extensible through documented slots only |
| `TextInput` | Composite | single-line text entry, caret, selection, composition, clipboard, and active text-input ownership | multiline editing, rich-text authoring, consumer-managed native text-input lifecycle | fixed |
| `TextArea` | Composite | multiline text entry with internal scrolling on the owned field content | single-line submit semantics, external scroll orchestration on owned axes, rich-text authoring | fixed |
| `Tabs` | Composite | one-to-one trigger and panel coordination, active-value resolution, and roving focus | closable or reorderable tabs, swipe navigation, business state inside panels | extensible through documented slots only |
| `Modal` | Composite | blocking overlay behavior, open-state requests, focus trapping, focus restoration, and backdrop policy | scene navigation, workflow policy, overlay stacking outside the overlay layer contract | extensible through documented slots only |
| `Alert` | Composite | alert-dialog pattern over `Modal`, including title, message, actions, and initial-focus rules | arbitrary modal taxonomies, non-dismissible flows, action side effects | extensible through documented slots only |

Additional control identity rules:

- `TextArea` inherits behavior from `TextInput` but remains a distinct component identity with its own multiline and scroll contract.
- `Alert` is not an alias of `Modal`; it is a separate composite with a stronger content contract and a distinct accessible role.
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
| `Switch` | any component with an open descendant slot or action-bearing slot | optional `label`; optional `description` | nested interactive controls inside label or description regions | none | valid |
| `TextInput` | any layout or drawable container that permits interactive descendants | none | interactive child nodes; nesting inside another text-entry control | none | valid |
| `TextArea` | any layout or drawable container that permits interactive descendants | none | interactive child nodes; nesting inside another text-entry control; nesting inside a scroll container that intercepts the same owned scroll axis | none | valid |
| `Modal` | only the `overlay layer` owned by `Stage` | one `surface` subtree containing one `content` subtree; optional consumer close controls | placement in the base scene layer; direct interaction with underlying scene content while mounted | `surface`, `content` | invalid when detached from the overlay layer |
| `Alert` | only the `overlay layer` owned by `Stage` as a specialized `Modal` | required `title` and `actions`; optional `message`; optional close controls | absence of any action control; placement outside the overlay layer | `title`, `actions` | invalid when detached from the overlay layer |
| `Tabs` | any component with an open descendant slot | one `list` region and one `panels` region containing mapped `trigger` and `panel` sub-parts | unmatched triggers or panels; duplicate trigger values; trigger lists without panels or panels without triggers | `list`, `panels`, at least one mapped `trigger`/`panel` pair | valid only when the required pair structure is complete |

Validity notes:

- `Button`, `Checkbox`, and `Switch` are compositionally open only through their documented content-bearing regions.
- `TextInput` and `TextArea` expose named presentational parts but no consumer-fillable descendant slots in this revision.
- `Modal` and `Alert` are invalid as ordinary descendants of base-scene layout or control containers because their parent relationship is defined by overlay mounting, not ordinary containment.
- `Tabs` validity is re-evaluated whenever trigger or panel structure changes; insertion into an arbitrary ancestor does not preserve validity unless the full `Tabs` contract remains satisfied.

### 4B.2 Compound Control Contracts

| Root | Required sub-parts | Optional sub-parts | Independent meaning outside the root | Structural communication mechanism | Sub-part set |
|------|--------------------|--------------------|--------------------------------------|-----------------------------------|--------------|
| `Button` | `root`, `content` | `indicator` | `content` may contain independent components; `indicator` has no independent meaning outside `Button` | root-owned slot resolution for `content` | closed except for the open `content` slot |
| `Checkbox` | `root`, `box` | `indicator`, `label`, `description` | `label` and `description` may contain independent components; `box` and `indicator` are meaningful only within `Checkbox` | root-owned role resolution of label-participation and activation region | closed except for `label` and `description` content |
| `Switch` | `root`, `track`, `thumb` | `label`, `description` | `label` and `description` may contain independent components; `track` and `thumb` are meaningful only within `Switch` | root-owned role resolution of drag region and associated content | closed except for `label` and `description` content |
| `Modal` | `root`, `backdrop`, `surface`, `content` | `close controls` | `content` may contain independent components; the structural roles have no independent overlay meaning outside `Modal` | overlay-layer mounting plus root-owned slot resolution inside `surface` | closed except for the open `content` region |
| `Alert` | `root`, `backdrop`, `surface`, `title`, `actions` | `message`, `close controls` | `title`, `message`, and `actions` may contain independent components, but their alert roles exist only within `Alert` | specialized `Modal` slot resolution with required action-region presence | closed except for documented content regions |
| `Tabs` | `root`, `list`, `panels`, one or more `trigger`, one or more `panel` | `indicator` | `trigger` and `panel` roles have no valid independent meaning outside one owning `Tabs` root | structural registration of each `trigger` and `panel` to the owning `Tabs` root by mapped value and role | closed |

### 4B.3 Control Slot Declarations

| Control | Slot or region | Multiplicity | Filler constraints | Default content |
|---------|----------------|--------------|--------------------|-----------------|
| `Button` | `content` | zero or one subtree | text or drawable structure; no nested interactive controls | empty content is allowed |
| `Checkbox` | `label` | zero or one subtree | non-interactive associated content | none |
| `Checkbox` | `description` | zero or one subtree | non-interactive associated content | none |
| `Switch` | `label` | zero or one subtree | non-interactive associated content | none |
| `Switch` | `description` | zero or one subtree | non-interactive associated content | none |
| `Modal` | `content` | exactly one subtree | any layout or control components valid in overlay content | none |
| `Alert` | `title` | exactly one subtree | non-interactive heading content | none |
| `Alert` | `message` | zero or one subtree | non-interactive explanatory content | none |
| `Alert` | `actions` | one or more activation controls | controls that provide an explicit dismissal or confirmation path | none |
| `Tabs` | `list` | exactly one region | contains only `trigger` sub-parts for the owning `Tabs` root | none |
| `Tabs` | `panels` | exactly one region | contains only `panel` sub-parts for the owning `Tabs` root | none |

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
| `Switch` | `checked` | application state | negotiated | `checked` with `onCheckedChange` | `false` |
| `TextInput` | `value` | application state | negotiated | `value` with `onValueChange` | empty string |
| `TextInput` | `selectionStart` and `selectionEnd` as one property pair | UI state | negotiated | both selection boundaries plus `onSelectionChange` | collapsed selection at end of current value |
| `TextArea` | `value` | application state | negotiated | `value` with `onValueChange` | empty string |
| `TextArea` | `selectionStart` and `selectionEnd` as one property pair | UI state | negotiated | both selection boundaries plus `onSelectionChange` | collapsed selection at end of current value |
| `Modal` | `open` | UI state | negotiated | `open` with `onOpenChange` | `false` |
| `Alert` | `open` | UI state | negotiated through `Modal` | `open` with `onOpenChange` | `false` |
| `Tabs` | `value` | composition state | negotiated | `value` with `onValueChange` | first enabled mapped trigger value, otherwise `nil` |

Hybrid notes:

- `TextInput` and `TextArea` may control `value` and selection independently because those properties have separate ownership signals.
- `Checkbox`, `Switch`, `Modal`, `Alert`, and `Tabs` expose one negotiable public state property each in this revision.
- `Button` exposes negotiable `pressed` state, but hover and focus remain library-owned interaction state.

### 4C.3 Pending And Uncontrolled Behavior

Pending controlled behavior:

- `Button`, `Checkbox`, `Switch`, `Modal`, `Alert`, and `Tabs` must continue to render and behave from the last committed controlled value until the consumer updates that value.
- `TextInput` and `TextArea` must continue to render the last committed controlled `value` and controlled selection while allowing library-owned interaction state such as focus and composition candidate presence to continue updating.

Uncontrolled observation:

- no control in this revision exposes a stable imperative getter or setter for uncontrolled public state
- uncontrolled state changes remain observable through change callbacks, accessibility metadata, composition effects, and visible committed output

### 4C.4 Composition-State Scope And Coordination

Composition-state rules for concrete controls:

- `Tabs` is the only concrete control in this revision with public composition state. Its active value is scoped to the nearest `Tabs` root and coordinates registered triggers and panels only within that root.
- `Modal` and `Alert` use library-owned focus-trap coordination and overlay ownership state scoped to the mounted overlay subtree. That coordination state is not a consumer-owned public value.
- `Checkbox` and `Switch` do not automatically coordinate with sibling selection controls in this revision. Any shared checked-value semantics across multiple controls must be provided explicitly by the consumer.

### 4C.5 Control Derived State

| Control | Stable derived state | Derivation rule |
|---------|----------------------|-----------------|
| `Button` | effective pressed state | controlled `pressed` when present, otherwise library-owned press interaction state |
| `Checkbox` | effective checked state | controlled `checked` when present, otherwise the uncontrolled checked value after toggle-order resolution |
| `Switch` | effective checked state | controlled `checked` when present, otherwise the uncontrolled checked value after tap or drag resolution |
| `TextInput` | effective value, effective selection | controlled value and selection when present, otherwise uncontrolled committed text and library-managed selection |
| `TextArea` | effective value, effective selection, effective scrollability | `TextArea` derives the same committed editing values as `TextInput`, plus scrollability from content extent, wrap mode, and visible field size |
| `Modal` | effective open state | controlled `open` when present, otherwise uncontrolled mounted state |
| `Alert` | effective open state | `Alert` uses the `Modal` derivation for `open` |
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
| `Switch` | `Activate`, `Drag` | `onCheckedChange` | toggle on tap activation or resolve final checked state at drag release |
| `TextInput` | `Activate`, `Navigate`, `TextInput`, `TextCompose`, `Submit`, pointer selection gestures | `onValueChange`, `onSelectionChange`, `onSubmit` | acquire focus, update selection, propose committed text insertion, update composition candidate, or submit according to `submitBehavior` |
| `TextArea` | `Activate`, `Navigate`, `TextInput`, `TextCompose`, `Scroll`, `Submit`, pointer selection gestures | `onValueChange`, `onSelectionChange`, `onSubmit` | same as `TextInput`, plus internal scroll handling and newline insertion rules |
| `Modal` | `Dismiss`, `Activate` on explicit close actions, `Activate` on backdrop when configured | `onOpenChange` | propose `open = false` when dismissal policy allows |
| `Alert` | `Dismiss`, `Activate` on explicit actions, `Activate` on backdrop when configured | `onOpenChange` plus action-control callbacks supplied by the consumer | same as `Modal`, plus action activation inside the actions region |
| `Tabs` | `Navigate`, `Activate` | `onValueChange` | move roving focus on navigation and propose a new active value only on activation |

### 4D.2 Focus And Pointer-Coupling Rules By Control Family

| Control or family | Pointer-focus coupling | Focus movement responsibility | Notes |
|-------------------|------------------------|-------------------------------|-------|
| `Button`, `Checkbox`, `Switch` | focuses before default action | library-managed through ordinary focus traversal | pointer or touch activation may establish focus on the target control |
| `TextInput`, `TextArea` | focuses before text-entry activation | library-managed plus platform text-entry activation cooperation | focus acquisition must establish active text-entry ownership |
| `Modal`, `Alert` | opening moves focus into the overlay scope; backdrop activation does not move focus into underlying content | library-managed with trapping and restoration | dismissal may restore prior focus when configured |
| `Tabs` trigger list | focus moves independently of activation | library-managed roving focus within the trigger list | focus movement alone must not activate a tab |

### 4D.3 Control-Specific Dismissal And Submission Rules

- `Modal` and `Alert` recognize `Dismiss` through escape-like commands and backdrop activation only when the corresponding dismissal props allow it.
- `TextInput` recognizes `Submit` according to `submitBehavior`: `blur` proposes blur after submit, `submit` invokes `onSubmit`, and `none` takes no submit default action.
- `TextArea` consumes `Submit` as newline insertion when multiline editing rules require it; it must not treat the newline command as `onSubmit` unless a future component revision explicitly adds that behavior.
- `Tabs` does not recognize `Dismiss` as a tab-state-changing input in this revision.

### 4D.4 Event Ordering And Cancellation At Control Level

- For `Button`, `Checkbox`, `Switch`, `Tabs`, `Modal`, and `Alert`, cancellable interaction events must finish listener delivery before the library proposes any state change through the documented callback.
- Cancelling `ui.activate` on `Button`, `Checkbox`, `Switch`, or `Tabs` prevents the default action and therefore prevents the associated callback proposal for that activation.
- Cancelling `ui.dismiss` on `Modal` or `Alert` prevents the `onOpenChange(false)` proposal for that dismissal attempt.
- Cancelling `ui.text.input`, `ui.text.compose`, or `ui.submit` on `TextInput` or `TextArea` prevents the associated insertion, composition update, or submit default action for that interaction.

## 4E. Control Behavioral Completeness

The behavioral-completeness rules in Section 3E of [UI Foundation Specification](./ui-foundation-spec.md) are binding for all controls in this document.

### 4E.1 Empty And Null State Behavior By Control

| Control | No-content or empty case | Library-provided empty state | Observable empty-state transition |
|---------|---------------------------|------------------------------|-----------------------------------|
| `Text` | empty string renders nothing and remains valid | none | no |
| `Button` | empty `content` slot remains valid and interactive | none | no |
| `Checkbox` and `Switch` | absent `label` or `description` remains valid and interactive | none | no |
| `TextInput` and `TextArea` | empty value remains valid; placeholder behavior follows the existing component contract | placeholder is consumer-provided content, not library-injected fallback | no |
| `Modal` | no focusable content remains valid; the overlay still mounts and traps focus when configured | none | no |
| `Alert` | missing `message` is valid; missing `actions` is prohibited by the component contract | none | no |
| `Tabs` | zero valid trigger/panel pairs is structurally invalid per the composition contract, not an empty-but-valid interactive state | none | no |

### 4E.2 Overflow And Constraint Behavior By Control Family

| Control or family | Default overflow behavior | Minimum functional contract | Response to post-mount constraint changes |
|-------------------|---------------------------|-----------------------------|-------------------------------------------|
| `Text` | wrap when configured, otherwise overflow without clipping unless an ancestor clips | remains valid at zero or tiny width but may render no visible glyphs | re-measure on the next draw preparation |
| `Button`, `Checkbox`, `Switch` | content may visually overflow, clip through ancestors, or compress according to skin geometry; no implicit scroll region is created | activation region remains valid even when text or indicator art no longer fits fully | recompute part layout from the latest bounds on the next pass |
| `TextInput` | single-line content does not wrap; overflow is handled by selection/caret movement within the field contract rather than by multiline reflow | remains focusable and editable so long as the field region exists | recompute selection geometry and visible insertion region from the new field size |
| `TextArea` | vertical overflow is handled by the internal scroll region; horizontal overflow is suppressed when `wrap = true` and allowed when wrapping is disabled | remains editable at any finite size, though visible text area may collapse to a minimal viewport | recompute wrapping, content extent, and internal scroll range |
| `Tabs` | overflow in the trigger list may be handled by scrollable composition when enabled; panel overflow follows the panel content contract | trigger activation and focus movement remain valid even when the list is partially offscreen | re-resolve trigger list overflow and active panel layout |
| `Modal` and `Alert` | surface content may overflow according to the layout content placed inside the surface; backdrop always fills the viewport | overlay remains dismissable and focus-managed even when surface content cannot fully fit | recompute surface placement and safe-area-aware bounds on the next pass |

### 4E.3 Rapid And Concurrent Input Behavior By Control Family

| Control or family | Queueing or arbitration policy | Consistency guarantee |
|-------------------|--------------------------------|-----------------------|
| `Button`, `Checkbox`, `Switch` | each activation attempt is processed independently in arrival order; gesture ownership determines which pointer sequence may finish a press or drag | committed state remains coherent after each completed activation or drag release |
| `TextInput` and `TextArea` | committed text and composition updates are processed in arrival order while the field owns active text-entry state | committed value and selection reflect a consistent committed pair after each processed logical input |
| `Modal` and `Alert` | dismissal requests are processed in arrival order; once a close has been proposed, additional close requests before commit do not create a second distinct close state | open-state proposals remain coherent and focus-trap ownership does not split across concurrent dismiss inputs |
| `Tabs` | navigation and activation inputs are processed independently in arrival order; navigation never retroactively activates a tab | roving focus and active value remain coherent and do not diverge within one `Tabs` root |

No control in this revision declares a built-in throttle or debounce policy.

### 4E.4 Transition Interruption And Destruction During Activity

| Control or family | Interrupted activity | Resolution rule |
|-------------------|----------------------|-----------------|
| `Button` | press interaction interrupted by disable, release outside, or destruction | clear press ownership, emit no activation, and leave only the last committed authoritative pressed value |
| `Checkbox` and `Switch` | activation or drag interrupted by disable, focus loss, or destruction | abandon the in-progress gesture; only a completed uncancelled activation or drag release may propose a new checked value |
| `TextInput` and `TextArea` | text composition interrupted by focus loss or destruction | discard the composition candidate without committing it and release active text-entry ownership |
| `Modal` and `Alert` | open or close flow interrupted by a new authoritative `open` value or destruction | resolve to the latest authoritative open state; if destroyed while open, release focus trap ownership and stop further dismissal proposals from that instance |
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
| `Switch` | `Stable` | `0.1.0` | no | n/a | n/a |
| `TextInput` | `Stable` | `0.1.0` | no | n/a | n/a |
| `TextArea` | `Stable` | `0.1.0` | no | n/a | n/a |
| `Tabs` | `Stable` | `0.1.0` | no | n/a | n/a |
| `Modal` | `Stable` | `0.1.0` | no | n/a | n/a |
| `Alert` | `Stable` | `0.1.0` | no | n/a | n/a |

### 4F.2 Control Public Surface Classification

Unless this section explicitly says otherwise, every documented control surface in this document is `Stable` as of `0.1.0`.

| Control | Documented props and public state | Documented callbacks and event payload contracts | Documented slots or compound regions | Documented named visual parts | Undocumented helpers and private coordination state |
|---------|-----------------------------------|--------------------------------------------------|--------------------------------------|-------------------------------|-----------------------------------------------------|
| `Text` | `Stable` since `0.1.0` | no public callback surface in this revision | none | `Stable` since `0.1.0` | `Internal` |
| `Button` | `Stable` since `0.1.0` | `Stable` since `0.1.0` | `content` slot is `Stable` since `0.1.0` | `Stable` since `0.1.0` | `Internal` |
| `Checkbox` | `Stable` since `0.1.0` | `Stable` since `0.1.0` | `label` and `description` regions are `Stable` since `0.1.0` | `Stable` since `0.1.0` | `Internal` |
| `Switch` | `Stable` since `0.1.0` | `Stable` since `0.1.0` | `label` and `description` regions are `Stable` since `0.1.0` | `Stable` since `0.1.0` | `Internal` |
| `TextInput` | `Stable` since `0.1.0` | `Stable` since `0.1.0` | no consumer-fillable descendant slots in this revision | `Stable` since `0.1.0` | `Internal` |
| `TextArea` | `Stable` since `0.1.0` | `Stable` since `0.1.0` | no consumer-fillable descendant slots in this revision | `Stable` since `0.1.0` | `Internal` |
| `Tabs` | `Stable` since `0.1.0` | `Stable` since `0.1.0` | `list`, `panels`, `trigger`, and `panel` structure is `Stable` since `0.1.0` | `Stable` since `0.1.0` | `Internal` |
| `Modal` | `Stable` since `0.1.0` | `Stable` since `0.1.0` | `surface`, `content`, and documented close-control regions are `Stable` since `0.1.0` | `Stable` since `0.1.0` | `Internal` |
| `Alert` | `Stable` since `0.1.0` | `Stable` since `0.1.0` | `title`, `message`, `actions`, and documented close-control regions are `Stable` since `0.1.0` | `Stable` since `0.1.0` | `Internal` |

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
| structural invalidity | `Tabs` trigger/panel mismatches, duplicate trigger values, `Modal` or `Alert` detached from the overlay layer, prohibited child nodes in `Text`, `TextInput`, or `TextArea` | when the control structure is mounted, registered, or next reconciled | `Hard failure` | no control-specific structural repair is attempted |
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
- invalid `Tabs`, `Modal`, or `Alert` operations must not leave split active-value ownership, split focus-trap ownership, or partially committed overlay state across unrelated roots
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

All concrete controls in this document inherit the interaction, event propagation, focus, responsive, render-effects, and theming contracts defined in [UI Foundation Specification](./ui-foundation-spec.md).

Additional shared control rules for this revision:

- controls with a defined default action must execute that action only after listener delivery unless prevented
- controls that expose associated labels must define whether the label participates in activation
- controls that own text entry must own native text input lifecycle through the foundation runtime model
- overlay controls must bind to the overlay layer and focus-trap rules defined in the foundation specification
- tab-family controls must use roving focus within the trigger list and must not activate on focus movement in this revision
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
| `Switch` | `track`, `thumb`, `label`, `description` |
| `TextInput` | `field`, `placeholder`, `selection`, `caret` |
| `TextArea` | `field`, `placeholder`, `selection`, `caret`, `scroll region` |
| `Tabs` | `list`, `trigger`, `indicator`, `panel` |
| `Modal` | `backdrop`, `surface`, `content`, `close controls` |
| `Alert` | `backdrop`, `surface`, `title`, `message`, `actions`, `close controls` |

### 8.2 Control Visual Surfaces

| Control or family | Library-owned visual structure | Shared overridable appearance surface | Consumer-owned surface |
|-------------------|--------------------------------|--------------------------------------|------------------------|
| `Text` | existence of one `content` part and text measurement boundary | font selection, color, alignment treatment, wrapping presentation | supplied text content |
| `Button`, `Checkbox`, `Switch` | required part split between press region and indicators such as `surface`, `box`, `track`, `thumb`, and label-bearing regions | part skins, border treatment, typography, indicator art, focus styling, disabled styling | content supplied through open content-bearing regions |
| `TextInput`, `TextArea` | field-versus-content separation, caret/selection/placeholder part roles, internal editable region ownership | field chrome, placeholder styling, caret styling, selection styling, read-only and disabled skins | input value text supplied by consumer state |
| `Tabs` | required separation of `list`, `trigger`, `indicator`, and `panel` roles | trigger chrome, indicator treatment, panel chrome, disabled and active trigger skins | panel content and trigger content |
| `Modal`, `Alert` | required separation of `backdrop`, `surface`, content regions, and alert title/action roles | backdrop fill, surface chrome, title/message typography, action-region styling, close-control styling | modal body content and alert action content |

### 8.3 Stateful Variant Priority Order

These priority orders satisfy Section 8.12 of the foundation specification:

- `Button`: `disabled > pressed > hovered > focused > base`
- `Checkbox`: `disabled > indeterminate > checked > focused > base`
- `Switch`: `disabled > dragging > checked > focused > base`
- `TextInput`: `disabled > readOnly > composing > focused > base`
- `TextArea`: `disabled > readOnly > composing > focused > base`
- `Tabs` trigger parts: `disabled > active > focused > base`
- `Tabs` panel parts: `active > inactive`
- `Modal` and `Alert` do not define additional stateful skin priority beyond mounted versus unmounted presence in this revision

### 8.4 Control Structure Versus Appearance Boundary

The following are structural and therefore stable:

- the presentational part names in Section 8.1
- required role separation such as `backdrop` versus `surface`, `list` versus `panel`, and `field` versus `caret` and `selection`
- the existence of indicator-bearing regions such as `Checkbox.indicator`, `Switch.thumb`, and `Tabs.indicator` when those parts are named by the control contract

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
