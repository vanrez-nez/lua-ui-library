# Phase 02 Task Set

This task set consolidates Phase 02 onto the authoritative runtime contract in `docs/spec`.

Authority order for this folder:

- `docs/spec/ui-foundation-spec.md` is normative for `Stage`, `Scene`, and `Composer`.
- Trace note additions in that spec are part of the settled contract for this phase and close earlier draft ambiguities.
- `docs/implementation/phase-02-runtime.md` remains useful for sequencing, examples, and harness intent, but it is not authoritative where it diverges from `docs/spec`.

Relevant trace-note clarifications now treated as settled:

- `Stage`: `safeAreaInsets` does not replace safe-area bounds, and raw host input still enters only through `Stage`.
- `Scene`: no public `"running"` lifecycle phase is standardized, and scene-local visibility helpers do not define activation.
- `Composer`: transition helper surfaces and overlay helper methods remain internal even though overlay ownership itself is part of the runtime contract.

Consolidated spec decisions carried through these tasks:

- `Stage` must expose both `safeAreaInsets` and safe area bounds, and it remains the only raw-input intake boundary.
- `Scene` public lifecycle is limited to creation, enter-before, enter-after, leave-before, leave-after, and destruction.
- Scene activation and deactivation are owned by `Composer`; scene-local visibility helpers do not define a parallel public contract.
- `Composer` interruption handling follows the published state machine, including the no-intermediate-hooks rule during interrupted transitions.
- Transition catalogs, helper modules, canvas-composition mechanics, and overlay helper methods remain internal unless the spec later promotes them.

Task order:

1. `00-compliance-review.md`
2. `01-stage-runtime-contract.md`
3. `02-scene-lifecycle-and-composition.md`
4. `03-composer-registry-activation-and-transition-state.md`
5. `04-runtime-transition-execution-internals.md`
6. `05-phase-02-demo-and-acceptance.md`
