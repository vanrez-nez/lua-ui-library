# Demo Authoring Rules

## Purpose

This document captures the concrete rules learned while building the first component demo.

It exists to keep the next demos:

- spec-driven
- isolated
- consistent
- easier to review
- easier to maintain

These rules apply to every runnable demo under `demos/`.

## Core Rule

Each demo must validate one public contract at a time.

A demo may cover:

- one component
- one tightly coupled component pair

A demo must not become:

- a phase showcase
- a kitchen-sink playground
- an implementation experiment disconnected from the spec

## Spec First

Before implementing a demo:

1. identify the authoritative spec section
2. list the exact public props and behaviors to validate
3. list the invalid or ambiguous cases that must not be implied as valid
4. define screen cases from the contract, not from implementation convenience

Demo code must not invent semantics that the spec does not define.

If implementation and expected behavior disagree:

- stop
- inspect the spec
- if the spec is unclear, document the conflict before normalizing the demo around one accidental implementation behavior

## DemoBase Rules

All demos must use the shared infrastructure in `demos/common/`.

Use:

- `demos.common.bootstrap`
- `demos.common.demo_base`
- `demos.common.colors`

Do not duplicate:

- `package.path` root bootstrap logic
- header / footer rendering
- screen switching
- reset behavior
- memory overlay
- sidebar framework

The common shell owns:

- `[Left/Right]` screen switching
- `[R]` screen reset
- `[H]` navigation visibility
- `[M]` memory monitor
- `[Esc]` quit

The demo must not override those keys.

## Screen Lifecycle Rules

Every screen must be a factory registered through `DemoBase:push_screen(...)`.

Each screen factory receives:

- `index`
- `scope`
- `owner`

Use `scope` for temporary Love resources.

Do not rely on manual teardown inside the demo.
Screen cleanup is owned by `DemoBase`.

Every reset must rebuild the screen from scratch.

## Sidebar Rules

Use the shared left info sidebar for live inspection values.

The sidebar is for:

- resolved measurements
- bounds
- state values
- object relationships
- other concrete runtime facts

The sidebar is not for:

- long prose
- behavior explanations
- duplicate navigation markers
- general instructions already visible in the header or footer

Behavior explanations belong in the header description below the title.

Sidebar lines should be:

- short
- factual
- current
- easy to compare across frames

## Title And Description Rules

The header title must change with the active screen.

Use the screen title, not the demo folder name, as the visible title.

The header description must summarize:

- what this screen is testing
- what the reviewer should pay attention to

Do not repeat that information in the sidebar.

## Colors Rules

All color usage must come directly from `demos/common/colors.lua`.

Allowed:

- `DemoColors.roles.*`
- `DemoColors.names.*`

Not allowed:

- demo-local palette tables
- demo-local color aliases like `BACKGROUND`, `PANEL_TEXT`, `COLORS`, or `PALETTES`
- hardcoded RGBA literals in demo code when a shared color already fits
- per-demo color derivation layers

If a new color is genuinely needed:

1. add it to `demos/common/colors.lua`
2. give it a generic name or role
3. do not create per-component aliases unless the shared module truly needs them

Alpha-adjusted colors should also be defined in `demos/common/colors.lua`, not inside demos.

## Bootstrap Rules

All demo entrypoints must initialize imports through:

```lua
package.path = '../../?.lua;../../?/init.lua;' .. package.path
require('demos.common.bootstrap').init()
```

Do not copy the full `love.filesystem.getSource()` resolution block into each demo.

## Layout Rules

A demo must not imply layout semantics that the component under test does not own.

Examples:

- plain `Container` must not be used to imply sibling-aware fill distribution
- remaining-space allocation belongs to layout containers like `Row` and `Column`
- overlays must not be demonstrated in non-overlay demos

If a case is visually misleading for the tested contract, remove or reframe it.

## Behavior Rules

Animated fixtures are allowed only when they help expose recalculation or state transitions.

Animation must:

- be minimal
- remain deterministic enough to inspect
- stay relevant to the component contract

Animation must not:

- turn the demo into a motion showcase
- hide measurement errors
- introduce unrelated behavior noise

## Formatting Rules For Inspection Data

Use compact, consistent value formatting.

Example:

```text
x:10 y:20 w:100 h:60
```

Do not use:

```text
x=10 y=20 width=100 height=60
```

Do not repeat footer information such as `screen 1/6` inside sidebar panels.

## Complexity Rules

Do not hand-build large screen trees when data-driven helpers are enough.

Preferred patterns:

- one node creation helper
- one screen wrapper
- one metric formatting helper
- one or a few small scenario builders

Avoid:

- repeated draw logic per screen
- repeated resize logic per screen
- repeated sidebar update logic per screen

Keep the demo implementation compact, but not abstract for abstraction's sake.

## Conflict Handling Rules

If a demo reveals a contract conflict:

1. stop treating the current implementation as automatically correct
2. compare against the spec
3. compare against established external precedent if needed
4. write the conflict down in a standalone note
5. only then decide whether to change:
   - the demo
   - the spec
   - the implementation

Do not silently normalize a confusing case in the demo if the underlying contract is the real problem.

## Review Checklist

Before marking a demo ready:

- does each screen map to one contract concern?
- is the title screen-specific?
- is the description in the header rather than the sidebar?
- is the sidebar factual and compact?
- are all colors coming directly from `demos/common/colors.lua`?
- is the bootstrap using `demos.common.bootstrap`?
- is all cleanup owned by `DemoBase` and `scope`?
- does the demo avoid implying semantics outside the current spec?
- are any ambiguous or conflicting behaviors documented rather than hidden?

If any answer is no, the demo is not ready.
