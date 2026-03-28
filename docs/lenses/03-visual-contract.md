# Lens 03 — Visual Contract

> **Core question:** What does the library own visually, and what does it surrender to the consumer?

---

## Purpose

The Visual Contract defines the **boundary between what the library controls visually and what the consumer controls**. It does not describe how components look in any specific implementation — it describes the *surface* through which appearance is determined and the *rules* that govern what can and cannot be changed.

This lens is deliberately separated from the Component Model (which defines identity) and the State Model (which defines what visual states exist). The Visual Contract defines only the mechanism and limits of visual customization.

---

## Strict Scope

This lens owns:

- The definition of the library's visual ownership boundary
- The taxonomy of visual properties and which are library-owned, consumer-owned, or shared
- The customization mechanism: how the consumer overrides or extends visual properties
- The structural/appearance distinction: what is considered stable structure vs. presentational detail
- The token model: how design-level variables bind to components
- Visual inheritance rules within a composition: what propagates, what is isolated

This lens does **not** own:

- What states a component can be in → **State Model**
- How those states are triggered → **Interaction Model**
- What a component looks like in any specific implementation (that is design documentation, not spec)
- Layout or positioning decisions that are structural rather than visual → **Component Model**, **Composition Grammar**
- What happens when a consumer overrides a property that isn't on the customization surface → **Failure Semantics**

---

## Required Spec Sections

### 3.1 Visual Ownership Model

Declare the library's position on visual ownership. Every library must take an explicit stance on the following axis:

```
Opinionated ◄──────────────────────────────► Headless
Library owns all appearance        Library owns only structure;
                                   consumer owns all appearance
```

This is not a binary — the library must declare its position and the rationale. A library at the opinionated end has a smaller customization surface but stronger visual consistency guarantees. A library at the headless end delegates visual responsibility almost entirely.

The spec must declare:
- Where on this axis the library sits
- Whether the position is uniform across all components or varies by component tier
- What motivated this position (i.e., what would break if a component moved toward the other extreme)

### 3.2 Visual Property Taxonomy

Classify every category of visual property into one of three ownership categories:

| Category | Definition | Examples |
|----------|-----------|---------|
| **Library-owned** | Set by the library; consumer cannot override | Internal layout of a compound component's structure |
| **Consumer-owned** | Not set by the library; consumer is fully responsible | Color scheme, typography, brand identity |
| **Shared (overridable)** | Set by the library as a default; consumer may override through the defined customization surface | Spacing, corner radius, motion duration |

For each overridable property, the spec must declare:
- The default source (hardcoded, token-resolved, or inherited)
- The override mechanism (see §3.3)
- Whether overriding this property is considered stable API

### 3.3 Customization Mechanism

Define exactly how a consumer modifies visual properties. The spec must name the mechanism and describe its rules precisely. Common mechanisms include:

- **Token substitution**: consumer replaces named design variables at the library level, affecting all components that reference them
- **Property override at component level**: consumer passes a visual property directly to a component instance
- **Style injection**: consumer provides a block of style declarations that are applied to a defined target within the component
- **Variant selection**: consumer selects from a library-defined set of pre-built appearances
- **Unstyled/headless mode**: consumer opts a component (or the entire library) into a mode where library-owned defaults are stripped

For each mechanism, the spec must declare:
- Its scope (library-wide, component-wide, or instance-level)
- Its precedence relative to other mechanisms if multiple apply simultaneously
- Whether it is considered a stable part of the public API

### 3.4 Token Model

If the library uses a token system (named variables that represent design decisions), define:

- **Token categories**: what types of decisions are represented as tokens (spacing scale, color roles, motion curves, etc.)
- **Token naming convention**: the schema for token names, and whether names are part of the stable API
- **Token resolution order**: if a token can be overridden at multiple levels (library default → theme → component → instance), define the resolution chain
- **Required vs. optional tokens**: which tokens must be defined by the consumer for the library to function correctly, and which have library-provided fallbacks
- **Token-to-component binding**: how the library connects tokens to specific components or properties (implicit by name convention, or explicit mapping)

The token model must not describe specific token values — that is design documentation. It describes only the structure and rules of the token system.

### 3.5 Structure vs. Appearance Boundary

The library must declare what it considers "structure" (stable, part of component identity) vs. "appearance" (presentational, overridable).

Structure is what the component *is*. Appearance is how it *presents*.

This distinction matters for versioning (structural changes are breaking; appearance changes may not be) and for consumer expectations (consumers may rely on structure but should not rely on appearance).

The spec must:
- Define the criteria that classify something as structure vs. appearance
- List, per component or component tier, what is classified as structure
- Declare whether internal visual structure (e.g., the DOM hierarchy or render tree of a composite component) is part of the structural contract or considered an implementation detail

### 3.6 Visual Inheritance Within Composition

Define how visual properties propagate through a composition:

- Which properties cascade from parent to child
- Which properties are isolated per component instance regardless of parent
- Whether a consumer can interrupt cascading at a specific node, and through what mechanism
- Whether the library guarantees visual isolation for components rendered outside the normal composition tree (e.g., portals, overlays, detached trees)

---

## What a Weak Visual Contract Looks Like

A spec has a weak Visual Contract if:

- The customization surface is defined by describing what the library currently renders, rather than what it guarantees is overridable
- Tokens are listed as values rather than as a structural system
- The structure/appearance boundary is undefined, causing consumers to accidentally depend on internal visual structure that changes between versions
- Visual inheritance is undocumented, causing consumers to be surprised when styles propagate or fail to propagate

---

## Boundary Assertions

| Question | Belongs Here | Belongs Elsewhere |
|----------|-------------|-------------------|
| Can the consumer change the color of a button? | ✓ (mechanism and category) | |
| What is the default button color? | No (design documentation) | |
| What states does a button have visually (hover, pressed)? | No (state existence) | State Model |
| How does hover state become active? | | Interaction Model |
| What token controls button border radius? | ✓ | |
| What is the value of the border radius token? | No (design documentation) | |
| What happens if the consumer overrides a library-owned property? | | Failure Semantics |
