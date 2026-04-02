package.path = '?.lua;?/init.lua;' .. package.path

local UI = require('lib.ui')
local FontCache = require('lib.ui.text.font_cache')

local Stage = UI.Stage
local Column = UI.Column
local Row = UI.Row
local Text = UI.Text

local BG = { 0.09, 0.1, 0.12, 1 }
local PANEL = { 0.14, 0.15, 0.19, 1 }
local BORDER = { 0.34, 0.37, 0.45, 1 }
local FG = { 0.95, 0.96, 0.98, 1 }
local SUB = { 0.66, 0.69, 0.75, 1 }
local ACCENT = { 0.19, 0.66, 0.96, 1 }
local FONT_PATH = 'assets/fonts/DynaPuff-Regular.ttf'

local stage
local root
local refs = {}

local function rounded(value)
    return math.floor((value or 0) + 0.5)
end

local function label(text, size, color, opts)
    opts = opts or {}
    return Text.new({
        text = text,
        font = opts.font or FONT_PATH,
        fontSize = size or 16,
        lineHeight = opts.lineHeight or 1,
        color = color or FG,
        width = opts.width or 'fill',
        maxWidth = opts.maxWidth,
        textAlign = opts.textAlign or 'start',
        wrap = opts.wrap == true,
    })
end

local function measured_height(size, line_height, lines)
    local font = FontCache.get(FONT_PATH, size)
    return font:getHeight() * line_height * lines
end

local function set_ref(name, node)
    refs[name] = node
    return node
end

local function panel(width)
    local node = Column.new({
        width = width or 'fill',
        height = 'content',
        gap = 12,
        padding = { 16, 16, 16, 16 },
        align = 'stretch',
        justify = 'start',
    })
    rawset(node, '_text_demo_panel', true)
    return node
end

local function build_scene()
    local scene_root = Column.new({
        width = 'fill',
        height = 'fill',
        gap = 18,
        padding = { 24, 24, 24, 24 },
        align = 'stretch',
        justify = 'start',
    })

    scene_root:addChild(label('Text Harness', 30, FG, {
        textAlign = 'center',
        lineHeight = 1.05,
        maxWidth = 1200,
    }))
    scene_root:addChild(label(
        'Validates font loading, wrapping, line-height, alignment, and multiline measurement against the current Text control.',
        15,
        SUB,
        { textAlign = 'center', lineHeight = 1.25, maxWidth = 1200, wrap = true }
    ))

    local top = Row.new({
        width = 'fill',
        height = 'content',
        gap = 16,
        align = 'start',
        justify = 'start',
    })

    local styles = panel(420)
    styles:addChild(label('Font And Size', 18, ACCENT))
    styles:addChild(set_ref('lh_base', label('DynaPuff 16 / lineHeight 1.0', 16, FG, { lineHeight = 1 })))
    styles:addChild(set_ref('lh_tall', label('DynaPuff 16 / lineHeight 1.35', 16, FG, { lineHeight = 1.35 })))
    styles:addChild(set_ref('size_large', label('DynaPuff 24 / lineHeight 1.1', 24, FG, { lineHeight = 1.1 })))
    styles:addChild(label('Color override still respects measurement.', 16, { 0.95, 0.74, 0.25, 1 }, {
        lineHeight = 1.2,
    }))
    top:addChild(styles)

    local multiline = panel('fill')
    multiline:addChild(label('Multiline And Wrapping', 18, ACCENT))
    multiline:addChild(set_ref('multiline', label('Explicit\nnewline\nmeasurement', 16, FG, {
        lineHeight = 1.3,
    })))
    multiline:addChild(set_ref('wrapped', label(
        'Wrapped text should use the assigned width, keep each line inside the panel, and respect lineHeight consistently during both measurement and draw.',
        16,
        FG,
        { width = 'fill', wrap = true, lineHeight = 1.3, maxWidth = 420 }
    )))
    top:addChild(multiline)

    scene_root:addChild(top)

    local bottom = Row.new({
        width = 'fill',
        height = 'content',
        gap = 16,
        align = 'start',
        justify = 'start',
    })

    local alignment = panel(420)
    alignment:addChild(label('Alignment', 18, ACCENT))
    alignment:addChild(label('Start aligned', 16, FG, { textAlign = 'start' }))
    alignment:addChild(label('Centered text', 16, FG, { textAlign = 'center' }))
    alignment:addChild(label('End aligned', 16, FG, { textAlign = 'end' }))
    bottom:addChild(alignment)

    local notes = panel('fill')
    notes:addChild(label('Notes', 18, ACCENT))
    notes:addChild(label(
        'This harness exercises Love Font APIs rather than low-level glyph raster data. GlyphData remains relevant only if Text later implements custom per-glyph shaping or effects.',
        15,
        SUB,
        { width = 'fill', wrap = true, lineHeight = 1.25 }
    ))
    bottom:addChild(notes)

    scene_root:addChild(bottom)

    local checks = panel('fill')
    checks:addChild(label('Verification', 18, ACCENT))
    checks:addChild(set_ref('verification_text', label('Running text checks...', 15, SUB, {
        width = 'fill',
        wrap = true,
        lineHeight = 1.25,
    })))
    scene_root:addChild(checks)

    return scene_root
