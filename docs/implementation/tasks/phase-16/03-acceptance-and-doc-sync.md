# Phase 16 Task 03: Acceptance And Doc Sync

## Goal

Verify the new quad-normalization model end to end and update stale
implementation docs so the project no longer documents the old flat-only model.

## Scope

Runtime verification files:

- `spec/styling_resolution_spec.lua`
- `spec/styling_renderer_spec.lua`
- any focused spec files that cover Foundation prop normalization

Documentation files to update or supersede:

- `docs/implementation/phase-12-styling-schema.md`
- `docs/implementation/tasks/phase-12/*`
- `docs/implementation/tasks/phase-14/01-styling-keys-constant.md`

## Work

1. Add regression coverage for:
   - aggregate side-quad normalization
   - aggregate corner-quad normalization
   - aggregate-plus-flat override precedence
   - deterministic failure for malformed quad shapes
2. Verify that rendering behavior is unchanged once canonical expanded props are produced.
3. Update stale implementation docs that still assert:
   - no `borderWidth` shorthand
   - no `cornerRadius` shorthand
   - no shared quad-family abstraction
4. Leave a clear note anywhere the project intentionally keeps an older phase doc as historical context instead of current execution guidance.

## Exit Criteria

- Focused runtime/spec coverage exists for the new model.
- No current implementation planning doc contradicts the accepted spec surface.
- The code and docs describe the same normalization model.
