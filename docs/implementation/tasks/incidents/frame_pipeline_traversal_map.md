# Frame Pipeline Traversal Map

## Goal

Provide a concrete frame-cost map for the retained runtime so performance work
can target the actual traversals and invalidation chain rather than isolated
utility modules.

This document is based on the `demos/06-performance` retained `Image` stress
case and the latest profiled 100-image run.

Artifacts:

- [06-performance-timing-100-pass4.txt](/Users/vanrez/Documents/game-dev/lua-ui-library/tmp/06-performance-timing-100-pass4.txt)
- [06-performance-memory-100-pass4.txt](/Users/vanrez/Documents/game-dev/lua-ui-library/tmp/06-performance-memory-100-pass4.txt)

## Spec Alignment Boundary

This document proposes internal optimization directions only.

It does not propose:

- changing the retained rendering model
- introducing a public immediate-mode exception
- moving state resolution into the draw pass
- weakening clipping, focus, layout, responsive, or isolation behavior when
  those surfaces are active by contract

Relevant spec constraints:

- the runtime remains retained and `Stage` still drives ordered update then
  draw passes
- the update pass must resolve dirty geometry, layout, world transforms, and
  queued state changes before draw
- the draw pass must not become a deferred state-resolution pass
- isolation must not be applied speculatively when inline drawing satisfies the
  contract
- undocumented traversal strategy, batching, helper structure, and cache layout
  remain implementation detail

So every optimization target below should be read as:

- "make this pass skippable or cheaper when the node contract proves it is not
  participating in that concern"

not as:

- "remove this concern from the retained runtime model"

## Measured Top-Level Costs

From the profiled 100-image pass:

- `Stage.update`: about `2.754 ms/frame`
- `Stage.draw`: about `1.523 ms/frame`
- `RootCompositor.resolve_node_plan`: about `0.332 ms/frame` aggregate
- `RootCompositor.plan_requires_isolation`: about `0.051 ms/frame` aggregate

Memory profile:

- `Stage.update` self allocation: about `574 KB/frame`
- `Stage.draw` self allocation: about `218 KB/frame`

Important limitation:

- the profiler measures `Stage.update` and `Stage.draw` as zones, but it does
  not separately time every internal traversal inside them
- internal-pass cost statements below are therefore marked as either
  `measured` or `inferred`

## Motion Invalidation Chain

For a moving visual leaf, the expensive recalculation starts before
`Stage.update`.

1. Demo logic writes `node.x` / `node.y`
   - `demos/06-performance/screens/empty.lua`
2. Public prop change handling runs
   - [handle_public_prop_change](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/core/container.lua:1537)
3. For transform keys, the node is marked dirty and world state is invalidated
   - [Container:invalidate_world](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/core/container.lua:241)
   - [Container:invalidate_descendant_world](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/core/container.lua:246)
4. On the next stage update, the runtime revisits the node through the stage
   traversals and refreshes dirty geometry

This means a simple position write is not a local sprite update. It becomes a
retained-node invalidation event.

## Traversal Map

