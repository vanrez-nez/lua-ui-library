# UI Motion Specification

> Version `0.1.0` — initial publication. Release history and change management policy: [UI Evolution Specification](./ui-evolution-spec.md).

## 3. Glossary

All terminology defined in [UI Foundation Specification](./ui-foundation-spec.md) is binding in this document.

`Motion surface`: A documented animatable visual target owned by a component or graphics primitive, such as a named part or the root visual surface.

`Motion phase`: A documented behavioral phase during which a component may request motion, such as `open`, `close`, `enter`, `exit`, `reflow`, or `value`.

`Motion property`: A documented visual property that may be driven over time, such as opacity, translation, scale, rotation, color, or a component-specific visual progress value.

`Shader-bound motion property`: A documented motion property whose resolved output is consumed by a shader attached to the targeted motion surface.

`Motion descriptor`: A declarative description of one motion request for one phase and one or more properties.

`Motion preset`: A named library-recognized shorthand that expands into one or more motion descriptors.

`Motion adapter`: A library integration boundary that receives motion requests and drives motion over time. A motion adapter may be library-provided, consumer-provided, or supplied by an external animation library.

`Easing identifier`: A string name that resolves to a known easing function.

`Easing function`: A function that maps normalized input progress in the inclusive range `[0, 1]` to normalized output progress in the inclusive range `[0, 1]`.

`Frame step callback`: A consumer- or adapter-provided callback that computes per-frame visual output for a documented motion surface without requiring the UI library to own a full animation engine.

## 4. Scope And Domain

This document defines the public motion integration contract for the UI library.

This revision owns:

- motion phases
- motion surfaces
- motion properties
- motion descriptors
- motion presets
- motion adapters
- easing inputs

This revision does not own:

- a required built-in timeline engine
- a required spring or physics engine
- keyframe sequencing APIs
- animation playback objects
- host-runtime-specific frame schedulers beyond the retained update and draw model defined in the foundation specification

The library standardizes how controls and graphics primitives expose motion-capable visual surfaces and how an animation system may drive those surfaces. It does not standardize one animation engine implementation.

## 4A. Motion Responsibility Boundary

The UI library owns:

- when motion opportunities are raised
- which phases are valid for a given component family
- which surfaces and properties are safe to animate
- interruption and destruction semantics
- the integration boundary between retained UI state and an animation driver

The motion adapter owns:

- time progression
- interpolation strategy
- easing evaluation
- sequencing and orchestration
- optional timeline, spring, physics, or keyframe behavior

The consumer owns:

- whether to use no motion, preset motion, or a custom motion adapter
- any external animation library selection
- any custom frame-step callback supplied through the documented motion surface

## 4B. Motion Surface Model

Motion in this revision is attached only to documented visual surfaces.

A motion request may target:

- a component root visual surface when the component contract documents it
- a named presentational part documented by the owning component specification
- a graphics primitive's retained visual surface when the graphics specification documents it

Motion must not target:

- undocumented helper wrappers
- arbitrary descendants chosen by tree traversal
- runtime-utility internals such as `Stage` implementation nodes
- focus ownership or propagation state

The target name of a motion request is stable only when the part or surface is already a documented stable surface.

## 4C. Motion Property Model

This revision standardizes the following shared motion properties:

- `opacity`
- `translationX`
- `translationY`
- `scaleX`
- `scaleY`
- `rotation`
- `color`
- `shaderParameter`

This revision additionally allows a component family to define component-specific motion properties when that property is already part of the component's visual contract. Examples include:

- progress-indicator fill progression for `ProgressBar`
- tab-indicator offset for `Tabs`
- popup placement offset for anchored or overlay surfaces
- shader-bound visual parameters for a documented part that already exposes shader behavior through the visual contract

Motion properties are visual-only in this revision.

`shaderParameter` is a shared motion-property family rather than one exhaustive fixed key set. A motion request may target one or more named shader-bound properties only when all of the following are true:

- the targeted motion surface is already a documented stable visual surface
- that surface already permits shader behavior through the visual contract
- the shader-bound property name is documented by the owning component family, graphics primitive, or adapter contract

This revision does not standardize one universal shader-uniform schema. It standardizes the fact that shader-bound visual parameters may be motion-driven through documented motion properties.

Motion properties must not:

- mutate composition validity
- mutate parent-child ownership
- mutate focus-trap ownership
- mutate event propagation routing
- mutate controlled application state directly

## 4D. Motion Descriptor Contract

A motion descriptor may be supplied through a preset, explicit property declarations, or an external adapter binding.

The stable descriptor fields in this revision are:

- `target`
- `properties`
- `preset`
- `adapter`
- `onStep`

Where:

- `target` names the documented motion surface to animate
- `properties` maps property names to property-driving rules
- `preset` selects a named shorthand recognized by the active motion system
- `adapter` supplies an explicit motion adapter for this descriptor or phase
- `onStep` supplies a per-frame step callback for custom visual output

### 4D.1 Property rule contract

Each property rule may define:

- `from`
- `to`
- `duration`
- `delay`
- `easing`

Property-level timing and easing are authoritative. A phase-level or preset-level default may exist, but a property-level value overrides it.

`easing` may be:

- an easing identifier string
- an easing function
- `nil`

