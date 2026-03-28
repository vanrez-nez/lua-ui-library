# Phase 04 Compliance Review

Authority used for this review:

1. `docs/spec/ui-foundation-spec.md`
2. `docs/implementation/phase-04-events.md`

Primary corrections required for compliance, ordered by severity:

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

3. The phase harness names a concrete focus helper surface that the spec does not standardize.
   Source: `phase-04-events.md:154-155`
   Spec anchors: `ui-foundation-spec.md §3D.4 Focus Model`, `ui-foundation-spec.md §7.2 Focus`
   Problem: the draft names `stage:requestFocus()` as if it were the public path for explicit focus requests. The current spec now clarifies that explicit focus request support is behavioral, not a commitment to one public imperative method name.
   Required normalization: remove the public `stage:requestFocus()` assumption from Phase 4 acceptance. Use an internal harness fixture or other non-promoted test-only seeding path.

4. Hover tracking is being promoted to public-ish container state even though the spec now classifies it as internal derived state.
   Source: `phase-04-events.md:111-115`
   Spec anchors: `ui-foundation-spec.md §3C.6 Derived State`, `ui-foundation-spec.md §7.2 Focus`, `ui-foundation-spec.md §3F.2 API Surface Classification`
   Problem: the draft defines `hovered` as a derived interaction-state flag on `Container` and describes synthetic `ui.pointer-enter` / `ui.pointer-leave` notifications. The current spec now explicitly classifies hover ownership and pointer-entry/exit bookkeeping as internal derived state.
   Required normalization: keep hover ownership and pointer-enter/leave plumbing internal in the Phase 4 task set rather than describing them as public surface.

5. The listener helper surface is now explicitly outside the stabilized API contract, but the draft still reads as if it were public API.
   Source: `phase-04-events.md:117-123`
   Spec anchors: `ui-foundation-spec.md §7.1 Event Propagation`, `ui-foundation-spec.md §3F.2 API Surface Classification`
   Problem: `node:on`, `node:off`, `node:capture`, and `node:bubble` are implementation choices in the phase doc. The current spec now states this boundary directly: propagation phases and payloads are public, but one listener-registration method surface is not.
   Required normalization: implement a listener surface if needed, but treat helper names, storage, and registration mechanics as internal and undocumented for compatibility purposes.

Secondary scoping notes:

- The event object fields themselves are broadly spec-aligned, including `phase`, `immediatePropagationStopped`, and spatial coordinate fields.
- The 4px drag threshold is an implementation choice, not a spec commitment, and should stay internal.
- No unresolved Phase 04 spec gap remains in this task set around hover, listener helpers, or explicit focus-request method naming; those boundaries are now settled by the published spec.
