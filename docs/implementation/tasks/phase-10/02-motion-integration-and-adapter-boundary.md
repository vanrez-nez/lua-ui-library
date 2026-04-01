# Task 02: Motion Integration And Adapter Boundary

## Goal

Implement the shared motion integration surface without turning the UI library into a built-in animation engine.

## Spec Anchors

- `docs/spec/ui-motion-spec.md §4 Scope And Domain`
- `docs/spec/ui-motion-spec.md §4A Motion Responsibility Boundary`
- `docs/spec/ui-motion-spec.md §4B Motion Surface Model`
- `docs/spec/ui-motion-spec.md §4C Motion Property Model`
- `docs/spec/ui-motion-spec.md §4D Motion Descriptor Contract`
- `docs/spec/ui-motion-spec.md §4E Motion Adapter Contract`
- `docs/spec/ui-motion-spec.md §4G Easing Contract`
- `docs/spec/ui-motion-spec.md §4H Interruption, Authority, And Destruction`
- `docs/spec/ui-foundation-spec.md §3A.5 Rendering Model Declaration`

## Scope

- Shared motion request plumbing
- `motionPreset` and `motion` surface handling
- Motion surface targeting to documented stable parts and root visual surfaces only
- Property-level duration, delay, and easing handling
- Acceptance of string easing identifiers and easing functions
- Adapter boundary for external or consumer-provided motion drivers
- Shader-bound motion-property support on documented shader-capable surfaces

## Concrete Module Targets

- Add motion integration modules under `lib/ui/motion/` unless an existing runtime module is the clearer home.
- Keep the public-facing integration boundary separated from any library-provided default adapter implementation.
- Retrofit prop handling in existing motion-relevant controls instead of hiding all motion resolution behind one undocumented helper attached to a single control.

## Implementation Guidance

- Reuse `lib/cls` for any adapter, request, or registry objects that need retained runtime identity; do not introduce a second object system.
- Reuse `lib/ui/utils/schema.lua` for validating `motionPreset`, `motion`, target names, descriptor tables, easing inputs, and other stable public fields wherever those props become part of a node's public contract.
- Keep adapter-specific extension fields adapter-owned. The shared validation layer should enforce only the stable descriptor contract from the motion spec.
- Follow the current control integration pattern: motion-aware controls should keep negotiated state in their existing public/effective value paths and raise motion requests from lifecycle/state transitions rather than mutating visual state directly through bespoke timers.
- Do not couple the shared motion boundary to `love.update` in a way that prevents consumer-provided adapters or immediate-apply adapters from participating.
- Any helper that writes surface properties must operate only on documented parts or root visual surfaces and must remain internal unless the spec explicitly names it.

## Required Behavior

- The runtime raises motion opportunities only for documented motion phases.
- Motion requests target only documented stable visual surfaces.
- Motion properties remain visual-only and do not mutate control ownership, focus, or propagation behavior.
- Property-level timing and easing override any broader preset or phase defaults.
- Motion adapters may be library-provided or consumer-provided, but the implementation must not require one specific engine object model.
- Shader-bound motion properties are supported only on documented shader-capable surfaces and only through documented property names.
- Interruption and destruction resolve to the latest authoritative visual state and stop further motion from destroyed surfaces.

## Settled Boundaries

- Do not freeze a built-in timeline catalog, spring schema, or keyframe format as public API in this phase.
- Do not expose implementation-specific scheduler or frame-loop objects as stable surface.
- Keep custom per-step logic within the published `onStep` boundary; do not let it mutate retained-tree structure or control-owned public state.

## Non-Goals

- No public animation-player object.
- No required built-in preset catalog.
- No public timeline or sequencing DSL.

## Acceptance Checks

- Motion descriptors resolve through the shared contract rather than through per-control ad hoc props.
- Easing inputs accept both string identifiers and functions.
- External or consumer-provided motion adapters can be used without violating the spec boundary.
- Shader-bound motion works only through documented shader-capable surfaces and documented properties.
- Motion integration remains aligned with existing `Container` / `Drawable` public-value ownership and does not create a second public state channel.
