---
name: project-love2d
description: "Project-specific conventions for this Love2D UI library. Use alongside lua-love2d for any work in this codebase. Covers lib/cls usage, utils constraints, public API contracts, naming prefixes, error philosophy, and tooling commands."
---

# Project Conventions — Love2D UI Library

---

## Environment

Run after every change before considering work complete:
- `./lua_modules/bin/luacheck .` — fix all warnings and errors.
- `./lua -e <file>` — sanity check on any touched file.

---

## Class Usage (`lib/cls`)

Use `cls` when an abstraction has **identity, state, and lifecycle** — it needs to be instantiated, may be destroyed, and benefits from inheritance or mixins.

Do not use `cls` for:
- Stateless utilities — use a plain module returning a table of functions.
- Objects created in hot-paths — class instantiation allocates a table and calls a constructor; prefer pre-allocated structs or object pools instead.

When unsure: does this thing need `destroy()`? If no, it's probably a module.

---

## Utils

It is forbidden to modify, expand, or replace files under `lib/ui/utils` without explicit permission.

**Generic utils**
- Type checks and assertions: use `lib/ui/utils/types.lua` and `lib/ui/utils/assert.lua`.
- Common math operations: reuse `lib/ui/utils/math.lua`.

---

## Public Library Classes

For classes where the Specification mandates a specific property API:
1. Use Rule and Schema helpers under `self.schema`.
2. Properties must be scoped under `self.props`.
3. Dirty tracking must use the `DirtyProps` class — do not implement custom dirty flags.

---

## Naming Prefixes

Naming is documentation. Prefer names that express purpose scoped to their context — in a `World` class, write `on_update` not `on_world_update`. Don't over-specify: `process_pending_queued_render_update_request` is noise.

**State queries** — return bool, no side effects
- `is_`: current state — `is_visible`, `is_open`, `is_selected`
- `can_`: capability or permission — `can_focus`, `can_edit`
- `has_`: ownership or presence — `has_data`, `has_children`
- `supports_`: platform/feature capability — `supports_alpha`
- `uses_`: active implementation strategy — `uses_native_presentation`

**Events and hooks**
- `on_`: event callback — `on_changed`, `on_viewport_change`
- `before_` / `after_`: lifecycle hooks flanking an action — `before_change`, `after_draw`
- `do_`: internal/overridable dispatch point — `do_click`, `do_paint`

**Lifecycle**
- `create_` / `destroy_`: construction and teardown
- `open_` / `close_`: modal or resource lifecycle
- `show_` / `hide_`: visibility

**Collection mutation**
- `add_`, `insert_`, `remove_`, `delete_`, `clear_`

**Persistence and lookup**
- `load_` / `save_`: persistence
- `apply_`: style, theme, placement, or effect application
- `find_`: lookup expected to succeed — errors or asserts if not found
- `try_find_`: fallible lookup, returns nil on failure

**Computation and invalidation**
- `calc_`: derive a value or geometry (use this, not `calculate_`)
- `update_`: recompute and apply
- `invalidate_`: mark dirty, defer recomputation
- `refresh_`: force recompute from current state
- `repaint_`: trigger visual redraw only, no layout
- `realign_`: recompute layout or position
- `resize_`: recompute dimensions

**Accessors**
- `get_` / `set_`: only when the property noun alone is ambiguous or when the getter/setter has meaningful side effects. Otherwise prefer the noun directly.

**Scoped paired operations**
- `begin_` / `end_`: bracket a stateful scope — `begin_update` / `end_update`

---

## rawset / rawget

Use only in two contexts:
1. Inside a metamethod body (`__index`, `__newindex`) to avoid infinite recursion.
2. Inside a constructor where the metatable is already attached and `__newindex` would fire prematurely.

Never use to skip validation, change-tracking, or as a micro-optimization. If you reach for it outside these two contexts, the real problem is a missing method or a rigid constructor API. Leave a comment explaining why normal access cannot be used.

---

## Error Handling Philosophy

Let errors surface naturally. Do not reshape or suppress failures from bad callers.

**Use `assert()` with a message only when:**
- The function is public API called across module boundaries.
- The failure mode is non-obvious and the native error would mislead.

**No assert, no guard when:**
- The caller is internal — a wrong argument will produce a Lua error anyway.
- The check would live in a hot path — guards have real cost under LuaJIT.
- The error message would just restate what Lua already says.

**Never:**
- Silently return `nil`/`false` to swallow a programming error.
- Add defensive fallbacks that hide bugs from the caller.
- Wrap internal errors in `pcall` unless recovery is meaningful.

A nil dereference in internals is not a bug to catch — it is the error. The stack trace is the message.