When a property rule omits `duration`, `delay`, or `easing`, resolution falls back to any descriptor-level default recognized by the active motion adapter or preset. If no fallback exists, the adapter may treat the property as an immediate visual step.

For shader-bound motion properties:

- `from` and `to` must resolve to values accepted by the targeted shader-bound property
- interpolation semantics are adapter-defined unless the owning contract documents them more narrowly
- the UI library must not assume that every shader-bound property is scalar; vector-, color-, or adapter-defined value forms are permitted when documented

### 4D.2 `onStep` callback contract

`onStep` is the advanced custom-motion hook in this revision.

The callback receives a read-only context that includes:

- `phase`
- `target`
- `progress`
- `instance`
- `surface`
- `resolvedPlacement` when the owning component exposes placement
- `previousValue` and `nextValue` when the owning phase is value-like
- adapter-specific supplemental fields when documented by that adapter

`onStep` may:

- compute one or more visual property values for the targeted documented surface
- combine multiple animated properties in one step
- defer to external animation state owned by the adapter

`onStep` must not:

- mutate retained-tree structure
- remount or unmount components
- mutate controlled component state directly
- reassign focus
- alter propagation semantics

## 4E. Motion Adapter Contract

A motion adapter is the public integration boundary between the retained UI library and an animation driver.

The adapter must be able to:

- receive a motion request for a documented phase
- start, update, interrupt, and stop motion for a documented target
- write only documented motion properties of the targeted surface
- resolve either preset-driven or explicit property-driven motion
- drive shader-bound motion properties only through documented shader-capable surfaces and documented property names

The adapter may:

- be implemented by the UI library
- be implemented by application code
- be implemented by an external animation library

The adapter contract is behavioral, not one required class shape or constructor signature.

The UI library must not require the adapter to expose one specific timeline object model in this revision.

## 4F. Preset Motion Contract

Motion presets are optional convenience shorthands.

This revision standardizes the concept of a motion preset, not an exhaustive preset catalog.

A preset may expand into:

- one target or multiple targets
- one property or multiple properties
- property-level defaults for duration, delay, and easing

Preset names remain stable only when a future revision or consumer-provided adapter documents them explicitly. The existence of the preset mechanism is stable in this revision; any built-in preset catalog remains optional.

## 4G. Easing Contract

The library recognizes two stable easing input forms:

- easing identifier string
- easing function

When an easing identifier string is used, resolution of that identifier is the responsibility of the active motion adapter or the active preset-expansion layer.

When an easing function is used:

- it must accept one normalized input progress value
- it must return one normalized output progress value

This revision does not standardize one canonical library-owned easing catalog. It standardizes only the accepted input forms and their purpose.

## 4H. Interruption, Authority, And Destruction

Motion always remains subordinate to authoritative retained UI state.

Therefore:

- a motion request may begin only from a documented component phase
- a new authoritative state change may interrupt an in-progress motion request
- destruction of the owning component or motion surface stops further motion from that instance
- motion must resolve to the latest authoritative visual state after interruption

An adapter must not keep driving a destroyed surface after the owning instance leaves retained traversal.

## 4I. Family Adoption Matrix

The following families are directly motion-relevant in this revision:

| Family or object | Motion-relevant phases | Typical targets |
|------------------|------------------------|-----------------|
| `Composer` | `enter`, `exit`, `transition` | outgoing scene surface, incoming scene surface |
| `Modal` | `open`, `close` | `backdrop`, `surface` |
| `Alert` | `open`, `close` | `backdrop`, `surface` |
| `Notification` | `enter`, `exit`, `reflow` | `surface`, `content` |
| `Tooltip` | `open`, `close`, `placement` | `surface`, `content` |
| `Select` | `open`, `close`, `placement` | `popup` |
| `Tabs` | `value` | `indicator`, `panel` |
| `ProgressBar` | `value`, `indeterminate` | `indicator` |
| `Button`, `Checkbox`, `Switch`, `Slider` | `state-change`, `value` | documented indicator or thumb surfaces |
| `Image` | consumer-defined visual motion only | retained image surface |

The following are explicitly not motion owners in this revision:

- `Texture`
- `Atlas`
- `Sprite`

They may participate as render inputs, but they do not own motion playback.

## 5. Stability

Unless this section explicitly says otherwise, the following are `Stable` in `0.1.0`:

- motion phase vocabulary
- motion surface targeting boundary
- shared motion property vocabulary
- support for documented shader-bound motion properties on shader-capable surfaces
- motion descriptor concepts
- per-property timing and easing rules
- motion adapter concept
- acceptance of easing identifiers and easing functions

The following remain internal or adapter-specific:

- exact adapter object shape
- preset catalogs
- timeline objects
- spring parameter schemas
- keyframe schema
- color interpolation math details
- frame-loop storage and scheduler implementation

## 6. Failure Semantics

The following failures must be deterministic:

- targeting an undocumented surface as a motion target
- targeting an undocumented or unsupported motion property
- supplying a negative duration or delay where the active adapter requires finite non-negative timing
- supplying an easing value that is neither a string nor a function when easing is provided

The following are adapter-defined unless a later revision tightens them:

- unknown easing identifier strings
- unknown preset names
- adapter-specific extension fields

If the adapter cannot execute a requested motion, it may fall back to immediate visual application only when that fallback is documented by the adapter. Otherwise the request must fail deterministically.
