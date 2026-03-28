# Phase 07 Task Set

Source implementation document used for this phase: `docs/implementation/phase-07-controls.md`.

Normalization rules for this phase:

- Treat `docs/spec/ui-controls-spec.md` as normative for all concrete control families.
- Keep `docs/spec/ui-foundation-spec.md` normative for event propagation, focus, layout ownership, responsive behavior, and visual-contract boundaries.
- Do not freeze any imperative control method surface unless the spec explicitly stabilizes it.
- Hardcoded visuals and helper caches may exist for Phase 7, but they remain implementation detail and must not redefine the stable control contract.

Key corrections applied to the original phase document:

- `Text` must keep the spec-backed public surface, including `textAlign` and `textVariant`, instead of replacing it with drawable-style alignment props.
- `Button`, `Checkbox`, `Switch`, `TextInput`, `TextArea`, and `Tabs` must expose the negotiated props and callbacks named by the spec.
- `button:setContent`, `tabs:addTab`, and `tabs:setTriggerDisabled` are not spec-stabilized public APIs and must be treated as internal builder helpers if they exist at all.
- `TextArea` inherits `TextInput` props and must add the spec-backed scroll props, not just `wrap` and `rows`.
- The phase doc omits `Modal` and `Alert`, which are part of the controls specification. This phase task set treats them as deferred scope and keeps that boundary explicit rather than silently folding them into Phase 7.

Task order:

1. `00-compliance-review.md`
2. `01-text-and-font-surface.md`
3. `02-button-activation-and-slotting.md`
4. `03-checkbox-and-switch-selection-controls.md`
5. `04-text-entry-controls.md`
6. `05-tabs-structure-and-roving-focus.md`
7. `06-deferred-modal-alert-boundary.md`
8. `07-demo-and-acceptance.md`
