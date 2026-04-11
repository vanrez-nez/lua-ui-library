# Phase 22: Audit-Driven Object Model Migration And Source Audit Refactor

This phase translates the five object-model proposals and the source-code audit in [audits/](/Users/vanrez/Documents/game-dev/lua-ui-library/audits) into implementation tasks for the current `lib/ui` runtime.

Source documents driving this phase:

- [audits/dirty_obj.md](/Users/vanrez/Documents/game-dev/lua-ui-library/audits/dirty_obj.md) — `DirtyState` value object
- [audits/proxy_obj.md](/Users/vanrez/Documents/game-dev/lua-ui-library/audits/proxy_obj.md) — `Proxy` pipeline (`__index`/`__newindex` intercept with `read`, `pre_write`, `on_write`, `on_change` slots)
- [audits/reactive_obj.md](/Users/vanrez/Documents/game-dev/lua-ui-library/audits/reactive_obj.md) — `Reactive` binding object
- [audits/schema_obj.md](/Users/vanrez/Documents/game-dev/lua-ui-library/audits/schema_obj.md) — `Schema(instance)` binding object
- [audits/schema_refactor_proposal.md](/Users/vanrez/Documents/game-dev/lua-ui-library/audits/schema_refactor_proposal.md) — `Rule` builders and validation tiers
- [audits/dirty_props_refactor.md](/Users/vanrez/Documents/game-dev/lua-ui-library/audits/dirty_props_refactor.md) — inventory of the ten mutation families any refactor must cover
- [audits/source_code_audit_findings.md](/Users/vanrez/Documents/game-dev/lua-ui-library/audits/source_code_audit_findings.md) — nineteen quality findings

Out of scope in this phase:

- [audits/graphics_pipeline_analysis_findings.md](/Users/vanrez/Documents/game-dev/lua-ui-library/audits/graphics_pipeline_analysis_findings.md) is already covered by [phase-21](/Users/vanrez/Documents/game-dev/lua-ui-library/docs/implementation/tasks/phase-21-graphics-perf).

The phase is intentionally constrained:

- no public API expansion
- no public prop surface changes
- no spec or behavior changes hidden under refactor work
- no new mutation-family abstractions on top of the ten from `dirty_props_refactor.md`
- naming and call shape of the new foundation modules are kept verbatim from the audits

Authoritative contracts remain:

- [UI Foundation Specification](/Users/vanrez/Documents/game-dev/lua-ui-library/docs/spec/ui-foundation-spec.md)
- [UI Graphics Specification](/Users/vanrez/Documents/game-dev/lua-ui-library/docs/spec/ui-graphics-spec.md)
- [UI Motion Specification](/Users/vanrez/Documents/game-dev/lua-ui-library/docs/spec/ui-motion-spec.md)
- phase-20 and phase-21 task sets in [docs/implementation/tasks](/Users/vanrez/Documents/game-dev/lua-ui-library/docs/implementation/tasks)

Phase assumptions:

- the foundation modules (`DirtyState`, `Proxy`, `Reactive`, `Rule`, `Schema(instance)`) are ported verbatim from the audits; deviations are only allowed when a real constraint surfaces during implementation and they must be recorded in the acceptance summary
- the ten mutation families from `dirty_props_refactor.md` are preserved intact; each family keeps its current internal method, rewritten to use `Proxy.raw_set`/`Proxy.raw_get` for the internal writes
- responsive override resolution is implemented as a `Proxy.on_read` hook on affected keys; the raw store holds the user value and the read hook substitutes the active override
- `lib/ui/utils/schema.lua` loses its legacy module functions (`validate`, `validate_all`, `extract_defaults`, `merge`) by the end of task 05 in favor of the constructor-style `Schema(instance)`
- `lib/ui/core/container.lua` is migrated before its descendants; every subclass migration in tasks 06–09 depends on the Container migration in task 05
- error messages produced by the Rule builders must match the currently observable error messages from inline validators; any spec that asserts on a validator error message must keep passing without edits

Task order:

1. `00-compliance-review.md`
2. `01-source-audit-prep-and-helper-consolidation.md`
3. `02-dirty-state-and-proxy-modules.md`
4. `03-reactive-and-rule-modules.md`
5. `04-schema-binding-and-schema-files-migration.md`
6. `05-container-base-migration.md`
7. `06-drawable-and-shape-migration.md`
8. `07-layout-family-migration.md`
9. `08-stage-scroll-text-migration.md`
10. `09-controls-migration-and-lifecycle.md`
11. `10-gpu-caching-and-alloc-reduction.md`
12. `11-acceptance-and-summary.md`

Phase-wide stop conditions:

- If the responsive-override-as-read-hook design cannot cleanly model the current `_effective_values` semantics for any documented prop, stop before landing task 05 and open a design discussion. Do not paper over the gap with a second backing store.
- If any spec asserting on a validator error message needs to be edited to accommodate a Rule builder, stop and fix the builder until the existing message matches exactly.
- If a container subclass migration in tasks 06–09 needs to add or change a dirty flag on Container, stop and amend the Container dirty set in task 05 instead of adding a second DirtyState on the subclass. Shape's `paint`/`geometry` buckets are the one permitted exception because they are genuinely shape-local.
- If removal of the legacy `Schema.validate`/`validate_all`/`extract_defaults`/`merge` module functions in task 05 leaves any remaining caller anywhere in `lib/ui/` or `spec/`, stop and migrate that caller before landing.
- If any public prop read or write produces a different value before and after a migration task, stop and resolve the contract drift rather than editing the spec.

Exit criteria:

- every file listed in each task's `File targets` has been modified as described
- every audit finding from `source_code_audit_findings.md` is classified as landed, intentionally unchanged, or deferred in the acceptance summary
- every base class (`Container`, `Drawable`, `Shape`, `LayoutNode`, `Stack`, `Row`, `Column`, `Flow`, `SafeAreaContainer`, `Stage`, `ScrollableContainer`, `Text`, and every `Control`) constructs at least one of `DirtyState`, `Reactive`, `Schema(self)` in its constructor
- the legacy property surfaces `_public_values`, `_effective_values`, `_set_public_value`, `_allowed_public_keys`, and the module functions `Schema.validate`/`validate_all`/`extract_defaults`/`merge` are absent from `lib/ui/`
- the full `spec/` suite is green
- no task in the phase required a spec patch to explain its behavior
- the acceptance summary records the ten mutation families from `dirty_props_refactor.md` with a pointer to the file and method in the new code that handles each family
