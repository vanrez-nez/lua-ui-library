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

The demo must prove that contract through the real implementation of the component under test.

The execution code is the primary learning surface.

That execution code should stay isolated because it will be reused in documentation and examples.

If a developer reads the execution file, they should see only the code needed to understand:

- how to import the library
- how to construct the component
- how to compose the scene
- how to run the minimal loop or update flow for that example

If that same execution code is copied into a standalone Lua example, it should still run without depending on demo-only chrome.

A demo may cover:

- one component
- one tightly coupled component pair

A demo must not become:

- a phase showcase
- a kitchen-sink playground
- an implementation experiment disconnected from the spec
- a demo-local simulation of behavior the component does not actually own
- a wall of setup code that hides the actual component usage

## Spec First

Before implementing a demo:

1. identify the authoritative spec section
2. list the exact public props and behaviors to validate
3. list the invalid or ambiguous cases that must not be implied as valid
4. define screen cases from the contract, not from implementation convenience

Demo code must not invent semantics that the spec does not define.

Demo code must not require the reader to understand demo infrastructure before they can understand the component usage.

Demo docs must not justify missing or incorrect behavior with phase language such as:

- deferred
- later
- not yet implemented
- current runtime

If the behavior is not real and observable in the component being demoed, the screen should not claim it.

If implementation and expected behavior disagree:

- stop
- inspect the spec
- if the spec is unclear, document the conflict before normalizing the demo around one accidental implementation behavior

If a component does not own a behavior, the demo must not recreate that behavior with demo-local math just to make a more impressive screen.

Examples:

- a `Drawable` demo must not implement child layout or spacing composition
- a non-layout component demo must not pretend to measure or arrange descendants

## Learning Surface Rules

The demo source is a learnable API guide first and a runnable demo second.

Every non-trivial screen should be split into two files:

- `{name}.lua`
- `{name}_setup.lua`

The purpose of each file is different.

`{name}.lua` is the execution file.

It is the code the developer is meant to learn from.

It should show only:

- imports relevant to the component being demoed
- object construction for the target component
- scene composition for the target component
- the minimal runtime flow needed to make that example work

It should read like a standalone example.

If copied into documentation, it should still make sense as the component usage snippet.

`{name}_setup.lua` is the setup file.

It may contain:

- demo instrumentation
- native buttons
- hint wiring
- inspection overlays
- screen-local positioning utilities
- cleanup registration
- non-essential visual scaffolding

The setup file exists to keep the execution file readable.

The execution file must not call generic helpers like:

- `mark_box(...)`
- `attach_drawable(...)`
- `make_node(...)`
- similar wrappers that hide target construction or scene composition

The execution file may call one setup entry point after the main scene exists.

Example shape:

1. create the target objects directly
2. compose them directly
3. pass them to setup/instrumentation

The developer should not need to read the setup file to understand how the component itself is being used.

If a reader must parse demo widgets, inspector layout, or helper wrappers before reaching the component usage, the screen is incorrectly structured.

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

## Screen File Rules

If a demo has multiple screens, each screen factory must live in its own demo-local file.

Preferred structure:

- `main.lua` for bootstrap, screen registration, and Love callbacks only
- one shared demo-local helper module for reusable scenario wiring
- one `screens/` directory with one file per screen
- shared lifecycle helpers stay under `demos/common/` when they are reused across demos

Do not keep all screen builders inline in one large `main.lua` once a demo grows beyond a trivial case.

## Sidebar Rules

Sidebar is only for not visible state that cannot be inspected with the mouse.

The sidebar is for:

- non-visible state
- hidden-node facts
- other state that cannot be inspected with the mouse

The sidebar is not for:

- long prose
- behavior explanations
- duplicate navigation markers
- general instructions already visible in the header or footer
- values already available through the shared hover hint overlay
- visible-object inspection data

Behavior explanations belong in the header description below the title.

Sidebar lines should be:

- short
- factual
- current
- easy to compare across frames

## Hover Hint Rules

Hover hints exist to inspect the hovered object and nothing else.

The first row is always fixed:

- `node: {name}`

That row is owned by the shared hint renderer and must not be redefined per screen.

The `name` value should:

- identify the hovered case or object
- stay short and readable
- avoid dumping configuration values when a clearer case name exists
- match the visible label drawn on the inspected object

Good names:

- `Single`
- `Nested`
- `Full`
- `Center`

Bad names:

- `opacity 1.0`
- `alignX center alignY end`
- long descriptive sentences
- raw inset dumps such as `padding 12/28/36/20`
- raw enum bundles such as `start / stretch`

All remaining hint rows should:

- expose only inspectable properties relevant to the behavior under test
- use property labels that match the real property naming
- use unique labels within the same hint
- use dotted labels for sub-properties such as `rect.content`, `rect.bounds`, or `props.padding.top`
- prefer grouped labels when a screen is inspecting a pair or set as one concept, such as `position` for `x` and `y`, or `dimensions` for `width` and `height`
- prefer badges for scalar values
- allow table values to be expanded into per-key badges through the shared hint normalizer

Repeated hint labels are invalid and should fail deterministically.

Grouping is the exception to the dotted sub-property rule:

- use `position` instead of separate `x` and `y` rows when the screen is inspecting placement as one concept
- use `dimensions` or `size` instead of separate `width` and `height` rows when the screen is inspecting size as one concept
- use dotted labels when the value is a real sub-property of a larger concept, such as `bounds.local`, `bounds.world`, `clamp.width`, or `rect.content`

Do not use hints for:

- free-form instructions
- behavior explanations
- duplicated visible labels
- unrelated runtime data

If a screen is demonstrating scale, rotation, alignment, clipping, opacity, or similar, the hint should only show the properties needed to inspect that behavior.

Visible node labels follow the same naming rule as the hint name:

- they identify the case
- they stay short
- they do not dump raw values that already belong in the hint
- they should read well on screen without requiring the viewer to parse configuration syntax

When a screen draws inspection geometry, keep the visual vocabulary small and stable:

- prefer a primary `container` shape
- prefer a single `target` shape when the screen is about content, alignment, or resolved inner placement
- add extra overlays such as `padding` or `margin` only when they are the behavior under test
- do not stack multiple overlapping helper rects unless each one is necessary to read the claim being demonstrated

If a screen is interactive instead of preset:

- show a clear selection state on the object currently being edited
- keep the controls close to the affected object so the mapping is obvious without reading extra text
- make each control mutate one property in one direction at a time
- keep the edited values inspectable through the same hover-hint rules as preset screens

When choosing offsets, insets, padding, or margin values for a demo:

- prefer simple proportional steps such as `5`, `10`, `15`, and `20`
- prefer larger visible box sizes such as `50`, `100`, and `150` when the demo is about nested sizing, spacing, or accumulation
- prefer values that are easy to compare visually, such as doubles or clean increments
- avoid awkward values such as `4`, `18`, `19`, `160`, or near-miss sizes when a cleaner proportional value would communicate the same point
- choose numbers that reduce mental subtraction for the reviewer

If a case is meant to compare mixed insets, the relationship between the values should be visually legible at a glance.

If a screen composes nested boxes, prefer a stable size ladder such as `50 -> 100 -> 150` so the reviewer can recognize the progression before inspecting the hint.

The goal is to offload cognitive calculation from the reviewer, not to make the reviewer decode more geometry.

## Title And Description Rules

The header title must change with the active screen.

Use the screen title, not the demo folder name, as the visible title.

The header description must summarize:

- what this screen is testing
- what the reviewer should pay attention to
- what the reviewer should expect to see visually before hovering
- what hovering or inspection should confirm

Descriptions should orient the reviewer to the visible comparison first and the inspected details second.

Good description structure:

- identify the main visual cues on screen
- explain what each cue means
- state what the hint confirms when inspected

If a screen contains multiple overlays or guide shapes, the description must explain:

- which shape is the container
- which shape is the target
- which overlays are optional guides such as padding or margin

Do not write descriptions that assume the reviewer already knows the implementation details.

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
- `rgba(...)` inside shared color definitions

If a new color is genuinely needed:

1. add it to `demos/common/colors.lua`
2. give it a generic name or role
3. do not create per-component aliases unless the shared module truly needs them

Use `DemoColors.rgba(...)` at the point of use when alpha is needed.

Do not bake alpha into `demos/common/colors.lua` role definitions.

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
