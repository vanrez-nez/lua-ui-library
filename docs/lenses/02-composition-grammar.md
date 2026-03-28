# Lens 02 — Composition Grammar

> **Core question:** How do units legally relate to each other?

---

## Purpose

The Composition Grammar defines the **rules governing how components combine**. It is the library's grammar in the linguistic sense: the set of valid sentences (compositions) that can be formed from its vocabulary (components).

This lens operates entirely at the structural level. It does not care what state flows through a composition, what the composition looks like, or what happens when interaction occurs. It defines only what is structurally valid, how structural relationships are expressed, and how components within a composition communicate in terms of structure.

---

## Strict Scope

This lens owns:

- The rules that define valid and invalid component combinations
- The structural relationship types available in this library (parent/child, sibling, slot, context provider/consumer, etc.)
- How a parent delegates structural responsibility to a child
- How components within a composition communicate at the structural level (not state-level)
- The hierarchy depth model: whether the library imposes or recommends nesting limits
- Compound component patterns: the structural contract between a component and its named sub-parts

This lens does **not** own:

- What a component is or how it is classified → **Component Model**
- What state flows between composed components → **State Model**
- What visual properties are inherited or overridden through composition → **Visual Contract**
- What happens when an invalid composition is submitted at runtime → **Failure Semantics**

---

## Required Spec Sections

### 2.1 Relationship Types

Define every structural relationship type the library supports. For each type, specify:

- **Name**: the canonical term for this relationship in the spec
- **Direction**: unidirectional, bidirectional, or broadcast
- **Cardinality**: one-to-one, one-to-many, many-to-one
- **Initiator**: which side declares the relationship
- **Mechanism**: how the relationship is expressed (nesting, explicit reference, context, registration)

Minimum relationship types to define:

| Type | Definition |
|------|-----------|
| Containment | A component structurally encloses another; the parent owns the child's mounting |
| Slotting | A component designates named regions that consumers fill with arbitrary structure |
| Delegation | A component passes its structural responsibility entirely to a child for a defined sub-region |
| Context provision | A component makes structural data available to any descendant that requests it, without explicit passing |

### 2.2 Composition Validity Rules

The spec must define validity as a formal set of rules, not as a list of examples.

For each component (or component tier), declare:

- **Allowed children**: by name, by tier, by trait, or unrestricted
- **Prohibited children**: explicit exclusions and the reason (semantic, behavioral, or structural)
- **Required children**: compositions that are incomplete without a specific child type
- **Allowed parents**: the valid structural containers for this component
- **Standalone validity**: whether the component is valid with no parent and no children

Validity rules must be:
- **Decidable**: given a composition tree, it must be possible to determine validity without running the composition
- **Compositionally closed**: if A is valid inside B, and B is valid inside C, the spec must declare whether A inside C (transitively) is valid or requires re-evaluation

### 2.3 Compound Component Contract

A compound component is a component that exposes named sub-parts as part of its public API (e.g., `Menu` + `Menu.Item` + `Menu.Separator`).

For each compound component, the spec must declare:

- The canonical set of sub-parts and their individual responsibility boundaries
- Which sub-parts are **required** vs. **optional** for a valid composition
- Whether sub-parts carry meaning independently or only within their parent compound
- The **communication mechanism** between the compound root and its sub-parts (how the root and sub-parts share structural information without relying on state — structural registration, slot resolution, etc.)
- Whether the sub-part set is closed (consumer cannot add new sub-parts) or open (consumer-defined sub-parts are valid)

### 2.4 Slot Model

If the library supports slotting (regions a consumer fills with structure), define:

- **Slot declaration**: how a component declares it has a slot and what its name is
- **Slot filling**: how a consumer targets a named slot
- **Default slot content**: whether components can declare fallback structure for unfilled slots
- **Slot constraints**: whether slots restrict the type or tier of components that may fill them
- **Slot multiplicity**: whether a slot may be filled by multiple components, and if so, how ordering is determined
- **Unnamed slot**: whether an implicit/default slot exists and how it is distinguished from named slots

### 2.5 Structural Communication

Components within a composition sometimes need to exchange information to produce correct structure (e.g., a list that must know how many children it has to render connectors correctly).

This lens owns only **structural communication** — information exchanged to determine correct structure, not to drive state transitions.

The spec must define:

- What categories of structural information components are permitted to exchange
- The direction of structural communication (downward-only, upward registration, or peer-to-peer)
- Whether structural communication is implicit (automatic by position or type) or explicit (consumer-declared)
- Whether structural communication crosses composition boundaries (i.e., can a grandchild communicate structurally with a grandparent without going through intermediaries)

### 2.6 Composition Depth Model

Declare the library's position on nesting depth:

- Is there a maximum structural depth? If so, is it enforced or advisory?
- Do guarantees about behavior, performance, or correctness degrade at depth? If so, at what threshold and in what way?
- Are there components that reset depth semantics (e.g., a portal that re-establishes the root of a composition)?

---

## What a Weak Composition Grammar Looks Like

A spec has a weak Composition Grammar if:

- Validity is defined entirely by example ("you can use `MenuItem` inside `Menu`") without a generative rule
- Compound component sub-parts have no independent responsibility boundary — their spec is entirely "deferred to the parent"
- Slot constraints are undefined, so consumers discover limits by trial and error
- Structural communication is described under state management or event handling, conflating structure with behavior

---

## Boundary Assertions

| Question | Belongs Here | Belongs Elsewhere |
|----------|-------------|-------------------|
| Can a `MenuItem` be used outside a `Menu`? | ✓ | |
| How many `MenuItem`s can a `Menu` contain? | ✓ | |
| What state does `Menu` share with `MenuItem`? | | State Model |
| What does a `MenuItem` look like? | | Visual Contract |
| What happens if a `MenuItem` is placed inside a `Dialog`? | ✓ (validity rule) and | Failure Semantics (runtime response) |
| How does `Menu` know which `MenuItem` is selected? | | State Model |
