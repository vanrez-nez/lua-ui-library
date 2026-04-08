local Rectangle = require('lib.ui.core.rectangle')
local UI = require('lib.ui')

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

local function assert_rectangle_equal(actual, expected, message)
    assert_true(actual:equals(expected, 1e-9),
        message .. ': expected ' .. tostring(expected) ..
        ', got ' .. tostring(actual))
end

local function make_fake_graphics()
    local graphics = {
        scissor_calls = {},
    }

    function graphics.getScissor()
        return nil
    end

    function graphics.setScissor(x, y, width, height)
        graphics.scissor_calls[#graphics.scissor_calls + 1] = {
            x = x,
            y = y,
            width = width,
            height = height,
        }
    end

    return graphics
end

local function run_content_box_placement_tests()
    local stage = UI.Stage.new({
        width = 240,
        height = 160,
    })
    local stack = UI.Stack.new({
        width = 120,
        height = 90,
        padding = { 5, 10, 15, 20 },
    })
    local percentage_child = UI.Container.new({
        tag = 'percentage',
        x = 3,
        y = 4,
        width = '50%',
        height = '100%',
    })
    local anchored_child = UI.Container.new({
        tag = 'anchored',
        anchorX = 1,
        anchorY = 1,
        pivotX = 1,
        pivotY = 1,
        width = 30,
        height = 20,
    })

    stack:addChild(percentage_child)
    stack:addChild(anchored_child)
    stage.baseSceneLayer:addChild(stack)
    stage:update()

    assert_rectangle_equal(percentage_child:getLocalBounds(),
        Rectangle.new(0, 0, 45, 70),
        'Stack should resolve percentage-sized children from the effective content box')
    assert_rectangle_equal(stack:_get_effective_content_rect(),
        Rectangle.new(20, 5, 90, 70),
        'Stack should resolve a padded local content box')

    local percent_x, percent_y = percentage_child:localToWorld(0, 0)
    local anchor_right, anchor_bottom = anchored_child:localToWorld(30, 20)

    assert_equal(percent_x, 23,
        'Stack should place children relative to the content-box origin without overwriting x')
    assert_equal(percent_y, 9,
        'Stack should place children relative to the content-box origin without overwriting y')
    assert_equal(anchor_right, 140,
        'Stack should keep anchor-based placement independent from the child pivot on the horizontal axis')
    assert_equal(anchor_bottom, 95,
        'Stack should keep anchor-based placement independent from the child pivot on the vertical axis')

    stage:destroy()
end

