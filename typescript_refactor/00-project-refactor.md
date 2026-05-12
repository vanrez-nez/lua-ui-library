# 00 - Project Refactor

## Goal

Make the repository structure clear before any TypeScript module migration
starts. Runtime Lua code and runtime assets should move behind a single source
boundary: `src/lua`. TypeScript source, TypeScript declarations, and generated
output already have their own `src` subtrees and should stay separate.

This task is setup only. It does not port Lua modules to TypeScript and does
not replace handwritten Lua with generated Lua.

## Target Runtime Layout

Move runtime Lua code into this shape:

```text
src/lua/
  conf.lua
  main.lua
  assets/
  lib/
    cls/
    ui/
  demos/
  profiler/
  scenes/
  spec/
```

Keep root-level tooling and non-runtime docs/config at root:

```text
README.md
docs/
scripts/
lua
luarocks
lua-ui-library-0.1-1.rockspec
package.json
package-lock.json
tsconfig.json
```

## Required Changes

1. Move runtime Lua directories and entry files into `src/lua`.
   - Move `lib` to `src/lua/lib`.
   - Move `demos` to `src/lua/demos`.
   - Move `spec` to `src/lua/spec`.
   - Move `profiler` to `src/lua/profiler`.
   - Move `scenes` to `src/lua/scenes`.
   - Move `assets` to `src/lua/assets` so `love src/lua` can resolve
     existing `assets/...` runtime paths directly.
   - Move `main.lua` to `src/lua/main.lua`.
   - Move `conf.lua` to `src/lua/conf.lua`.
   - Do not move `lua_modules`, `.luarocks`, `external`, `tmp`, or generated
     output.

2. Preserve Lua require names during the move.
   - `require('lib.ui...')` must continue to work while source uses the
     compatibility `lib.*` namespace.
   - `require('spec...')`, `require('scenes...')`, and demo-local requires
     must continue to resolve from `src/lua`.
   - Update the `./lua` wrapper package path to include:
     - `root .. "/src/lua/?.lua"`
     - `root .. "/src/lua/?/init.lua"`
   - Keep LuaRocks module names as `ui.*` unless a later packaging task changes
     the public package namespace.

3. Update direct LÖVE launch expectations.
   - The intended app launch target becomes `love src/lua`.
   - Root `love .` should no longer be treated as the canonical runtime launch
     path once this refactor is complete.
   - Demo launch docs and Love2D Forge configuration should point at
     `src/lua/demos/...`.

4. Update tooling paths.
   - `.luacheckrc` should lint `src/lua` runtime code and continue excluding
     dependency, generated, vendor, temp, and output paths.
   - `.love2d-forge/config.json` should watch and launch paths under
     `src/lua`.
   - `README.md` commands should reference `src/lua/spec...` where needed only
     if require names change; otherwise keep require names stable and document
     the wrapper path behavior.
   - Any scripts that assume `lib`, `demos`, `spec`, `profiler`, or `scenes`
     at root must be updated to use `src/lua`.

5. Update LuaRocks packaging paths.
   - The rockspec module map should keep public module names unchanged.
   - Each module source path should change from `lib/ui/...` to
     `src/lua/lib/ui/...`.
   - `copy_directories` should keep `docs` only if docs remain part of the
     rock. Do not package `src/ts`, `src/types`, or `src/generated`.

## Non-Goals

- Do not port modules to TypeScript.
- Do not promote generated Lua.
- Do not rename public `require('ui...')` package modules.
- Do not rewrite internal `require('lib.ui...')` imports unless a separate
  namespace decision is made.
- Do not modify protected utility implementations under `lib/ui/utils` beyond
  moving them into `src/lua`.
- Do not keep runtime assets at the repository root; `assets/...` is part of
  the `src/lua` LÖVE source tree after this setup task.

## Acceptance Criteria

- `love src/lua` starts the main LÖVE app.
- `./lua -e 'require("spec.rule_spec").run()'` resolves through `src/lua`.
- `./lua -e 'require("lib.ui.core.container")'` resolves through `src/lua`.
- `./lua_modules/bin/luacheck .` does not lint generated TypeScriptToLua
  output or `node_modules`.
- `npm run list:ts` and `npm run build:ts` still pass.
- Runtime asset references such as `assets/fonts/...` and `assets/images/...`
  resolve under `love src/lua`.
- `rg "lib/ui|demos/|spec/|profiler/|scenes/" README.md scripts .love2d-forge .luacheckrc lua-ui-library-0.1-1.rockspec`
  has no stale root-path assumptions except historical docs or explicitly
  documented compatibility notes.
