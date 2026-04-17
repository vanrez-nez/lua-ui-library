---
name: lua-love2d
description: "Guidance for Lua 5.1 + Love2D development. Use when writing, debugging, or reviewing any Lua code in a Love2D project — OOP patterns, module semantics, lifecycle wiring, LuaJIT constraints, and error handling direction. Trigger on any Lua or Love2D question."
---

# Lua 5.1 + Love2D — Guidance Reference

For full API surface, refer to:
- Lua 5.1: https://www.lua.org/manual/5.1/
- Love2D: https://love2d.org/wiki/Main_Page

---

## Environment

Development uses the **Love2D Forge** VS Code extension for hot-reload and log routing.
Full setup: https://github.com/vanrez-nez/love2d-forge

**Logging**
Use prefixed `print()` calls — the extension's `inferLogTypes` classifies them automatically in the output channel:
- `print('error: ...')` → ERROR
- `print('warn: ...')` → WARN
- `print('info: ...')` → INFO
- `print('debug: ...')` → DEBUG
- Unprefixed → INFO

Prefer this over custom log wrappers unless richer context (stack traces, structured data) is needed.

**Love2D MCP**
An MCP server exposing the full LÖVE 12.0 API to AI assistants.
Repo: https://github.com/vanrez-nez/love2d-mcp

When answering Love2D API questions, prefer calling the MCP tools over relying on training data:
- `love2d_search_docs` — fuzzy search across all symbols, use when the exact name is uncertain.
- `love2d_lookup_symbol` — full signature, args, returns, and examples for a known symbol.
- `love2d_update_docs` — fetch latest docs if responses seem stale.

Always use these tools before guessing at signatures, argument order, or return values. The bundled docs target LÖVE 12.0 — do not fall back to memory for version-specific behavior.

---

## Tables

Tables are Lua's only data structure. Variables hold references, never copies — equality checks identity, not content.

**Key access**
- `t.foo` is sugar for `t["foo"]`. `t[foo]` uses the *variable* `foo` as key.
- `t[0]` is valid but invisible to `#`, `ipairs`, and `table.*`.
- `#t` is undefined when the sequence has nil holes — only reliable on gap-free arrays.
- Setting a key to `nil` removes it. `nil` cannot be stored as a value.

**Iteration**
- `ipairs` stops at the first nil — use for ordered sequences.
- `pairs` visits all keys in unspecified order — use for mixed/hash tables.
- During `pairs`: assigning *new* keys is undefined behavior (`next` §5.1). Mutating existing keys is safe.

**Table stdlib** (`table.*`) covers insert, remove, sort, concat — see manual §5.5.
- `table.sort` is **not stable**. Equal elements may reorder.

**Metatables and OOP**
- `__index` fires on nil lookup. Set it to the class table for method inheritance.
- `__newindex` fires only for *new* keys — it does not intercept updates to existing fields.
- `__len` does **not** work on tables — userdata only.
- `rawget`/`rawset` bypass all metamethods — use only inside metamethod bodies to avoid infinite recursion, or in constructors where the metatable is already attached and `__newindex` would fire prematurely. Anywhere else: use normal field access.
- `:` syntax is sugar: `obj:method(a)` → `obj.method(obj, a)`. The implicit first arg is always `self`.

In a constructor, `setmetatable({...}, Class)` with `Class.__index = Class` is the standard delegation pattern.

---

## Modules

`require` checks `package.loaded` first — a module file runs **exactly once**. All callers share the same returned value; mutating it affects every requirer.

- Dots map to path separators: `require('a.b')` → `a/b.lua`.
- `require('foo')` also resolves `foo/init.lua` via the `?/init.lua` template.
- Force reload: `package.loaded['foo'] = nil` before re-requiring.
- `module()` is deprecated — return a table or factory function directly.
- Never assign module results to globals. Always `local M = require(...)`. Globals are slower under LuaJIT and leak across the process.

Two module shapes to choose from:
- **Factory** — returns a class table with a `.new()` constructor. Use when instances need distinct state.
- **Singleton utility** — returns a plain table of functions. Use for stateless helpers.

---

## Love2D Lifecycle

Love2D uses `main.lua` and `conf.lua` for minimal project setup. For the full config API see: https://love2d.org/wiki/Config_Files

Execution order:
```
conf.lua → love.load() → loop[ love.update(dt) → love.draw() ]
```

- `conf.lua` runs before any modules load. Window size, title, and disabling unused modules (`t.modules.*`) go here. Setting these in `main.lua` is too late.
- `love.update(dt)`: all state mutation. Use `dt` scaling for frame-rate-independent movement.
- `love.draw()`: rendering only, after update. No state changes here.
- Input callbacks (`love.keypressed`, `love.mousepressed`, etc.) fire between frames as part of event dispatch.
- Love2D callbacks are globals by convention but can be assigned directly: `love.update = function(dt) ... end`.

