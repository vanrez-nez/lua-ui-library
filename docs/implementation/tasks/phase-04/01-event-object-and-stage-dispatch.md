# Task 01: Event Object And Stage Dispatch

## Goal

Implement the shared event object and the Stage-level raw-input delivery boundary without overcommitting a listener API or activation timing policy.

## Spec Anchors

- `docs/spec/ui-foundation-spec.md §3D.1 Input Abstraction Model`
- `docs/spec/ui-foundation-spec.md §3D.2 Event Contract`
- `docs/spec/ui-foundation-spec.md §7.1 Event Propagation`
- `docs/spec/ui-foundation-spec.md §6.4.1 Stage`

## Scope

- Implement `lib/ui/event/event.lua`
- Extend `lib/ui/scene/stage.lua` with `deliverInput(rawEvent)`
- Translate raw Love2D callbacks into logical intents before propagation

## Required Behavior

- Event objects expose the spec-backed fields: `type`, `phase`, `target`, `currentTarget`, `path`, `timestamp`, `defaultPrevented`, `propagationStopped`, `immediatePropagationStopped`.
- Spatial events expose the spec-backed pointer and coordinate fields.
- Navigation, scroll, drag, text, composition, and focus events carry the required family-specific fields when they are dispatched.
- Stage remains the single raw-input entry point for the retained tree.

## Normalization Rules

- Pointer activation must resolve through a single activation gesture per user action. Press/release mapping may exist internally, but it must not produce duplicate public `ui.activate` dispatches for one pointer sequence.
- The drag-threshold value is an internal gesture-recognition detail, not a new public API.
- Text and focus dispatch remain phase-5-facing public behaviors; Phase 4 may build the event object and routing scaffolding without claiming to finalize those future surfaces.

## Non-Goals

- No public listener-registration API commitment.
- No hover-state public API commitment.
- No control-specific default action behavior beyond dispatch plumbing.

## Acceptance Checks

- Raw Love2D input reaches Stage only through `deliverInput`.
- Event objects are populated consistently for all supported logical intents.
- One pointer gesture cannot emit duplicate activation events in the steady-state path.
