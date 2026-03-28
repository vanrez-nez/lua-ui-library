# Phase 02 Task Set

This task set normalizes Phase 2 against the authoritative spec set in `docs/spec`.

Normalization rules for this phase:

- Treat `docs/spec/ui-foundation-spec.md` as normative for `Stage`, `Scene`, and `Composer`.
- Keep the runtime public surface limited to what the spec names or clearly requires.
- Extra transition helpers, hook plumbing, and caching mechanics may exist, but they must be treated as internal implementation detail unless the spec stabilizes them.
- Do not make overlay APIs or transition APIs public just because they are convenient to implement early.

Key corrections applied to the original phase document:

- `Scene` lifecycle is normalized to creation, enter-before, enter-after, leave-before, leave-after, and destruction. No public `"running"` phase is introduced.
- `Scene` validity remains tied to `Composer` management and mounting in the Stage base scene layer.
- `Stage` root input delivery remains a required runtime surface and cannot be documented as a pure no-op if Phase 2 claims full runtime compliance.
- Transition composition helpers are scoped as internal support code unless and until the spec names them as public API.
- Overlay management stays within the spec boundary of `Stage`/`Composer` layer ownership and must not freeze a public overlay-scene API early.

Task order:

1. `00-compliance-review.md`
2. `01-stage-runtime-contract.md`
3. `02-scene-lifecycle-and-composition.md`
4. `03-composer-registry-activation-and-transition-state.md`
5. `04-runtime-transition-execution-internals.md`
6. `05-phase-02-demo-and-acceptance.md`
