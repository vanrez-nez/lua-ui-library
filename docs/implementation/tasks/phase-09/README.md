# Phase 09 Task Set

Source implementation document used for this phase: `docs/implementation/phase-09-modal-responsive.md`.

Authority rules for this phase:

- Treat `docs/spec/ui-foundation-spec.md` and `docs/spec/ui-controls-spec.md` as authoritative for overlay behavior, modal/alert contracts, focus trapping, and responsive rules.
- Use `docs/implementation/phase-09-modal-responsive.md` only as historical implementation intent and task-sequencing context.
- Keep overlay orchestration internal unless the spec explicitly stabilizes a public API.
- Do not freeze a concrete responsive-rule schema beyond what the spec says.
- Do not introduce public lifecycle phases or control props that are not named by the spec.

Settled spec clarifications that control this task set:

- `Scene` lifecycle must stay within the spec-defined enter/leave phases; no public `"running"` phase is stabilized.
- `Modal` and `Alert` must use the spec-backed prop surface, including `dismissOnBackdrop`, `dismissOnEscape`, `trapFocus`, `restoreFocus`, `safeAreaAware`, `backdropDismissBehavior`, and `initialFocus`.
- Overlay mounting through `Composer` may exist as implementation plumbing, but `showOverlay` and `hideOverlay` should not be treated as stable public API unless separately documented.
- Responsive rules must remain declarative and may depend on viewport, orientation, safe area, and parent dimensions; a viewport-only breakpoint loop is too narrow.
- `Alert` must be modeled as a specialized `Modal` with required title and actions semantics, not as a constructor-centered dialog API.
- Overlay orchestration helpers, stacking registries, and z-order allocation remain internal unless a future spec revision promotes them.
- Responsive-rule normalization may exist internally, but no public breakpoint-table schema or single exact resolver algorithm is stabilized in this revision.

Task order:

1. `00-compliance-review.md`
2. `01-overlay-orchestration-internals.md`
3. `02-modal-control-contract.md`
4. `03-alert-control-contract.md`
5. `04-responsive-rules-finalization.md`
6. `05-demo-and-acceptance.md`
