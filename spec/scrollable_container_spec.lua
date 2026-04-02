local Container = require('lib.ui.core.container')
local Drawable = require('lib.ui.core.drawable')
local ScrollableContainer = require('lib.ui.scroll.scrollable_container')
local Stage = require('lib.ui.scene.stage')
local Rectangle = require('lib.ui.core.rectangle')
local Column = require('lib.ui.layout.column')

local function assert_equal(actual, expected, message)
    if actual ~= expected then
        error(message .. ': expected ' .. tostring(expected) ..
            ', got ' .. tostring(actual), 2)
    end
end

local function assert_true(value, message)
    if not value then
        error(message, 2)
    end
end

local function assert_error(fn, needle, message)
    local ok, err = pcall(fn)

    if ok then
        error(message .. ': expected an error', 2)
    end

    local text = tostring(err)

    if needle and not text:find(needle, 1, true) then
        error(message .. ': expected error containing "' .. needle ..
            '", got "' .. text .. '"', 2)
    end
end

local function assert_near(actual, expected, tolerance, message)
    if math.abs(actual - expected) > tolerance then
        error(message .. ': expected ~' .. tostring(expected) ..
            ', got ' .. tostring(actual), 2)
    end
end

-- ── Anatomy Tests ───────────────────────────────────────────────────────────

