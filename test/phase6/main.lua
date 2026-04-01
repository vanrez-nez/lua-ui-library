package.path = '?.lua;?/init.lua;' .. package.path

local UI = require('lib.ui')
local Stage             = UI.Stage
local Container         = UI.Container
local Drawable          = UI.Drawable
local Row               = UI.Row
local Column            = UI.Column
local ScrollableContainer = UI.ScrollableContainer

-- ── Palette ─────────────────────────────────────────────────────────────────

local BG           = { 0.09, 0.09, 0.11, 1 }
local PANEL_BG     = { 0.14, 0.14, 0.18, 1 }
local CARD_BG      = { 0.20, 0.20, 0.26, 1 }
local ACCENT       = { 0.40, 0.60, 1.00, 1 }
local ACCENT_DIM   = { 0.30, 0.44, 0.76, 1 }
local WHITE        = { 1, 1, 1, 1 }
local GREY         = { 0.5, 0.5, 0.55, 1 }
local SCROLLBAR_TRACK = { 0.20, 0.20, 0.25, 0.5 }
local SCROLLBAR_THUMB = { 0.50, 0.60, 0.90, 0.8 }

-- ── State ───────────────────────────────────────────────────────────────────

local stage
local active_demo = 1
local demo_names = {
    'Vertical',
    'Horizontal',
    'Two-Axis',
    'Momentum',
    'Nested',
    'Disabled',
}

local demo_containers = {}

-- ── Helpers ─────────────────────────────────────────────────────────────────

local function hsl_to_rgb(h, s, l)
    h = h % 360
    local c = (1 - math.abs(2 * l - 1)) * s
    local x = c * (1 - math.abs((h / 60) % 2 - 1))
    local m = l - c / 2
    local r, g, b = 0, 0, 0
    if h < 60 then r, g, b = c, x, 0
    elseif h < 120 then r, g, b = x, c, 0
    elseif h < 180 then r, g, b = 0, c, x
    elseif h < 240 then r, g, b = 0, x, c
    elseif h < 300 then r, g, b = x, 0, c
    else r, g, b = c, 0, x end
    return r + m, g + m, b + m
end

local function make_colored_card(index, w, h, label)
    local hue = (index * 37) % 360
    local r, g, b = hsl_to_rgb(hue, 0.6, 0.45)
    return Drawable({
        tag = label or ('card_' .. index),
        width = w,
        height = h,
        interactive = false,
    }), { r, g, b, 1 }
end

-- ── Demo builders ───────────────────────────────────────────────────────────

local function build_vertical_demo()
    local sc = ScrollableContainer.new({
        width = 280,
        height = 400,
        scrollYEnabled = true,
        scrollXEnabled = false,
        momentum = false,
        showScrollbars = true,
    })

    local col = Column.new({ width = 'fill', height = 'content', gap = 8 })
    for i = 1, 100 do
        local card = Drawable({ width = 260, height = 50, tag = 'v_item_' .. i })
        col:addChild(card)
    end
    sc.content:addChild(col)
    return sc, 'Vertical scroll – 100 items in a Column'
end

local function build_horizontal_demo()
    local sc = ScrollableContainer.new({
        width = 400,
        height = 120,
        scrollYEnabled = false,
        scrollXEnabled = true,
        momentum = false,
        showScrollbars = true,
    })

    local row = Row.new({ height = 'fill', width = 'content', gap = 8 })
    for i = 1, 15 do
        local card = Drawable({ width = 100, height = 100, tag = 'h_item_' .. i })
        row:addChild(card)
    end
    sc.content:addChild(row)
    return sc, 'Horizontal scroll – 15 items in a Row'
end

local function build_two_axis_demo()
    local sc = ScrollableContainer.new({
        width = 300,
        height = 300,
        scrollYEnabled = true,
        scrollXEnabled = true,
        momentum = false,
        showScrollbars = true,
    })

    -- Grid of cards
    for row = 0, 5 do
        for col = 0, 5 do
            local card = Drawable({
                width = 80,
                height = 80,
                x = col * 90,
                y = row * 90,
                tag = 'grid_' .. row .. '_' .. col,
            })
            sc.content:addChild(card)
        end
    end
    return sc, 'Two-axis scroll – 6×6 grid'
end

