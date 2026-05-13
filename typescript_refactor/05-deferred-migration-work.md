# 05 - Deferred Migration Work

## Goal

Keep setup focused. This file records migration work that is intentionally
deferred until the project layout, tooling, and external declarations are
stable.

## Deferred Until After Setup

- Per-module TypeScript ports.
- Promotion of generated Lua into runtime source paths.
- Public namespace changes from `lib.ui.*` internal requires to another
  internal convention.
- Automated rockspec generation from the TypeScript or Lua source graph.
- Performance comparisons between handwritten Lua and generated Lua.
- Final release strategy for generated Lua.
- Demo conversion to TypeScript.

## First Future Migration Candidate

After setup is complete, choose one low-risk module class rather than a broad
subsystem:

- constants
- enums
- small pure math or placement helpers
- declarative `*_schema.lua` modules that do not include protected utility
  implementations

Do not start with:

- `lib.ui.utils.reactive`
- `lib.ui.utils.dirty_props`
- `lib.ui.utils.memoize`
- `lib.ui.utils.schema`
- `lib.ui.utils.rule`
- hot-path layout, render, or event-dispatch classes

## Future Migration Entry Requirements

Before porting a module, the repo should have:

- `src/lua` runtime layout complete.
- Stable TypeScript declarations for all Lua dependencies used by the module.
- A repeatable generated-output review path.
- Runtime smoke checks for the module.
- Focused LuaUnit coverage for the module's public behavior.

## Future Work Recording Rule

Do not append a source-file checklist to this setup roadmap. After setup is
accepted, evaluate one candidate at a time with the intake template:

```text
typescript_refactor/future-migration-intake-template.md
```

Each future migration record should describe:

- The candidate category and one candidate module.
- Why it is low risk.
- Which Lua dependencies already have declarations.
- Which runtime smoke checks and LuaUnit specs prove parity.
- How the generated Lua diff will be reviewed before any promotion.

If a candidate needs a new external declaration, add that declaration before
porting. If the candidate depends on a protected optimized utility, keep that
utility handwritten and import it through declarations.

## Acceptance Criteria

- No setup task contains a per-file port list.
- No setup task promotes generated Lua.
- Future migration candidates are described by category and entry requirements,
  not by a full port schedule.
- Future migration work uses the intake template instead of editing setup tasks
  into a migration backlog.
