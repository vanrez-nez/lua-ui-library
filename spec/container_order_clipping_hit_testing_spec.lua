local Container = require('lib.ui.core.container')

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

local function assert_nil(value, message)
    if value ~= nil then
        error(message .. ': expected nil, got ' .. tostring(value), 2)
    end
end

local function assert_children(actual, expected, message)
    assert_equal(#actual, #expected, message .. ' child count')

    for index = 1, #expected do
        assert_equal(actual[index], expected[index], message .. ' child ' .. index)
    end
end

local function assert_contains(values, needle, message)
    for index = 1, #values do
        if values[index] == needle then
            return
        end
    end

    error(message .. ': missing "' .. tostring(needle) .. '"', 2)
end

local function make_fake_graphics()
    local graphics = {
        calls = {},
        current_scissor = nil,
        stencil_compare = nil,
        stencil_value = nil,
    }

    function graphics.getScissor()
        local rect = graphics.current_scissor

        if rect == nil then
            return nil
        end

        return rect.x, rect.y, rect.width, rect.height
    end

    function graphics.setScissor(x, y, width, height)
        if x == nil then
            graphics.current_scissor = nil
            graphics.calls[#graphics.calls + 1] = 'scissor:nil'
            return
        end

        graphics.current_scissor = {
            x = x,
            y = y,
            width = width,
            height = height,
        }
        graphics.calls[#graphics.calls + 1] = string.format(
            'scissor:%.2f:%.2f:%.2f:%.2f',
            x,
            y,
            width,
            height
        )
    end

    function graphics.getStencilTest()
        return graphics.stencil_compare, graphics.stencil_value
    end

    function graphics.setStencilTest(compare, value)
        graphics.stencil_compare = compare
        graphics.stencil_value = value

        if compare == nil then
            graphics.calls[#graphics.calls + 1] = 'stencil_test:nil'
            return
        end

        graphics.calls[#graphics.calls + 1] =
            'stencil_test:' .. tostring(compare) .. ':' .. tostring(value)
    end

    function graphics.stencil(callback, action, value, keepvalues)
        graphics.calls[#graphics.calls + 1] =
            'stencil:' .. tostring(action) .. ':' .. tostring(value) ..
            ':' .. tostring(keepvalues)
        callback()
    end

    function graphics.polygon(mode, points)
        graphics.calls[#graphics.calls + 1] =
            'polygon:' .. tostring(mode) .. ':' .. tostring(#points)
    end

    return graphics
end

local function run_ordering_and_hit_priority_tests()
    local root = Container.new({
        width = 200,
        height = 200,
    })
    local low = Container.new({
        tag = 'low',
        interactive = true,
        width = 120,
        height = 120,
        zIndex = 0,
    })
    local mid = Container.new({
        tag = 'mid',
        interactive = true,
        width = 120,
        height = 120,
        zIndex = 1,
    })
    local high = Container.new({
        tag = 'high',
        interactive = true,
        width = 120,
        height = 120,
        zIndex = 1,
    })

    root:addChild(low)
    root:addChild(mid)
    root:addChild(high)

    local ordered = root:_get_ordered_children()

    assert_children(ordered, { low, mid, high },
        'Ordered children should sort by zIndex and preserve stable insertion order')
    assert_equal(root:_hit_test(20, 20), high,
        'Hit resolution should use reverse draw order among equal zIndex siblings')

    mid.zIndex = 3

    assert_equal(root:_hit_test(20, 20), mid,
        'Increasing zIndex should move the sibling ahead in both draw and hit order')
end

local function run_non_interactive_and_disabled_tests()
    local root = Container.new({
        width = 200,
        height = 200,
    })
    local shell = Container.new({
        width = 120,
        height = 120,
    })
    local leaf = Container.new({
        tag = 'leaf',
        interactive = true,
        x = 10,
        y = 10,
        width = 60,
        height = 60,
    })

    shell:addChild(leaf)
    root:addChild(shell)

    assert_equal(root:_hit_test(20, 20), leaf,
        'Non-interactive ancestors should remain structural for descendant hit resolution')

    leaf.interactive = false

    assert_nil(root:_hit_test(20, 20),
        'Hit testing should return no target when the tested point has no effectively targetable node')

    leaf.interactive = true
    shell.enabled = false

    assert_nil(root:_hit_test(20, 20),
        'Disabled ancestors must suppress descendant targetability')
end

local function run_clip_hit_tests()
    local root = Container.new({
        width = 300,
        height = 300,
    })
    local clip = Container.new({
        x = 150,
        y = 150,
        pivotX = 0.5,
        pivotY = 0.5,
        width = 100,
        height = 100,
        rotation = math.rad(45),
        clipChildren = true,
    })
    local inside = Container.new({
        tag = 'inside',
        interactive = true,
        x = 20,
        y = 20,
        width = 20,
        height = 20,
        zIndex = 1,
    })
    local overflow = Container.new({
        tag = 'overflow',
        interactive = true,
        x = -60,
        y = 20,
        width = 80,
        height = 40,
    })

    clip:addChild(overflow)
    clip:addChild(inside)
    root:addChild(clip)
    root:update()

    local overflow_x, overflow_y = overflow:localToWorld(10, 10)
    local inside_x, inside_y = inside:localToWorld(10, 10)

    assert_true(overflow:containsPoint(overflow_x, overflow_y),
        'Overflow child should still contain its own world-space point geometrically')
    assert_true(not clip:containsPoint(overflow_x, overflow_y),
        'Overflow sample should sit outside the rotated clip container bounds')
    assert_nil(root:_hit_test(overflow_x, overflow_y),
        'Rotated clip bounds must suppress overflow hit targets')
    assert_equal(root:_hit_test(inside_x, inside_y), inside,
        'Points inside the rotated clip bounds should still resolve to eligible descendants')
end

local function run_degenerate_clip_tests()
    local root = Container.new({
        width = 200,
        height = 200,
    })
    local clip = Container.new({
        clipChildren = true,
        width = 0,
        height = 80,
    })
    local leaf = Container.new({
        interactive = true,
        x = -20,
        y = 10,
        width = 60,
        height = 40,
    })

    clip:addChild(leaf)
    root:addChild(clip)
    root:update()

    local world_x, world_y = leaf:localToWorld(10, 10)

    assert_true(leaf:containsPoint(world_x, world_y),
        'Degenerate clips should not change the child geometry itself')
    assert_nil(root:_hit_test(world_x, world_y),
        'Degenerate clip bounds must behave as an empty effective clip region')
end

local function run_draw_clipping_tests()
    local root = Container.new({
        tag = 'root',
        width = 200,
        height = 200,
        clipChildren = true,
    })
    local axis = Container.new({
        tag = 'axis',
        x = 10,
        y = 10,
        width = 50,
        height = 50,
        clipChildren = true,
        zIndex = 0,
    })
    local rotated = Container.new({
        tag = 'rotated',
        x = 100,
        y = 100,
        pivotX = 0.5,
        pivotY = 0.5,
        width = 80,
        height = 80,
        rotation = math.rad(20),
        clipChildren = true,
        zIndex = 1,
    })
    local leaf = Container.new({
        tag = 'leaf',
        width = 20,
        height = 20,
    })
    local graphics = make_fake_graphics()
    local draw_order = {}

    rotated:addChild(leaf)
    root:addChild(rotated)
    root:addChild(axis)

    root:_draw_subtree(graphics, function(node)
        draw_order[#draw_order + 1] = node.tag
    end)

    assert_children(draw_order, { 'root', 'axis', 'rotated', 'leaf' },
        'Draw traversal should follow ascending draw order among siblings')
    assert_contains(graphics.calls, 'stencil:increment:1:true',
        'Rotated clips should use the stencil path for rendering')
    assert_contains(graphics.calls, 'stencil:decrement:1:true',
        'Nested stencil clips should restore the prior stencil state on pop')
    assert_contains(graphics.calls, 'stencil_test:nil',
        'Draw traversal should restore the prior stencil test after rendering')
    assert_contains(graphics.calls, 'scissor:nil',
        'Draw traversal should restore the prior scissor state after rendering')
end

local function run()
    run_ordering_and_hit_priority_tests()
    run_non_interactive_and_disabled_tests()
    run_clip_hit_tests()
    run_degenerate_clip_tests()
    run_draw_clipping_tests()
end

return {
    run = run,
}
