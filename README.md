# Lua UI Library

## Testing

Run the current headless spec module with the project LuaJIT wrapper:

```bash
./lua -e 'require("spec.core_math_spec").run()'
```

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
