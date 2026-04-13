local Container = require('lib.ui.core.container')
local LayoutNode = require('lib.ui.layout.layout_node')
local Stage = require('lib.ui.scene.stage')
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

local TestLayout = {}

TestLayout.__index = function(self, key)
    local method = rawget(TestLayout, key)

    if method ~= nil then
        return method
    end

    return LayoutNode.__index(self, key)
end

TestLayout.__newindex = LayoutNode.__newindex

function TestLayout.new(opts)
    local self = {
        layout_passes = 0,
        applied_x = 0,
    }

    LayoutNode._initialize(self, opts)

    return setmetatable(self, TestLayout)
end

function TestLayout:_apply_layout(_)
    self.layout_passes = self.layout_passes + 1

    local children = self:getChildren()
    local child = children[1]

    if child ~= nil then
        child.x = self.applied_x
    end

    return self
end

local function run_update_layout_order_tests()
    local stage = Stage.new({ width = 320, height = 180 })
    local layout = TestLayout.new({
        width = 200,
        height = 100,
    })
    local child = Container.new({
        width = 40,
        height = 20,
    })

    layout.applied_x = 24
    layout:addChild(child)
    stage.baseSceneLayer:addChild(layout)

    assert_true(layout.dirty:is_dirty('layout'),
        'Layout nodes should begin dirty until the first Stage update')

    stage:update()

    local world_x, world_y = child:localToWorld(0, 0)

    assert_equal(layout.layout_passes, 1,
        'Stage.update should run the layout pass once for a dirty layout root')
    assert_true(not layout.dirty:is_dirty('layout'),
        'Stage.update should leave the layout root clean after layout resolution')
    assert_equal(world_x, 24,
        'Layout placement must resolve before downstream transform reads in the same update')
    assert_equal(world_y, 0,
        'Layout placement should remain stable through the transform pass')

    stage:update()

    assert_equal(layout.layout_passes, 1,
        'Repeated updates without mutations should keep clean layout roots out of the layout pass')

    stage:destroy()
end

local function run_layout_dirty_propagation_tests()
    local stage = Stage.new({ width = 320, height = 180 })
    local layout = TestLayout.new({
        width = 200,
        height = 100,
    })
    local child = Container.new({
        width = 40,
        height = 20,
    })
    local added_child = Container.new({
        width = 20,
        height = 10,
    })

    layout:addChild(child)
    stage.baseSceneLayer:addChild(layout)
    stage:update()

    child.width = 60
    assert_true(layout.dirty:is_dirty('layout'),
        'Child size mutation should dirty ancestor layout roots')
    stage:update()
    assert_true(not layout.dirty:is_dirty('layout'),
        'Stage.update should clean layout roots dirtied by child size mutation')

    child.visible = false
    assert_true(layout.dirty:is_dirty('layout'),
        'Child visibility mutation should dirty ancestor layout roots')
    stage:update()
    assert_true(not layout.dirty:is_dirty('layout'),
        'Stage.update should clean layout roots dirtied by child visibility mutation')

    child.visible = true
    stage:update()

    layout:addChild(added_child)
    assert_true(layout.dirty:is_dirty('layout'),
        'Child addition should dirty the affected layout root')
    stage:update()
    assert_true(not layout.dirty:is_dirty('layout'),
        'Stage.update should clean layout roots dirtied by child addition')

    layout:removeChild(added_child)
    assert_true(layout.dirty:is_dirty('layout'),
        'Child removal should dirty the affected layout root')
    stage:update()
    assert_true(not layout.dirty:is_dirty('layout'),
        'Stage.update should clean layout roots dirtied by child removal')

    child.breakpoints = {
        compact = {
            maxWidth = 200,
            props = {
                width = 30,
            },
        },
    }
    assert_true(layout.dirty:is_dirty('layout'),
        'Breakpoint mutation should dirty ancestor layout roots')
    stage:update()
    assert_true(not layout.dirty:is_dirty('layout'),
        'Stage.update should clean layout roots dirtied by breakpoint mutation')

    stage:resize(180, 180)
    assert_true(layout.dirty:is_dirty('layout'),
        'Stage resize should dirty layout roots for the next update traversal')
    stage:update()
    assert_true(not layout.dirty:is_dirty('layout'),
        'Stage.update should clean layout roots dirtied by viewport changes')

    stage:destroy()
