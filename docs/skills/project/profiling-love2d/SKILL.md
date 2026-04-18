---
name: profiling-love2d
description: "Project-specific instructions for coding performant code in Lua/Love2d and profiling."
---

## Profiling
- Profile first — never try to optimize without measuring. Use existing `profiler` at the root project. Read  `profiler/README.md`
- It is forbidden to modify any files on the profiler or doing custom implementations in the code you are testing.
- Never trust a single profiler run; require two orthogonal views (e.g. function-level and line-level sampling) to agree before believing a hotspot is real.
- Validate attribution with ablation: stub the alleged hotspot to a no-op and confirm total runtime drops proportionally — if it doesn't, the profiler lied about where the cost lives.
- Always measure A vs B, never A alone; absolute numbers are noise, deltas across versions are signal.
- When the profile is flat with no dominant hotspot, stop hunting — the answer is architectural (data layout, call frequency, allocation strategy), not a local optimization.

## Performance
- **Locals over globals.** VM stores locals in registers; globals cost a table lookup. Alias anything accessed in a hot path: `local floor = math.floor`.
- **Minimize allocations in loops.** Tables, strings, and closures created per-frame feed the GC. Reuse and pre-allocate.
- **String operations are expensive.** Never concatenate in a loop — build a table and `table.concat` at the end.
- **Numeric `for` over `pairs`/`ipairs` in hot paths.** Generic iterators carry overhead; a numeric loop is a tight VM counter.
- **Flatten abstraction in critical paths.** Function calls have overhead. Inline trivial logic where profiling shows it matters — not preemptively.
- **Metamethods add dispatch cost.** Avoid `__index`/`__newindex` chains in tight loops.
- **Tables with predictable structure JIT better.** Mixing array and hash usage, or mutating the shape of a table after construction, degrades JIT trace quality.
