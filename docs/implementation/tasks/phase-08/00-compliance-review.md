# Phase 08 Compliance Review

Source under review: `docs/implementation/phase-08-theming.md`

Primary findings, ordered by severity:

1. The phase document freezes public theming surface that the published spec now narrows more precisely.
   Source: `phase-08-theming.md:43-69`, `phase-08-theming.md:133-135`
   Spec anchors: `ui-foundation-spec.md §8.7 Token Classes`, `ui-controls-spec.md §8.1 Stable Control Presentational Parts`, `ui-controls-spec.md §8.2 Control Visual Surfaces`
   Problems:
   - the spec defines 13 token classes, but the phase doc says "all twelve token classes"
   - the `Text` coverage invents body, heading, and caption roles as if they were stabilized part roles, but the controls spec stabilizes only a single `content` part for `Text`
   - the phase doc presents "focus indicator tokens" as if they were their own public token family, but the controls spec now explicitly says focus styling must be expressed through documented parts and their variants
   Required normalization: align all theming work to the published component-part-property surface only, including `Text.content` plus `textVariant`, and keep focus affordances within documented part/property bindings.

2. The phase document implies stable public helper surfaces where the current spec now explicitly declines to do so.
   Source: `phase-08-theming.md:48-55`, `phase-08-theming.md:73-98`
   Spec anchors: `ui-controls-spec.md §4B.3`, `ui-controls-spec.md §6.1`, `ui-controls-spec.md §6.2`, `ui-controls-spec.md §6.6`, `ui-controls-spec.md §6.8`, `ui-controls-spec.md §6.9`
   Problems:
   - the phase draft is written in a way that can be read as freezing authoring helpers around content population and control setup
   - later spec trace notes now explicitly clarify that documented slots, regions, and props do not themselves standardize helper APIs such as `setContent(...)`, `open()`, `close()`, or `addTab(...)`
   Required normalization: keep task wording structural and prop-driven, and treat any builder, registration, or convenience helper as internal unless a control section documents it as public API.

3. The token/default surface is broader in implementation intent than the stable public contract.
   Source: `phase-08-theming.md:57-69`
   Spec anchors: `ui-foundation-spec.md §8.4 Token Model`, `ui-foundation-spec.md §8.16 Missing Or Invalid Skin Inputs`, `ui-controls-spec.md §8.1 Stable Control Presentational Parts`
   Problem: the phase doc describes a "complete library default token table" that covers all controls, parts, and states. That is a valid implementation goal, but the spec only stabilizes token bindings where the part/property is documented and allows fallbacks where defaults exist.
   Required normalization: treat any extra convenience aliases or internal fallback tables as implementation detail, and keep the public contract to the documented token naming and binding surfaces.

Settled clarifications from trace notes that should now be treated as closed:

- `Text` presentation variation is handled through the documented `textVariant` prop and the single `Text.content` part; this closes the earlier ambiguity that encouraged semantic text-role names.
- Focus styling is part-surface styling, not its own token class or token family.
- Documented structure and props do not imply stable imperative builder helpers for controls or slots.
- The uncontrolled-default tables in the controls spec do not by themselves imply `default*` props; Phase 08 theming work must not infer new public initialization props from them.
- The nine-slice helper and canvas-pool helper may exist, but their concrete module APIs remain internal implementation detail.
- The render-effect isolation sequence is spec-consistent only if it preserves the foundation isolation rules and does not expose a new public rendering contract.