| Pass | Entry Point | Scope | Trigger | Cost Signal | Optimization Direction For Pure Visual Leaf |
| --- | --- | --- | --- | --- | --- |
| Prop invalidation | [handle_public_prop_change](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/core/container.lua:1537) | per write | every animated `x/y` write | inferred high frequency | keep, but reduce invalidation breadth |
| Descendant world invalidation | [invalidate_descendant_world](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/core/container.lua:246) | subtree | any local transform change | inferred | skip when the node is a leaf and descendant invalidation is provably unnecessary |
| Layout prep traversal | [prepare_layout_subtree](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/scene/stage.lua:1476) | whole tree | every `Stage.update` | inside measured `Stage.update` | skip for nodes/subtrees with no active layout or responsive participation |
| Responsive resolution | [Stage:_resolve_responsive_for_node](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/scene/stage.lua:1708) | whole tree, per node | called from layout prep traversal | inside measured `Stage.update` | skip when `responsive` and `breakpoints` are inactive |
| Layout execution traversal | [run_layout_subtree](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/scene/stage.lua:1481) | whole tree | every `Stage.update` | inside measured `Stage.update` | skip for subtrees with no layout-family participation |
| Container update traversal | [Container:update](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/core/container.lua:1890) | whole tree recursion | every `Stage.update` | inside measured `Stage.update`; allocates snapshot tables | replace with a cheaper equivalent for leaves when retained guarantees are unchanged |
| Dirty geometry refresh | [_refresh_if_dirty](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/core/container.lua:1844) | dirty nodes | reached during update recursion | inside measured `Stage.update` | narrow the dirty categories reached by pure transform motion |
| Measurement refresh | [refresh_measurement](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/core/container.lua:847) | dirty node | measurement dirty | inferred secondary | avoid reopening for transform-only motion |
| Local transform refresh | [refresh_local_transform](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/core/container.lua:877) | dirty node | local transform dirty | inferred primary | keep |
| World transform refresh | [refresh_world_transform](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/core/container.lua:918) | dirty node plus descendants | world dirty | inferred primary | keep, but reduce descendant fanout where possible |
| Bounds refresh | [refresh_bounds](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/core/container.lua:963) | dirty node | bounds dirty | inferred primary | specialize when equivalent bounds behavior can be proven |
| Draw traversal | [_draw_subtree_resolved](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/core/container.lua:2151) and [draw_subtree](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/core/container.lua:1281) | whole tree | every `Stage.draw` | measured inside `Stage.draw` | keep traversal, but thin per-node work when clip/focus/compositor surfaces are inactive |
| Root compositor plan lookup | [RootCompositor.resolve_node_plan](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/render/root_compositor.lua:413) | per drawn node | every draw traversal | measured `0.332 ms/frame` aggregate | skip for node classes that cannot isolate by contract |
| Isolation eligibility check | [RootCompositor.plan_requires_isolation](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/render/root_compositor.lua:466) | per drawn node | every draw traversal | measured `0.051 ms/frame` aggregate | skip for node classes that cannot isolate by contract |

## Update Pipeline Detail

### 1. Layout Prep Traversal

Entry:

- [Stage.update](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/scene/stage.lua:2388)
- [prepare_layout_subtree](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/scene/stage.lua:1476)

What it does:

- walks the whole tree
- resolves responsive state for each node
- runs `_prepare_for_layout_pass()` for each node

Why it is suspicious:

- the 06-performance scene is a set of moving image leaves
- responsive/layout prep is still revisited frame-wide
- this work is paid even when only `x/y` changed

Assessment for pure visual leaves:

- should be bypassed when the node/subtree contract proves no layout or
  responsive participation is active

### 2. Layout Execution Traversal

Entry:

- [run_layout_subtree](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/scene/stage.lua:1481)

What it does:

- walks the whole tree again
- invokes `_run_layout_pass()` on layout nodes

Why it is suspicious:

- this is a second full traversal before the normal update recursion begins
- moving image leaves do not need a layout pass every frame

Assessment for pure visual leaves:

- should be skipped when the subtree has no layout-family participation and no
  contract-relevant placement work pending

### 3. Generic Container Update Recursion

Entry:

- [Stage.update](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/scene/stage.lua:2407)
- [Container:update](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/core/container.lua:1890)

What it does:

- recursively visits all children
- refreshes dirty state
- allocates `snapshot = {}` for children before recursing

Why it is suspicious:

- this is generic retained-tree recursion even for leaves that have no
  children and no interaction
- the memory profile strongly points to update-side allocation churn

Assessment for pure visual leaves:

- leaf visuals need a much cheaper equivalent update path than generic
  `Container:update()`, while preserving retained update-pass guarantees

### 4. Dirty Geometry Refresh

Entry:

- [_refresh_if_dirty](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/core/container.lua:1844)

What it does:

- conditionally runs responsive, measurement, transform, bounds, and child-order
  refresh

Important sub-passes:

- [refresh_measurement](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/core/container.lua:847)
- [refresh_local_transform](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/core/container.lua:877)
- [refresh_world_transform](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/core/container.lua:918)
- [refresh_bounds](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/core/container.lua:963)

Why it is suspicious:

- `x/y` animation fundamentally needs local/world transform refresh
- it does not obviously need measurement and broader retained geometry plumbing
- world refresh can also fan invalidation down descendants

Assessment for pure visual leaves:

- retain local/world transform refresh
- minimize or eliminate measurement and unrelated dirty categories
- consider specialized axis-aligned bounds rules for simple leaves when hit,
  clip, and world-bounds behavior remain equivalent

## Draw Pipeline Detail

### 5. Whole-Tree Draw Traversal

Entry:

- [Stage:draw](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/scene/stage.lua:2437)
- [_draw_subtree_resolved](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/core/container.lua:2151)
- [draw_subtree](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/core/container.lua:1281)

