# TypeScriptToLua Migration Plan

## Current Baseline

This repository is currently a LuaJIT/LÖVE UI library with handwritten Lua under `lib/ui`, demo apps under `demos`, LuaUnit specs under `spec`, and LuaRocks packaging in `lua-ui-library-0.1-1.rockspec`. These root-level Lua paths are the current state, not the target TypeScript migration shape. The first TypeScriptToLua setup is intentionally additive: existing Lua remains the runtime source, and TypeScript output is emitted to `src/generated/tstl` until converted modules pass parity checks.

TypeScriptToLua is installed locally through npm so builds are reproducible per checkout. The initial config follows the upstream TypeScriptToLua guidance for a root `tsconfig.json`, `target: "ESNext"`, `lib: ["ESNext"]`, and `luaTarget: "JIT"` for the LÖVE/LuaJIT runtime. LÖVE declarations are included through `love-typescript-definitions`.

References:

- TypeScriptToLua getting started: https://typescripttolua.github.io/docs/getting-started
- TypeScriptToLua configuration: https://typescripttolua.github.io/docs/configuration
- TypeScriptToLua self parameter behavior: https://typescripttolua.github.io/docs/the-self-parameter
- LÖVE declarations package: https://www.npmjs.com/package/love-typescript-definitions

## Installed Tooling

- `typescript`
- `typescript-to-lua`
- `@typescript-to-lua/language-extensions`
- `love-typescript-definitions`

Useful scripts:

- `npm run build:ts` transpiles TypeScript with `tstl -p tsconfig.json`.
- `npm run watch:ts` runs the transpiler in watch mode.
- `npm run list:ts` prints the files TypeScript sees, useful while growing declarations.
- `npm run check:lua` keeps the existing Lua lint path visible from npm.

## Target Repository Shape

The migration should isolate all code under `src`. Root-level files and directories remain for tooling metadata, docs, assets, package manifests, scripts, and current-state Lua until the later physical reorganization pass.

```text
src/
  ts/              # Authored TypeScript migration source
  types/           # Type declarations, including Lua externals
  lua/             # Handwritten Lua source during/after repo reorganization
  generated/tstl/  # Ignored TSTL validation output
```

Current root paths such as `lib/`, `demos/`, `spec/`, `profiler/`, `scenes/`, `main.lua`, and `conf.lua` should be treated as temporary compatibility paths. Do not point TSTL directly at `lib/ui` or `src/lua` until module-level parity is proven. Generated code should first live under `src/generated/tstl` so diffs are easy to inspect and the current LuaRocks module map cannot be broken by an early conversion.

## Permanent Lua Externals

Some existing Lua modules are intentionally optimized around LuaJIT behavior, shared metatables, hidden table keys, raw table access, bit masks, or broad validation contracts. These modules should not be ported to TypeScript as part of the migration. They remain handwritten Lua sources of truth, and TypeScript source consumes them through ambient `.d.ts` declarations only.

Permanent external modules:

- `lib/ui/utils/reactive.lua`
- `lib/ui/utils/dirty_props.lua`
- `lib/ui/utils/memoize.lua`
- `lib/ui/utils/schema.lua`
- `lib/ui/utils/rule.lua`

Declarations for these modules should live under `src/types/lua-interop` and use the exact Lua require names:

```ts
import Rule = require("lib.ui.utils.rule");
import Schema = require("lib.ui.utils.schema");
```

Use `export =` for Lua modules that return tables. Use `this: void` for module functions called with dot syntax, and TypeScript instance interfaces for colon-call Lua methods such as `schema:get_rules()` or `props:sync_dirty_props()`. Declarations should describe the stable public contract only; do not expose private sentinels, hidden accessor keys, validator dispatch tables, or other performance internals.

## Migration Strategy

1. Establish compile-only TypeScript infrastructure.
   - Keep `tsconfig.json` root-based, but restrict source inclusion to `src/ts` and `src/types`.
   - Use `luaTarget: "JIT"` for LÖVE's LuaJIT runtime.
   - Keep `noImplicitSelf: true` for ordinary implemented functions, then use explicit `this` annotations only where Lua colon calls are required.
   - Keep `luaLibImport: "require-minimal"` to limit runtime helpers.

