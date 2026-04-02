# DemoBase

`DemoBase` is the shared plain-Love2D shell for demos under `demos/`.

It is intentionally outside `lib/ui`.
It exists to provide consistent demo infrastructure without making demos depend on the UI library for their outer shell.

## What DemoBase Owns

`DemoBase` owns:

- full-screen background clear
- top header overlay
- bottom footer overlay
- collapsible left info sidebar
- shared navigation text
- screen counting and active screen index
- left/right screen switching
- active screen reset
- chrome visibility toggle
- memory monitor toggle
- active-screen lifecycle
- forced cleanup between screens
- reset of common global Love state after screen teardown

## Screen Model

Screens are registered as factories:

```lua
local DemoBase = require('demos.common.demo_base')

local demo_base = DemoBase.new({
    title = 'My Demo',
    description = 'What it does and what it tests',
})

demo_base:push_screen(function(index, scope, owner)
    local font = scope:font(18)

    return {
        draw = function()
            local g = love.graphics
            local width, height = g.getDimensions()
            g.setFont(font)
            g.printf(
                string.format('Screen %d/%d', index, owner:get_screen_count()),
                0,
                height * 0.5,
                width,
                'center'
            )
        end,
    }
end)
```

Factory arguments:

- `index`: the 1-based index of the screen being created
- `scope`: a forced-cleanup resource scope for Love objects and cleanup callbacks
- `owner`: the `DemoBase` instance

## Scope Rules

Every screen should allocate short-lived Love objects through `scope` when possible:

- `scope:font(...)`
- `scope:image(...)`
- `scope:image_data(...)`
- `scope:canvas(...)`
- `scope:shader(...)`
- `scope:mesh(...)`
- `scope:quad(...)`
- `scope:source(...)`
- `scope:on_cleanup(function() ... end)`

When the active screen changes, `DemoBase`:

1. cleans the previous scope
2. releases tracked resources
3. runs registered cleanup callbacks
4. resets common global Love state
5. creates the next screen fresh

This is the isolation boundary.

## Shared Keys

These bindings are owned by `DemoBase`:

- `[Left/Right]` switch screen
- `[R]` reset screen
- `[H]` toggle header/footer navigation
- `[M]` toggle memory monitor
- `[Esc]` quit

When navigation is hidden with `[H]`, the info sidebar also hides.

## Shared Colors

Use [colors.lua](/Users/vanrez/Documents/game-dev/lua-ui-library/demos/common/colors.lua) for demo palette values.

It exports:

- `names`: raw reusable named colors
- `roles`: semantic usage colors like `background`, `surface`, `surface_alt`, `surface_emphasis`, `text`, `text_muted`, `border`, and accent fill/line pairs

Demo rule:

- do not introduce new hardcoded RGBA literals in demos when an existing `DemoColors.roles` entry already fits the usage

## Info Sidebar

`DemoBase` provides a collapsible left sidebar for screen-specific inspection data.

Capabilities:

- up to 10 items
- each item has a title and a list of lines
- each item can be collapsed or expanded from its title bar
- the whole sidebar collapses to a shared triangle toggle
- item panels use `+/-` controls
- bars and panels use plain rectangles without rounded corners

Public sidebar helpers:

- `add_info_item(title, lines) -> index`
- `set_info_title(index, title)`
- `set_info_lines(index, lines)`
- `set_info_collapsed(index, collapsed)`
- `toggle_info_item(index)`
- `clear_info_items()`

Sidebar state is screen-scoped.
`DemoBase` clears info items automatically on screen switch and screen reset.

## What Demos Should Do

- set only `title` and `description` when creating `DemoBase`
- register screens with `push_screen(...)`
- keep each screen scoped to one component or one tightly coupled component pair
- use `scope` for demo-owned Love resources
- keep screen-local input behavior inside `screen:keypressed(...)` only for keys not already owned by `DemoBase`

## What Demos Must Not Do

- do not override left/right screen switching
- do not override `[R]`, `[H]`, `[M]`, or `[Esc]`
- do not manage their own screen index counters outside `DemoBase`
- do not rely on manual screen destruction
- do not bypass `scope` for temporary demo-owned Love resources unless there is a strong reason
- do not move the header/footer shell logic into the demo itself
- do not build a second custom inspector panel when the shared sidebar is sufficient

The most important rule:

- screen switching is owned by `DemoBase`, not by the demo

## Minimal Wiring

```lua
function love.update(dt)
    demo_base:update(dt)
end

function love.draw()
    demo_base:begin_frame()
    demo_base:draw()
end

function love.keypressed(key)
    demo_base:handle_keypressed(key)
end

function love.mousepressed(x, y, button)
    demo_base:handle_mousepressed(x, y, button)
end
```
