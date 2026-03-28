# Phase 09 Task Set

Source implementation document used for this phase: `docs/implementation/phase-09-modal-responsive.md`.

Normalization rules for this phase:

- Treat `docs/spec/ui-foundation-spec.md` and `docs/spec/ui-controls-spec.md` as normative for overlay behavior, modal/alert contracts, focus trapping, and responsive rules.
- Keep overlay orchestration internal unless the spec explicitly stabilizes a public API.
- Do not freeze a concrete responsive-rule schema beyond what the spec says.
- Do not introduce public lifecycle phases or control props that are not named by the spec.

Key corrections applied to the original phase document:

- `Scene` lifecycle must stay within the spec-defined enter/leave phases; no public `"running"` phase is stabilized.
- `Modal` and `Alert` must use the spec-backed prop surface, including `dismissOnBackdrop`, `dismissOnEscape`, `trapFocus`, `restoreFocus`, `safeAreaAware`, `backdropDismissBehavior`, and `initialFocus`.
- Overlay mounting through `Composer` may exist as implementation plumbing, but `showOverlay` and `hideOverlay` should not be treated as stable public API unless separately documented.
- Responsive rules must remain declarative and may depend on viewport, orientation, safe area, and parent dimensions; a viewport-only breakpoint loop is too narrow.
- `Alert` must be modeled as a specialized `Modal` with required title and actions semantics, not as a constructor-centered dialog API.

Unresolved spec gap carried into this phase:

- The foundation and controls specs require responsive rules and overlay support, but they do not stabilize a single concrete overlay registry API or breakpoint-table schema. Phase 09 must therefore preserve those as internal implementation choices unless the specification is revised.

Task order:

1. `00-compliance-review.md`
2. `01-overlay-orchestration-internals.md`
3. `02-modal-control-contract.md`
4. `03-alert-control-contract.md`
5. `04-responsive-rules-finalization.md`
6. `05-demo-and-acceptance.md`
