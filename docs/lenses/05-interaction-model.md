# Lens 05 — Interaction Model

> **Core question:** How does user intent become a state transition trigger?

---

## Purpose

The Interaction Model defines the **library's input abstraction layer and its event contract**. It describes what the library recognizes as input, what it emits in response, and the rules governing the relationship between input and proposed state change. It does not own state itself, and it does not own what happens outside the normal interaction path.

This lens sits between the physical world (raw input) and the State Model (authoritative data). Its job is to define the translation layer.

---

## Strict Scope

This lens owns:

- The input abstraction model: what logical input types the library recognizes, independent of physical device
- The event contract: what the library emits, when, in what order, and with what payload shape
- The relationship between input events and state transition proposals: which inputs propose which state changes
- Cancellation semantics: which events are cancellable and what "cancelled" means
- Focus model: how focus moves, what the library is responsible for managing, and what it exposes

This lens does **not** own:

- The authoritative state and who holds it → **State Model**
- What the component looks like during or after an interaction → **Visual Contract**
- Edge cases in interaction (rapid input, conflicting input, interaction during destruction) → **Behavioral Completeness**
- What happens when an interaction produces an invalid state proposal → **Failure Semantics**

---

## Required Spec Sections

### 5.1 Input Abstraction Model

The library must not define its interaction model in terms of physical input devices. Define input at the **logical level** — abstract intents that map to one or more physical inputs depending on platform.

Define the complete set of logical input types the library recognizes:

| Logical Input | Definition | Physical Mappings (non-exhaustive, platform-specific) |
|--------------|-----------|------------------------------------------------------|
| **Activate** | The primary confirmation intent on a focused element | Click, tap, Enter key, Space key |
| **Navigate** | Intent to move focus or selection within a structured set | Arrow keys, swipe, D-pad |
| **Dismiss** | Intent to cancel or close without committing | Escape key, back gesture, tap-outside |
| **Scroll** | Intent to move the viewport within a scrollable region | Mouse wheel, scroll gesture, scroll key |
| **Drag** | Intent to relocate an element by continuous pointing | Mouse drag, touch drag |
| **Text input** | Intent to supply character data | Keyboard input, voice input, paste |

For each logical input type:
- Define the intent precisely
- Declare whether the library handles physical-to-logical mapping or expects it to be resolved by the platform/runtime before reaching the library
- Declare whether the library suppresses the original physical input after consuming it

### 5.2 Event Contract

Define every event the library emits as part of its public interaction API.

For each event, the spec must declare:

- **Name**: canonical identifier
- **Trigger**: the exact condition that causes this event to fire (a logical input reaching a specific component in a specific state)
- **Payload shape**: every field in the event payload, its type, and its meaning — specified as a schema, not an example
- **Cancellability**: whether the consumer can cancel this event, and what "cancelled" means in terms of state and subsequent events
- **Timing**: when in the interaction sequence this event fires relative to other events
- **Propagation model**: whether this event propagates through the composition tree, and in which direction

The spec must additionally define:

- **Event ordering guarantees**: for interactions that produce multiple events, the guaranteed sequence
- **Event deduplication**: whether the library deduplicates rapid identical inputs, and if so, the deduplication rule
- **Synthetic events**: whether the library ever emits events that were not directly caused by physical input (e.g., programmatic state changes that emit an event as if triggered by input)

### 5.3 Input-to-State-Proposal Mapping

The Interaction Model does not own state — it owns the **proposal** to change state. The State Model governs whether the proposal is accepted.

For each logical input type, define:

- Which state category it proposes to change (reference State Model categories)
- The exact proposed value or transition
- Whether the proposal is direct (the library applies it immediately in uncontrolled mode) or mediated (the library always emits an event and waits for consumer response before applying)

This section must be a complete mapping — if a logical input type has no state implication for a given component, that must be declared explicitly (not omitted).

### 5.4 Focus Model

Focus is a first-class concern of the Interaction Model because it is the library's mechanism for directing subsequent input to the correct component.

The spec must define:

**Focus ownership**:
- What the library is responsible for managing (initial focus on composition mount, focus restoration after a component closes, focus trapping within a modal composition)
- What the consumer is responsible for managing
- What is explicitly outside the library's scope

**Focus movement rules**:
- The complete set of logical inputs that move focus
- The traversal order for each input (linear, hierarchical, wrapping behavior at boundaries)
- Whether focus movement is library-managed or delegated to the platform's native mechanism
- How focus movement interacts with composition boundaries (does focus leave a compound component, or is it trapped?)

**Focus state**:
- Whether focus state is observable by the consumer, and through what mechanism (this is an observation contract, not state ownership — the State Model owns whether focus state is library-owned)
- Whether focus and keyboard-focus are differentiated, and if so, how

### 5.5 Interaction Propagation

When a component is part of a composition, interactions may need to propagate or be absorbed.

Define:
- The default propagation direction for each logical input type (inward from composition root, outward from leaf, or both in sequence)
- The rule for determining which component in a composition is the primary recipient of a given input
- How a component signals that it has consumed an input and propagation should stop
- Whether propagation behavior is overridable by the consumer, and if so, whether doing so is stable API

---

## What a Weak Interaction Model Looks Like

A spec has a weak Interaction Model if:

- Events are documented by example ("fires when the user clicks") rather than by logical trigger
- Payload shape is described informally ("contains info about the event") without a schema
- The input-to-state-proposal mapping is implicit — consumers must infer which state an event is proposing to change
- Focus model responsibility is split across multiple components without a unifying rule
- Propagation behavior is undocumented, so consumers discover it by experimentation

---

## Boundary Assertions

| Question | Belongs Here | Belongs Elsewhere |
|----------|-------------|-------------------|
| What event fires when a user activates a `Button`? | ✓ | |
| What state changes when that event fires? | | State Model |
| What does the `Button` look like while being pressed? | | Visual Contract |
| What happens if the user activates a `Button` 100 times per second? | | Behavioral Completeness |
| What payload does the activation event carry? | ✓ | |
| Who manages focus when a `Dialog` closes? | ✓ | |
| What state does focus represent? | | State Model |