For the full callback list: https://love2d.org/wiki/love_(module)

---

## Error Handling

Three primitives: `error()`, `pcall()`, `xpcall()`.

- `error(msg, level)` — `level=2` blames the caller; use this in validators.
- `pcall(f, ...)` — returns `true, results` or `false, errobj`. The stack is gone after it returns.
- `xpcall(f, handler)` — calls `handler(errobj)` *before* the stack unwinds. The only place `debug.traceback` captures a full trace. Under LuaJIT (Love2D), extra args are supported directly; standard Lua 5.1 requires a closure wrapper.

Use `pcall` for expected, recoverable failures (asset loading, I/O). Do not use it as a blanket try/catch — it catches bugs too.

`love.errorhandler` (Love2D 11+) is for crash reporting, not mid-run recovery. It must return a function that drives one render frame per call. See: https://love2d.org/wiki/love.errorhandler

If you throw a table as an error object, define `__tostring` — otherwise the error screen shows `table: 0x...`.

---

## LuaJIT Notes (Love2D runtime)

Love2D runs LuaJIT, not reference Lua 5.1. Differences that matter:

- `xpcall` accepts extra args directly (not standard 5.1 behavior).
- `jit.off(fn)` disables JIT for a specific function — useful when a hot path hits a NYI.
- Common NYI (Not Yet Implemented) JIT paths: `pairs` in tight loops, `string.format` with `%q`, `pcall` with varargs, `select('#', ...)`.
- Accessing upvalues is fast; global access is slower. Always prefer `local` aliases for hot-path globals: `local floor = math.floor`.
- LuaJIT traces inline across module boundaries — `local` function references in hot paths are preferable to repeated table lookups.

For NYI reference: https://luajit.org/extensions.html and the `jit.p` profiler for identifying actual trace aborts.

---

## Code Style

**Naming**
- `snake_case` for variables, functions, instances. `PascalCase` for factories/classes.
- `_` for ignored loop variables.

**Formatting**
- 2-space indentation. No alignment padding — it breaks word wrap.
- One statement per line. No semicolons.
- Spaces around operators and after commas: `a + b`, `f(a, b)`.
- Declare variables individually — no `local a, b = c, d` unless the right side is a multi-return function call.
- Inline tables only for single-attribute literals. Two or more attributes: one per line, trailing comma omitted on last entry.

**Variables**
- Always `local`. Globals persist for the process lifetime and are slower under LuaJIT.
- `require` calls at the top of the file — no lazy requires inside functions.

**Strings**
- Always single quotes `''`.
- Multi-line strings: use `..` concatenation. `[[...]]` only when the content contains single quotes that would require escaping.

**Functions**
- Prefer `local function foo()` over `local foo = function()` — only the former allows recursion.

**Conditionals**
- Use truthiness shortcuts: `if x then`, not `if x ~= nil then`. Remember: only `false` and `nil` are falsy — `0` and `''` are truthy.
- Never use `and`/`or` as a ternary substitute. `cond and a or b` silently returns `b` when `a` is falsy.

```lua
-- wrong
local x, y = 0, 0
local t = { x = 1, y = 2 }
local name = input and input or 'default'
if x ~= nil then ... end

-- correct
local x = 0
local y = 0
local t = {
  x = 1,
  y = 2
}
if not name then name = 'default' end
if x then ... end

-- correct (multi-return)
local x, y = node:get_position()
```

---

## Conventions

**Privacy**
Prefix private fields and functions with a single underscore (`_name`).
This applies to both class members and module-level internals.

**File structure** (top to bottom)
1. Imports
2. Performance aliases — `local abs = math.abs`
3. Module constants and static definitions
4. Constructor / initialization
5. Public API
6. Private methods
7. Low-level helpers (pure functions, no class dependencies)

**Function ordering — caller before callee**
Place high-level functions first. Each function's dependencies appear after it.

**Comments**
The code states what. Comments state why — only when it isn't obvious. If deleting the comment loses no information, delete it.

A comment is warranted when:
- The behavior has a non-obvious precondition or side effect
- A decision looks wrong but is intentional
- Execution order or timing matters in a non-local way
- A workaround exists for an external constraint (engine bug, API limitation)

Use `---@param` / `---@return` only for primitive types (`number`, `boolean`, `string`) and known classes. Do not annotate plain table shapes — they drift and mislead. A missing annotation loses nothing; a wrong one actively misleads.