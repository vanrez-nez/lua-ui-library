# Phase 16 Task Set

Source implementation document for this phase:

- `docs/implementation/phase-16-quad-normalization.md`

Related incident / spec-patch context:

- `docs/incidents/spec_patch_quad_normalization_model.md`

Authority rules for this phase:

- `docs/spec/ui-foundation-spec.md` §3B is authoritative for `SideQuad input`, `CornerQuad input`, and the aggregate-plus-flat override rule.
- `docs/spec/ui-foundation-spec.md` `Drawable`, layout-family common props, and `Stage` are authoritative for which Foundation surfaces use `SideQuad input`.
- `docs/spec/ui-styling-spec.md` §5 is authoritative for styling value-form categories and failure semantics.
- `docs/spec/ui-styling-spec.md` §7 is authoritative for `borderWidth` and the per-side canonical resolved form.
- `docs/spec/ui-styling-spec.md` §8 is authoritative for `cornerRadius` and the per-corner canonical resolved form.
- `docs/spec/ui-styling-spec.md` §12 is authoritative for motion-capable styling keys.
- `docs/spec/ui-styling-spec.md` §13 is authoritative for deterministic failure behavior.

Settled decisions that control this task set:

- The reusable normalization model is now spec-owned. Implementation must follow the Foundation-defined quad families instead of continuing to normalize each property family ad hoc.
- `SideQuad input` is the shared model for `padding`, `margin`, `safeAreaInsets`, and `borderWidth`.
- `CornerQuad input` is the shared model for `cornerRadius`.
- Aggregate props establish the family fallback. Flat member props override their own side or corner. Canonical resolved form remains expanded member-by-member.
- `Insets` remains a valid implementation artifact for spacing and safe-area semantics, but it is no longer the only place where four-side normalization logic is allowed to exist.
- The renderer must consume canonical expanded values only. It should not need to reason about multiple public authoring forms.
- This phase is allowed to supersede earlier planning docs that assumed "no shorthand aliases" for styling, because the spec has now changed.

Implementation conventions for every task in this phase:

- Prefer one shared helper per quad family over repeated local normalization code.
- Keep Foundation normalization separate from property-family semantics. The helper owns shape parsing; the schema owns domain checks such as non-negative-only.
- Preserve deterministic hard failures for malformed quad shapes and invalid member values.
- Update stale planning docs only after the current implementation/documentation source of truth is in place.

Task order:

1. `00-compliance-review.md`
2. `01-shared-quad-helpers-and-foundation-surfaces.md`
3. `02-styling-schema-and-resolution.md`
4. `03-acceptance-and-doc-sync.md`