local function run_layering_and_hit_resolution_tests()
    local stage = UI.Stage.new({
        width = 160,
        height = 120,
    })
    local stack = UI.Stack.new({
        width = 100,
        height = 100,
    })
    local low = UI.Container.new({
        tag = 'low',
        interactive = true,
        x = 10,
        y = 10,
        width = 50,
        height = 50,
        zIndex = 0,
    })
    local mid = UI.Container.new({
        tag = 'mid',
        interactive = true,
        x = 10,
        y = 10,
        width = 50,
        height = 50,
        zIndex = 1,
    })
    local high = UI.Container.new({
        tag = 'high',
        interactive = true,
        x = 10,
        y = 10,
        width = 50,
        height = 50,
        zIndex = 1,
    })
    local draw_order = {}

    stack:addChild(low)
    stack:addChild(mid)
    stack:addChild(high)
    stage.baseSceneLayer:addChild(stack)
    stage:update()

    stack:_draw_subtree({}, function(node)
        if node.tag ~= nil then
            draw_order[#draw_order + 1] = node.tag
        end
    end)

    assert_equal(draw_order[1], 'low',
        'Stack should draw the lowest zIndex child first')
    assert_equal(draw_order[2], 'mid',
        'Stack should preserve ascending zIndex order for overlapping children')
    assert_equal(draw_order[3], 'high',
        'Stack should keep stable insertion order among equal-zIndex children')
    assert_equal(stack:_hit_test(20, 20), high,
        'Stack should resolve hits in reverse draw order')

    mid.zIndex = 3
    stage:update()

    assert_equal(stack:_hit_test(20, 20), mid,
        'Stack hit resolution should follow updated z-order after layout dirties')

    stage:destroy()
end

local function run_empty_hidden_and_clip_tests()
    local stage = UI.Stage.new({
        width = 200,
        height = 120,
    })
    local empty_stack = UI.Stack.new({
        width = 60,
        height = 40,
    })
    local stack = UI.Stack.new({
        width = 100,
        height = 80,
        clipChildren = true,
    })
    local hidden = UI.Container.new({
        tag = 'hidden',
        visible = false,
        interactive = true,
        width = 30,
        height = 30,
    })
    local overflow = UI.Container.new({
        tag = 'overflow',
        interactive = true,
        x = -30,
        y = 20,
        width = 40,
        height = 30,
        zIndex = 1,
    })
    local graphics = make_fake_graphics()
    local drawn_tags = {}

    stack:addChild(hidden)
    stack:addChild(overflow)
    stage.baseSceneLayer:addChild(empty_stack)
    stage.baseSceneLayer:addChild(stack)
    stage:update()

    assert_nil(empty_stack:_hit_test(10, 10),
        'An empty Stack should remain a valid no-target container')
    assert_nil(stack:_hit_test(-5, 25),
        'Stack clipChildren should suppress hits outside the stack bounds')
    assert_equal(stack:_hit_test(5, 25), overflow,
        'Stack clipChildren should still allow hits inside the clipped region')

    stack:_draw_subtree(graphics, function(node)
        if node.tag ~= nil then
            drawn_tags[#drawn_tags + 1] = node.tag
        end
    end)

    assert_equal(#drawn_tags, 1,
        'Hidden stack children should not affect visual traversal output')
    assert_equal(drawn_tags[1], 'overflow',
        'Visible stack children should still draw while clipped')
    assert_true(#graphics.scissor_calls >= 2,
        'Stack clipChildren should activate and later clear a scissor rect on draw')
    assert_equal(graphics.scissor_calls[1].x, 0,
        'Stack should clip draw output to its local bounds on the x axis')
    assert_equal(graphics.scissor_calls[1].y, 0,
        'Stack should clip draw output to its local bounds on the y axis')
    assert_equal(graphics.scissor_calls[1].width, 100,
        'Stack should clip draw output to its resolved width')
    assert_equal(graphics.scissor_calls[1].height, 80,
        'Stack should clip draw output to its resolved height')
    assert_nil(graphics.scissor_calls[#graphics.scissor_calls].x,
        'Stack should restore the previous scissor rect after drawing')

    stage:destroy()
end

local function run_margin_consumption_tests()
    local stage = UI.Stage.new({
        width = 200,
        height = 120,
    })
    local stack = UI.Stack.new({
        width = 'content',
        height = 'content',
        padding = 10,
    })
    local visible = UI.Drawable.new({
        tag = 'visible',
        interactive = true,
        width = 20,
        height = 10,
        marginLeft = -20,
        marginTop = 5,
        marginRight = 10,
        marginBottom = 15,
    })
    local hidden = UI.Drawable.new({
        visible = false,
        width = 10,
        height = 10,
        margin = 100,
    })

    stack:addChild(visible)
    stack:addChild(hidden)
    stage.baseSceneLayer:addChild(stack)
    stage:update()

    assert_equal(stack:getLocalBounds().width, 30,
        'Stack content sizing should measure visible children by their outer footprint')
    assert_equal(stack:getLocalBounds().height, 50,
        'Stack content sizing should include visible child margin in the measured footprint')
    assert_equal(visible:getWorldBounds().x, -10,
        'Stack should allow negative left margin to expand the child placement region before clipping')
    assert_equal(visible:getWorldBounds().y, 15,
        'Stack should apply top margin when resolving the child placement region')
    assert_equal(stack:_hit_test(-5, 20), visible,
        'Stack negative margins should move the child border box itself for hit testing')
    assert_nil(stack:_hit_test(15, 20),
        'Stack child margin should not create hit area outside the child border box')

    stage:destroy()
end

local function run()
    run_content_box_placement_tests()
    run_layering_and_hit_resolution_tests()
    run_empty_hidden_and_clip_tests()
    run_margin_consumption_tests()
end

return {
    run = run,
}