2. Add interop declarations before moving runtime code.
   - Declare existing Lua modules as TypeScript module shapes in `src/types/lua-interop`.
   - Start with public API modules used by demos: `ui.init`, `ui.core.container`, `ui.core.drawable`, `ui.core.shape`, layout modules, render modules, and controls.
   - Declare permanent Lua externals before migrating modules that depend on them.
   - Model tuple returns with `@tupleReturn` where Lua returns multiple values.
   - Avoid declaring broad `any` APIs unless the current Lua contract is genuinely dynamic.

3. Convert low-risk leaf modules first.
   - Good candidates: constants, enums, easing functions, insets, color helpers, simple render placement helpers, and declarative `*_schema.lua` modules.
   - Do not convert the permanent Lua externals listed above unless they are explicitly reclassified later.
   - Avoid the rest of `lib/ui/utils` initially. Project convention currently marks utilities as protected; migrating them should be a separate explicit approval because they are shared by most modules.
   - Avoid hot path render/layout classes until output shape and allocation behavior have been reviewed.

4. Run module-level parity checks for each conversion.
   - Preserve Lua require names, public tables, exported constructors, constants, and enum atom identity.
   - Add or update LuaUnit specs before replacing a handwritten module.
   - For each converted module, compare generated Lua shape with existing module behavior using `./lua -e 'require("...")'` smoke checks and targeted specs.
   - Run `./lua_modules/bin/luacheck .` after any Lua output is promoted.

5. Promote generated Lua only after passing parity.
   - Option A: emit converted modules into `src/generated/tstl`, copy reviewed output into the current runtime Lua path, and keep generated Lua committed for LuaRocks/LÖVE consumers.
   - Option B: later change TSTL `outDir` to emit directly into `src/lua` once the whole package is TypeScript-owned and generation is reliable.
   - Whichever option is chosen, make LuaRocks packaging consume the final Lua output and keep npm build scripts as a required release step.

6. Migrate demos after the library surface is stable.
   - Keep current Lua demos running as acceptance fixtures while core modules move.
   - Convert demos last because they exercise broad API surfaces and will expose declaration gaps naturally.

## Module Order

Suggested first pass:

1. `lib/ui/core/constants.lua` and `lib/ui/core/enums.lua`
2. `lib/ui/core/easing.lua`, `insets.lua`, and simple geometry helpers
3. `lib/ui/render/color.lua`, `source_placement.lua`, and validation helpers
4. Declarative `*_schema.lua` modules with limited behavior, excluding `lib/ui/utils/schema.lua` and `lib/ui/utils/rule.lua`
5. Leaf shape/render modules
6. Layout primitives
7. Controls
8. Scene, motion, and demo entry points

## Compatibility Rules

- Preserve current Lua module names. Existing callers should continue to `require('ui.core.container')`, not a TypeScript-specific path.
- Permanent Lua externals should be imported from TypeScript using their exact current require names, such as `lib.ui.utils.rule`.
- Preserve atom identity by importing shared constants instead of recreating literal values.
- Keep generated Lua compatible with LuaJIT/Lua 5.1 semantics used by LÖVE.
- Prefer explicit TypeScript interfaces for public properties and schema values. Avoid making TypeScript classes mirror `cls` internals until the class construction pattern is chosen.
- Keep declarations for permanent externals strict enough to catch missing exports. Do not add catch-all `any` fields for convenience.
- Do not use TypeScript features that create heavy runtime helpers in hot paths without profiling.

## Open Decisions

- Whether release artifacts should commit generated Lua or generate it during packaging.
- Whether converted modules should use idiomatic TypeScript classes, factory tables, or a typed wrapper around the existing `cls` pattern.
- Whether generated release Lua should eventually live in `src/lua` or be copied into package-only output during release.
- How much of the current LuaRocks rockspec should be generated from the TypeScript source graph once migration is underway.

## First Milestone

Convert one low-risk module and keep the rest of the repo unchanged:

1. Add declarations for the module's existing dependencies.
2. Implement the TypeScript equivalent under `src/ts/...`.
3. Build to `src/generated/tstl`.
4. Diff the generated Lua against the current handwritten module for API shape and side effects.
5. Add or update focused specs.
6. Promote the generated Lua only after `npm run build:ts`, `./lua -e 'require("...")'`, and `./lua_modules/bin/luacheck .` pass.