local function run_anatomy_tests()
    local stage = Stage.new({ width = 400, height = 300 })

    local sc = ScrollableContainer.new({ width = 200, height = 150 })
    stage.baseSceneLayer:addChild(sc)

    assert_true(sc.viewport ~= nil, 'Viewport role node must exist')
    assert_true(sc.content ~= nil, 'Content role node must exist')

    -- Content is a child of viewport
    local viewport_children = rawget(sc.viewport, '_children') or {}
    assert_true(#viewport_children >= 1, 'Viewport must contain at least the content node')
    assert_equal(viewport_children[1], sc.content,
        'Content must be the first child of viewport')

    -- Viewport has clipChildren = true
    local vev = rawget(sc.viewport, '_effective_values')
    assert_equal(vev.clipChildren, true, 'Viewport must clip children')

    -- Content and viewport are read-only
    assert_error(function()
        sc.content = Container.new()
    end, 'read-only', 'Content must be read-only')

    assert_error(function()
        sc.viewport = Container.new()
    end, 'read-only', 'Viewport must be read-only')

    -- Direct child insertion is blocked
    assert_error(function()
        sc:addChild(Container.new({ width = 10, height = 10 }))
    end, 'direct child insertion', 'addChild must be blocked on ScrollableContainer')

    assert_error(function()
        sc:removeChild(sc.content)
    end, 'direct child removal', 'removeChild must be blocked on ScrollableContainer')

    stage:destroy()
end

-- ── Default Props Tests ─────────────────────────────────────────────────────

local function run_default_props_tests()
    local stage = Stage.new({ width = 400, height = 300 })

    local sc = ScrollableContainer.new({ width = 200, height = 150 })
    stage.baseSceneLayer:addChild(sc)

    assert_equal(sc.scrollXEnabled, false, 'scrollXEnabled default should be false')
    assert_equal(sc.scrollYEnabled, true, 'scrollYEnabled default should be true')
    assert_equal(sc.momentum, true, 'momentum default should be true')
    assert_equal(sc.momentumDecay, 0.95, 'momentumDecay default should be 0.95')
    assert_equal(sc.overscroll, false, 'overscroll default should be false')
    assert_equal(sc.scrollStep, 40, 'scrollStep default should be 40')
    assert_equal(sc.showScrollbars, true, 'showScrollbars default should be true')

    stage:destroy()
end

-- ── Offset Clamping Tests ───────────────────────────────────────────────────

local function run_offset_clamping_tests()
    local stage = Stage.new({ width = 400, height = 300 })

    local sc = ScrollableContainer.new({
        width = 200,
        height = 150,
        scrollYEnabled = true,
        momentum = false,
    })
    stage.baseSceneLayer:addChild(sc)

    -- Add tall content
    local tall_content = Container.new({ width = 200, height = 600 })
    sc.content:addChild(tall_content)

    stage:update()

    -- Scroll within range
    sc:_scroll_to(0, 100)
    local ox, oy = sc:_get_scroll_offset()
    assert_equal(oy, 100, 'Scroll to 100 should be 100')

    -- Scroll past max — should clamp
    sc:_scroll_to(0, 9999)
    ox, oy = sc:_get_scroll_offset()
    assert_true(oy <= 600, 'Scroll past max should clamp to max')

    -- Scroll below 0 — should clamp
    sc:_scroll_to(0, -100)
    ox, oy = sc:_get_scroll_offset()
    assert_equal(oy, 0, 'Scroll below 0 should clamp to 0')

    stage:destroy()
end

-- ── Empty Content Tests ─────────────────────────────────────────────────────

local function run_empty_content_tests()
    local stage = Stage.new({ width = 400, height = 300 })

    local sc = ScrollableContainer.new({
        width = 200,
        height = 150,
        scrollYEnabled = true,
    })
    stage.baseSceneLayer:addChild(sc)
    stage:update()

    -- With no children, content extent should be 0
    local cw, ch = sc:_get_content_extent()
    assert_equal(cw, 0, 'Empty content width should be 0')
    assert_equal(ch, 0, 'Empty content height should be 0')

    -- Should not be able to scroll
    sc:_scroll_to(0, 100)
    local ox, oy = sc:_get_scroll_offset()
    assert_equal(oy, 0, 'Empty content should not scroll')

    -- State should be idle
    assert_equal(sc:_get_scroll_state(), 'idle', 'Empty content state should be idle')

    stage:destroy()
end

-- ── Both Axes Disabled Tests ────────────────────────────────────────────────

local function run_both_axes_disabled_tests()
    local stage = Stage.new({ width = 400, height = 300 })

    local sc = ScrollableContainer.new({
        width = 200,
        height = 150,
        scrollXEnabled = false,
        scrollYEnabled = false,
    })
    stage.baseSceneLayer:addChild(sc)

    local tall_content = Container.new({ width = 500, height = 600 })
    sc.content:addChild(tall_content)
    stage:update()

    -- Max scroll range should be 0 on both axes
    local max_x, max_y = sc:_get_scroll_range()
    assert_equal(max_x, 0, 'Both axes disabled: max x should be 0')
    assert_equal(max_y, 0, 'Both axes disabled: max y should be 0')

    -- Programmatic scroll should be clamped to 0
    sc:_scroll_to(100, 200)
    local ox, oy = sc:_get_scroll_offset()
    assert_equal(ox, 0, 'Both axes disabled: scroll x should stay 0')
    assert_equal(oy, 0, 'Both axes disabled: scroll y should stay 0')

    stage:destroy()
end

-- ── State Transitions Tests ─────────────────────────────────────────────────

local function run_state_transition_tests()
    local stage = Stage.new({ width = 400, height = 300 })

    local sc = ScrollableContainer.new({
        width = 200,
        height = 150,
        scrollYEnabled = true,
        momentum = false,
    })
    stage.baseSceneLayer:addChild(sc)

    local tall_content = Container.new({ width = 200, height = 600 })
    sc.content:addChild(tall_content)
    stage:update()

    -- Initially idle
    assert_equal(sc:_get_scroll_state(), 'idle', 'Initial state should be idle')

    -- After programmatic scroll, still idle with momentum disabled
    sc:_scroll_by(0, 50)
    assert_equal(sc:_get_scroll_state(), 'idle', 'After scroll_by, state should remain idle')

    stage:destroy()
end

-- ── Programmatic Scroll Tests ───────────────────────────────────────────────

local function run_programmatic_scroll_tests()
    local stage = Stage.new({ width = 400, height = 300 })

    local sc = ScrollableContainer.new({
        width = 200,
        height = 150,
        scrollYEnabled = true,
        momentum = false,
    })
    stage.baseSceneLayer:addChild(sc)

    local tall_content = Container.new({ width = 200, height = 600 })
    sc.content:addChild(tall_content)
    stage:update()

    -- scroll_by increments
    sc:_scroll_by(0, 30)
    local ox, oy = sc:_get_scroll_offset()
    assert_equal(oy, 30, 'scroll_by should increment offset')

    sc:_scroll_by(0, 20)
    ox, oy = sc:_get_scroll_offset()
    assert_equal(oy, 50, 'scroll_by should accumulate offset')

    -- scroll_to sets absolute
    sc:_scroll_to(0, 200)
    ox, oy = sc:_get_scroll_offset()
    assert_equal(oy, 200, 'scroll_to should set absolute offset')

    stage:destroy()
end

-- ── Momentum Cancellation Tests ─────────────────────────────────────────────

local function run_momentum_cancellation_tests()
    local stage = Stage.new({ width = 400, height = 300 })

    local sc = ScrollableContainer.new({
        width = 200,
        height = 150,
        scrollYEnabled = true,
        momentum = true,
        overscroll = false,
    })
    stage.baseSceneLayer:addChild(sc)

    local tall_content = Container.new({ width = 200, height = 900 })
    sc.content:addChild(tall_content)
    stage:update()

    stage:deliverInput({
        kind = 'wheelmoved',
        x = 0,
        y = -1,
        stageX = 20,
        stageY = 20,
    })

    assert_equal(sc:_get_scroll_state(), 'inertial',
        'Coarse wheel input with momentum should enter inertial state')

    stage:deliverInput({
        kind = 'mousepressed',
        x = 20,
        y = 20,
        button = 1,
    })

    assert_equal(sc:_get_scroll_state(), 'idle',
        'Pointer press should stop inertial scrolling')

    local vx = rawget(sc, '_velocity_x') or 0
    local vy = rawget(sc, '_velocity_y') or 0
    assert_near(vx, 0, 1e-6, 'Velocity X should be reset when momentum is cancelled')
    assert_near(vy, 0, 1e-6, 'Velocity Y should be reset when momentum is cancelled')

    stage:destroy()
end

-- ── Overscroll Thumb Compression Tests ──────────────────────────────────────

local function run_overscroll_thumb_compression_tests()
    local stage = Stage.new({ width = 400, height = 300 })

    local sc = ScrollableContainer.new({
        width = 200,
        height = 150,
        scrollYEnabled = true,
        momentum = false,
        overscroll = true,
        showScrollbars = true,
    })
    stage.baseSceneLayer:addChild(sc)

    local tall_content = Container.new({ width = 200, height = 900 })
    sc.content:addChild(tall_content)
    stage:update()

    local v_thumb = rawget(sc, '_scrollbar_v_thumb')
    assert_true(v_thumb ~= nil, 'Vertical scrollbar thumb should exist')

    local function thumb_height_for_scroll(scroll_y)
        rawset(sc, '_scroll_state', 'dragging')
        rawset(sc, '_scroll_y', scroll_y)
        stage:update()
        local ev = rawget(v_thumb, '_effective_values')
        return (ev and ev.height) or 0
    end

    local h0 = thumb_height_for_scroll(0)
    local h1 = thumb_height_for_scroll(-20)
    local h2 = thumb_height_for_scroll(-60)
    local h3 = thumb_height_for_scroll(-120)

    assert_true(h1 < h0, 'Thumb should shrink on overscroll')
    assert_true(h2 < h1, 'Thumb should continue shrinking as overscroll grows')
    assert_true(h3 < h2, 'Thumb should keep shrinking without early plateau')

    stage:destroy()
end

-- ── Schema Validation Tests ─────────────────────────────────────────────────

local function run_schema_validation_tests()
    -- momentumDecay out of range
    assert_error(function()
        ScrollableContainer.new({
            width = 200,
            height = 150,
            momentumDecay = 0,
        })
    end, 'between 0 and 1', 'momentumDecay = 0 should error')

    assert_error(function()
        ScrollableContainer.new({
            width = 200,
            height = 150,
            momentumDecay = 1,
        })
    end, 'between 0 and 1', 'momentumDecay = 1 should error')

    -- scrollStep <= 0
    assert_error(function()
        ScrollableContainer.new({
            width = 200,
            height = 150,
            scrollStep = 0,
        })
    end, 'greater than 0', 'scrollStep = 0 should error')
end

-- ── TextArea Integration Boundary Tests ─────────────────────────────────────

local function run_textarea_boundary_tests()
    local stage = Stage.new({ width = 400, height = 300 })

    local region = ScrollableContainer._create_scroll_region({
        scroll_x = false,
        scroll_y = true,
        momentum = false,
        show_scrollbars = true,
    })
    stage.baseSceneLayer:addChild(region)

    assert_equal(region.scrollXEnabled, false, 'TextArea region: scrollX should be false')
    assert_equal(region.scrollYEnabled, true, 'TextArea region: scrollY should be true')
    assert_equal(region.momentum, false, 'TextArea region: momentum should be false')
    assert_equal(region.overscroll, false, 'TextArea region: overscroll should be false')

    -- Should function as a normal ScrollableContainer
    assert_true(region.content ~= nil, 'TextArea region must have content node')
    assert_true(region.viewport ~= nil, 'TextArea region must have viewport node')

    stage:destroy()
end

-- ── Nested Layout Scroll Regression Tests ──────────────────────────────────

local function run_nested_layout_scroll_regression_tests()
    local stage = Stage.new({ width = 800, height = 600 })

    local outer = ScrollableContainer.new({
        width = 300,
        height = 400,
        scrollYEnabled = true,
        momentum = false,
        showScrollbars = true,
    })
    stage.baseSceneLayer:addChild(outer)

    local outer_column = Column.new({
        width = 'fill',
        height = 'content',
        gap = 12,
    })

    for i = 1, 5 do
        outer_column:addChild(Drawable({ width = 260, height = 50, tag = 'outer_pre_' .. i }))
    end

    local inner = ScrollableContainer.new({
        width = 260,
        height = 150,
        scrollYEnabled = true,
        momentum = false,
        showScrollbars = true,
    })

    local inner_column = Column.new({
        width = 'fill',
        height = 'content',
        gap = 4,
    })
    for i = 1, 12 do
        inner_column:addChild(Drawable({ width = 240, height = 30, tag = 'inner_' .. i }))
    end
    inner.content:addChild(inner_column)
    outer_column:addChild(inner)

    for i = 1, 5 do
        outer_column:addChild(Drawable({ width = 260, height = 50, tag = 'outer_post_' .. i }))
    end

    outer.content:addChild(outer_column)

    stage:update()

    local max_x, max_y = inner:_get_scroll_range()
    assert_true(max_y > 0, 'Nested inner layout content should produce vertical scroll range')

    local inner_bounds = inner:getWorldBounds()
    stage:deliverInput({
        kind = 'wheelmoved',
        x = 0,
        y = -1,
        stageX = inner_bounds.x + 5,
        stageY = inner_bounds.y + 5,
    })

    local _, inner_offset_y = inner:_get_scroll_offset()
    local _, outer_offset_y = outer:_get_scroll_offset()
    assert_true(inner_offset_y > 0,
        'Inner nested scroll container should consume wheel input while it has remaining range')
    assert_equal(outer_offset_y, 0,
        'Outer scroll container should not consume while inner still has range')

    stage:destroy()
end

local function run_content_fill_contract_tests()
    local stage = Stage.new({ width = 400, height = 300 })
    local scrollable = ScrollableContainer.new({
        width = 220,
        height = 160,
        scrollYEnabled = true,
        momentum = false,
        showScrollbars = false,
    })
    local content_root = Column.new({
        width = 'fill',
        height = 'content',
        gap = 8,
    })

    content_root:addChild(Drawable({ width = 120, height = 40 }))
    content_root:addChild(Drawable({ width = 120, height = 40 }))
    scrollable.content:addChild(content_root)
    stage.baseSceneLayer:addChild(scrollable)

    stage:update()

    assert_equal(content_root:getLocalBounds().width, 220,
        'ScrollableContainer content should define delegated fill resolution for direct child width')

    stage:destroy()
end

-- ── Run all ─────────────────────────────────────────────────────────────────

return {
    run = function()
        run_anatomy_tests()
        run_default_props_tests()
        run_offset_clamping_tests()
        run_empty_content_tests()
        run_both_axes_disabled_tests()
        run_state_transition_tests()
        run_programmatic_scroll_tests()
        run_momentum_cancellation_tests()
        run_overscroll_thumb_compression_tests()
        run_schema_validation_tests()
        run_textarea_boundary_tests()
        run_nested_layout_scroll_regression_tests()
        run_content_fill_contract_tests()
    end,
}
