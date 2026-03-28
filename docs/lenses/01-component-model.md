# Lens 01 — Component Model

> **Core question:** What is the unit of this library?

---

## Purpose

The Component Model defines the **identity and classification of a component** as an abstract artifact — before any composition, behavior, or appearance is considered. It answers what a component *is*, not what it does or how it looks.

This lens is the foundation all other lenses reference. If it is vague, every other lens inherits that ambiguity.

---

## Strict Scope

This lens owns:

- The definition of "component" within this library's model
- The classification taxonomy (primitive, composite, layout, utility, etc.)
- The component's declared responsibility boundary — what it is accountable for
- The component's identity contract: what makes it a stable, nameable unit
- The retained vs. immediate rendering model declaration (library-wide)
- The lifecycle model: what phases a component goes through (creation, update, destruction) and what the library guarantees at each phase

This lens does **not** own:

- How components nest or combine → **Composition Grammar**
- What state a component holds or delegates → **State Model**
- What the component looks like or what is styleable → **Visual Contract**
- What happens when a component receives invalid usage → **Failure Semantics**

---

## Required Spec Sections

### 1.1 Definition of a Component

State explicitly and without ambiguity:

- What constitutes a component in this library (not a framework-specific answer — a model-level answer)
- What a component is *not* (helpers, utilities, layout primitives, icons — classify or exclude)
- Whether a component is the minimal unit of composition, or if sub-component parts are also first-class

### 1.2 Classification Taxonomy

Define every tier in the component hierarchy and the precise criteria that places a component in a tier.

| Tier | Definition | Criteria |
|------|-----------|----------|
| Primitive | Cannot be decomposed into smaller library components | — |
| Composite | Built entirely from primitives or other composites within this library | — |
| Layout | Exists solely to arrange other components; has no semantic meaning of its own | — |
| Utility | Has no visual output; provides behavior or context only | — |

Every classification must include:
- A positive definition (what qualifies)
- A negative definition (what disqualifies)
- At least one canonical example per tier

### 1.3 Component Responsibility Boundary

For each component, the spec must declare:

- What the component is **solely responsible for**
- What it explicitly **does not manage** (even if it seems naturally related)
- Whether its responsibility boundary is fixed or extensible by the consumer

A component's responsibility boundary is distinct from its API surface. The boundary defines scope of correctness — what the library guarantees is consistent and intentional.

### 1.4 Identity Contract

Define what makes a component a stable unit across versions:

- Its canonical name and whether aliases are part of the contract
- Whether its internal structure (sub-parts, slots) is part of its identity or an implementation detail
- How identity relates to classification — can a component change tiers across versions without being treated as a breaking change?

### 1.5 Rendering Model Declaration

Declare at library level whether the model is:

- **Retained mode**: components persist between renders; the library manages a component tree
- **Immediate mode**: components are re-described each frame; no persistent identity between frames
- **Hybrid**: if so, which components belong to which model and why

This is declared once at the library level. If individual components deviate from the library norm, each deviation must be documented here as a named exception with a justification.

### 1.6 Lifecycle Model

Define the phases every component passes through:

- **Creation**: what the library guarantees is initialized and in what order
- **Update**: what triggers a component to re-evaluate its output, and what the library guarantees about consistency during an update
- **Destruction**: what the library guarantees is cleaned up, and what the consumer is responsible for releasing

The lifecycle model must specify:
- Whether lifecycle phases are observable by the consumer, and through what mechanism
- Whether lifecycle guarantees differ between primitive and composite components
- What "fully initialized" and "fully destroyed" mean in concrete terms

---

## What a Weak Component Model Looks Like

A spec has a weak Component Model if:

- "Component" is defined by example rather than by rule
- Classification tiers exist but overlap (a composite that is also a primitive in some contexts)
- The lifecycle section is aspirational ("the library tries to clean up resources") rather than contractual
- Responsibility boundaries are defined by what the component *currently does* rather than what it is *designed to do*

---

## Boundary Assertions

| Question | Belongs Here | Belongs Elsewhere |
|----------|-------------|-------------------|
| Is a `Tooltip` a primitive or composite? | ✓ | |
| What props does a `Tooltip` accept? | | Visual Contract, State Model |
| Can a `Tooltip` contain a `Dialog`? | | Composition Grammar |
| What state does a `Tooltip` own? | | State Model |
| What happens if a `Tooltip` receives null content? | | Failure Semantics |
