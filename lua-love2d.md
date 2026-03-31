---
name: lua-love2d
description: "Foundational reference for Lua 5.1 + Love2D game development. Use this skill whenever writing, debugging, or reviewing Lua code in a Love2D project — including table operations, OOP patterns, module organization, lifecycle wiring, and error handling. Also trigger for any Love2D-specific questions about conf.lua, callbacks, asset loading, or the error screen. If the user is writing Lua at all, consult this."
---

# Lua 5.1 + Love2D — Foundational Reference

---

## 1. Tables

Tables are Lua's **only** data structure (§2.2). Variables hold references, never copies. Two tables with identical contents are never `==` (§2.5.2).

### Constructor forms (§2.5.7)
```lua
t = {
  [expr] = val,   -- explicit key
  name  = val,    -- sugar for ["name"]
  val,            -- sequential key, starts at 1
}
```
Last positional field: if it's a function call or `...`, all return values expand. Wrap in `()` to suppress.

### Key mechanics
- `t.foo` is sugar for `t["foo"]`. `t[foo]` uses variable `foo`. Numeric keys require `t[1]`, never `t.1`.
- **`#t` is undefined if the array has nil holes.** Only reliable on sequences with no gaps.
- `ipairs` stops at the first nil. `pairs` visits all keys in unspecified order.
- Setting a key to `nil` deletes it. You cannot store `nil` as a value.

### `ipairs` vs `pairs`
```lua
local t = {10, 20, nil, 40, x = "hi"}
for i, v in ipairs(t) do end  -- stops at i=2
for k, v in pairs(t) do end   -- all 4 entries, any order
```
During `pairs`: modifying existing keys is safe; **assigning new keys is undefined** (§5.1, `next`).

### Table library (§5.5)
| Function | Notes |
|---|---|
| `table.insert(t, v)` | Append at `#t+1` |
| `table.insert(t, pos, v)` | Insert, shift up |
| `table.remove(t [, pos])` | Remove, shift down, returns removed |
| `table.sort(t [, comp])` | In-place, **not stable** |
| `table.concat(t, sep, i, j)` | Join array portion |

### OOP via metatables (§2.8)
`__index` fires on nil lookup. If it's a table, Lua recurses into it.
```lua
local Entity = {}
Entity.__index = Entity

function Entity.new(x, y)
  return setmetatable({x=x, y=y, hp=100}, Entity)
end

function Entity:takeDamage(d) self.hp = self.hp - d end
-- e:takeDamage(25)  →  Entity.takeDamage(e, 25)
```
`rawget`/`rawset` bypass all metamethods.
**`__len` does NOT work for tables in Lua 5.1** (userdata only). Fixed in 5.2+.
**`__newindex`** fires only for *new* keys, not updates to existing ones.

### Pitfalls
- `t[0]` is valid but invisible to `#`, `ipairs`, and the table library.
- `table.sort` is not stable — equal elements may reorder.
- `{1,2} == {1,2}` → `false` (reference equality).

---

## 2. Modules

### `require` caching (§5.3)
`require(mod)` checks `package.loaded[mod]` first — the module file runs **exactly once**. Force reload: `package.loaded["foo"] = nil`.

Dots become path separators: `require("src.player")` → `src/player.lua`.
`require("mylib")` also matches `mylib/init.lua` via `?/init.lua` template.

### Canonical module pattern (`module()` is deprecated)
```lua
-- src/player.lua
local Player = {}
Player.__index = Player
local SPEED = 200   -- private

function Player.new(x, y)
  return setmetatable({x=x, y=y}, Player)
end

function Player:update(dt)
  if love.keyboard.isDown("right") then self.x = self.x + SPEED * dt end
end

function Player:draw()
  love.graphics.rectangle("fill", self.x, self.y, 32, 32)
end

return Player
```
Pure-function variant:
```lua
-- utils.lua
local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end
return { clamp = clamp }
```