local function build_momentum_demo()
    local sc = ScrollableContainer.new({
        width = 280,
        height = 400,
        scrollYEnabled = true,
        scrollXEnabled = false,
        momentum = true,
        momentumDecay = 0.97,
        overscroll = true,
        showScrollbars = true,
    })

    local col = Column.new({ width = 'fill', height = 'content', gap = 6 })
    for i = 1, 100 do
        local card = Drawable({ width = 260, height = 40, tag = 'mom_item_' .. i })
        col:addChild(card)
    end
    sc.content:addChild(col)
    return sc, 'Momentum + overscroll – flick to scroll'
end

local function build_nested_demo()
    local outer = ScrollableContainer.new({
        width = 300,
        height = 400,
        scrollYEnabled = true,
        momentum = false,
        showScrollbars = true,
    })

    local col = Column.new({ width = 'fill', height = 'content', gap = 12 })

    -- Add some normal items
    for i = 1, 5 do
        local card = Drawable({ width = 260, height = 50, tag = 'outer_' .. i })
        col:addChild(card)
    end

    -- Add a nested scroller
    local inner = ScrollableContainer.new({
        width = 260,
        height = 150,
        scrollYEnabled = true,
        momentum = false,
        showScrollbars = true,
    })
    local inner_col = Column.new({ width = 'fill', height = 'content', gap = 4 })
    for i = 1, 12 do
        local card = Drawable({ width = 240, height = 30, tag = 'inner_' .. i })
        inner_col:addChild(card)
    end
    inner.content:addChild(inner_col)
    col:addChild(inner)

    -- More normal items
    for i = 6, 10 do
        local card = Drawable({ width = 260, height = 50, tag = 'outer_' .. i })
        col:addChild(card)
    end

    outer.content:addChild(col)
    return outer, 'Nested scroll – inner consumes first'
end

local function build_disabled_demo()
    local sc = ScrollableContainer.new({
        width = 280,
        height = 300,
        scrollYEnabled = false,
        scrollXEnabled = false,
        showScrollbars = false,
    })

    local col = Column.new({ width = 'fill', gap = 8 })
    for i = 1, 10 do
        local card = Drawable({ width = 260, height = 50, tag = 'dis_item_' .. i })
        col:addChild(card)
    end
    sc.content:addChild(col)
    return sc, 'Both axes disabled – no scrolling'
end

local demo_builders = {
    build_vertical_demo,
    build_horizontal_demo,
    build_two_axis_demo,
    build_momentum_demo,
    build_nested_demo,
    build_disabled_demo,
}

-- ── Active demo info ────────────────────────────────────────────────────────

local active_desc = ''

local function rebuild_stage()
    if stage then
        stage:destroy()
    end

    local w, h = love.graphics.getDimensions()
    stage = Stage.new({ width = w, height = h })

    -- Build active demo
    local sc, desc = demo_builders[active_demo]()
    active_desc = desc
    demo_containers = { sc }

    -- Center it
    local ev = rawget(sc, '_effective_values')
    if ev then
        ev.x = math.floor((w - (ev.width or 0)) / 2)
        ev.y = math.floor((h - (ev.height or 0)) / 2) + 30
    end
    local pv = rawget(sc, '_public_values')
    if pv then
        pv.x = ev.x
        pv.y = ev.y
    end

    stage.baseSceneLayer:addChild(sc)
end

-- ── LÖVE callbacks ──────────────────────────────────────────────────────────

function love.load()
    love.graphics.setBackgroundColor(BG)
    rebuild_stage()
end

function love.update(dt)
    if stage and not rawget(stage, '_destroyed') then
        stage:update(dt)
    end
end

