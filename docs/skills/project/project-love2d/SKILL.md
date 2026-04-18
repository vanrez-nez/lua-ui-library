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

- Never use to skip validation, change-tracking, or as a micro-optimization. If you reach for it outside these two contexts, the real problem is a missing method or a rigid constructor API.
- Leave a comment explaining why normal access cannot be used. comments like `-- bypass __index: read raw prop value` are not useful nor describe the why. Consider refactor this instead of justifying with a comment.

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

## Testing & Spec Compliance

### Common Practices
- Test behavior, not implementation. Assertions should target the observable contract (inputs → outputs, visible state changes), not internal structure. If a refactor that preserves behavior breaks the test, the test was coupled to the wrong thing — and it will slow every future refactor.
- One reason to fail per test. A test that can fail for three unrelated reasons is three tests fused; when it goes red, you don't know which. Split until each test guards exactly one invariant, and name it after that invariant.
- Determinism is non-negotiable. Pin clocks, seed RNGs, fix ordering, eliminate network/filesystem races. A flaky test poisons the entire suite — devs start ignoring red builds, which defeats the point of the suite. Never "retry until green"; find the root cause.
- Mock at architectural boundaries only. Mock I/O, time, network, external services — the things you don't control. Don't mock your own pure functions; that's testing your mocks. Over-mocked suites pass while the integrated system is broken.
- A failing test should diagnose itself. Test name + failure message should tell you what broke without attaching a debugger. assertEquals(a, b) on opaque values is a smell; explicit messages, descriptive names, and meaningful diffs turn failures into specs.
- Prefer explicit duplication over clever abstraction in test code. Tests invert the DRY instinct: a shared helper across five tests means a helper bug breaks five tests simultaneously, and reading any one test requires chasing abstractions. Linear, slightly repetitive test code is more maintainable than elegant test code.

### Library
- All specs go into under `spec` project path. You mirror the code organization of your testing files. Do not drop everything at the root.
- Import LuaUnit as `lu = require('luaunit')` at the top of every test file.
- End the test script with `os.exit(lu.LuaUnit.run())` so the process returns a meaningful exit code (required for CI pipelines to detect failure).
- Prefix every test function with test or Test — LuaUnit only discovers functions matching this prefix.
- Prefix every test group/table with test or Test as well; otherwise its methods won't be scanned.
- Inside test tables, method names must also start with test/Test to be picked up.

### Enums and Constants

## Atoms

- An atom is one primitive value (string or number) bound to one identifier in one module. Never tables, functions, or userdata.
- Name atoms by semantic category, not by consumer. `ALIGN_CENTER`, not `JUSTIFY_CENTER`.
- Category prefixes partition the namespace. Same prefix = interchangeable within an enum. Different prefix = never mixed.
- Atom values are opaque. Compare references (`x == Justify.CENTER`), never literals (`x == "center"`).
- Atoms are frozen at declaration. No runtime mutation, no dynamic construction.
- Value type is consistent within a category. All `ALIGN_*` strings, or all integers. No mixing.
- Within a category, atom values are distinct. Across categories, collisions are fine — they never co-occur.

## Enums

- Enums compose atoms, not other enums. List atoms directly; never reference another enum's members.
- An atom may appear in any number of enums, at most once per enum.
- Subsets and unions are declared, not derived. No filter, merge, or extend operations.
- Enums carry only membership and order. No labels, defaults, or metadata — use parallel tables keyed by atom.
- Never inline atom values in enum declarations. `{ CENTER = Constants.ALIGN_CENTER }`, never `{ CENTER = "center" }`.
- Cross-enum equality is load-bearing: `Justify.CENTER == AlignItems.CENTER` must hold because both dereference the same atom.
- Declare enums at module load. Never inside functions, constructors, or hot paths.

## Usage

- Atoms flow through the system as values. Runtime code sees `"center"`, not `"CENTER"`.
- Validate at boundaries with `enum_has`. Trust internally; do not re-validate.
- Never compare member names at runtime.

## Scope

- Global constants go in `lib/ui/core/constants.lua`.
- Global enums go in `lib/ui/core/enums.lua`.
- Base class for defining enums is inside `lib/ui/utils/enum.lua`
- A class may own its constants and enums as long as no other module references them directly.
- The moment a second module references a class-local constant or enum, promote it to global.
- Class-local constants and enums are exported as static members of the class, not instance fields.
- Class-local atoms follow the same naming rules: category prefix, uppercase snake case, opaque values.
- Do not pre-promote. Keep atoms class-local until a concrete second consumer exists.

## Anti-patterns

- Consumer-prefixed atoms (`JUSTIFY_CENTER`).
- Inline string literals in enum declarations.
- Derived enums (`filter`, `merge`, `extend`).
- Dynamic enums built from runtime input.
- Enums carrying metadata beyond membership and order.
- Comparing member names at runtime.
- Class-local enums exposed as instance fields instead of static class members.
- Duplicating an atom across classes for a shared concept instead of promoting it.
- Global constants with only one consumer.


### Assertions
- Use `assertEquals(actual, expected)` — the order is actual-first, expected-second. Getting this reversed produces misleading failure messages.
- For error paths, prefer `assertErrorMsgContains(expectedMsg, fn, args...)` over bare assertError; validating the message catches the wrong error being raised for the right reason.
- Use type assertions (assertIsFunction, assertIsNil, etc.) when return type is part of the contract, not just return value.

### Grouping and Life Cycle
- Once the suite grows beyond a handful of tests, move related tests into a table. One table per unit-under-test is the default grain.
- Use `setUp()` to allocate per-test state and tearDown() to release it — they run before/after each test in the table.
- Never rely on test execution order or on state leaking between tests; if two tests share setup, that's what `setUp()` is for.
- Keep `setUp()`/`tearDown()` minimal and defensive — failures inside them are reported as errors, not failures, and can mask the actual test result.
- Make `setUp()` idempotent against leftover state (e.g. `os.remove(file)` before creating it) in case a previous `tearDown()` didn't run.

### Failures vs Errors
- Assertion mismatches produce failures; unexpected runtime errors produce errors. A clean suite should have zero of either, but when triaging, treat errors as higher-priority (they indicate the test didn't even complete).
- Any exception in setUp/tearDown is always classified as an error, never a failure.
