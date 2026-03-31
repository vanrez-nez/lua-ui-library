local Container = require('lib.ui.core.container')
local Drawable = require('lib.ui.core.drawable')
local Stage = require('lib.ui.scene.stage')

local function assert_equal(actual, expected, message)
    if actual ~= expected then
        error(message .. ': expected ' .. tostring(expected) ..
            ', got ' .. tostring(actual), 2)
    end
end

local function assert_nil(value, message)
    if value ~= nil then
        error(message .. ': expected nil, got ' .. tostring(value), 2)
    end
end

local function assert_true(value, message)
    if not value then
        error(message, 2)
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

local function assert_sequence_equal(actual, expected, message)
    assert_equal(#actual, #expected, message .. ' length')

    for index = 1, #expected do
        assert_equal(actual[index], expected[index], message .. ' [' .. index .. ']')
    end
end

local function run_focus_scope_chain_and_trap_bookkeeping_tests()
    local stage = Stage.new({ width = 320, height = 180 })
    local scoped_parent = Container.new({
        width = 120,
        height = 80,
    })
    local scoped_leaf = Container.new({
        focusable = true,
        width = 40,
        height = 24,
    })

    stage.baseSceneLayer:addChild(scoped_parent)
    scoped_parent:addChild(scoped_leaf)
    stage:_set_focus_contract_internal(scoped_parent, {
        scope = true,
    })
    stage:_set_focus_owner_internal(scoped_leaf)

    assert_equal(stage:_get_focus_owner_internal(), scoped_leaf,
        'Stage should retain the current logical focus owner')
    assert_sequence_equal(
        stage:_get_active_focus_scope_chain_internal(),
        { stage, scoped_parent },
        'Active scope chain should include Stage and focused nested scopes'
    )

    local outer_trap = Container.new({
        width = 140,
        height = 90,
    })
    local outer_focus = Container.new({
        focusable = true,
        width = 30,
        height = 20,
    })

    outer_trap:addChild(outer_focus)
    stage.overlayLayer:addChild(outer_trap)
    stage:_set_focus_contract_internal(outer_trap, {
        scope = true,
        trap = true,
    })

    local trap_stack = stage:_get_focus_trap_stack_internal()
    local trap_history = stage:_get_pre_trap_focus_history_internal()

    assert_sequence_equal(trap_stack, { outer_trap },
        'Newly attached trap scopes should be tracked in stack order')
    assert_sequence_equal(trap_history, { scoped_leaf },
        'Trap history should record the focus owner that existed before activation')
    assert_equal(stage:_get_focus_owner_internal(), outer_focus,
        'Trap activation should move focus into the overlay scope')

    local inner_trap = Container.new({
        width = 150,
        height = 100,
    })
    local inner_focus = Container.new({
        focusable = true,
        width = 24,
        height = 18,
    })

    inner_trap:addChild(inner_focus)
    stage.overlayLayer:addChild(inner_trap)
    stage:_set_focus_contract_internal(inner_trap, {
        scope = true,
        trap = true,
    })
    stage:_set_focus_owner_internal(inner_focus)

    trap_stack = stage:_get_focus_trap_stack_internal()
    trap_history = stage:_get_pre_trap_focus_history_internal()

    assert_sequence_equal(trap_stack, { outer_trap, inner_trap },
        'Nested traps should preserve deterministic stack order')
    assert_sequence_equal(trap_history, { scoped_leaf, outer_focus },
        'Each trap should retain its own pre-trap focus history entry')
    assert_sequence_equal(
        stage:_get_active_focus_scope_chain_internal(),
        { stage, outer_trap, inner_trap },
        'Active scope chain should include the active trap stack'
    )
    assert_equal(stage:_get_focus_owner_internal(), inner_focus,
        'Nested trap activation should move focus into the innermost trap')

    inner_trap:destroy()

    assert_sequence_equal(
        stage:_get_focus_trap_stack_internal(),
        { outer_trap },
        'Destroyed traps should be removed from bookkeeping immediately'
    )
    assert_equal(stage:_get_focus_owner_internal(), outer_focus,
        'Closing the inner trap should restore focus to its immediate prior owner')

    outer_trap:destroy()

    assert_equal(stage:_get_focus_owner_internal(), scoped_leaf,
        'Closing the outer trap should restore focus to the pre-trap owner')
    assert_sequence_equal(
        stage:_get_focus_trap_stack_internal(),
        {},
        'Closing the last active trap should clear trap bookkeeping'
    )

    stage:destroy()
end

local function run_empty_trap_entry_focus_tests()
    local stage = Stage.new({ width = 240, height = 140 })
    local outside = Container.new({
        focusable = true,
        width = 40,
        height = 20,
    })
    local trap = Container.new({
        width = 120,
        height = 80,
    })

    stage.baseSceneLayer:addChild(outside)
    stage.overlayLayer:addChild(trap)
    stage:_set_focus_owner_internal(outside)
    stage:_set_focus_contract_internal(trap, {
        scope = true,
        trap = true,
    })

    assert_equal(stage:_get_focus_owner_internal(), trap,
        'Trap scopes without focusable descendants should retain focus on the scope root')

    trap:destroy()

    assert_equal(stage:_get_focus_owner_internal(), outside,
        'Destroying an empty trap should still restore the previous focus owner')

    stage:destroy()
end

local function run_focus_cleanup_and_draw_state_tests()
    local stage = Stage.new({ width = 240, height = 140 })
    local scope = Container.new({
        width = 100,
        height = 60,
    })
    local focus_target = Container.new({
        focusable = true,
        width = 36,
        height = 18,
    })
    local other = Container.new({
        focusable = true,
        x = 50,
        width = 36,
        height = 18,
    })

    stage.baseSceneLayer:addChild(scope)
    scope:addChild(focus_target)
    stage.baseSceneLayer:addChild(other)

    stage:_set_focus_owner_internal(focus_target)
    stage.overlayLayer:addChild(focus_target)

    assert_nil(stage:_get_focus_owner_internal(),
        'Reparented nodes should not retain stale Stage focus ownership')

    stage:_set_focus_owner_internal(other)
    stage:update()

    local focused_values = {}

    stage:draw({}, function(node)
        focused_values[node] = rawget(node, '_focused')
    end)

    assert_equal(focused_values[other], true,
        'Draw-time focus ownership should be available on the focused node only')
    assert_nil(focused_values[scope],
        'Non-focused nodes should not expose focused draw state')
    assert_nil(rawget(other, '_focused'),
        'Focused draw state should not persist after the draw callback returns')

    other:destroy()

    assert_nil(stage:_get_focus_owner_internal(),
        'Destroying the focused node should clear Stage focus ownership')

    stage:destroy()
end

local function make_focus_indicator_graphics()
    local graphics = {
        calls = {},
        color = { 0.25, 0.5, 0.75, 0.9 },
        line_width = 1,
    }

    function graphics.getColor()
        return graphics.color[1], graphics.color[2], graphics.color[3], graphics.color[4]
    end

    function graphics.setColor(r, g, b, a)
        graphics.color = { r, g, b, a }
        graphics.calls[#graphics.calls + 1] = string.format(
            'color:%.2f:%.2f:%.2f:%.2f',
            r,
            g,
            b,
            a
        )
    end

    function graphics.getLineWidth()
        return graphics.line_width
    end

    function graphics.setLineWidth(width)
        graphics.line_width = width
        graphics.calls[#graphics.calls + 1] = 'line_width:' .. tostring(width)
    end

    function graphics.rectangle(mode, x, y, width, height)
        graphics.calls[#graphics.calls + 1] = string.format(
            'rectangle:%s:%.2f:%.2f:%.2f:%.2f',
            tostring(mode),
            x,
            y,
            width,
            height
        )
    end

    return graphics
end

local function run_drawable_focus_indicator_and_error_cleanup_tests()
    local stage = Stage.new({ width = 240, height = 140 })
    local first = Drawable.new({
        tag = 'first',
        focusable = true,
        x = 10,
        y = 12,
        width = 30,
        height = 20,
    })
    local second = Drawable.new({
        tag = 'second',
        focusable = true,
        x = 60,
        y = 16,
        width = 40,
        height = 24,
    })

    stage.baseSceneLayer:addChild(first)
    stage.baseSceneLayer:addChild(second)

    stage:_set_focus_owner_internal(first)
    stage:update()

    local graphics = make_focus_indicator_graphics()

    stage:draw(graphics, function()
    end)

    assert_contains(
        graphics.calls,
        'rectangle:line:8.00:10.00:34.00:24.00',
        'Focused drawables should render the default focus ring with the Phase 05 geometry'
    )
    assert_equal(graphics.line_width, 1,
        'Focus-ring drawing should restore the previous line width')
    assert_equal(graphics.color[1], 0.25,
        'Focus-ring drawing should restore the previous color state')
    assert_equal(graphics.color[2], 0.5,
        'Focus-ring drawing should restore the previous color state')
    assert_equal(graphics.color[3], 0.75,
        'Focus-ring drawing should restore the previous color state')
    assert_equal(graphics.color[4], 0.9,
        'Focus-ring drawing should restore the previous color state')

    stage:_set_focus_owner_internal(second)
    stage:update()
    graphics = make_focus_indicator_graphics()

    stage:draw(graphics, function()
    end)

    assert_contains(
        graphics.calls,
        'rectangle:line:58.00:14.00:44.00:28.00',
        'The focus ring should move immediately with current focus ownership'
    )

    stage:_set_focus_owner_internal(first)
    stage:update()

    local ok = pcall(function()
        stage:draw({}, function(node)
            if node == first then
                error('draw failure')
            end
        end)
    end)

    assert_true(not ok,
        'Stage draw should still surface callback failures')
    assert_nil(rawget(first, '_focused'),
        'Transient focused draw state should be restored even when drawing fails')

    stage:destroy()
end

local function run()
    run_focus_scope_chain_and_trap_bookkeeping_tests()
    run_empty_trap_entry_focus_tests()
    run_focus_cleanup_and_draw_state_tests()
    run_drawable_focus_indicator_and_error_cleanup_tests()
end

return {
    run = run,
}