end

local function update_verification()
    local verification = refs.verification_text
    if verification == nil then
        return
    end

    local results = {}

    local base = refs.lh_base
    local tall = refs.lh_tall
    local multiline = refs.multiline
    local wrapped = refs.wrapped

    if base ~= nil and tall ~= nil then
        local base_height = base:getLocalBounds().height
        local tall_height = tall:getLocalBounds().height
        if tall_height > base_height then
            results[#results + 1] = string.format('PASS lineHeight increases height: %d -> %d', rounded(base_height), rounded(tall_height))
        else
            results[#results + 1] = string.format('FAIL lineHeight height check: %d -> %d', rounded(base_height), rounded(tall_height))
        end
    end

    if multiline ~= nil then
        local actual = multiline:getLocalBounds().height
        local expected = measured_height(16, 1.3, 3)
        if math.abs(actual - expected) <= 1 then
            results[#results + 1] = string.format('PASS explicit newline measurement: expected %d got %d', rounded(expected), rounded(actual))
        else
            results[#results + 1] = string.format('FAIL explicit newline measurement: expected %d got %d', rounded(expected), rounded(actual))
        end
    end

    if wrapped ~= nil then
        local bounds = wrapped:getLocalBounds()
        if bounds.width <= 421 then
            results[#results + 1] = string.format('PASS wrapped width clamp: %d px', rounded(bounds.width))
        else
            results[#results + 1] = string.format('FAIL wrapped width clamp: %d px', rounded(bounds.width))
        end

        if bounds.height > measured_height(16, 1.3, 1) then
            results[#results + 1] = string.format('PASS wrapped text spans multiple lines: %d px tall', rounded(bounds.height))
        else
            results[#results + 1] = string.format('FAIL wrapped text did not reflow: %d px tall', rounded(bounds.height))
        end
    end

    verification:setText(table.concat(results, '\n'))
end

local function draw_node(node)
    local bounds = rawget(node, '_world_bounds_cache')
    if bounds == nil then
        return
    end

    if rawget(node, '_ui_text_control') then
        node:_draw_control(love.graphics)
        return
    end

    if rawget(node, '_text_demo_panel') then
        love.graphics.setColor(PANEL)
        love.graphics.rectangle('fill', bounds.x, bounds.y, bounds.width, bounds.height, 10, 10)
        love.graphics.setColor(BORDER)
        love.graphics.rectangle('line', bounds.x, bounds.y, bounds.width, bounds.height, 10, 10)
    end
end

function love.load()
    love.graphics.setBackgroundColor(BG)
    stage = Stage.new({ width = love.graphics.getWidth(), height = love.graphics.getHeight() })
    root = build_scene()
    stage.baseSceneLayer:addChild(root)
    stage:update(0)
    update_verification()
    stage:update(0)
end

function love.update(dt)
    if stage ~= nil then
        stage:update(dt)
        update_verification()
        stage:update(0)
    end
end

function love.draw()
    if stage ~= nil then
        love.graphics.clear(BG)
        if not rawget(stage, '_update_ran') then
            stage:update(0)
        end
        stage:draw(love.graphics, draw_node)
    end
end

function love.resize(w, h)
    if stage ~= nil then
        stage:resize(w, h)
        stage:update(0)
        update_verification()
        stage:update(0)
    end
end

function love.keypressed(key)
    if key == 'escape' then
        love.event.quit()
    end
end
