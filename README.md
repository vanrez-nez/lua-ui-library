# Lua UI Library

## Testing

Run the current headless spec module with the project LuaJIT wrapper:

```bash
./lua -e 'require("spec.rule_spec").run()'
```

Runtime Lua code lives under `src/lua`. The `./lua` wrapper adds that directory
to `package.path`, so existing module names such as `spec.*`, `lib.ui.*`, and
`profiler.*` continue to resolve from the repository root.

Smoke-check LuaUnit availability:

```bash
./lua -e 'local luaunit = require("luaunit"); print(luaunit.VERSION or "luaunit ok")'
```

LuaUnit is installed as a project-local development dependency for new tests.
Existing specs are not migrated to LuaUnit yet.

## Tooling

Install the system bootstrap tools:

```bash
brew install luarocks luajit
```

Initialize the LuaRocks project files for LuaJIT/Lua 5.1:

```bash
luarocks --lua-version=5.1 init --lua-versions=5.1 lua-ui-library 0.1
```

Use the project wrappers from the repository root:

```bash
./lua -v
./luarocks --version
```

Install project-local development rocks:

```bash
./luarocks install luacheck
./luarocks install luaunit
```

Verify installed rocks:

```bash
./luarocks list
```

Run Luacheck:

```bash
./lua_modules/bin/luacheck .
```

The Luacheck configuration targets LuaJIT and excludes generated, vendor, output,
and ignored manual-test paths.

Run the LÖVE app:

```bash
love src/lua
```

Run a focused demo from its `src/lua` app directory:

```bash
love src/lua/demos/03-drawable
```

Root `love .` is not the canonical runtime target after the TypeScriptToLua
setup refactor.

## Build and Packaging Boundaries

TypeScriptToLua output is validation and review output only. `npm run build:ts`
writes to ignored `src/generated/tstl`; generated Lua is not runtime source
until a later explicit promotion step reviews and moves it into `src/lua`.

LuaRocks packaging consumes reviewed Lua from `src/lua/lib` through the
rockspec module map. It must not package `src/ts`, `src/types`,
`src/generated`, dependency directories, or temporary output.

Check those boundaries with:

```bash
npm run check:boundaries
```

Run the non-GUI setup validation gates with:

```bash
npm run check:setup
```

This includes TypeScript checks, Lua module smoke checks, stale documentation
path checks, packaging boundary checks, and the current Luacheck baseline.
