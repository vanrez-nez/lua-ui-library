# Task 00: Compliance Review

## Goal

Turn the audit proposals into a spec-safe implementation plan before any runtime module is written, rewritten, or deleted. Pin down the design decisions that cross task boundaries so downstream tasks do not re-litigate them.

## Current implementation notes

- `lib/ui/core/container.lua` maintains `_public_values` (user-set) and `_effective_values` (responsive-override-resolved) in parallel. `Container.__newindex` routes writes through `_set_public_value`, which validates, stores into both tables where appropriate, and fans out to per-property dirty flags.
- `lib/ui/utils/schema.lua` is a module with `validate`, `validate_all`, `extract_defaults`, `merge`, and `validate_size`. `Schema.validate` at line 41 references an undefined `full_opts`; `validate_all` at line 53 passes a 7th argument that the signature drops (`DC-02`).
- `Proxy.install` in `audits/proxy_obj.md` replaces the instance metatable, so after install non-declared reads fall through to `_pclass[k]` and non-declared writes go straight to `rawset`. Every public prop must be explicitly declared via `Proxy.declare` during construction — no implicit catch-all survives.
- `audits/dirty_props_refactor.md` enumerates ten mutation families any refactor must cover. Seven of them are implemented today via direct writes to `_public_values`/`_effective_values` or raw dirty flags, not through the public `__newindex` path.
- `lib/ui/core/drawable.lua` has duplicate `__index`/`__newindex` definitions at lines 21–49 and 410–438. The first block is dead code (`DC-01`).

## Status key

- `safe`: the finding can be implemented as an internal refactor without touching documented semantics.
- `spec-sensitive`: the finding is only allowed if the implementation preserves the published contract exactly and proves equivalence with focused tests.
- `excluded`: the finding as proposed would alter docs/spec, add contract surface, or rely on undocumented semantics.

## Review matrix

| Finding / refactor direction | Status | Why |
|---|---|---|
| Verbatim port of `DirtyState` from `audits/dirty_obj.md` | safe | Standalone value object with no runtime coupling until a class wires it in. |
| Verbatim port of `Proxy` from `audits/proxy_obj.md` | safe | No class consumes it in task 02; wiring comes in tasks 05–09. |
| Verbatim port of `Reactive` from `audits/reactive_obj.md` | safe | Thin wrapper over `Proxy`; standalone in task 03. |
| Verbatim port of `Rule` builders from `audits/schema_refactor_proposal.md` §2.1 | safe | New module; rules are consumed only after `Schema(instance)` lands in task 04. |
| `Schema(instance):define(...)` binding replacing the current module functions | spec-sensitive | Replaces the central validation path. Allowed only if every existing schema spec passes unchanged and error messages match byte-for-byte where specs observe them. |
| Migration of every `*_schema.lua` to Rule builders | spec-sensitive | Authoring-shape change only; effective rule behavior and error messages must match exactly. |
| Full `Container` migration to `Proxy` + `Reactive` + `DirtyState` + `Schema(self)` | spec-sensitive | Public read precedence, effective-value semantics, and all ten mutation families must remain identical. |
| Responsive override resolution as a `Proxy.on_read` hook | spec-sensitive | Allowed only if existing responsive specs pass unchanged and the read hook is cleared/updated on every invalidation event that today touches `_effective_values`. |
| Removal of the legacy `Schema.validate`/`validate_all`/`extract_defaults`/`merge` module functions | spec-sensitive | Allowed only once every consumer in `lib/ui/` and `spec/` has migrated. Grep proof required in task 11. |
| Consolidating `apply_resolved_size`/`apply_content_measurement` duplication (families 4–5) into a single Container helper | safe | Internal helper change; subclasses switch call target. |
| Keeping `markDirty()` as a coarse fallback (family 9) | safe | Current callers keep their semantics; the method just moves to the new dirty set. |
| Controller-owned internal writes migrating to `Reactive.raw_set` (family 8) | spec-sensitive | Equivalence with current behavior must be proven for scroll content offset, scrollbar geometry, viewport sync, and Text intrinsic size. |
| Structural mutations (`addChild`, `detach_child`, `destroy_subtree`) keeping their current fan-out (family 3) | safe | Structural state is held in non-declared fields and does not need to flow through the proxy. |
| Stage environment changes via `Proxy.raw_set` on stage fields (family 10) | safe | Stage resize/safe-area paths remain identical in behavior; only the backing store changes. |
| Fix `DC-02` (`Schema.validate` `full_opts` variable) | safe | Bug fix; the 7th argument is currently dropped. |
| Remove `DC-01` (duplicate `__index`/`__newindex` in drawable.lua) | safe | Dead code; second definition already overwrites the first. |
| Remove `DC-03` (`DrawHelpers.for_each_dashed_segment`) | safe | Zero callers. |
| `ML-01`, `ML-02`, `ML-03`, `ML-04` memory-leak fixes | safe | Mechanical caching/cleanup; invalidation tied to existing property writes. |
| `CS-01` through `CS-05` helper consolidation | safe | Pure deduplication. |
| `CS-06` controlled-value factory in `ControlUtils` | safe | Pattern is identical across seven controls. |
| `CS-07` `_destroyed` guard standardization | safe | Current guard is already present in some controls; this makes it uniform. |
| `CS-08` shape draw error fallback standardization | safe | Chooses the already-documented fallback path. |
| `RE-01` overlay mixin extraction | safe | Identical logic in four controls. |
| `RE-02` shape draw sequence hoist | safe | Base class already partially owns it. |
| `AP-01`, `AP-02` frame-hot allocation reduction | safe | Invalidation tied to Shape's new `paint`/`geometry` DirtyState buckets. |
| Introducing new public dirty flags or cache-control opt-ins | excluded | Would add contract surface absent from the specs. |
| Changing error message format for any Rule builder vs. the current inline validator | excluded | Error messages are part of the observable contract via specs. |
| Collapsing, unifying, or replacing any of the ten mutation families from `dirty_props_refactor.md` | excluded | The inventory is explicit that any refactor must preserve all ten. A collapse is a separate spec discussion. |
| Introducing a paint/render dirty domain on Container | excluded | Flagged as future work in the inventory. Shape gains `paint`/`geometry` buckets only because they are genuinely shape-local. |

