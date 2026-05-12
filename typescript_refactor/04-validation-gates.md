# 04 - Validation Gates

## Goal

Define the checks required for setup changes. These gates protect the current
Lua runtime while TypeScript tooling is introduced.

## TypeScript Gates

Run after TypeScript config, declaration, or folder-layout changes:

```bash
npm run list:ts
npm run build:ts
```

Expected setup behavior:

- `list:ts` sees `src/types`.
- `build:ts` succeeds even if `src/ts` is empty.
- No generated files are committed under `src/generated/tstl`.

## Lua Gates

Run after moving or modifying runtime Lua paths:

```bash
./lua -e 'require("spec.rule_spec").run()'
./lua -e 'require("spec.schema_spec").run()'
./lua -e 'require("lib.ui.core.container")'
./lua_modules/bin/luacheck .
```

When the project refactor moves runtime Lua under `src/lua`, these commands
must still work through the updated `./lua` wrapper path.

## LÖVE Gates

Run after moving `main.lua`, `conf.lua`, demos, or Love2D Forge config:

```bash
love src/lua
love src/lua/demos/01-container
love src/lua/demos/03-drawable
```

The main app and representative demos should open without module resolution
errors.

## Documentation Gates

Run after documentation restructure:

```bash
rg "typescript_refactor[.]md"
rg "build[/]tstl|(^|[^/])types[/]lua-interop|src[/]lib[/]ui"
```

Expected results:

- No required reference should point at the removed root
  migration document.
- No setup doc should describe old root build output or root type declarations
  as the target.
- Any rejected TypeScript runtime path mention should be historical or
  explicitly rejected.

## Known Baseline

`./lua_modules/bin/luacheck .` currently reports existing warnings. A setup task
does not need to fix unrelated warnings unless it creates new warnings or moves
files in a way that changes the warning count unexpectedly.

The latest observed baseline was:

```text
125 warnings / 0 errors
```

## Acceptance Criteria

- Every setup task records which gates were run.
- Any skipped gate has a reason.
- New warnings, module resolution errors, or generated tracked files block the
  task.
