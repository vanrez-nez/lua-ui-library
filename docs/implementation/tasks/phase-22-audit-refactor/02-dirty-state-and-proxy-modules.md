# Task 02: DirtyState And Proxy Modules

## Goal

Introduce the two foundational utility modules — `DirtyState` and `Proxy` — as verbatim ports of the audit source. Neither module is wired into any class in this task. This establishes the foundation the remaining object-model tasks build on.

## Scope

In scope:

- create `lib/ui/utils/dirty_state.lua` from `audits/dirty_obj.md`
- create `lib/ui/utils/proxy.lua` from `audits/proxy_obj.md`
- add new specs covering every documented slot and method for both modules
- zero changes to any existing class

Out of scope:

- wiring either module into `Container`, `Shape`, or any other class — that work belongs to tasks 05–09
- any behavior change in the existing property pipeline

## Spec anchors

- [audits/dirty_obj.md](/Users/vanrez/Documents/game-dev/lua-ui-library/audits/dirty_obj.md)
- [audits/proxy_obj.md](/Users/vanrez/Documents/game-dev/lua-ui-library/audits/proxy_obj.md)
- Task 00 compliance review — both modules classified as `safe`

## Current implementation notes

- `lib/ui/utils/` currently contains `assert.lua`, `common.lua`, `math.lua`, `matrix.lua`, `schema.lua`, `types.lua`, `vec2.lua`. Neither `dirty_state.lua` nor `proxy.lua` exists.
- The audits provide complete Lua source for both modules. This task ports the source verbatim; any deviation must be justified as a real constraint and recorded in task 11.
- `Proxy` replaces the instance metatable. The new metatable uses the original metatable via a stashed `_pclass` reference for fallthrough reads of methods. Non-declared writes go straight to `rawset(instance, k, v)` on the instance table.
- `Proxy` exposes four hook slots per key: `read` (single function, last registration wins), `pre_write` (ordered list of transforms, runs before store), `on_write` (ordered list, unconditional after store), `on_change` (ordered list, fires after store only when `new ~= old`).

## Work items

- **DirtyState module.** Create `lib/ui/utils/dirty_state.lua` as a verbatim port of the source in `audits/dirty_obj.md`. Constructor `DirtyState({flag_names})` takes an array of flag name strings and initializes each to `false`. Methods: `mark(...)`, `is_dirty(flag)`, `clear(...)`, `clear_all()`, `is_any(...)`, `is_all(...)`. `mark` and `clear` accept a vararg of flag names. `is_any`/`is_all` with no args check all declared flags.
- **Proxy module.** Create `lib/ui/utils/proxy.lua` as a verbatim port of the source in `audits/proxy_obj.md`. Exposes `Proxy.declare(instance, key, opts)`, `Proxy.on_read`, `Proxy.on_pre_write`, `Proxy.on_write`, `Proxy.on_change`, `Proxy.off_change`, `Proxy.raw_set`, `Proxy.raw_get`, `Proxy.is_installed`. Internal storage keys: `_pdata` (backing values), `_phooks` (per-key hook tables), `_pclass` (stashed original metatable). `install(instance)` is idempotent.
- **DirtyState spec.** Create `spec/utils/dirty_state_spec.lua` covering: construction with a flag list, `mark` single and vararg, `is_dirty` returning correct boolean, `clear` single and vararg, `clear_all`, `is_any` with and without args, `is_all` with and without args, silent write of undeclared flag name (current audit behavior; the audit notes an optional assertion for stricter checking that is explicitly out of scope for this task).
- **Proxy spec.** Create `spec/utils/proxy_spec.lua` covering:
  - `install` is idempotent (calling `declare` multiple times installs only once)
  - non-declared reads return `_pclass[k]` fallthrough (method lookup on the original class still works)
  - non-declared writes go via `rawset` and do not trigger hooks
  - `declare` with `opts.default` fires the full write pipeline exactly once (so `pre_write` and `on_change` see the default)
  - `on_read` is single-slot, last registration wins
  - `pre_write` is an ordered list; each transform may return a new value that the next transform receives
  - `on_write` is an ordered list; every registered function runs after store unconditionally
  - `on_change` is an ordered list; every registered function runs after store only when `new ~= old`
  - `off_change` removes by function identity and is a no-op for unknown functions
  - `raw_set` bypasses `pre_write`, `on_write`, and `on_change`
  - `raw_get` returns the backing value without running `on_read`
  - `is_installed` reports `false` before any declare and `true` after

## File targets

- `lib/ui/utils/dirty_state.lua` (new)
- `lib/ui/utils/proxy.lua` (new)
- `spec/utils/dirty_state_spec.lua` (new)
- `spec/utils/proxy_spec.lua` (new)

## Testing

Required runtime verification:

- none; neither module is wired into runtime code in this task.

Required spec verification:

- the two new spec files pass
- full existing `spec/` suite remains green (no file in `lib/ui/` changed)

## Acceptance criteria

- `lib/ui/utils/dirty_state.lua` source matches `audits/dirty_obj.md` verbatim (whitespace and comment differences allowed; control flow and method behavior identical).
- `lib/ui/utils/proxy.lua` source matches `audits/proxy_obj.md` verbatim under the same tolerance.
- New DirtyState spec covers every method and both forms (with and without args) of `is_any`/`is_all`.
- New Proxy spec covers every slot, idempotent install, non-declared pass-through, and all four bypass cases for `raw_get`/`raw_set`.
- Full spec suite green with zero changes to existing files.
