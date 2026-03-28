# Phase 07 Task Set

Primary authority for this task set:

- `docs/spec/ui-controls-spec.md`
- `docs/spec/ui-foundation-spec.md`

Parent planning context: `docs/implementation/phase-07-controls.md`.

Use the parent phase document as a historical implementation draft only. Where it diverges from `docs/spec`, the spec wins.

Normalization rules for this phase:

- Treat `docs/spec/ui-controls-spec.md` as normative for control public surfaces, ownership models, composition rules, behavioral edge cases, and stable part names.
- Treat `docs/spec/ui-foundation-spec.md` as normative for slotting, structural registration, event ordering, focus behavior, retained update/draw guarantees, overlay-layer ownership, and failure semantics.
- Treat the controls-spec `Trace note` additions as settled contract clarifications, not as open implementation gaps.
- Do not stabilize imperative helper methods, builder APIs, or `default*` props unless a control section explicitly names them.
- Phase 07 may use hardcoded visuals before Phase 08, but those visuals must stay within the documented part and state boundaries and must not invent new public theming or focus-indicator APIs.

Settled consolidation points carried through this directory:

- `Text` keeps the public surface `text`, `font`, `fontSize`, `maxWidth`, `textAlign`, `textVariant`, `color`, and `wrap`. Convenience font loaders and semantic text-role aliases remain internal.
- `Button`, `Checkbox`, `Switch`, `TextInput`, `TextArea`, and `Tabs` expose only the props, callbacks, slots, regions, and structural pairings named by the current spec.
- Documented slots, regions, and structural registration are stable composition surface, but helper methods such as `setContent(...)`, `addTab(...)`, `setTriggerDisabled(...)`, modal `open()` / `close()` helpers, and alert-construction helpers remain internal unless later documented.
- The uncontrolled-default table in the controls spec does not create public `defaultChecked`, `defaultValue`, or similar props by implication. If a control section does not name a `default*` prop, this phase must not add one.
- Raw host key handling, clipboard plumbing, native text-input activation, and internal scroll or list composition remain implementation detail beneath the logical input contract.
- Focus affordances render through documented control parts and state variants. Phase 07 must not imply a separate public focus-token taxonomy.
- `Modal` and `Alert` are stable controls in `docs/spec`, but this Phase 07 directory keeps them as an explicit deferred boundary because the parent implementation plan only covers `Text`, `Button`, `Checkbox`, `Switch`, `TextInput`, `TextArea`, and `Tabs`.

Task order:

1. `00-compliance-review.md`
2. `01-text-and-font-surface.md`
3. `02-button-activation-and-slotting.md`
4. `03-checkbox-and-switch-selection-controls.md`
5. `04-text-entry-controls.md`
6. `05-tabs-structure-and-roving-focus.md`
7. `06-deferred-modal-alert-boundary.md`
8. `07-demo-and-acceptance.md`