What it does:

- traverses the whole retained tree
- checks visibility and clipping
- runs node draw dispatch
- evaluates root compositor plan state on every node

Measured cost:

- `Stage.draw`: about `1.523 ms/frame`

Assessment for pure visual leaves:

- traversal still exists, but it should be thinner
- clip logic may be skipped only when neither the node nor its ancestor chain
  makes clipping contract-relevant
- focus logic may be skipped for node classes that do not participate in focus
  traversal by contract
- compositor logic may be skipped for node classes that cannot isolate by
  contract

### 6. Root Compositor Plan Resolution

Entry:

- [RootCompositor.resolve_node_plan](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/render/root_compositor.lua:413)
- [RootCompositor.plan_requires_isolation](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/render/root_compositor.lua:466)

Measured cost:

- `resolve_node_plan`: about `0.332 ms/frame`
- `plan_requires_isolation`: about `0.051 ms/frame`

Why it is suspicious:

- the cost is real and scales with node count
- most image leaves in this stress case cannot meaningfully isolate

Assessment for pure visual leaves:

- nodes/classes that cannot isolate should skip this path entirely

## What The Profile Rules Out

The current evidence does not support utility modules as the primary scaling
failure:

- native harness `plain` vs `proxy` vs `schema` does not show material scaling
  differences at high counts
- image draw-specific work was already reduced materially in earlier passes
- the largest measured remaining zone is still `Stage.update`

So the bottleneck is not:

- raw image drawing
- `Proxy`
- `Schema`

The bottleneck is:

- retained invalidation
- whole-tree update traversals
- generic container recursion
- dirty geometry refresh paid by moving leaves

## Decision Rule

No optimization should be implemented from this document based on suspicion
alone.

Required order:

1. isolate one suspect with instrumentation or a reversible feature gate
2. capture timing and memory before/after against the same scenario
3. quantify the delta in `ms/frame`, `alloc/frame`, or call count
4. only then decide whether the suspect is a primary bottleneck worth
   implementation work

This document therefore treats each suspected traversal as a profiling task
first and an implementation candidate second.

## Measurement Protocol

Scenario:

- `demos/06-performance`
- `UI_PERF_IMAGE_COUNT=100`
- 5-second timing and memory captures

Required outputs for every task:

- before timing artifact
- after timing artifact
- before memory artifact when allocation is relevant
- after memory artifact when allocation is relevant
- one short written conclusion: `confirmed`, `secondary`, or `rejected`

Minimum comparison fields:

- `Stage.update ms/frame`
- `Stage.draw ms/frame`
- suspect-specific zone time or call count
- suspect-specific allocation if measurable

Decision thresholds:

- `confirmed`: suspect moves total frame time by at least `0.5 ms/frame` or
  moves `Stage.update` / `Stage.draw` by at least `10%`
- `secondary`: suspect moves time, but less than the threshold above
- `rejected`: suspect produces no material movement

## Evidence Tasks

### Task 1. Split `Stage.update` Into Internal Zones

Goal:

- stop treating `Stage.update` as one opaque block

Work:

- add profiler zones around:
  - `prepare_layout_subtree`
  - `run_layout_subtree`
  - `self:_refresh_if_dirty()`
  - `baseSceneLayer:update()`
  - `overlayLayer:update()`
  - `refresh_hover_target`

Measure:

- ms/frame for each internal update zone
- calls per frame where relevant

Exit criterion:

- identify the top 2 update subzones by frame cost

Status after task:

- only those top 2 subzones move forward as implementation suspects

### Task 2. Measure Responsive Resolution Cost Directly

Goal:

- determine whether responsive work is materially contributing to the 100-image
  stress case

Work:

- add a profiler zone around
  [Stage:_resolve_responsive_for_node](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/scene/stage.lua:1708)
- count how many nodes per frame actually enter responsive resolution with
  active `responsive` / `breakpoints`

Measure:

- total responsive ms/frame
- calls/frame
- number of active responsive nodes

Exit criterion:

- classify responsive resolution as `confirmed`, `secondary`, or `rejected`

Implementation gate:

- do not build a responsive fast path until this task confirms meaningful cost

### Task 3. Measure Layout Prep Traversal Cost

Goal:

- determine whether whole-tree layout preparation is a primary update bottleneck

Work:

- profile
  [prepare_layout_subtree](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/scene/stage.lua:1476)
  directly
- capture node count visited per frame

Measure:

- layout prep ms/frame
- visited nodes/frame