### Love2D lifecycle order
```
conf.lua (love.conf)  →  love.load(args)  →  [loop: event dispatch → love.update(dt) → love.draw()]
```
- **`conf.lua`** runs before modules load — set window size, title, disable unused modules there.
- `love.update(dt)`: use `x = x + speed * dt` for frame-rate-independent movement.
- `love.draw()`: all rendering here, after update.

```lua
-- conf.lua
function love.conf(t)
  t.window.width  = 1280
  t.window.height = 720
  t.window.title  = "Game"
  t.modules.physics = false
end
```

### Wiring modules into main.lua
```lua
local Player = require("src.player")
local player

function love.load()   player = Player.new(100, 100) end
function love.update(dt) player:update(dt) end
function love.draw()   player:draw() end
function love.keypressed(k) if k == "escape" then love.event.quit() end end
```

### Project layout
```
project/
├── main.lua
├── conf.lua
├── src/         -- game modules
├── lib/         -- third-party
└── assets/
    ├── sprites/
    └── sounds/
```
A `.love` file is a `.zip` with `main.lua` at its root.

### Pitfalls
- **Never use globals for modules.** Always `local M = require(...)`. Globals leak and are slower under LuaJIT.
- Shared `require` → shared state. Mutating a required module in one file affects all files that required it.
- `conf.lua` must define `love.conf` — putting it in `main.lua` is too late.

---

## 3. Error Handling

### Primitives (§5.1)
- **`error(msg [, level])`** — throws. `msg` can be any Lua value. `level=0` omits position; `level=2` blames the caller (use in validators).
- **`pcall(f, ...)`** → `true, results...` | `false, errobj`
- **`xpcall(f, handler)`** → calls `handler(errobj)` **before the stack unwinds** — the only place `debug.traceback` captures the full trace.

```lua
-- Safe asset load
local ok, img = pcall(love.graphics.newImage, "hero.png")
if not ok then print("Load failed: " .. tostring(img)) end

-- Full traceback
local ok, err = xpcall(riskyInit, debug.traceback)
if not ok then print(err) end
```

**Lua 5.1 standard:** `xpcall` takes exactly two args. Wrap extra args in a closure.
**LuaJIT (Love2D):** supports `xpcall(f, handler, arg1, ...)` directly.

### Error objects
```lua
local E = {}; E.__index = E
function E.new(code, msg) return setmetatable({code=code, msg=msg}, E) end
function E:__tostring() return string.format("[%d] %s", self.code, self.msg) end

error(E.new(404, "level3.lua not found"))
```
**Without `__tostring`**, Love2D's error screen shows `"table: 0x..."`.

### `love.errorhandler` (Love2D 11+)
Must **return a function** that drives one frame of the error display loop. Called repeatedly until it returns non-nil.
```lua
function love.errorhandler(msg)
  msg = tostring(msg)
  print(debug.traceback("Error: " .. msg, 2))
  return function()
    love.event.pump()
    for e, a in love.event.poll() do
      if e == "quit" or (e == "keypressed" and a == "escape") then return 1 end
    end
    if love.graphics and love.graphics.isActive() then
      love.graphics.clear(0.35, 0.62, 0.86)
      love.graphics.printf("Error:\n" .. msg, 70, 70, love.graphics.getWidth() - 140)
      love.graphics.present()
    end
    if love.timer then love.timer.sleep(0.1) end
  end
end
```
Love2D ≤ 0.10.x used `love.errhand` with an internal `while` loop instead.

### Pitfalls
- `pcall` catches **everything**, including bugs. Use it for expected failures (I/O, asset loading), not as a blanket try/catch.
- `debug.traceback` is only useful **inside** an `xpcall` handler. After `pcall` returns, that stack is gone.
- `love.errorhandler` is for reporting, not mid-game recovery. Use `pcall`/`xpcall` inside your callbacks for that.

---

## 4. Style Guide

### Naming

`snake_case` for variables, functions, instances. `PascalCase` for factories/classes. `is_`/`has_` prefix for boolean-returning functions. `_` for ignored loop variables.

