# Task 11: Acceptance And Summary

## Goal

Close phase-22 with a phase-21-style acceptance gate. Rerun the full spec suite and the representative demos, produce grep-based migration proofs, map each of the ten mutation families from `audits/dirty_props_refactor.md` to its new call site, and record any follow-up deferrals. No code edits in this task unless a regression surfaces, in which case the fix happens in the owning task and this task reruns the verification.

## Scope

In scope:

- run the full `spec/` suite and record the result
- run the representative demos (`love demos/04-graphics` plus at least one layout demo and one controls demo) and confirm visual parity with the pre-phase-22 baseline
- produce grep proofs that the legacy API surface is gone from `lib/ui/` and `spec/`
- produce a grep proof that every migrated base class and concrete class constructs at least one of `DirtyState` / `Reactive` / `Schema(self)`
- map each of the ten mutation families to the file/method that handles it in the new code
- classify every audit finding from `audits/source_code_audit_findings.md` as landed, intentionally unchanged, or deferred
- write the phase-22 acceptance summary document

Out of scope:

- any new code; if a regression surfaces, it is fixed in the task that owns the regressed file and task 11 reruns the verification

## Spec anchors

- [audits/source_code_audit_findings.md](/Users/vanrez/Documents/game-dev/lua-ui-library/audits/source_code_audit_findings.md) — every finding must be accounted for in the summary
- [audits/dirty_props_refactor.md](/Users/vanrez/Documents/game-dev/lua-ui-library/audits/dirty_props_refactor.md) — the ten mutation families are the migration's correctness contract

## Work items

- **Full spec run.** Run the complete `spec/` suite. Record the pass count and zero-failure proof. If any spec fails, stop and return the failure to the owning task for a fix, then rerun.
- **Demo smoke.** Run `love demos/04-graphics` and at least one layout-exercising demo and one controls-exercising demo. Confirm visual parity with the pre-phase-22 baseline. If visual capture infrastructure exists, attach before/after screenshots to the summary.
- **Legacy API grep proofs.** Produce grep output showing zero matches in `lib/ui/` and `spec/` for each of:
  - `_public_values`
  - `_effective_values`
  - `_set_public_value`
  - `_allowed_public_keys`
  - `Schema.validate`
  - `Schema.validate_all`
  - `Schema.extract_defaults`
  - `Schema.merge`
  - `DrawHelpers.for_each_dashed_segment`
  - `full_opts`
  The only acceptable hits for the schema module functions are inside `spec/utils/schema_binding_spec.lua` or `spec/utils/rule_spec.lua` if those specs intentionally reference the removed names in a negative assertion; otherwise zero.
- **Object-model installation grep proof.** Produce grep output showing that each of `Container`, `Drawable`, `Shape`, `LayoutNode`, `Stack`, `Row`, `Column`, `Flow`, `SafeAreaContainer`, `Stage`, `Composer`, `ScrollableContainer`, `Text`, `Button`, `Checkbox`, `Switch`, `Radio`, `RadioGroup`, `Slider`, `ProgressBar`, `Select`, `Option`, `TextInput`, `TextArea`, `Tabs`, `Modal`, `Alert`, `Notification`, `Tooltip` constructs at least one of `DirtyState(`, `Reactive(`, or `Schema(self)` / `self.schema:define` in its constructor.
- **Mutation family mapping.** Produce a table mapping each of the ten mutation families from `dirty_props_refactor.md` to its implementation in the new code. Expected layout:
  1. Public prop writes with fixed fan-out → `Container:constructor` declarative fan-out table + `Reactive:watch` handlers
  2. Schema-level side-effect escalation → Rule `set` option → `Schema:define` → `Proxy.on_write`
  3. Structural mutations → `Container:addChild` / `detach_child` / `destroy_subtree` (non-declared field edits)
  4. Layout-owned placement → `Container:_set_layout_offset` via `Proxy.raw_set`
  5. Layout-owned resolved-size writes → `Container:_apply_resolved_size` / `_apply_content_measurement` via `Proxy.raw_set`
  6. Parent-region dependency → `Container:_mark_parent_layout_dependency_dirty`
  7. Parent/stage-injected measurement contexts → `Container:_set_measurement_context` via `Proxy.raw_set`
  8. Controller-owned internal-node mutations → `ScrollableContainer` / `Text` / `Stage` via `Reactive:raw_set`
  9. Broad `markDirty()` fallback → `Container:markDirty`
  10. Stage environment changes → `Stage:resize` / `refresh_environment_bounds` via `Proxy.raw_set`
- **Finding-by-finding status.** Walk every finding in `audits/source_code_audit_findings.md` and classify it as:
  - **Landed** — list the task number that closed it and any verification evidence
  - **Intentionally unchanged** — explain why (out of scope for phase-22, covered by phase-21, etc.)
  - **Deferred** — name the concrete follow-up (phase/task) that will close it
  The expected result is that `DC-01`, `DC-02`, `DC-03`, `ML-01`, `ML-02`, `ML-03`, `ML-04`, `CS-01` through `CS-08`, `RE-01`, `RE-02`, `AP-01`, `AP-02` all land; any finding listed in phase-21 stays classified as covered there.
- **Deferred items list.** Record any future follow-ups the phase intentionally did not close. Expected entries:
  - Paint/render dirty domain separation on Container (flagged as future work in the compliance review)
  - Dispatcher-level `_destroyed` filtering (if not done in task 09)
  - Any other item that surfaced during implementation and was deliberately pushed
- **Phase-22 acceptance summary document.** Write the final summary in the phase-21 format at `docs/implementation/tasks/phase-22-audit-refactor/acceptance-summary.md` (or the equivalent convention the repo uses). Include: the grep proofs, the mutation family mapping, the finding-by-finding table, the deferred items list, the spec run result, and the demo smoke result.

## File targets

- `docs/implementation/tasks/phase-22-audit-refactor/acceptance-summary.md` (new)

## Testing

Required runtime verification:

- `love demos/04-graphics` — visual parity confirmed
- one representative layout demo — visual parity confirmed
- one representative controls demo — visual parity confirmed

Required spec verification:

- full `spec/` suite green with zero edits to any existing spec file
- every new spec added in tasks 02–09 passes

## Acceptance criteria

- Full spec suite passes with zero failures and zero edits to any existing spec file.
- Representative demos render identically to the pre-phase-22 baseline.
- Grep proofs show zero legacy-API references in `lib/ui/` and `spec/`.
- Grep proof shows every base class and concrete class constructs at least one of `DirtyState` / `Reactive` / `Schema(self)`.
- Every mutation family from `dirty_props_refactor.md` is mapped to a concrete file/method in the new code.
- Every finding in `audits/source_code_audit_findings.md` is classified as landed, intentionally unchanged, or deferred.
- The phase-22 acceptance summary document is written and committed to the phase folder.
