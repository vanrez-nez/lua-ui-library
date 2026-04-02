# 01-container

## Goal

Build the first component demo for `Container`.

This demo must verify the `Container` contract directly, not indirectly through `Drawable`, controls, or old phase harness behavior.

Primary authority:

- [UI Foundation Specification](../../docs/spec/ui-foundation-spec.md)
- `docs/spec/ui-foundation-spec.md §6.1.1 Container`
- `docs/spec/ui-foundation-spec.md §3A`
- `docs/spec/ui-foundation-spec.md §3B`
- `docs/spec/ui-foundation-spec.md §3G`

Useful historical reference:

- `docs/implementation/tasks/phase-01/07-phase-01-demo-and-acceptance.md`
- `_test/phase1/`

## What This Demo Must Prove

The `Container` demo must prove:

- retained parent/child tree behavior
- local bounds versus world bounds
- width and height resolution across common sizing modes
- percentage sizing against the effective parent region
- min/max clamp behavior
- visibility behavior
- transform participation at the container level if already part of the current `Container` contract
- zero-size and near-zero parent edge behavior without hard failure

This demo must not drift into:

- `Drawable` content-box behavior
- clipping demonstrations that belong to `Drawable` / render behavior
- control semantics
- focus behavior
- overlay behavior

## Demo Strategy

The demo should test features in multiple scenarios while still showing full property usage.

The key approach:

1. use a small number of reusable scenario builders
2. vary props through data tables, not custom handwritten screens
3. keep visual language consistent across screens
4. show resolved values beside each scenario
5. keep every scenario isolated to one container concern

In this demo, resolved values should be shown through the shared `DemoBase` info sidebar, not through a demo-local floating inspector panel.

The second requirement is equally important:

- show correct behavior by reducing demo-code complexity

That means the demo code should not be a long hand-built scene graph for every case.
Instead, it should use a compact fixture system.

## Proposed Screen Set

### Screen 1: Parent / Child Bounds

Should test:

- one parent container with nested children
- local bounds for each node
- world bounds for each node
- parent offset influence on child world position

Should display:

- parent label
- child label
- local x/y/width/height
- world x/y/width/height

### Screen 2: Fixed / Fill / Content Sizing

Should test:

- fixed width and height
- fill sizing only where the parent contract explicitly supports it
- content sizing where valid for the current node family
- mixed sizing combinations

Should display:

- assigned props
- resolved width/height

### Screen 3: Percentage Sizing

Should test:

- percentage width
- percentage height
- nested percentage sizing
- percentage sizing under resize

Should display:

- parent dimensions
- percentage input
- resolved child dimensions

### Screen 4: Min / Max Clamps

Should test:

- `minWidth`
- `maxWidth`
- `minHeight`
- `maxHeight`
- clamp interaction with percentage sizing and fixed sizing

Should display:

- unclamped target size
- resolved clamped size

### Screen 5: Visibility And Tree Membership

Should test:

- visible versus hidden nodes
- hidden parent influence on descendants
- retained-tree presence separate from visibility

Should display:

- visibility flags
- whether the node is expected to draw
- whether bounds remain inspectable

### Screen 6: Zero / Tiny Parent Edge Cases

Should test:

- zero-width parent
- zero-height parent
- near-zero parent dimensions
- descendant percentage sizing under degenerate parent size

Should display:

- parent size
- child resolved size
- whether the result degraded to zero cleanly

## Property Coverage Matrix

The demo should make property usage explicit.

At minimum, `Container` scenarios should visibly exercise:

- `x`
- `y`
- `width`
- `height`
- `minWidth`
- `maxWidth`
- `minHeight`
- `maxHeight`
- `visible`

If the current `Container` spec includes additional stable transform props on the same public surface, they should be added in one dedicated screen rather than mixed into every screen.

## Implementation Tasks

### Task 1: Create Minimal Scenario DSL

Create a small internal helper layer for the demo only.

It should provide:

- a way to define scenario data as plain tables
- a way to instantiate scenario containers from that data
- a way to render inspection text from the resolved node state

This is required to keep the demo concise.

### Task 2: Create Shared Visual Fixture

Create a small visual fixture for the `Container` demo:

- one parent frame color
- one child frame color
- one nested-child frame color
- one consistent text style for metrics

This fixture must remain plain Love2D or shared demo-base rendering logic, not `lib/ui` helper abstractions outside the component under test.

### Task 3: Build Screen Factories

Build one screen factory per scenario group:

- parent/child bounds
- sizing modes
- percentages
- clamps
- visibility
- degenerate parent sizes

Every screen factory should:

- receive `index`, `scope`, and `DemoBase`
- build only the nodes required for that screen
- update one or more `DemoBase` sidebar items with the current metrics

### Task 4: Add Resize-Aware Metrics

Where the scenario depends on window size or parent size, the screen should recompute visible inspection values on resize or update.

This must be done with minimal code duplication.

### Task 5: Add Guarded Failure Fixture If Needed

If one container-edge case needs guarded failure demonstration, isolate it in one optional fixture and keep the rest of the screen usable.

Do not let a failure-path fixture take over the whole demo.

## Code Complexity Rules

To reduce implementation complexity, the demo should follow these rules:

- do not hand-author each node tree separately when only data changes
- do not duplicate metric text rendering logic per screen
- do not duplicate resize logic per screen when one helper can own it
- do not mix screen switching with screen content logic
- do not require every screen to manually destroy resources; rely on `DemoBase` scope cleanup
- do not create a separate custom inspection overlay when the shared sidebar can carry the metrics

Recommended pattern:

1. one `scenario_builder.lua`
2. one `metrics.lua`
3. one `draw_helpers.lua`
4. one `main.lua`

If fewer files are enough, that is better.
The point is not file count.
The point is keeping repeated container-case setup declarative.

## Acceptance Criteria

The final demo is acceptable when:

- each screen maps to one container concern
- each concern is shown in multiple scenarios, not only one happy path
- resolved values are visible on screen
- property usage is explicit
- the implementation remains compact because scenario data drives the setup
- no screen depends on later component demos
- screen switching and cleanup remain owned by `DemoBase`

## Non-Goals

This demo should not:

- test `Drawable`
- test `Stage`
- test control behavior
- become a general foundation harness
- recreate the old phase-01 mega-demo