```lua
-- bad
local OBJEcttsssss = {}
local thisIsMyObject = {}
local c = function() end

-- good
local this_is_my_object = {}
local function do_that_thing() end
local Player = require('player')       -- factory
local function is_evil(n) return n < 100 end
for _, name in pairs(names) do end
```

### Variables

Always `local`. Declare at the top of scope. Never name a parameter `arg`.

```lua
-- bad
superPower = SuperPower()

-- good
local super_power = SuperPower()
```

```lua
-- bad
local function bad()
  test()
  local name = getName()
  if name == 'test' then return false end
  return name
end

-- good
local function good()
  local name = getName()
  test()
  if name == 'test' then return false end
  return name
end
```

### Functions

Prefer `local function foo()` over `local foo = function()`. Validate early and return early. Prefer many small functions over large ones. Never name a parameter `arg`.

```lua
-- bad
local nope = function(name, options, arg) end

-- good
local function yup(name, options, ...)
  if #name < 3 or #name > 30 then return false end
  -- ...
  return true
end
```

### Tables

Use constructor syntax. Define functions outside the literal. Always use `self` as the receiver name.

```lua
-- bad
local player = {}
player.name = 'Jack'
player.attack = function(this) end

-- good
local function attack(self) end

local player = {
  name  = 'Jack',
  class = 'Rogue',
  attack = attack,
}
```

### Strings

Single quotes `''`. Lines > 80 chars: `..` concatenation, not `\` continuation or `[[]]`. Explicit coercion: `tostring(x)` not `x .. ''`, `tonumber(x)` not `x * 1`.

```lua
-- bad
local name = "Bob Parr"
local total = reviewScore .. ''

-- good
local name = 'Bob Parr'
local total = tostring(reviewScore)

-- bad (long string)
local msg = 'This is a super long error that was thrown because of Batman. When you stop to think about how Batman had anything to do with this, you would get nowhere fast.'

-- good
local msg = 'This is a super long error that ' ..
  'was thrown because of Batman. ' ..
  'When you stop to think about ' ..
  'how Batman had anything to do ' ..
  'with this, you would get nowhere fast.'
```

### Conditionals

Use truthiness shortcuts. Prefer positive conditions. Prefer a default value over an else branch.

```lua
-- bad
if name ~= nil then end

-- good
if name then end
```

```lua
-- bad
if not thing then
  -- ...
else
  -- ...
end

-- good
if thing then
  -- ...
else
  -- ...
end
```

```lua
-- bad
local function full_name(first, last)
  local name
  if first and last then
    name = first .. ' ' .. last
  else
    name = 'John Smith'
  end
  return name
end

-- good
local function full_name(first, last)
  local name = 'John Smith'
  if first and last then name = first .. ' ' .. last end
  return name
end
```

Short ternary is fine: `return name or 'Waldo'`.

### Blocks & Whitespace

- **2-space soft tabs.**
- Spaces inside braces `{ one = 1 }`, no spaces inside parens.
- Spaces around operators and after commas.
- One blank line after multiline blocks.
- 80-char line limit; wrap long conditions with indented continuation.
- No trailing whitespace. Empty newline at end of file.

```lua
-- bad
local thing=1
local t = {1,2,3}
if test < 1 and do_complicated_function(test) == false or seven == 8 and nine == 10 then do_other_complicated_function() end

-- good
local thing = 1
local t = { 1, 2, 3 }
if test < 1 and do_complicated_function(test) == false or
    seven == 8 and nine == 10 then
  do_other_complicated_function()
end
```

### Commas & Semicolons

No leading commas. Trailing comma on last item is discouraged. No semicolons — one statement per line.

```lua
-- bad
local thing = { once = 1 , upon = 2 }
local a = 1; local b = 2

-- good
local thing = {
  once = 1,
  upon = 2,
  aTime = 3
}
local a = 1
local b = 2
```

### Modules

Return a table or function. Never write to globals. File name matches module name, lowercase. Modules are singletons — use factories unless it's a pure utility library.

```lua
-- thing.lua
local thing = {}
return setmetatable(thing, {
  __call = function(self, key) print(key) end
})
```