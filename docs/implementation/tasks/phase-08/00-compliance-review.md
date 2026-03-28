# Phase 08 Compliance Review

Source under review: `docs/implementation/phase-08-theming.md`

Primary findings, ordered by severity:

1. The phase document misstates the token-class count and then uses unsupported role taxonomy for `Text`.
   Source: `phase-08-theming.md:43`, `phase-08-theming.md:60-62`
   Spec anchors: `ui-foundation-spec.md §8.7 Token Classes`, `ui-controls-spec.md §8.1 Stable Control Presentational Parts`, `ui-controls-spec.md §8.2 Control Visual Surfaces`
   Problems:
   - the spec defines 13 token classes, but the phase doc says "all twelve token classes"
   - the `Text` coverage invents body, heading, and caption roles as if they were stabilized part roles, but the controls spec only stabilizes a single `content` part for `Text`
   Required normalization: align the token-class count to the spec and keep `Text` token bindings limited to the documented `content` surface unless the spec is amended.

2. Focus styling is over-specified as a new theme-token surface.
   Source: `phase-08-theming.md:133-135`
   Spec anchors: `ui-foundation-spec.md §8.2 Visual Property Taxonomy`, `ui-foundation-spec.md §8.4 Token Model`, `ui-controls-spec.md §8.4 Control Structure Versus Appearance Boundary`
   Problem: the phase doc introduces "active theme's focus indicator tokens" as if they were a stabilized token family. The specs require focus indicators as an accessibility-significant visual affordance, but they do not stabilize a distinct focus-ring token taxonomy or naming scheme.
   Required normalization: keep focus styling within documented part/property bindings and avoid freezing a new public token family unless the spec explicitly adds it.

3. The token/default surface is framed too broadly for this revision.
   Source: `phase-08-theming.md:57-69`
   Spec anchors: `ui-foundation-spec.md §8.4 Token Model`, `ui-foundation-spec.md §8.16 Missing Or Invalid Skin Inputs`, `ui-controls-spec.md §8.1 Stable Control Presentational Parts`
   Problem: the phase doc describes a "complete library default token table" that covers all controls, parts, and states. That is a valid implementation goal, but the spec only stabilizes token bindings where the part/property is documented and allows fallbacks where defaults exist.
   Required normalization: treat any extra convenience aliases or internal fallback tables as implementation detail, and keep the public contract to the documented token naming and binding surfaces.

Secondary scoping notes:

- The nine-slice helper and canvas-pool helper may exist, but their concrete module APIs are internal implementation detail.
- The render-effect isolation sequence is spec-consistent only if it preserves the isolation rules from the foundation spec and does not expose a new public rendering contract.
