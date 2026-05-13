# TypeScriptToLua Setup Refactor

This folder is the setup roadmap for introducing TypeScriptToLua into this
LÖVE UI library. It replaces the old single-file migration note and is focused
on project structure, tooling, typed Lua externals, build boundaries, and
validation gates.

This is not the full migration plan. Do not lay out or start individual module
ports here. The first milestone is a project refactor that makes source layout
unambiguous before any runtime module is converted.

## Current Status

- TypeScriptToLua tooling is installed through npm.
- `tsconfig.json` is root-level tooling metadata.
- Authored TypeScript is reserved for `src/ts`.
- Type declarations live in `src/types`.
- TSTL validation output is ignored under `src/generated/tstl`.
- Runtime Lua and runtime assets live under `src/lua`.

## Target Setup Shape

All code should eventually be contained under `src`.

```text
src/
  lua/             # Handwritten and reviewed runtime Lua
  ts/              # Authored TypeScript migration source
  types/           # Type declarations, including Lua externals
  generated/tstl/  # Ignored TypeScriptToLua validation output
```

Root is reserved for tooling metadata, package manifests, docs, scripts, and
wrappers. Runtime Lua and runtime assets belong under `src/lua`.

## Setup Tasks

1. [Project Refactor](00-project-refactor.md)
   Move runtime code and assets into the `src/lua` boundary and update tooling
   that assumes root-level Lua paths.
2. [TypeScript Tooling](01-typescript-tooling.md)
   Keep the TSTL project isolated to `src/ts`, `src/types`, and
   `src/generated/tstl`.
3. [Lua External Types](02-lua-external-types.md)
   Define typed declarations for permanent handwritten Lua externals.
4. [Build And Packaging Boundaries](03-build-and-packaging-boundaries.md)
   Keep generated Lua, reviewed runtime Lua, and release packaging roles clear.
5. [Validation Gates](04-validation-gates.md)
   Define the checks required before each setup step is accepted.
6. [Deferred Migration Work](05-deferred-migration-work.md)
   Record what is deliberately out of scope until setup is stable.
   Future migration candidates should use the
   [intake template](future-migration-intake-template.md) after setup is
   accepted.

## Setup Acceptance

The setup phase is complete when:

- All runtime Lua code has a documented path into `src/lua`.
- TypeScript source, declarations, and generated output are isolated under
  `src`.
- Permanent Lua externals are typed without being ported.
- Existing Lua demos and specs still run from the documented launch paths.
- TSTL checks pass without writing generated code into runtime source paths.