function love.draw()
    if not stage or rawget(stage, '_destroyed') then return end

    local g = love.graphics
    local w, h = g.getDimensions()

    -- Draw stage tree manually (since we don't have a full render pipeline here)
    draw_tree(g, stage)

    -- HUD
    g.setColor(WHITE)
    g.printf('[' .. active_demo .. '/' .. #demo_names .. '] ' .. demo_names[active_demo],
        0, 8, w, 'center')
    g.setColor(GREY)
    g.printf(active_desc, 0, 28, w, 'center')
    g.printf('← / → to switch demos  |  Scroll with mousewheel or drag',
        0, h - 24, w, 'center')

    -- Scroll state info
    if #demo_containers > 0 then
        local sc = demo_containers[1]
        local sx, sy = sc:_get_scroll_offset()
        local mx, my = sc:_get_scroll_range()
        local st = sc:_get_scroll_state()
        g.setColor(ACCENT_DIM)
        g.printf(string.format('offset=(%.0f, %.0f)  range=(%.0f, %.0f)  state=%s',
            sx, sy, mx, my, st), 0, h - 44, w, 'center')
    end
end

-- ── Tree drawing ────────────────────────────────────────────────────────────

function draw_tree(g, node)
    if rawget(node, '_destroyed') then return end
    local ev = rawget(node, '_effective_values')
    if ev and ev.visible == false then return end

    local is_drawable = rawget(node, '_ui_drawable_instance')
    local is_scroll = rawget(node, '_ui_scrollable_instance')

    -- Read cached world bounds once — stage:update() has already refreshed them.
    -- Calling node:getWorldBounds() here would re-trigger _synchronize_for_read()
    -- on every node, causing O(N²) layout traversals per draw frame.
    local bounds = rawget(node, '_world_bounds_cache')

    -- Draw Drawable nodes as colored rects
    if is_drawable and bounds then
        local tag = (ev and ev.tag) or ''

        if tag:find('scrollbar_v_track') then
            g.setColor(SCROLLBAR_TRACK)
            g.rectangle('fill', bounds.x, bounds.y, bounds.width, bounds.height, 2, 2)
        elseif tag:find('scrollbar_v_thumb') or tag:find('scrollbar_h_thumb') then
            g.setColor(SCROLLBAR_THUMB)
            g.rectangle('fill', bounds.x, bounds.y, bounds.width, bounds.height, 3, 3)
        elseif tag:find('scrollbar_h_track') then
            g.setColor(SCROLLBAR_TRACK)
            g.rectangle('fill', bounds.x, bounds.y, bounds.width, bounds.height, 2, 2)
        else
            -- Color by tag index
            local idx = tonumber(tag:match('(%d+)$')) or 0
            local hue = (idx * 37) % 360
            local r, gg, b = hsl_to_rgb(hue, 0.55, 0.5)
            g.setColor(r, gg, b, 0.9)
            g.rectangle('fill', bounds.x, bounds.y, bounds.width, bounds.height, 4, 4)
            g.setColor(1, 1, 1, 0.7)
            g.printf(tag, bounds.x + 4, bounds.y + 4,
                math.max(1, bounds.width - 8), 'left')
        end
    end

    -- Clip children if needed
    local should_clip = ev and ev.clipChildren
    if should_clip and bounds then
        g.setScissor(bounds.x, bounds.y, bounds.width, bounds.height)
    end

    -- Draw ScrollableContainer background
    if is_scroll and bounds then
        g.setColor(PANEL_BG)
        g.rectangle('fill', bounds.x, bounds.y, bounds.width, bounds.height, 6, 6)
        g.setColor(ACCENT_DIM[1], ACCENT_DIM[2], ACCENT_DIM[3], 0.3)
        g.rectangle('line', bounds.x, bounds.y, bounds.width, bounds.height, 6, 6)
    end

    -- Recurse into children
    local children = rawget(node, '_children') or {}
    for i = 1, #children do
        draw_tree(g, children[i])
    end

    if should_clip then
        g.setScissor()
    end
end

-- ── Input ───────────────────────────────────────────────────────────────────

function love.wheelmoved(x, y)
    if stage and not rawget(stage, '_destroyed') then
        local mx, my = love.mouse.getPosition()
        stage:deliverInput({
            kind = 'wheelmoved',
            x = x,
            y = y,
            stageX = mx,
            stageY = my,
        })
    end
end

function love.mousepressed(x, y, button)
    if stage and not rawget(stage, '_destroyed') then
        stage:deliverInput({
            kind = 'mousepressed',
            x = x,
            y = y,
            button = button,
        })
    end
end

function love.mousereleased(x, y, button)
    if stage and not rawget(stage, '_destroyed') then
        stage:deliverInput({
            kind = 'mousereleased',
            x = x,
            y = y,
            button = button,
        })
    end
end

function love.mousemoved(x, y, dx, dy)
    if stage and not rawget(stage, '_destroyed') then
        stage:deliverInput({
            kind = 'mousemoved',
            x = x,
            y = y,
            dx = dx,
            dy = dy,
        })
    end
end

function love.keypressed(key)
    if key == 'escape' then
        love.event.quit()
        return
    end

    if key == 'right' then
        active_demo = (active_demo % #demo_names) + 1
        rebuild_stage()
        return
    end

    if key == 'left' then
        active_demo = ((active_demo - 2) % #demo_names) + 1
        rebuild_stage()
        return
    end

    if stage and not rawget(stage, '_destroyed') then
        stage:deliverInput({
            kind = 'keypressed',
            key = key,
        })
    end
end

function love.resize(w, h)
    rebuild_stage()
end
