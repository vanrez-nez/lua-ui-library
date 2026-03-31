## Installation

Drop `cls.lua` into your project and require it:

```lua
local Object = require "cls"
```

---

## Core Concepts

classic uses **prototype-based inheritance**. Classes are plain Lua tables. Instances are tables whose metatable points to their class. Method lookup walks the metatable chain — no methods are copied per instance.

```
Instance  -->  Class  -->  Parent  -->  Object
 (table)   __index   __index    __index
```

This means:
- Instantiation is O(1): `setmetatable({}, Class)`
- One metatable is shared across all instances of the same class
- **Table fields defined at class level are shared across all instances** (see [Shared State Footgun](#shared-state-footgun))

---

## API

### `Object:extends(name)`

Creates a new subclass. `name` is optional but strongly recommended — it appears in `tostring()` output and aids debugging.

```lua
local Animal = Object:extends("Animal")

function Animal:constructor(name, sound)
  self.name  = name
  self.sound = sound
end

function Animal:speak()
  print(self.name .. " says " .. self.sound)
end

local cat = Animal("Luna", "meow")
cat:speak()  --> Luna says meow
```

Subclasses can extend other subclasses:

```lua
local Dog = Animal:extends("Dog")

function Dog:constructor(name)
  Animal.constructor(self, name, "woof")  -- call parent constructor explicitly
  self.tricks = {}
end

function Dog:learnTrick(trick)
  table.insert(self.tricks, trick)
end

local d = Dog("Rex")
d:speak()         --> Rex says woof
d:learnTrick("sit")
```

---

### `Object:constructor(...)`

The initializer called when a new instance is created. Override in each class. **Super constructors are not called automatically** — call them explicitly when needed.

```lua
local Vehicle = Object:extends("Vehicle")

function Vehicle:constructor(speed)
  self.speed = speed
end

local Car = Vehicle:extends("Car")

function Car:constructor(speed, brand)
  Vehicle.constructor(self, speed)  -- explicit super call
  self.brand = brand
end

local c = Car(120, "Toyota")
print(c.speed, c.brand)  --> 120   Toyota
```

If you forget the super call, the parent's initialization simply does not run. No error is raised.

---

### `Object:implements(...)`

Copies methods from one or more mixin tables into the class. Only copies methods not already defined on the class. **Shallow only**: methods the mixin itself inherited are not included.

```lua
local Serializable = {}

function Serializable:serialize()
  local parts = {}
  for k, v in pairs(self) do
    parts[#parts+1] = k .. "=" .. tostring(v)
  end
  return table.concat(parts, ", ")
end

local Player = Object:extends("Player")
Player:implements(Serializable)

function Player:constructor(name, hp)
  self.name = name
  self.hp   = hp
end

local p = Player("Ivan", 100)
print(p:serialize())  --> hp=100, name=Ivan
```

Existing methods are never overwritten:

```lua
local Logger = {}
function Logger:serialize() return "LOGGER VERSION" end

-- Player already has :serialize() from Serializable above
Player:implements(Logger)

print(p:serialize())  --> hp=100, name=Ivan  (Logger version ignored)
```

#### Shallow copy tradeoff

`implements` only sees the mixin's **own** keys — not methods the mixin inherited from its own parent:

```lua
local Base = {}
function Base:baseMethod() return "base" end

local Mixin = setmetatable({}, { __index = Base })
function Mixin:ownMethod() return "own" end

local MyClass = Object:extends("MyClass")
MyClass:implements(Mixin)

local obj = MyClass()
obj:ownMethod()   -- works
obj:baseMethod()  -- ERROR: method not found
```

If you need the full interface, flatten it manually or pass both tables:

```lua
MyClass:implements(Mixin, Base)
```

---

### `Object:instanceOf(T)`

Returns `true` if the object was instantiated **directly** from `T`. Does not match parent classes.

```lua
local Animal = Object:extends("Animal")
local Dog    = Animal:extends("Dog")

local d = Dog()

print(d:instanceOf(Dog))     --> true
print(d:instanceOf(Animal))  --> false  (use derivedFrom for this)
print(d:instanceOf(Object))  --> false
```

---

### `Object:derivedFrom(T)`

Returns `true` if `T` appears **anywhere** in the prototype chain. Use this for general type checks.

```lua
local Animal = Object:extends("Animal")
local Dog    = Animal:extends("Dog")
local Poodle = Dog:extends("Poodle")

local p = Poodle()

print(p:derivedFrom(Poodle))  --> true
print(p:derivedFrom(Dog))     --> true
print(p:derivedFrom(Animal))  --> true
print(p:derivedFrom(Object))  --> true

-- also works on class tables (not just instances)
print(Poodle:derivedFrom(Animal))  --> true
```

#### `instanceOf` vs `derivedFrom`

| | `instanceOf(T)` | `derivedFrom(T)` |
|---|---|---|
| Direct class only | ✅ | ❌ |
| Full chain | ❌ | ✅ |
| Use for | Exact dispatch, factory logic | General type guards |

---

### `tostring(obj)`

Returns the class name. Works correctly for both instances and class tables.

```lua
local Enemy = Object:extends("Enemy")
local e = Enemy()

print(tostring(e))      --> Enemy
print(tostring(Enemy))  --> Enemy

-- unnamed class
local Anon = Object:extends()
print(tostring(Anon))   --> ?
```

---

## Metamethod Inheritance

Metamethods are copied explicitly to each subclass on `extends()`. This is necessary because Lua resolves metamethods directly in the metatable — they are never reached through `__index`.

Define metamethods on a class and they will propagate to all subclasses that don't override them:

```lua
local Vec = Object:extends("Vec")

function Vec:constructor(x, y)
  self.x, self.y = x, y
end

function Vec:__add(other)
  return Vec(self.x + other.x, self.y + other.y)
end

function Vec:__tostring()
  return "(" .. self.x .. ", " .. self.y .. ")"
end

local Vec3 = Vec:extends("Vec3")

function Vec3:constructor(x, y, z)
  Vec.constructor(self, x, y)
  self.z = z
end

-- Vec3 inherits __add from Vec automatically via extends()
local a = Vec(1, 2)
local b = Vec(3, 4)
local c = a + b
print(tostring(c))  --> (4, 6)
```

---

## Known Limitations and Footguns

### Shared State Footgun

**The most common mistake.** Table fields defined at class level are shared across all instances through the metatable chain:

```lua
local Inventory = Object:extends("Inventory")
Inventory.items = {}  -- SHARED across all instances

function Inventory:addItem(item)
  table.insert(self.items, item)  -- mutates the CLASS-level table
end

local a = Inventory()
local b = Inventory()

a:addItem("sword")
print(#b.items)  --> 1  (b sees a's item — this is almost never what you want)
```

**Fix**: always reinitialize table fields in `constructor`:

```lua
function Inventory:constructor()
  self.items = {}  -- each instance gets its own table
end

local a = Inventory()
local b = Inventory()
a:addItem("sword")
print(#b.items)  --> 0  (correct)
```

This applies to **any mutable table field**. Primitive values (numbers, strings, booleans) are safe at class level since assignment to an instance writes a new key onto the instance table, shadowing the class-level value.

---

### No Automatic Super Constructor Chaining

classic does not call parent constructors automatically. If your hierarchy has multiple levels, you are responsible for threading the calls:

```lua
local A = Object:extends("A")
function A:constructor() self.a = true end

local B = A:extends("B")
function B:constructor()
  A.constructor(self)   -- must be explicit
  self.b = true
end

local C = B:extends("C")
function C:constructor()
  B.constructor(self)   -- must be explicit
  self.c = true
end

local obj = C()
print(obj.a, obj.b, obj.c)  --> true  true  true
```

If a level is skipped, that ancestor's initialization silently does not run.

---

### `implements` is Shallow

Mixin inheritance chains are not walked. Only methods defined directly on the passed table are copied. See [`implements` tradeoff](#shallow-copy-tradeoff) above.

---

### No Field Declaration or Enforcement

classic has no mechanism to declare expected fields, enforce constructor initialization, or detect the shared-state footgun at runtime. These are documentation and convention concerns.

---

## Full Usage Example

```lua
local Object = require "classic"

-- Base class
local Entity = Object:extends("Entity")

function Entity:constructor(x, y)
  self.x      = x
  self.y      = y
  self.active = true
end

function Entity:update(dt) end
function Entity:destroy() self.active = false end

-- Mixin
local Damageable = {}

function Damageable:takeDamage(amount)
  self.hp = self.hp - amount
  if self.hp <= 0 then self:destroy() end
end

-- Subclass
local Enemy = Entity:extends("Enemy")
Enemy:implements(Damageable)

function Enemy:constructor(x, y, hp)
  Entity.constructor(self, x, y)
  self.hp    = hp
  self.drops = {}        -- initialized here, not at class level
end

function Enemy:addDrop(item)
  table.insert(self.drops, item)
end

-- Further subclass
local Boss = Enemy:extends("Boss")

function Boss:constructor(x, y)
  Enemy.constructor(self, x, y, 500)
  self.phase = 1
end

function Boss:takeDamage(amount)
  -- override: reduce damage in phase 1
  local actual = self.phase == 1 and amount * 0.5 or amount
  Damageable.takeDamage(self, actual)
end

-- Type checks
local b = Boss(0, 0)

print(b:instanceOf(Boss))    --> true
print(b:instanceOf(Enemy))   --> false
print(b:derivedFrom(Enemy))  --> true
print(b:derivedFrom(Entity)) --> true
print(b:derivedFrom(Object)) --> true
print(tostring(b))           --> Boss

b:takeDamage(100)
print(b.hp)  --> 450  (phase 1 reduction applied)
```