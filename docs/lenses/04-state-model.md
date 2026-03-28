# Lens 04 — State Model

> **Core question:** What state exists, who owns it, and what does the library guarantee about its consistency?

---

## Purpose

The State Model defines the **categories of state a component can hold, who is authoritative for each category, and what consistency guarantees the library makes across a composition**. It is concerned with state as a structural concept — not with what triggers state changes (that is the Interaction Model) and not with how state is visually expressed (that is the Visual Contract).

This lens is where the library declares its ownership boundaries at the data level. Ambiguity here cascades into every other behavioral lens.

---

## Strict Scope

This lens owns:

- The taxonomy of state categories and their definitions
- The ownership model for each category: library-owned, consumer-owned, or shared
- The controlled/uncontrolled duality and the rules governing each
- State flow direction within a composition: how state propagates, how it is inherited, how it is isolated
- Consistency guarantees: what the library promises about state coherence across a tree of components
- Derived state: what the library computes from authoritative state, and whether derived values are part of the public contract

This lens does **not** own:

- What input events trigger a state transition → **Interaction Model**
- How a state is visually represented → **Visual Contract**
- What happens when a consumer puts state into an invalid value → **Failure Semantics**
- What happens in edge-case scenarios like rapid transitions or destruction mid-update → **Behavioral Completeness**

---

## Required Spec Sections

### 4.1 State Category Taxonomy

Define every category of state that can exist within the library's component model. The taxonomy must be exhaustive and mutually exclusive — every piece of state must belong to exactly one category.

Minimum categories to define:

| Category | Definition |
|----------|-----------|
| **Interaction state** | Transient state driven by user input that the library manages (e.g., pressed, hovered, focused, dragging) |
| **UI state** | State that determines the structural or visual condition of the component independent of application data (e.g., open/closed, expanded/collapsed, selected, loading) |
| **Application state** | State that represents domain data meaningful to the application, not the UI (e.g., the value in an input, the selected item in a list) |
| **Composition state** | State shared across a composition tree to coordinate behavior between related components (e.g., which item in a group is active) |

For each category, declare:
- Whether the library can be the authoritative owner
- Whether the consumer can be the authoritative owner
- Whether ownership can be transferred between library and consumer per instance

### 4.2 Ownership Model

For each state category, define ownership precisely:

**Library-owned state**: The library is the sole authoritative source. The consumer may read this state through the defined observation mechanism, but cannot set it directly.

**Consumer-owned state**: The consumer is the sole authoritative source. The library reads this state and responds to it, but does not modify it.

**Negotiated state (controlled/uncontrolled)**: Ownership is determined at instantiation time. Once established, ownership cannot transfer for the lifetime of that component instance.

For negotiated state, the spec must define:

- How the consumer signals which ownership mode is active
- What the default mode is when neither signal is given
- Whether switching ownership mode during a component's lifetime is valid, and if not, what the declared behavior is (see also **Failure Semantics**)

### 4.3 Controlled vs. Uncontrolled Model

This section governs all state that is subject to ownership negotiation.

**Controlled mode**:
- The consumer provides the authoritative value and a mechanism to receive proposed changes
- The library never modifies the state directly; it proposes changes by invoking the consumer-provided mechanism
- If the consumer does not apply the proposed change, the component must reflect the consumer's value, not the proposed value
- The spec must declare what the component does during the window between proposing a change and receiving an updated value from the consumer

**Uncontrolled mode**:
- The library is the authoritative source
- The library must declare the initial value contract (is an initial value required, optional, or prohibited)
- The library must declare whether the consumer can read the current value, and through what mechanism
- The library must declare whether the consumer can imperatively reset or set state in uncontrolled mode, and if so, whether doing so is considered stable API

**Hybrid restriction**:
The spec must declare whether a component can mix controlled and uncontrolled state for different state properties simultaneously, and if so, what the rules are.

### 4.4 State Flow Within Composition

Define how state moves through a composition tree:

- **Downward flow**: which state categories a parent is permitted to push to children
- **Upward notification**: how children notify parents of state changes (the mechanism, not the event semantics — that belongs to the Interaction Model)
- **Sibling coordination**: whether sibling components can share state, and if so, through what intermediary
- **Composition state isolation**: whether state shared across a composition is scoped to the nearest composition root, or whether it can span multiple composition boundaries

The spec must declare whether the library uses **implicit state sharing** (components within a composition automatically share state by proximity) or **explicit state sharing** (consumer must declare state sharing relationships).

### 4.5 Consistency Guarantees

Define what the library guarantees about state coherence:

- **Single-update atomicity**: if a single action causes multiple state properties to change, does the library guarantee all changes are reflected before any consumer observation occurs?
- **Composition coherence**: when composition state is shared across multiple components, does the library guarantee all components reflect the new state simultaneously?
- **Re-entrancy**: if a state change triggers a consumer callback that triggers another state change, what is the defined behavior?
- **Ordering**: if multiple state changes are queued, does the library guarantee the order they are applied?

The spec must make these as binary commitments: either the library guarantees it (and it is testable) or it does not (and it explicitly disclaims it).

### 4.6 Derived State

Define any state the library computes from authoritative state and exposes to consumers:

- What derived values exist per component
- The derivation rule (how the value is computed from authoritative state)
- Whether the derivation is guaranteed to be synchronous with the authoritative state or may lag
- Whether derived values are part of the stable API or considered implementation details

---

## What a Weak State Model Looks Like

A spec has a weak State Model if:

- State categories overlap (interaction state and UI state are not distinguished)
- The controlled/uncontrolled model is described per-component inconsistently rather than as a library-wide rule
- Consistency guarantees are aspirational ("we try to update all components together") rather than contractual
- Composition state is described under event handling or visual theming rather than as its own structural concern
- Derived state is undocumented, causing consumers to re-derive it and produce inconsistent results

---

## Boundary Assertions

| Question | Belongs Here | Belongs Elsewhere |
|----------|-------------|-------------------|
| Does `Dialog` own its open/closed state or does the consumer? | ✓ | |
| What triggers `Dialog` to open? | | Interaction Model |
| How is the open state visually represented? | | Visual Contract |
| What happens if the consumer passes an invalid state value? | | Failure Semantics |
| Can two `RadioButton`s in the same group share state automatically? | ✓ (composition state model) | |
| What event fires when `RadioButton` selection changes? | | Interaction Model |