## Design decisions fixed for downstream tasks

- **Responsive override as `Proxy.on_read`.** The raw store in `_pdata` holds the user-authored value. When `_resolved_responsive_overrides` contains an active override for a key, the read hook returns the override; otherwise it returns the raw value. `_set_resolved_responsive_overrides` updates the override table and marks `responsive`/`measurement`/`local_transform` dirty; it never writes to a second backing store. Container specs that compare effective reads against expected resolved values must pass unchanged.
- **Container dirty set.** `DirtyState({'responsive', 'measurement', 'local_transform', 'world_transform', 'bounds', 'child_order', 'layout', 'world_inverse'})`. These eight flags mirror the current `_*_dirty` booleans on Container. No subclass adds or renames a flag in this set; Shape's extra `DirtyState({'paint', 'geometry'})` is a separate instance on Shape.
- **Per-key dependency fan-out is declarative.** Task 05 lifts the if/elseif in `Container._set_public_value` into a table keyed by prop family (`measurement`, `transform`, `zIndex`, `visible`, `other`), and registers `Reactive:watch` handlers from that table. The behavior is identical; only the shape of the source code changes.
- **Internal methods keep their names.** `_set_layout_offset`, `_set_measurement_context`, `_set_resolved_responsive_overrides`, `_mark_parent_layout_dependency_dirty`, `apply_resolved_size`, `apply_content_measurement`, `markDirty`, `addChild`, `detach_child`, `destroy_subtree`, `_refresh_if_dirty` all survive. Internal writes inside them use `Proxy.raw_set`/`Proxy.raw_get`; their call sites and dirty fan-out are unchanged.
- **Schema module functions are removed in task 05.** Until then, the new `Schema(instance)` binding coexists with the legacy module functions so task 04 can migrate `*_schema.lua` files without touching Container.
- **Error message parity.** Every Rule builder must reproduce the exact error message its inline predecessor produced, where that message is observable through a spec. If a spec needs to change to accommodate a new message, the builder is wrong.
- **Shape is allowed its own DirtyState.** Only Shape. `paint` and `geometry` are shape-local concepts and do not compete with Container's eight flags. No other subclass adds its own DirtyState.

## Work items

- Record the review matrix above as the phase-local compliance record.
- Record the design decisions above as the authoritative source for tasks 02–11.
- Identify any current `Schema.validate` caller or custom validator that would be affected by the `DC-02` signature fix, so task 01 can verify the change is transparent.
- Identify every file in `lib/ui/` and `spec/` that references `_public_values`, `_effective_values`, `_set_public_value`, `_allowed_public_keys`, or the legacy `Schema.validate`/`validate_all`/`extract_defaults`/`merge` module functions. Produce a removal checklist task 05 and task 11 consume.

## File targets

- `docs/implementation/tasks/phase-22-audit-refactor/00-compliance-review.md`

## Testing

Required runtime verification:

- none for this task; it is a review gate.

Required spec verification before downstream tasks begin:

- full `spec/` suite green at baseline so later regressions are detectable.

## Acceptance criteria

- Every audit finding from `source_code_audit_findings.md` and every concept from `dirty_obj.md`, `proxy_obj.md`, `reactive_obj.md`, `schema_obj.md`, `schema_refactor_proposal.md`, and `dirty_props_refactor.md` is classified as `safe`, `spec-sensitive`, or `excluded`.
- The responsive-override-as-read-hook design is explicitly recorded as the only approved approach for task 05.
- The Container dirty set and the declarative fan-out table shape are explicitly recorded.
- Error message parity is explicitly recorded as a stop condition for tasks 03 and 04.
- Removal of the legacy `Schema` module functions is explicitly gated on task 11 grep proof.
- No downstream task requires a spec patch just to begin implementation.
