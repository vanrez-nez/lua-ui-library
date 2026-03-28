# Phase 07 Compliance Review

Source under review: `docs/implementation/phase-07-controls.md`

Task-set authority:

- `docs/spec/ui-controls-spec.md`
- `docs/spec/ui-foundation-spec.md`

This review records the consolidated Phase 07 position after the current controls spec and its `Trace note` clarifications. The parent phase document remains useful planning context, but it is not the authority for public API or behavior.

Primary findings, ordered by severity:

1. Phase scope in the parent draft overstates what this directory implements.
   Source: `docs/implementation/phase-07-controls.md`
   Spec anchors:
   - `docs/spec/ui-controls-spec.md §4 Scope And Domain`
   - `docs/spec/ui-controls-spec.md §6.7 Modal`
   - `docs/spec/ui-controls-spec.md §6.8 Alert`
   Settled requirement:
   - The controls spec owns `Modal` and `Alert`, but this Phase 07 task directory still covers only `Text`, `Button`, `Checkbox`, `Switch`, `TextInput`, `TextArea`, and `Tabs`.
   - `Modal` and `Alert` are therefore an explicit deferred boundary for this directory, not an unresolved spec gap and not something to backfill through ad hoc overlay APIs in Phase 07.

2. Control composition surfaces are structural, not imperative builder APIs.
   Source: `docs/implementation/phase-07-controls.md`
   Spec anchors:
   - `docs/spec/ui-foundation-spec.md §3B Composition Grammar`
   - `docs/spec/ui-controls-spec.md §4B.3 Control Slot Declarations`
   - `docs/spec/ui-controls-spec.md §6.2 Button`
   - `docs/spec/ui-controls-spec.md §6.7 Modal`
   - `docs/spec/ui-controls-spec.md §6.8 Alert`
   - `docs/spec/ui-controls-spec.md §6.9 Tabs`
   Settled requirement:
   - `content`, `label`, `description`, `title`, `actions`, `list`, `panels`, `trigger`, and `panel` are stable slot, region, or registration surfaces.
   - Helper methods such as `button:setContent(...)`, `tabs:addTab(...)`, `tabs:setTriggerDisabled(...)`, modal `open()` / `close()`, and alert action-builder helpers remain internal unless the relevant control section explicitly promotes them.
   Trace-note closure:
   - The controls spec now says directly that documented slots and structural registration do not imply stable imperative setter or builder APIs.

3. Uncontrolled-default semantics do not create public `default*` props by implication.
   Source: `docs/implementation/phase-07-controls.md`
   Spec anchors:
   - `docs/spec/ui-controls-spec.md §4C.2 Public State Ownership Matrix`
   - `docs/spec/ui-controls-spec.md §6.5 TextInput`
   Settled requirement:
   - The task set must not preserve draft-only props such as `defaultChecked` or `defaultValue` for `Checkbox`, `Switch`, `TextInput`, `TextArea`, or `Tabs`.
   - Uncontrolled initial state follows the spec-owned defaults in the ownership matrix unless a control section explicitly names a `default*` prop, which these controls do not in this revision.
   Trace-note closure:
   - The ownership-matrix trace note explicitly closes the earlier ambiguity around `default*` prop inference.

4. `Text` and text-entry public surfaces are settled and narrower than the parent draft in specific areas.
   Source: `docs/implementation/phase-07-controls.md`
   Spec anchors:
   - `docs/spec/ui-controls-spec.md §6.1 Text`
   - `docs/spec/ui-controls-spec.md §6.5 TextInput`
   - `docs/spec/ui-controls-spec.md §6.6 TextArea`
   Settled requirement:
   - `Text` keeps `textAlign` and `textVariant`; draft-only public props such as `alignX` and `fontPath` do not survive into the task set.
   - `TextInput` and `TextArea` keep the spec-backed props and ownership rules, including `inputMode`, selection control, and `TextArea` scroll props.
   - Raw host key handling, clipboard plumbing, and native text-input activation remain internal beneath the logical input model.
   Trace-note closure:
   - The `Text` section now explicitly locks the public text-style surface.
   - The `TextInput` section now explicitly states that this revision does not add a separate `defaultValue` prop and keeps host plumbing internal.

5. `Checkbox`, `Switch`, and `Tabs` must follow the settled prop and structural contracts, not the older draft API shape.
   Source: `docs/implementation/phase-07-controls.md`
   Spec anchors:
   - `docs/spec/ui-controls-spec.md §6.3 Checkbox`
   - `docs/spec/ui-controls-spec.md §6.4 Switch`
   - `docs/spec/ui-controls-spec.md §6.9 Tabs`
   Settled requirement:
   - `Checkbox` uses negotiated `checked`, `onCheckedChange`, and `toggleOrder`, with label and description treated as structural content regions rather than string-only convenience props.
   - `Switch` uses negotiated `checked`, `onCheckedChange`, `dragThreshold`, and `snapBehavior`; midpoint-only drag resolution is not the public contract.
   - `Tabs` remains structural and value-driven, with `orientation`, `activationMode`, `listScrollable`, `loopFocus`, and `disabledValues` included in the public surface and manual activation preserved.
   Trace-note closure:
   - The `Tabs` section now explicitly closes the builder-method question and keeps registration helpers internal.

6. Phase 07 visuals may stay provisional, but only inside the settled part and state boundaries.
   Source: `docs/implementation/phase-07-controls.md`
   Spec anchors:
   - `docs/spec/ui-controls-spec.md §8.1 Control Part Names`
   - `docs/spec/ui-controls-spec.md §8.2 Control Visual Surfaces`
   - `docs/spec/ui-controls-spec.md §8.3 Stateful Variant Priority Order`
   Settled requirement:
   - Hardcoded Phase 07 visuals are acceptable as temporary implementation detail, but the task docs must preserve the spec-backed part topology and state priority order.
   - Focus affordances are rendered through documented parts and stateful variants; the task set must not imply a new public focus-style or token family.
   Trace-note closure:
   - The focus-styling boundary is now explicit in the controls spec.

Secondary scoping notes:

- Internal utilities such as a font cache remain acceptable so long as they do not leak into the public control contract.
- The parent phase document remains useful for sequencing, algorithms, and harness ideas where it does not widen the stable public surface.
- No unresolved Phase 07 compliance gap remains in this directory on builder methods, `default*` props, text-style surface, text-entry host plumbing, or focus-style boundary. These points are now settled by `docs/spec`.
