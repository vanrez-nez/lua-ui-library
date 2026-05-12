# 03 - Build And Packaging Boundaries

## Goal

Keep generated Lua, reviewed runtime Lua, and package release outputs separate.
Setup should make boundaries explicit without deciding every future migration
detail.

## Source Roles

Use these roles consistently:

- `src/ts`: authored TypeScript migration source.
- `src/types`: compile-time TypeScript declarations.
- `src/generated/tstl`: ignored generated Lua for validation and review.
- `src/lua`: reviewed runtime Lua used by LÖVE and LuaRocks after the project
  refactor.

Generated Lua is not automatically runtime Lua. A generated file becomes
runtime source only after review, parity checks, and an explicit promotion step.

## Promotion Rule

For setup, no generated Lua should be promoted. The first promotion process can
be designed later, but it must include:

- A source module selected for migration.
- Declaration coverage for dependencies.
- A generated Lua diff reviewed against the existing Lua module.
- Lua smoke checks and relevant specs.
- Luacheck after the promoted Lua is in the runtime path.

## LuaRocks Boundary

LuaRocks should consume reviewed runtime Lua, not TypeScript source or ignored
generated output.

After `00-project-refactor.md`, rockspec paths should point at
`src/lua/lib/...` while public package module names remain `ui.*`.

Do not package:

- `src/ts`
- `src/types`
- `src/generated`
- `node_modules`
- `lua_modules`
- temporary profiling output

## LÖVE Boundary

The direct app target after the project refactor should be:

```bash
love src/lua
```

Demo targets should follow the same rule:

```bash
love src/lua/demos/03-drawable
```

Root `love .` is not the target runtime path after setup.

## Non-Goals

- Do not decide whether final release Lua is committed forever or generated
  during release.
- Do not add a bundler.
- Do not rewrite every `require` namespace.
- Do not port individual modules.

## Acceptance Criteria

- Generated TSTL output remains ignored.
- Runtime launch docs point at `src/lua`.
- Rockspec source paths point at reviewed Lua only.
- No setup task requires TypeScript source to overwrite runtime Lua.
