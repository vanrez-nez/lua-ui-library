# Lens 06 — Behavioral Completeness

> **Core question:** What edge cases and boundary conditions is the library responsible for?

---

## Purpose

The Behavioral Completeness lens defines the **library's declared responsibility at the edges of normal operation**. It is not about the happy path — that is covered by the State Model and Interaction Model. This lens is specifically about what happens when the system is at a boundary: constrained resources, empty data, conflicting inputs, truncated space, or transitions that begin but cannot complete normally.

This lens is the difference between a library that works in demos and a library that works in production.

---

## Strict Scope

This lens owns:

- Empty and null state behavior: what components render when they have no content or data
- Overflow and constraint behavior: what components do when they cannot fit their content in the available space
- Concurrent and rapid input behavior: what the library guarantees when inputs arrive faster than state can settle
- Transition interruption: what happens when an animation or multi-step interaction is interrupted before completion
- Resource exhaustion behavior: what the library guarantees under memory or rendering pressure
- Destruction during activity: what happens when a component is removed while an interaction or transition is in progress

This lens does **not** own:

- What happens during normal-path interactions → **Interaction Model**
- What happens when state is driven to invalid values by the consumer → **Failure Semantics**
- What the component looks like in these edge states → **Visual Contract**
- Whether the library guarantees these edge cases will be defined for future components → **Contract Stability**

---

## Required Spec Sections

### 6.1 Empty and Null State Contract

For every component that renders content driven by input (lists, tables, inputs, content containers), define:

- **No content case**: what the component renders when its content set is empty (zero items, empty string, null/undefined value)
- **Library responsibility**: does the library provide a default empty state, or does it render nothing and delegate to the consumer?
- **Partial content case**: if content is partially available (e.g., a list with some items loading), what does the component render for the unavailable portion?

The spec must declare for each component:
- Whether the empty state is structurally part of the component or injected by the consumer
- Whether the empty state triggers any events (e.g., an `onEmpty` notification)
- Whether transitioning into and out of empty state is a defined state transition with observable events

### 6.2 Overflow and Constraint Behavior

Define what the library does when a component cannot fit its content within its spatial constraints.

Declare, per component or component tier:

- **Overflow model**: truncate, clip, scroll, wrap, or overflow — which is the default, which are options, which are prohibited
- **Overflow notification**: does the library emit an event or provide an observable flag when overflow occurs?
- **Minimum size contract**: what is the minimum space the library guarantees a component remains functional in? Below this threshold, what is the declared behavior?
- **Dynamic constraint changes**: if the available space changes after the component is mounted, what does the library do? (re-layout, re-measure, clip, nothing)

The overflow behavior declaration must be specific enough that a consumer can predict the output without rendering.

### 6.3 Concurrent and Rapid Input Behavior

Define what the library guarantees when inputs arrive at a rate higher than state can settle.

For each logical input type (reference Interaction Model), declare:

- **Queueing policy**: does the library queue inputs, coalesce them, drop all but the last, or process each independently?
- **State consistency during rapid input**: is the library guaranteed to reflect a consistent state at all times, or may it produce intermediate states the consumer never explicitly requested?
- **Throttle/debounce ownership**: if the library applies any input rate limiting, the rules must be declared explicitly. If the library does not, the spec must explicitly disclaim it and declare the consumer's responsibility.
- **Concurrent interaction from multiple sources**: if the library supports multiple simultaneous input sources (e.g., touch + keyboard simultaneously), define the arbitration rule

### 6.4 Transition Interruption

For components with transitions (animated state changes, multi-step interactions), define:

- **Interruption definition**: what constitutes an interruption (a new input arriving, a state change from the consumer, component destruction)
- **Mid-transition state**: what state does the library expose during a transition? Is intermediate state observable?
- **Interruption outcome**: when a transition is interrupted, does it: snap to the final state, snap to the initial state, reverse, or complete before processing the interruption?
- **Interruption event**: does the library emit an event when a transition is interrupted? With what payload?
- **Nested interruptions**: if an interruption itself is interrupted, define the resolution rule

### 6.5 Destruction During Activity

Define what the library guarantees when a component is destroyed (removed from the composition) while activity is in progress.

Activity types to define explicitly:

- **Pending state transition**: a state change was proposed but not yet resolved
- **In-progress transition/animation**: a visual transition has started but not completed
- **Active interaction**: a user input sequence is in progress (e.g., mid-drag, mid-text-input)
- **Pending async operation**: the component is waiting for an asynchronous result before completing a state change

For each activity type, the spec must declare:
- Whether the activity is completed, cancelled, or abandoned
- What cleanup the library is responsible for (releasing resources, restoring focus, emitting cancellation events)
- What the consumer is responsible for cleaning up

### 6.6 Loading and Async State

If any component in the library supports asynchronous content loading, define:

- The **loading state contract**: what the component renders and what state it is in during a pending async operation
- **Load success transition**: how the component transitions from loading to populated state, and whether this is a defined event
- **Load failure contract**: what the component renders if the async operation fails — this is a behavioral contract, not a visual one
- **Retry semantics**: whether the library provides retry capability and what its rules are
- **Cancellation**: if the component is destroyed or the consumer navigates away during a load, what does the library guarantee about cancellation of the pending operation?

---

## What a Weak Behavioral Completeness Lens Looks Like

A spec has a weak Behavioral Completeness section if:

- Edge cases are described only in a "tips and tricks" section rather than as formal contracts
- Overflow behavior is described as "handled by the platform" without specifying what the library does before deferring
- Rapid input behavior is undocumented, leaving consumers to discover coalescing or queueing behavior empirically
- Destruction during activity is not addressed, leading to resource leaks or unexpected events firing on unmounted components
- Empty states are implicitly "nothing" rather than explicitly declared, making the consumer uncertain whether empty content is an error or a valid state

---

## Boundary Assertions

| Question | Belongs Here | Belongs Elsewhere |
|----------|-------------|-------------------|
| What does a `List` render when it has zero items? | ✓ | |
| What does the `List` look like when empty? | | Visual Contract |
| What happens if the consumer gives `List` a null value instead of an empty array? | | Failure Semantics |
| What does `Dialog` do if it is closed while its open animation is 50% complete? | ✓ | |
| What does the animation look like? | | Visual Contract |
| What event fires when an animation is interrupted? | ✓ | |
| What triggers the `Dialog` to close? | | Interaction Model |
| Who owns `Dialog`'s open/closed state? | | State Model |