Exit criterion:

- confirm whether layout prep alone is a top-level update contributor

Implementation gate:

- do not skip layout prep for any node class until this task shows meaningful
  cost and a safe exclusion set

### Task 4. Measure Layout Execution Traversal Cost

Goal:

- determine whether
  [run_layout_subtree](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/scene/stage.lua:1481)
  is materially expensive in the stress case

Work:

- profile `run_layout_subtree` directly
- count nodes that actually execute `_run_layout_pass()`

Measure:

- layout execution ms/frame
- layout-node executions/frame

Exit criterion:

- classify full-tree layout execution as `confirmed`, `secondary`, or `rejected`

Implementation gate:

- do not introduce subtree skipping logic for layout execution before this task

### Task 5. Measure `Container:update()` Recursion And Snapshot Allocation

Goal:

- quantify how much of `Stage.update` is generic container recursion overhead

Work:

- add a profiler zone inside
  [Container:update](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/core/container.lua:1890)
  for:
  - `_refresh_if_dirty()`
  - child snapshot creation
  - child recursion loop
- add allocation profiling notes for the snapshot path

Measure:

- recursion ms/frame
- snapshot alloc/frame
- number of node updates/frame

Exit criterion:

- determine whether leaf recursion and snapshot allocation are a primary update
  bottleneck

Implementation gate:

- do not build a leaf fast path until this task confirms the generic update
  recursion cost

### Task 6. Measure Dirty Refresh Sub-Passes

Goal:

- stop bundling dirty refresh into one inferred bucket

Work:

- add profiler zones inside
  [_refresh_if_dirty](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/core/container.lua:1844)
  around:
  - `refresh_measurement`
  - `refresh_local_transform`
  - `refresh_world_transform`
  - `refresh_bounds`

Measure:

- ms/frame for each dirty-refresh sub-pass
- calls/frame for each sub-pass

Exit criterion:

- rank the dirty refresh sub-passes by actual measured cost

Implementation gate:

- only the top measured sub-pass should drive the next optimization

### Task 7. Measure Descendant Invalidation Fanout

Goal:

- determine whether invalidation breadth is itself a major cost before refresh
  even begins

Work:

- count calls and descendant visits for:
  - [invalidate_world](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/core/container.lua:241)
  - [invalidate_descendant_world](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/core/container.lua:246)
  - [invalidate_descendant_geometry](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/core/container.lua:255)

Measure:

- calls/frame
- descendants touched/frame

Exit criterion:

- determine whether breadth of invalidation, not refresh work, is the primary
  culprit

Implementation gate:

- do not narrow invalidation semantics until this task confirms fanout is large
  enough to matter

### Task 8. Measure Draw Traversal Internal Cost

Goal:

- split `Stage.draw` into actual internal contributors

Work:

- add profiler zones inside
  [draw_subtree](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/core/container.lua:1281)
  for:
  - visibility/entry checks
  - clip handling
  - draw dispatch
  - child recursion

Measure:

- draw traversal subzone ms/frame
- nodes drawn/frame

Exit criterion:

- identify whether draw traversal thinning is worth pursuing before update-side
  changes

### Task 9. Measure Root Compositor Plan Cost By Node Class

Goal:

- confirm whether compositor planning is concentrated on node classes that can
  never isolate

Work:

- count `RootCompositor.resolve_node_plan` calls by node class
- count non-`nil` plan results by node class
- count actual `plan_requires_isolation` positives by node class

Measure:

- calls/frame by class
- positive isolation decisions/frame by class
- total compositor ms/frame

Exit criterion:

- determine whether a no-isolation fast path would remove real work or only a
  tiny branch

Implementation gate:

- do not implement class-based compositor skipping until the per-class call
  profile confirms waste

## Execution Order

Run the tasks in this order:

1. Task 1
2. Task 6
3. Task 5
4. Task 3
5. Task 4
6. Task 2
7. Task 7
8. Task 8
9. Task 9

Rationale:

- first split the opaque `Stage.update` block
- then identify which dirty-refresh and recursion costs are real
- only after update-side evidence is clear, evaluate draw-side suspects

## Spec-Compatibility Summary

Any implementation work that follows these tasks must preserve:

- retained update then draw sequencing
- full state resolution before draw
- no hidden state resolution in draw
- clipping, focus, layout, and isolation behavior whenever those surfaces are
  contract-relevant
- consumer-observable contract equivalence for any optimized leaf path
