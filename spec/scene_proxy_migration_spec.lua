local Proxy = require('lib.ui.utils.proxy')
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

local function fake_font()
    return {
        getWidth = function(_, text)
            return #(text or '') * 8
        end,
        getHeight = function()
            return 10
        end,
        getWrap = function(_, text, width)
            local chars_per_line = math.max(1, math.floor((width or 0) / 8))
            local line_count = math.max(1, math.ceil(#(text or '') / chars_per_line))
            local lines = {}
            for index = 1, line_count do
                lines[index] = ''
            end
            return width, lines
        end,
    }
end

local function run_stage_environment_raw_write_tests()
    local stage = UI.Stage.new({
        width = 100,
        height = 80,
    })
    local child = UI.Container.new({
        width = 10,
        height = 10,
    })
    local width_changes = 0
    local safe_area_changes = 0

    stage.baseSceneLayer:addChild(child)
    stage:update()

    stage.props:watch('width', function()
        width_changes = width_changes + 1
    end)
    stage.props:watch('safeAreaInsets', function()
        safe_area_changes = safe_area_changes + 1
    end)

    stage:resize(200, 120)

    assert_equal(Proxy.raw_get(stage, 'width'), 200,
        'Stage.resize should update the raw width store')
    assert_equal(Proxy.raw_get(stage, 'height'), 120,
        'Stage.resize should update the raw height store')
    assert_equal(width_changes, 0,
        'Stage.resize should not fire public width watchers')
    assert_true(child.dirty:is_any(),
        'Stage.resize should mark descendants dirty for relayout')

    stage.safeAreaInsets = { 1, 2, 3, 4 }

    assert_equal(safe_area_changes, 1,
        'Public safeAreaInsets assignment should still fire watchers')

    stage:destroy()
end

local function run_scroll_controller_raw_write_tests()
    local stage = UI.Stage.new({
        width = 100,
        height = 80,
    })
    local scroll = UI.ScrollableContainer.new({
        width = 50,
        height = 40,
        scrollYEnabled = true,
    })
    local content_child = UI.Container.new({
        width = 50,
        height = 120,
    })
    local offset_changes = 0

    scroll.content:addChild(content_child)
    stage.baseSceneLayer:addChild(scroll)
    stage:update()

    scroll.content.props:watch('x', function()
        offset_changes = offset_changes + 1
    end)
    scroll.content.props:watch('y', function()
        offset_changes = offset_changes + 1
    end)

    scroll:_scroll_to(0, 20)

    assert_equal(offset_changes, 0,
        'ScrollableContainer controller offset writes should not fire content x/y watchers')
    assert_equal(Proxy.raw_get(scroll.content, 'y'), -20,
        'ScrollableContainer should raw-write the content y offset')

    stage:destroy()
end

local function run_text_intrinsic_raw_write_tests()
    local text = UI.Text.new({
        text = 'a',
        font = fake_font(),
    })
    local size_changes = 0

    text.props:watch('width', function()
        size_changes = size_changes + 1
    end)
    text.props:watch('height', function()
        size_changes = size_changes + 1
    end)

    text:setText('abcd')
    text:update(0)

    assert_equal(size_changes, 0,
        'Text intrinsic measurement should raw-write width/height without firing watchers')
    assert_equal(Proxy.raw_get(text, 'width'), 32,
        'Text intrinsic measurement should update raw width')

    text.width = 100

    assert_equal(size_changes, 1,
        'Public Text width assignment should still fire watchers')
end

local function run()
    run_stage_environment_raw_write_tests()
    run_scroll_controller_raw_write_tests()
    run_text_intrinsic_raw_write_tests()
end

return {
    run = run,
}
