# Phase 09 Compliance Review

Source under review: `docs/implementation/phase-09-modal-responsive.md`

Task-set authority:

- `docs/spec/ui-foundation-spec.md` is authoritative for overlay ownership, Composer lifecycle boundaries, focus trapping/restoration, and responsive-rule behavior.
- `docs/spec/ui-controls-spec.md` is authoritative for `Modal` and `Alert` public props, structure, and validity rules.
- `docs/implementation/phase-09-modal-responsive.md` is planning context only and cannot widen the public contract.

Primary findings, ordered by severity:

1. `Scene` lifecycle is over-specified again through public overlay wiring.
   Source: `phase-09-modal-responsive.md:19-31`
   Spec anchors: `ui-foundation-spec.md §6.4.2 Scene`, `ui-foundation-spec.md §6.4.3 Composer`
   Problem: the phase doc fires `onEnter("running")` and `onLeave("running")` as part of `showOverlay` / `hideOverlay`. The spec only stabilizes creation, enter-before, enter-after, leave-before, leave-after, and destruction hooks. Public running-phase hooks are not part of the contract.
   Required normalization: keep any transition-progress or overlay-open/close sequencing internal to Composer implementation details. Do not expose or stabilize a public `"running"` lifecycle phase.

2. `showOverlay` and `hideOverlay` are not spec-backed public API.
   Source: `phase-09-modal-responsive.md:19-31`
   Spec anchors: `ui-foundation-spec.md §6.4.3 Composer`, `ui-foundation-spec.md §3F.2 API Surface Classification`
   Problem: the phase doc defines a public overlay registry API with stacking semantics, zIndex allocation, and explicit hit-order rules. The spec requires overlay support, but it does not stabilize a concrete `showOverlay`/`hideOverlay` surface or a public overlay stack registry.
   Required normalization: treat overlay mounting as internal Composer plumbing or a later explicitly documented API, not as a frozen public surface in Phase 9.

3. `Modal` props and methods drift away from the spec-backed contract.
   Source: `phase-09-modal-responsive.md:43-76`
   Spec anchors: `ui-controls-spec.md §6.7 Modal`, `ui-foundation-spec.md §7.2.5 Focus and overlays`
   Problems:
   - the phase doc introduces `modal:open()` / `modal:close()` methods, but the spec only names controlled `open` plus `onOpenChange`
   - `dismissible` and `backdropDismiss` are not the spec's control props; the spec uses `dismissOnBackdrop`, `dismissOnEscape`, `trapFocus`, `restoreFocus`, `safeAreaAware`, and `backdropDismissBehavior`
   - `focusScope = true` on the surface is not part of the Modal public surface
   Required normalization: keep Modal on the spec-defined prop surface and let focus-trap behavior be driven by the overlay contract, not by extra control-local methods or props.

4. `Alert` is over-constrained and under-matched to the spec.
   Source: `phase-09-modal-responsive.md:83-107`
   Spec anchors: `ui-controls-spec.md §6.8 Alert`, `ui-controls-spec.md §4B.3 Control Slot Declarations`
   Problems:
   - the phase doc defines a constructor signature and type-specific hard-failure rules that are not part of the public contract
   - it uses `dismissible` instead of the Modal-derived dismissal props
   - it omits the spec-backed `initialFocus` property and instead hardcodes first-action focus behavior
   Required normalization: model Alert as a specialized Modal with `title`, `message`, `actions`, `variant`, and `initialFocus`, and keep construction/hard-failure policy aligned to the documented contract rather than to a custom constructor API.

5. Responsive-rule finalization is narrower than the spec and freezes implementation choices too early.
   Source: `phase-09-modal-responsive.md:111-126`
   Spec anchors: `ui-foundation-spec.md §7.3 Responsive Rules`, `ui-foundation-spec.md §6.2 Layout Family`, `ui-foundation-spec.md §6.2.8 SafeAreaContainer`
   Problems:
   - the phase doc hardcodes `resolveSize` invocation on all layout families and base Container as a finalized public rule
   - breakpoint reevaluation is scoped to viewport-only comparisons against each node's `breakpoints` table, even though the spec allows responsive rules to depend on orientation, safe area, and parent dimensions
   - the breakpoint schema itself remains unspecified by the spec, yet the phase doc treats it as finalized implementation API
   Required normalization: keep responsive behavior declarative and spec-backed, but do not freeze the schema or exact traversal order beyond what the spec states.

Secondary scoping notes:

- The phase doc’s nested overlay test intent is compatible with the spec requirement that nested Modals be supported, but that does not imply a public overlay registry API.
- Safe-area-relative percentage resolution is now settled by the published spec against the effective parent content region; task wording should treat that as closed rather than as optional interpretation.
