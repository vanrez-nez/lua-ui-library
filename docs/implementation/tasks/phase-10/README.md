# Phase 10 Task Set

Source implementation documents used for this phase:

- none; this phase is driven directly from the published specs

Authority rules for this phase:

- Treat `docs/spec/ui-foundation-spec.md`, `docs/spec/ui-controls-spec.md`, `docs/spec/ui-graphics-spec.md`, and `docs/spec/ui-motion-spec.md` as authoritative.
- Keep this phase strictly spec-driven; do not widen the public API beyond the published contracts.
- Graphics objects, retained graphics primitives, and motion integration are separate public domains and should not be collapsed into one undocumented helper surface.
- Motion support in this phase is an integration contract, not a commitment to a built-in timeline or physics engine.
- Control-local animation props that predate the motion spec must be normalized to the shared motion surface where the spec now requires it.

Settled spec clarifications that control this task set:

- `Texture`, `Atlas`, `Sprite`, and `Image` are first-class objects owned by `docs/spec/ui-graphics-spec.md`, not by the controls spec or the foundation spec.
- Motion is owned by `docs/spec/ui-motion-spec.md` as an integration contract. The library may ship internal helpers, but it must not require one built-in animation engine model.
- `motionPreset` and `motion` are the shared public motion entry points for motion-relevant controls in this revision.
- `Notification.duration` is dismissal timing only; it is not a general visual animation timing surface.
- Shader-driven motion is allowed only on documented shader-capable surfaces and only through documented motion properties.
- `Tooltip` is a distinct anchored overlay control, not a `Notification`, `Select`, or `Modal` variant.
- `Radio` and `RadioGroup` are separate controls with single-selection coordination; `Select` and `Option` are separate controls with popup selection coordination.
- Refactors needed to align older controls with the new graphics and motion specs are part of this phase and are not optional cleanup.

Implementation conventions for every task in this phase:

- Follow the current object model built on `lib/cls`; new runtime objects should be created with `Object:extends("Name")` or by extending the nearest existing base class rather than inventing a second class pattern.
- When adding retained primitives or controls, mirror the existing constructor pattern used by `Drawable`, `Button`, `Modal`, `Alert`, and `Tabs`: `:constructor(opts)`, a `new(opts)` helper, explicit parent-constructor calls, and internal state stored with `rawset`.
- Reuse `lib/ui/utils/schema.lua`, `lib/ui/utils/assert.lua`, `lib/ui/utils/types.lua`, and `lib/ui/utils/common.lua` for prop validation, defaults, type checks, and shallow-copy helpers instead of introducing one-off validators per module.
- For nodes with public props, extend the nearest existing schema via `Schema.merge(...)` or extend `_allowed_public_keys` in the same style used by `Drawable`, `Container`, `Modal`, and `Alert`.
- Reuse `lib/ui/controls/control_utils.lua` for base option extraction, controlled/uncontrolled pair validation, focus helpers, and optional callback dispatch instead of re-implementing those behaviors in each control.
- Before adding new helper modules, inspect nearby implementations under `lib/ui/core`, `lib/ui/controls`, and `lib/ui/utils` and preserve the prevailing naming, validation, and lifecycle patterns.

Task order:

1. `00-compliance-review.md`
2. `01-graphics-objects-and-image.md`
3. `02-motion-integration-and-adapter-boundary.md`
4. `03-radio-and-radiogroup-controls.md`
5. `04-select-and-option-controls.md`
6. `05-notification-and-tooltip-controls.md`
7. `06a-shared-drawable-render-effects-and-isolation.md`
8. `06-retrofit-existing-controls-for-motion-and-graphics.md`
9. `07-demo-and-acceptance.md`
