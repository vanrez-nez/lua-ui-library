# UI Evolution Specification

> This document governs how the library manages change over time: what constitutes a breaking change, how versions map to compatibility commitments, how deprecations are communicated, and what the library explicitly does not commit to. Read this alongside the stability tier taxonomy in [UI Foundation Specification §3F](./ui-foundation-spec.md).

## 1. Version and Release History

### Foundation

| Field | Value |
|-------|-------|
| Version | `0.1.0` |
| Revision type | `additive` |
| Finalized | `2026-03-27` |

Changelog:

1. Initial publication of the foundation standard for the UI library.

### Controls

| Field | Value |
|-------|-------|
| Version | `0.1.0` |
| Revision type | `additive` |
| Finalized | `2026-03-27` |

Changelog:

1. Initial publication of the concrete controls standard for the UI library.

### Graphics

| Field | Value |
|-------|-------|
| Version | `0.1.0` |
| Revision type | `additive` |
| Finalized | `2026-04-01` |

Changelog:

1. Initial publication of the graphics-object standard for `Texture`, `Atlas`, `Sprite`, and `Image`.

## 2. Breaking Change Definition

A breaking change is any change to a `Stable` or `Deprecated` surface that requires a consumer to modify usage, assumptions, styling inputs, or tests in order to preserve equivalent documented behavior.

The following rulings are binding:

| Change type | Breaking? | Ruling |
|-------------|-----------|--------|
| removing a stable component | yes | component existence is a stable contract surface |
| renaming a stable component | yes, unless the old name remains as a deprecated alias through the full deprecation window | canonical exported names are stable |
| removing a stable property, parameter, callback, slot, token key, or named visual part | yes | removal changes the documented surface |
| changing the type or accepted domain of a stable property or callback payload field | yes | consumer code must change to remain valid |
| adding a required property to a stable component or making an optional property required | yes | existing call sites become invalid |
| adding an optional property, optional callback, optional token, or optional slot | no | additive surfaces are allowed so long as existing behavior is unchanged |
| changing the documented default value or default resolution rule of an existing optional property | yes | if a consumer must now pass the old value to preserve equivalent behavior, the change is breaking |
| changing the payload schema of a stable event or callback | yes | payload shape is contract surface |
| adding a new optional field to a stable event payload | no | additive payload fields are allowed when existing fields, names, and meanings remain unchanged |
| changing component structure or render-tree decomposition | no, unless it changes documented named parts, slot topology, structural validity, hit or focus regions, event propagation guarantees, or another observable contract surface | internal helper structure is not public API |
| changing internal behavior without changing documented observable behavior | no | implementation changes are allowed |
| changing documented observable behavior while keeping the same signature | yes | behavior is part of the contract |
| removing or changing an experimental surface | no | experimental surfaces carry no compatibility promise |
| changing a deprecated surface before its declared removal version | yes, except for adding deprecation diagnostics that do not alter behavior | deprecated surfaces remain behaviorally stable until removal |
| renaming a documented token key or changing a documented token-to-part binding | yes | the consumer's theming surface changes |
| adding a new stable named visual part | no, unless existing required part names, roles, or required styling inputs change | additive part surfaces are allowed when prior part contracts remain valid |

### Control-Specific Rulings

The general breaking-change rules above apply to all controls. The following control-specific rulings are additionally binding:

| Change type | Breaking? | Ruling |
|-------------|-----------|--------|
| removing or renaming any canonical control defined in the controls specification | yes | control identity is stable |
| removing or renaming a documented control callback such as `onPressedChange`, `onCheckedChange`, `onValueChange`, `onSelectionChange`, or `onOpenChange` | yes | callback names are public API |
| changing the meaning of a documented state value such as `checked`, `open`, or `value` while keeping the same name | yes | state semantics are public contract |
| changing a documented default behavior such as button activation timing, text wrapping defaults, or modal dismissal defaults | yes when the consumer would need to pass an explicit value or rewrite logic to preserve equivalent behavior | default behavior is part of the stable contract |
| adding a new optional prop or optional visual variant to a control | no | additive optional surface is allowed when existing behavior is unchanged |
| removing or renaming a documented slot or required compound region such as `content`, `actions`, `list`, or `panels` | yes | composition grammar is public API |
| changing the role of a stable named visual part such as `backdrop`, `surface`, `trigger`, `panel`, `caret`, or `selection` | yes | part-role mapping is public API |
| adding a new named visual part to a control | no, unless existing part names, required styling inputs, or role boundaries change | additive parts are allowed |
| changing only undocumented internal wrappers, gesture bookkeeping, or helper layers | no | those surfaces are internal |

