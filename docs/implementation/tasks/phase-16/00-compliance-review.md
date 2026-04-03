# Phase 16 Task 00: Compliance Review

## Goal

Map the current implementation against the new quad-normalization spec so the
work starts from explicit gaps rather than assumption.

## Scope

Review these files:

- `lib/ui/core/insets.lua`
- `lib/ui/core/drawable_schema.lua`
- `lib/ui/layout/layout_node_schema.lua`
- `lib/ui/scene/stage_schema.lua`
- `lib/ui/render/styling_contract.lua`
- `lib/ui/render/styling.lua`
- `lib/ui/themes/default.lua`

Also review stale phase docs that now conflict with the accepted spec:

- `docs/implementation/phase-12-styling-schema.md`
- `docs/implementation/tasks/phase-12/*`
- `docs/implementation/tasks/phase-14/01-styling-keys-constant.md`

## Questions To Answer

1. Where is four-side normalization currently duplicated?
2. Which current schema surfaces already behave like `SideQuad input`?
3. Which current schema surfaces need new aggregate props or flat override props?
4. Which styling-resolution paths still assume flat-only border and radius families?
5. Which theme token tables already use aggregate keys such as `*.borderWidth`?
6. Which planning docs are now explicitly stale because of the spec patch?

## Deliverable

Produce a concise gap list that identifies:

- current-compliant behavior
- missing behavior
- contradictory planning docs
- implementation order dependencies

## Exit Criteria

- Every impacted runtime file is named.
- Every stale planning doc is named.
- The result is concrete enough to execute Tasks 01-03 without re-auditing the same surface.