end

local function run_ancestor_size_mutation_descendant_layout_tests()
    local stage = UI.Stage.new({
        width = 1400,
        height = 900,
    })
    local page = UI.Column.new({
        width = 500,
        height = '70%',
        padding = { 20, 20, 20, 20 },
        gap = 20,
        justify = 'start',
        align = 'stretch',
    })
    local body = UI.Row.new({
        width = 'fill',
        height = 'fill',
        gap = 20,
        justify = 'start',
        align = 'stretch',
    })
    local content = UI.Flow.new({
        width = 'fill',
        height = 'fill',
        padding = { 20, 20, 20, 20 },
        gap = 15,
        wrap = true,
        justify = 'start',
        direction = 'ltr',
    })
    local sidebar = UI.Column.new({
        width = '40%',
        height = 'fill',
        padding = { 20, 20, 20, 20 },
        gap = 15,
        justify = 'start',
        align = 'stretch',
    })
    local header = UI.Row.new({
        width = 'fill',
        height = 140,
        padding = { 20, 20, 20, 20 },
        gap = 20,
        justify = 'space-between',
        align = 'center',
    })
    local footer = UI.Row.new({
        width = 'fill',
        height = 100,
        padding = { 20, 20, 20, 20 },
        gap = 10,
        justify = 'center',
        align = 'center',
    })

    body:addChild(content)
    body:addChild(sidebar)
    page:addChild(header)
    page:addChild(body)
    page:addChild(footer)
    stage.baseSceneLayer:addChild(page)
    stage:update()

    page.width = '50%'

    assert_true(body.dirty:is_dirty('layout'),
        'Ancestor width mutation should dirty descendant layout nodes that own child distribution')
    stage:update()
    assert_true(not body.dirty:is_dirty('layout'),
        'Stage.update should clean descendant layout nodes dirtied by ancestor size mutation')

    local body_width = body:getLocalBounds().width
    local content_width = content:getLocalBounds().width
    local sidebar_width = sidebar:getLocalBounds().width

    assert_equal(body_width, 660,
        'Ancestor width mutation should resolve the row to the updated available width')
    assert_equal(content_width, 376,
        'Row should recompute fill-width children against the updated available width')
    assert_equal(sidebar_width, 264,
        'Row should recompute percentage-width siblings against the updated available width')
    assert_true(content_width + sidebar_width <= body_width,
        'Ancestor width mutation should not leave descendant row distribution stale after the next update')

    stage:destroy()
end

local function run_draw_read_only_tests()
    local stage = Stage.new({ width = 320, height = 180 })
    local layout = TestLayout.new({
        width = 200,
        height = 100,
    })
    local child = Container.new({
        width = 40,
        height = 20,
    })

    layout:addChild(child)
    stage.baseSceneLayer:addChild(layout)
    stage:update()

    child.width = 80
    assert_true(layout.dirty:is_dirty('layout'),
        'Child size mutation should leave the layout root dirty until Stage.update runs')

    assert_error(function()
        stage:draw({}, function()
        end)
    end, 'Stage.draw() called without a preceding Stage.update() in this frame',
        'Draw should reject frames that still have deferred update work pending')

    assert_true(layout.dirty:is_dirty('layout'),
        'A rejected draw must not resolve deferred layout work')
    assert_equal(layout.layout_passes, 1,
        'A rejected draw must not run the layout pass')

    stage:update()
    stage:draw({}, function()
    end)

    assert_true(not layout.dirty:is_dirty('layout'),
        'Layout should be clean again after the required update pass')
    assert_equal(layout.layout_passes, 2,
        'Only Stage.update should run the layout pass after a mutation')

    stage:destroy()
end

local M = {}

function M.run()
    run_update_layout_order_tests()
    run_layout_dirty_propagation_tests()
    run_ancestor_size_mutation_descendant_layout_tests()
    run_draw_read_only_tests()
end

return M
