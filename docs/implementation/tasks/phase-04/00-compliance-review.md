# Phase 04 Compliance Review

Source under review: `docs/implementation/phase-04-events.md`

Primary findings, ordered by severity:

1. Pointer activation is specified in a way that can double-fire `ui.activate` for a single tap or click.
   Source: `phase-04-events.md:75-80`
   Spec anchors: `ui-foundation-spec.md §3D.1 Input Abstraction Model`, `ui-foundation-spec.md §7.1.3 Default actions`
   Problem: the translation table maps `mousepressed` / `touchpressed` to `Activate` and also maps `mousereleased` / `touchreleased` to `Activate` when no drag started. That creates two activation opportunities for one pointer gesture unless the implementation adds extra gating.
   Required normalization: define a single gesture-level activation path, or explicitly gate press/release so only one `ui.activate` dispatch can occur per pointer sequence.

2. Hit-testing eligibility is under-specified relative to the spec’s effective visibility and clipping rules.
   Source: `phase-04-events.md:95-99`
   Spec anchors: `ui-foundation-spec.md §3C.6 Derived State`, `ui-foundation-spec.md §7.1.2 Target resolution rules`
   Problem: the target resolution algorithm checks `interactive=true`, `enabled=true`, `visible=true`, and `containsPoint(wx,wy)` but does not explicitly account for ancestor clipping or effective visibility. The spec requires target resolution among hit-test-eligible descendants, which is broader than local flags alone.
   Required normalization: define target eligibility in terms of effective visibility and clipping, not only local node flags.

3. The phase harness depends on a future Phase 5 focus API.
   Source: `phase-04-events.md:154-155`
   Spec anchors: `ui-foundation-spec.md §7.2 Focus`, `ui-foundation-spec.md §3A.6 Lifecycle Model`
   Problem: the `Navigate and dismiss` screen uses `stage:requestFocus()` and labels it as introduced in Phase 5 but stubbed here. That makes the Phase 4 demo depend on a later-phase API rather than on Phase 4’s own runtime contract.
   Required normalization: remove the future-phase API dependency from the Phase 4 acceptance harness and use a Phase-4-local focus target or internal test harness fixture instead.

4. Hover tracking is being promoted to public-ish container state without spec stabilization.
   Source: `phase-04-events.md:111-115`
   Spec anchors: `ui-foundation-spec.md §3C.6 Derived State`, `ui-foundation-spec.md §7.2 Focus`, `ui-foundation-spec.md §3F.2 API Surface Classification`
   Problem: the draft defines `hovered` as a derived interaction-state flag on `Container` and describes synthetic `ui.pointer-enter` / `ui.pointer-leave` notifications. The spec does not stabilize either surface as a public contract in this revision.
   Required normalization: keep hover ownership and pointer-enter/leave plumbing internal unless a later spec revision names them publicly.

5. The listener method surface is not spec-defined but is written as if it were stable API.
   Source: `phase-04-events.md:117-123`
   Spec anchors: `ui-foundation-spec.md §7.1 Event Propagation`, `ui-foundation-spec.md §3F.2 API Surface Classification`
   Problem: `node:on`, `node:off`, `node:capture`, and `node:bubble` are implementation choices in the phase doc. The spec requires propagation semantics but does not stabilize a concrete listener-registration API surface.
   Required normalization: implement a listener surface if needed, but keep it provisional and avoid treating the method names as a spec-level compatibility promise.

Secondary scoping notes:

- The event object fields themselves are broadly spec-aligned, including `phase`, `immediatePropagationStopped`, and spatial coordinate fields.
- The 4px drag threshold is an implementation choice, not a spec commitment, and should stay internal.
