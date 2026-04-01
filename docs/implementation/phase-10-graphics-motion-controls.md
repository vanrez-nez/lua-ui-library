# Phase 10: Graphics, Motion, And Additional Controls

## Purpose

Phase 10 closes the gap between the current published specs and the implementation plan by introducing:

- first-class graphics objects and the retained `Image` primitive
- the shared motion integration contract
- the remaining control families added after the earlier control phases
- retrofit work for previously implemented controls now affected by the graphics and motion revisions

This phase is intentionally spec-driven. Unlike earlier phases, it is not derived from one older implementation draft that predates the current published contracts.

## Authority

The following documents are authoritative for this phase:

- `docs/spec/ui-foundation-spec.md`
- `docs/spec/ui-controls-spec.md`
- `docs/spec/ui-graphics-spec.md`
- `docs/spec/ui-motion-spec.md`

This document is sequencing and scoping context only. It must not widen the public API beyond those published specs.

## Scope Summary

Phase 10 covers four major areas.

### 1. Graphics Objects

Implement the first-class graphics-object surface:

- `Texture`
- `Atlas`
- `Sprite`
- `Image`

This work must align to the graphics spec and the foundation graphics-asset interoperability contract without inventing a public asset-loader or animation-player API.

### 2. Motion Integration

Implement the shared motion surface:

- `motionPreset`
- `motion`
- motion phases
- motion surfaces
- motion properties
- motion adapters

This phase must preserve the spec boundary that motion integration is public while a built-in animation engine is not required public API.

### 3. Additional Controls

Implement the currently published controls that do not yet have dedicated implementation coverage:

- `Radio`
- `RadioGroup`
- `Select`
- `Option`
- `Notification`
- `Tooltip`

These controls must be implemented on the current published surfaces, including overlay, popup, placement, and motion behavior where applicable.

### 4. Retrofit Work

Bring earlier control implementations into alignment with the current spec revisions, especially where graphics-backed rendering or shared motion support now applies. This includes, at minimum:

- `Button`
- `ProgressBar`
- `Modal`
- `Alert`
- `Tabs`

## Key Normalizations

The following phase-level normalizations are settled:

- graphics objects are first-class objects, not internal render-only helpers
- motion is a shared integration contract, not a per-control ad hoc prop family
- `Notification.duration` is dismissal timing only and must not be treated as a generic visual animation prop
- shader-driven motion is allowed only on documented shader-capable surfaces and only through documented motion properties
- anchored overlay behavior for `Tooltip` must use the published preferred-placement and fallback-fitting contract
- popup, overlay, and motion helpers may exist internally, but their helper shapes are not public API unless the spec explicitly says so

## Implementation Strategy

Recommended order:

1. establish graphics objects and retained `Image`
2. establish the motion adapter boundary and shared motion plumbing
3. implement the missing control families that depend on those contracts
4. retrofit earlier controls to the revised specs
5. finish with a dedicated demo and acceptance harness

This ordering keeps later control work from hardcoding graphics- or motion-local assumptions that the current specs no longer permit.

## Task Set

The executable task breakdown for this phase is:

1. `docs/implementation/tasks/phase-10/00-compliance-review.md`
2. `docs/implementation/tasks/phase-10/01-graphics-objects-and-image.md`
3. `docs/implementation/tasks/phase-10/02-motion-integration-and-adapter-boundary.md`
4. `docs/implementation/tasks/phase-10/03-radio-and-radiogroup-controls.md`
5. `docs/implementation/tasks/phase-10/04-select-and-option-controls.md`
6. `docs/implementation/tasks/phase-10/05-notification-and-tooltip-controls.md`
7. `docs/implementation/tasks/phase-10/06-retrofit-existing-controls-for-motion-and-graphics.md`
8. `docs/implementation/tasks/phase-10/07-demo-and-acceptance.md`

## Non-Goals

Phase 10 does not introduce:

- a public animation-engine object model
- a required built-in preset catalog
- a public asset-loader registry
- a public popup manager or overlay registry API
- graphics-object-owned animation playback

## Expected Outcomes

At the end of this phase:

- the graphics spec has direct implementation coverage
- the motion spec has direct implementation coverage
- the remaining published controls have implementation coverage
- older controls no longer depend on superseded pre-motion or pre-graphics assumptions
- the demo and regression surface matches the current published spec set
