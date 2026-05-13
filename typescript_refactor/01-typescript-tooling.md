# 01 - TypeScript Tooling

## Goal

Keep TypeScriptToLua tooling isolated from runtime Lua while setup is in
progress. TypeScript should compile and type-check without emitting into
runtime source directories.

## Current Tooling Contract

Root-level tooling metadata is allowed:

```text
package.json
package-lock.json
tsconfig.json
```

Code and generated artifacts must stay under `src`:

```text
src/ts/              # Authored TypeScript
src/types/           # Declaration files
src/generated/tstl/  # Ignored generated Lua
```

## Required Configuration

`tsconfig.json` should keep these boundaries:

- `compilerOptions.rootDir = "src/ts"`
- `compilerOptions.outDir = "src/generated/tstl"`
- `include = ["src/ts/**/*.ts", "src/types/**/*.d.ts"]`
- `exclude` includes:
  - `node_modules`
  - `lua_modules`
  - `src/generated`
  - `tmp`
  - `external`
  - current or future runtime Lua output paths that should not be treated as
    TypeScript input

TSTL settings should remain conservative:

- `luaTarget = "JIT"` for LÖVE's LuaJIT runtime.
- `luaLibImport = "require-minimal"` to avoid unnecessary helpers.
- `noImplicitGlobalVariables = true`.
- `noImplicitSelf = true`; use explicit `this` annotations only where Lua
  colon-call behavior is needed.
- `sourceMapTraceback = true` with `compilerOptions.sourceMap = true`.

## NPM Scripts

Keep scripts focused on setup validation:

- `npm run build:ts`: run `tstl -p tsconfig.json`.
- `npm run watch:ts`: run the same compiler in watch mode.
- `npm run list:ts`: show TypeScript's input graph for declarations and source.
- `npm run check:lua`: keep the existing Lua lint command discoverable from npm.

## Non-Goals

- Do not add bundling.
- Do not emit directly into `src/lua`.
- Do not add TypeScript source files just to prove the compiler works unless a
  task specifically calls for a type-smoke file.
- Do not commit files under `src/generated/tstl`.

## Acceptance Criteria

- `npm run list:ts` includes files under `src/types`.
- `npm run build:ts` passes with no TypeScript source files present.
- `test ! -d src/generated || find src/generated -type f` prints no files
  after a build unless a later task adds actual TypeScript source.
- `git status --short` does not show generated TSTL output.
