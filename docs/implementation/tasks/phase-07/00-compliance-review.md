# Phase 07 Compliance Review

Source under review: `docs/implementation/phase-07-controls.md`

Primary findings, ordered by severity:

1. The phase scope is overstated relative to the controls spec.
   Source: `phase-07-controls.md:5`
   Spec anchors: `ui-controls-spec.md:911-1066`, `ui-controls-spec.md:1238-1240`
   Problem: the phase doc says it implements the full set of concrete controls, but the controls specification also owns `Modal` and `Alert`. Those controls are not included in the phase document at all.
   Required normalization: either state explicitly that Modal and Alert are deferred to a later phase, or include them in the phase scope. Do not imply that the phase covers the full spec control set when it does not.

2. `Text` exposes the wrong public surface.
   Source: `phase-07-controls.md:27-46`
   Spec anchors: `ui-controls-spec.md:394-440`, `ui-controls-spec.md:1179-1203`
   Problem: the draft uses `alignX` and `fontPath`, but the spec stabilizes `textAlign`, `textVariant`, `font`, `fontSize`, `maxWidth`, `color`, and `wrap`. `Text` should not invent a new drawable-style alignment surface or a font-path API as public contract.
   Required normalization: align the `Text` API to the spec-backed props and keep any font-loading convenience behind internal support.

3. `Button` freezes an unsupported imperative method surface and omits the negotiated pressed-state contract.
   Source: `phase-07-controls.md:50-81`
   Spec anchors: `ui-controls-spec.md:442-549`, `ui-controls-spec.md:322-326`, `ui-controls-spec.md:1183-1201`
   Problems:
   - the draft exposes `button:setContent(node)` as a public method, but the spec explicitly says this revision defines no stable imperative handle, ref, or method surface for controls
   - the draft does not expose the spec-backed negotiated `pressed` state with `onPressedChange`
   Required normalization: keep button content as a spec-shaped slot/structural region and move any builder/helper API behind internal implementation detail.

4. `Checkbox` uses the wrong ownership and toggle contract.
   Source: `phase-07-controls.md:85-113`
   Spec anchors: `ui-controls-spec.md:551-635`, `ui-controls-spec.md:1210-1212`
   Problem: the draft introduces `defaultChecked` and `allowIndeterminate` instead of the spec-backed negotiated `checked` prop plus `toggleOrder`, and it models `label`/`description` as strings instead of content regions.
   Required normalization: use the negotiated checked-state model, keep toggle order explicit, and represent labels/descriptions as documented structural content.

5. `Switch` omits required spec props and locks in a non-spec drag policy.
   Source: `phase-07-controls.md:117-146`
   Spec anchors: `ui-controls-spec.md:637-733`, `ui-controls-spec.md:1211`
   Problem: the draft adds `defaultChecked` and resolves drag purely by midpoint, but the spec requires `checked`, `onCheckedChange`, `disabled`, `dragThreshold`, and `snapBehavior`.
   Required normalization: expose the full spec-backed prop surface and keep drag resolution policy aligned to `dragThreshold` plus `snapBehavior`.

6. `TextInput` and `TextArea` are missing stable public props and use implementation-specific input handling as if it were contract.
   Source: `phase-07-controls.md:150-233`
   Spec anchors: `ui-controls-spec.md:735-909`, `ui-controls-spec.md:1168-1173`, `ui-controls-spec.md:1201-1203`
   Problems:
   - `TextInput` introduces `defaultValue`, but the spec does not stabilize that prop; it stabilizes `value`, `onValueChange`, `selectionStart`, `selectionEnd`, `onSelectionChange`, `placeholder`, `disabled`, `readOnly`, `maxLength`, `inputMode`, `submitBehavior`, and `onSubmit`
   - `TextArea` omits the spec-backed `scrollXEnabled`, `scrollYEnabled`, and `momentum` props
   - the draft routes behavior through raw keyboard handling and Stage-specific lifecycle assumptions instead of keeping the spec-backed logical-input contract as the public boundary
   Required normalization: restore the documented prop surfaces and keep keyboard/platform wiring as internal implementation detail beneath the logical input model.

7. `Tabs` freezes an imperative registration API and omits several stable public props.
   Source: `phase-07-controls.md:237-269`
   Spec anchors: `ui-controls-spec.md:1068-1160`, `ui-controls-spec.md:322-326`, `ui-controls-spec.md:1191-1203`
   Problems:
   - `tabs:addTab` and `tabs:setTriggerDisabled` are exposed as stable methods, but the spec does not stabilize a control method surface
   - the draft omits `orientation`, `activationMode`, `listScrollable`, `loopFocus`, and `disabledValues`
   - the draft relies on a default-value registration model that is not the spec-backed public contract
   Required normalization: make trigger/panel registration an internal builder concern or a separately documented API if one is ever stabilized, and expose the full spec-backed Tabs props.

Secondary scoping notes:

- The font cache module is fine as internal support, but it should not become part of the public contract.
- Hardcoded visual states in Phase 7 are acceptable only as placeholder rendering for Phase 8; they must not alter the stable part topology or state semantics.
