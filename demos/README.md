# Demos

`demos/` contains small, isolated Love2D apps whose only purpose is to teach
developers how to use the UI library through real, runnable examples.

This is the first rule of the demo system:

- demos educate
- demos guide
- demos make developers familiar with the UI library

Because of that, every demo must be structured as a learning surface first and
a runnable app second.

## Main Screen Rule

Demo implementation must not mix setup and demo.

The main execution file for a screen, typically `screens/{name}.lua`, must stay
plain, minimal, and readable.

A developer reading that file should immediately understand:

- how to import the library
- how to construct the component
- how to compose the scene
- how to run the minimal flow needed for the example

The main screen file must read like code that could be copied into a standalone
Lua example.

Besides the `Stage` setup managed by the shared helper layer, the main screen
file must remain simple enough that, if transported into another Lua file, it
still reads like runnable component-usage code rather than demo infrastructure.

That means:

- no demo-interaction layer belongs in the execution file
- no native buttons, labels, inspector widgets, or other demo chrome belong in
  the execution file
- no logic for positioning demo-only controls or overlays belongs in the
  execution file
- no external functions unrelated to the component usage should be declared in
  the execution file
- no instrumentation wrappers should hide real component construction
- no clever helper code should obscure how the component is actually used
- no top-level constants or config blocks should exist only to "style the
  demo" when direct declarative values would be easier to read
- no setup-heavy scaffolding should pollute the main screen file

If a developer must read setup code before understanding how the component is
used, the demo is structured incorrectly.

Prefer declarative, readable code that favors user understanding of how to use
the thing being demoed.

The execution file should prioritize:

- direct construction
- direct composition
- direct property values
- obvious flow

The execution file should avoid:

- demo-only UI wiring
- overlay positioning systems
- helper abstractions that save little but hide intent
- "styling the demo" through indirection when the real lesson is component usage

## Spec First

Before implementing a demo:

1. identify the authoritative spec section
2. list the exact public props and behaviors to validate
3. list the invalid or ambiguous cases that must not be implied as valid
4. define screen cases from the contract, not from implementation convenience

Demo code must not invent semantics that the spec does not define.

If implementation and expected behavior disagree:

1. stop
2. inspect the spec
3. document the conflict before normalizing the demo around one accidental implementation behavior

If a component does not own a behavior, the demo must not recreate that
behavior with demo-local math just to make a more impressive screen.

Examples:

- a `Drawable` demo must not implement child layout or spacing composition
- a non-layout component demo must not pretend to measure or arrange descendants

Primary spec authority:

- [UI Library Specification](/Users/vanrez/Documents/game-dev/lua-ui-library/docs/spec/ui-library-spec.md)
- [UI Foundation Specification](/Users/vanrez/Documents/game-dev/lua-ui-library/docs/spec/ui-foundation-spec.md)
- [UI Controls Specification](/Users/vanrez/Documents/game-dev/lua-ui-library/docs/spec/ui-controls-spec.md)
- [UI Graphics Specification](/Users/vanrez/Documents/game-dev/lua-ui-library/docs/spec/ui-graphics-spec.md)
- [UI Motion Specification](/Users/vanrez/Documents/game-dev/lua-ui-library/docs/spec/ui-motion-spec.md)

## Demo Shape

Each demo must validate one public contract at a time through the real
implementation of the component under test.

A demo may cover:

- one component
- one tightly coupled component pair

A demo must not become:

- a kitchen-sink playground
- a phase showcase
- an implementation experiment disconnected from the spec
- a demo-local simulation of behavior the component does not actually own
- a wall of setup code that hides actual component usage

## File Structure

Preferred layout for a non-trivial multi-screen demo:

- `main.lua` for bootstrap and screen registration only
- shared helper utilities in `demos/common/screen_helper.lua`
- one `screens/` directory with one file per screen
- one companion `screens/{name}_setup.lua` for non-essential instrumentation

Every non-trivial screen should be split into two files:

- `{name}.lua`
- `{name}_setup.lua`

`{name}.lua` is the execution file.

It should contain only:

- imports relevant to the component being demoed
- direct object construction for the target component
- direct scene composition for the target component
- the minimal runtime flow needed to make the example work

Prefer direct, declarative values in the execution file when only a small
number of objects are being constructed.

Do not add small indirection layers such as:

- tiny constants used once
- one-off config tables that only rename obvious literals
- helper functions that save only one or two repeated lines

`{name}_setup.lua` is the setup file.

It may contain:

- demo instrumentation
- hint wiring
- inspection overlays
- native buttons
- screen-local positioning utilities
- other non-essential visual scaffolding

The execution file must not call generic wrappers such as:

- `mark_box(...)`
- `attach_drawable(...)`
- `make_node(...)`

When setup code needs to manipulate or inspect nodes created by the execution
file, it must bind to those nodes through stable public `id` values and
retained lookup such as `findById(...)`.

The contract division is:

- execution file: constructs the real public scene and declares stable node IDs
- setup file: finds those nodes through the same public contract the reader
  should understand

## Shared Infrastructure

All demos use the shared plain-Love shell in
[demos/common/demo_base.lua](/Users/vanrez/Documents/game-dev/lua-ui-library/demos/common/demo_base.lua).

Use shared infrastructure from `demos/common/`:

- `bootstrap.lua`
- `demo_base.lua`
- `colors.lua`

Do not duplicate:

- root bootstrap logic
- header or footer rendering
- screen switching
- reset behavior
- memory overlay
- sidebar framework

`DemoBase` owns:

- left/right screen switching
- screen reset
- navigation visibility
- memory monitor visibility
- quit handling
- screen rebuild between switches
- reset of common global Love state after screen teardown

The demo must not override those responsibilities.

## Screen Lifecycle

Every screen must be a factory registered through `DemoBase:push_screen(...)`.

Each screen factory receives:

- `index`
- `scope`
- `owner`

Use `scope` only for temporary tracked Love resources such as fonts.

`scope` is not a cleanup-callback API.

Do not rely on manual teardown inside demo code.

Every reset must rebuild the screen from scratch.

## Sidebar

The sidebar is only for non-visible state that cannot be inspected with the
mouse.

Use the sidebar for:

- non-visible state
- hidden-node facts
- state that cannot be inspected through the shared hover hint

Do not use the sidebar for:

- long prose
- behavior explanations
- duplicate navigation markers
- values already available through hover hints
- visible-object inspection data

Behavior explanations belong in the header description below the title.

Sidebar lines should be:

- short
- factual
- current
- easy to compare across frames

Shared sidebar helpers:

- `add_info_item(title, lines) -> index`
- `set_info_title(index, title)`
- `set_info_lines(index, lines)`
- `set_info_collapsed(index, collapsed)`
- `toggle_info_item(index)`
- `clear_info_items()`

Sidebar state is screen-scoped and is cleared automatically on screen switch and
screen reset.

## Hover Hints

Hover hints exist to inspect the hovered object and nothing else.

The first row is always fixed:

- `node: {name}`

That row is owned by the shared hint renderer and must not be redefined per
screen.

All remaining hint rows should:

- expose only inspectable properties relevant to the behavior under test
- use property labels that match the real property naming
- use unique labels within the same hint
- use dotted labels for true sub-properties such as `rect.content` or `rect.bounds`
- prefer grouped labels when inspecting a pair or set as one concept
- prefer badges for scalar values

Repeated hint labels are invalid and should fail deterministically.

Do not use hints for:

- free-form instructions
- behavior explanations
- duplicated visible labels
- unrelated runtime data
