---
name: profiling-love2d
description: "Project-specific instructions for coding performant code in Lua/Love2d and profiling."
---

## Profiling
- Profile first — never try to optimize without measuring. Use existing `profiler` at the root project. Read  `profiler/README.md`
- It is forbidden to modify any files on the profiler or doing custom implementations in the code you are testing.

## Performance
- **Locals over globals.** VM stores locals in registers; globals cost a table lookup. Alias anything accessed in a hot path: `local floor = math.floor`.
- **Minimize allocations in loops.** Tables, strings, and closures created per-frame feed the GC. Reuse and pre-allocate.
- **String operations are expensive.** Never concatenate in a loop — build a table and `table.concat` at the end.
- **Numeric `for` over `pairs`/`ipairs` in hot paths.** Generic iterators carry overhead; a numeric loop is a tight VM counter.
- **Flatten abstraction in critical paths.** Function calls have overhead. Inline trivial logic where profiling shows it matters — not preemptively.
- **Metamethods add dispatch cost.** Avoid `__index`/`__newindex` chains in tight loops.
- **Tables with predictable structure JIT better.** Mixing array and hash usage, or mutating the shape of a table after construction, degrades JIT trace quality.