## 3. Versioning Semantics

This specification uses monolithic semantic versioning for the library as a whole.

Compatibility boundary rules:

- while the library version is in the `0.x.y` range, the `MINOR` field is treated as the breaking-change boundary and `PATCH` remains non-breaking
- starting at `1.0.0`, the `MAJOR` field is the breaking-change boundary in ordinary SemVer terms
- the library does not version components independently in this revision

Release-type guarantees:

| Release type | Guarantee |
|--------------|-----------|
| breaking-boundary release (`0.MINOR.0` before `1.0.0`, `MAJOR.0.0` at and after `1.0.0`) | may include breaking changes to stable surfaces and removals whose deprecation window has completed |
| non-breaking feature release (`0.x.0` where `x` is unchanged, or `MAJOR.MINOR.0` at and after `1.0.0`) | may add stable surfaces, declare deprecations, graduate experimental surfaces, and add optional payload fields or props without breaking existing consumers |
| patch release | may fix bugs, adjust internal or experimental surfaces, and improve performance, but may not break stable documented behavior |

Support window:

- after a new breaking compatibility line is released, the immediately previous compatibility line receives critical fixes for at least six months

## 4. Deprecation Protocol

Every deprecation must declare all of the following at the same time:

- the deprecated surface
- the first version in which it is deprecated
- the earliest removal version
- the replacement surface, or an explicit `no direct replacement` statement

Deprecation communication channels:

- the specification must mark the surface as `Deprecated` in the relevant stability table
- the changelog for the deprecating release must include a deprecation entry with the same removal and replacement information
- the runtime should emit a development-time warning when use of the deprecated surface is detectable; when it is not detectable at runtime, the spec and changelog remain authoritative

Minimum deprecation window:

- at least one subsequent non-breaking feature release must ship after the deprecation release before removal is allowed
- removal may occur only in the next breaking-boundary release after that minimum window has completed

Behavior during deprecation:

- deprecated surfaces must continue to function with the same documented behavior until removal
- the library may add diagnostics, documentation banners, or changelog guidance during the deprecation window, but it must not silently narrow or repurpose the deprecated contract

Removal mechanics:

- removal occurs only in a breaking-boundary release
- the removal release must include a migration guide entry describing the replacement or confirming that no direct replacement exists

## 5. Experimental Gate

No surface in this revision is marked `Experimental`.

If a future revision introduces an experimental surface, all of the following are required:

- the surface must be labeled `Experimental` in the relevant specification table
- the consumer must opt in explicitly through an experimental export path, experimental feature flag, or experimental name marker defined by the component contract
- the surface may ship in the normal package distribution, but it must not appear as an unlabeled stable default entry point
- graduation to `Stable` requires a release that assigns the stable name and tier explicitly in the specification and changelog
- abandonment or removal of the experimental surface requires a changelog note but does not require a deprecation window
- no backward-compatibility guarantee exists within the experimental tier

## 6. Stability Scope

The library makes no stability commitment about any surface not explicitly documented as public API. Any consumer dependency on out-of-scope surfaces is unsupported and may break in any release.

Out-of-scope surfaces include:

- undocumented helper nodes, wrapper layers, render passes, batching layout, and internal draw ordering
- exact callback timing relative to internal dirty-pass scheduling except where the Interaction Model or component contract says otherwise
- exact internal cache structure, invalidation granularity, and scheduling of recomputation passes
- undocumented token keys, undocumented visual parts, undocumented variant names, and undocumented skin-input fallbacks
- undocumented native primitive choices, backend integration choices, and private adapter APIs
- unsupported composition patterns or prop combinations beyond the deterministic failure guarantees stated by the component contract
- performance characteristics not explicitly stated as guarantees
- any consumer reliance on behavior that this specification marks as implementation detail, unsupported, or internal
- undocumented wrapper nodes inside a control's internal render tree
- exact internal ordering of helper decorations within a named visual part
- private gesture-tracking, composition-candidate, focus-restoration, or registration bookkeeping that is not surfaced as documented state
- incidental timing details of internal measurements, text-layout caches, or scroll-cache updates beyond the documented behavior contracts
- consumer reliance on unsupported nesting patterns or prohibited structural combinations
- any future control introduced without being added to a stability table in the controls specification
