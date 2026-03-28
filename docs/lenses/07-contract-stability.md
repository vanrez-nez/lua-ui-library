# Lens 07 — Contract Stability

> **Core question:** What is safe to depend on, and to what degree?

---

## Purpose

The Contract Stability lens defines the **library's promises to its consumers across time**. It is not about what the library does today — it is about what the library commits to continue doing, what it may change, and how it communicates change when it happens.

This lens governs the relationship between the library and its consumers as the library evolves. Without it, even a perfectly specified library is unpredictable in production.

---

## Strict Scope

This lens owns:

- The stability tier taxonomy: what levels of stability exist and what each promises
- The assignment of stability tiers to every part of the public API surface
- The definition of a breaking change within this library's model
- The versioning semantics: how versions map to stability commitments
- The deprecation protocol: how the library communicates intent to remove or change something
- The experimental gate: how unfinished API surfaces are marked and what rules govern them
- What is explicitly declared out of scope (and therefore implicitly unstable)

This lens does **not** own:

- What happens when a consumer uses a deprecated or unstable API at runtime → **Failure Semantics**
- The actual migration path for a specific breaking change (that is version-specific release documentation)
- What the API surface contains (that is per-lens documentation)

---

## Required Spec Sections

### 7.1 Stability Tier Taxonomy

Define every stability tier the library uses. Each tier is a **binding promise**, not a recommendation. The spec must define tiers with enough precision that a consumer can determine their risk exposure for any given dependency.

Required tiers (names may vary, definitions must match):

| Tier | Promise |
|------|---------|
| **Stable** | No breaking changes without a major version increment and deprecation period. Covered by the full breaking change policy. |
| **Experimental** | May change or be removed in any release, including patch releases. Consumers opt in explicitly. No deprecation notice guaranteed. |
| **Deprecated** | Stable until the declared removal version. Breaking removal will not occur before that version. Replacement is declared at deprecation time. |
| **Internal** | Not part of the public API. No stability promise. Consumer usage is explicitly unsupported. |

Additional tiers (e.g., "preview", "beta", "legacy") must be defined with the same precision. If two tiers have different promises, they must be different tiers.

### 7.2 API Surface Classification

The stability tier taxonomy is only useful if every part of the public API surface is assigned a tier.

Define the API surface exhaustively. For a UI library, the surface typically includes:

- Component names and their classification (component existence is a contract)
- Component configuration interface (properties, parameters, options, and their types)
- Event names and payload schemas
- Token names
- Composition rules (which combinations are supported)
- Programmatic control interfaces (imperative handles, ref contracts)
- Extension/plugin points
- Utilities and helpers

For each surface element, declare:
- Its assigned stability tier
- The version in which it achieved its current tier
- If deprecated: the version in which it will be removed and the replacement

### 7.3 Breaking Change Definition

Define precisely what constitutes a breaking change in this library. This definition is a contract — the library is committing that only changes meeting this definition will increment the major version.

A breaking change is any change that requires a consumer to modify their usage to maintain equivalent behavior. Be specific. Generic statements ("we follow SemVer") are insufficient.

Examples of breaking change categories that must be explicitly confirmed or denied:

| Change Type | Breaking? | Notes |
|-------------|----------|-------|
| Removing a stable component | Yes | |
| Renaming a stable component | Yes, unless old name is aliased | |
| Removing a stable property/parameter | Yes | |
| Changing the type of a stable property | Yes | |
| Adding a required property to a stable component | Yes | |
| Adding an optional property to a stable component | No | |
| Changing default value of an existing optional property | Declare explicitly | |
| Changing the payload schema of a stable event | Yes | |
| Adding a new field to a stable event payload | Declare explicitly | |
| Changing the DOM/render tree structure of a component | Declare explicitly — depends on structural contract from Visual Contract lens |
| Changing internal behavior without changing observable API | No, unless a behavioral guarantee was documented |
| Removing an experimental API | No | |
| Changing a deprecated API before its declared removal version | No (it is already deprecated) |

The spec must declare each category and its ruling. "Declare explicitly" entries must be resolved.

### 7.4 Versioning Semantics

Define how version numbers map to stability commitments.

The spec must declare:
- The versioning scheme used (SemVer, CalVer, or custom)
- What a major, minor, and patch version each guarantee in terms of this library's breaking change definition
- Whether the library versions as a monolith (one version for all components) or per-component
- If per-component: how consumers determine which component versions are compatible with each other
- The minimum support window for a major version after a subsequent major version is released

### 7.5 Deprecation Protocol

Define the lifecycle of a deprecation, from declaration to removal.

The protocol must specify:

- **Deprecation declaration**: how the library communicates that an API element is deprecated (in the spec, in the changelog, via runtime signals — all three must be addressed)
- **Minimum deprecation window**: the shortest time between deprecation declaration and allowed removal, expressed in either time or version increments
- **Replacement declaration**: whether a replacement must be declared at deprecation time, or whether deprecation without a stated replacement is permitted
- **Behavior during deprecation**: does a deprecated API continue to function identically until removal, or may its behavior change during the deprecation window?
- **Removal mechanics**: does removal occur in a major version, and is it announced in advance in a migration guide?

### 7.6 Experimental Gate

Define the rules that govern experimental API surfaces.

The spec must declare:
- How consumers access experimental APIs (opt-in mechanism, naming convention, or separate package)
- Whether experimental APIs are included in normal distribution or require a separate install
- The criteria for an experimental API to graduate to Stable
- The criteria for an experimental API to be abandoned and removed
- Whether the library makes any commitment to backward compatibility within the experimental tier (e.g., "we will not break experimental APIs more than once per minor version")

### 7.7 Out-of-Scope Declaration

The spec must explicitly declare what the library does not cover and therefore makes no stability commitments about.

This is not a failure mode list (that belongs to Failure Semantics). It is a scope boundary declaration. Examples:

- "The library makes no commitment about the internal render tree structure of composite components beyond what is declared in the Visual Contract."
- "The library makes no commitment about the execution order of consumer-provided callbacks relative to library-internal state updates, beyond what is declared in the Interaction Model."

Out-of-scope declarations are binding in the inverse direction: if something is declared out of scope, the library is permitted to change it without a major version increment.

---

## What a Weak Contract Stability Lens Looks Like

A spec has a weak Contract Stability section if:

- Stability tiers exist in name but are not assigned to specific API surface elements
- The breaking change definition is circular ("a breaking change is something that breaks consumers")
- Deprecation windows are stated as intentions ("we'll give plenty of notice") rather than as commitments
- Experimental APIs can silently graduate to stable without a documented graduation event
- The out-of-scope declaration is absent, meaning consumers cannot know what they must not rely upon

---

## Boundary Assertions

| Question | Belongs Here | Belongs Elsewhere |
|----------|-------------|-------------------|
| Is the `onActivate` event payload schema stable? | ✓ | |
| What does `onActivate` emit? | | Interaction Model |
| What happens if I call a deprecated method? | | Failure Semantics |
| What version will this deprecated method be removed in? | ✓ | |
| Is changing the token name `spacing-md` a breaking change? | ✓ | |
| What does the `spacing-md` token control? | | Visual Contract |
