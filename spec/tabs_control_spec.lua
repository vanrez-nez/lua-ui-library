local UI = require('lib.ui')

local function assert_equal(actual, expected, message)
    if actual ~= expected then
        error(message .. ': expected ' .. tostring(expected) .. ', got ' .. tostring(actual), 2)
    end
end

local function assert_true(value, message)
    if not value then
        error(message, 2)
    end
end

local function make_box(width, height)
    return UI.Container.new({
        width = width,
        height = height,
    })
end

local function run_trigger_list_layout_tests()
    local stage = UI.Stage.new({
        width = 640,
        height = 320,
    })
    local tabs = UI.Tabs.new({
        width = 400,
        height = 220,
        value = 'home',
        onValueChange = function() end,
        activationMode = 'manual',
        orientation = 'horizontal',
        listScrollable = true,
    })

    tabs:_register_tab('home', make_box(80, 24), make_box(120, 40))
    tabs:_register_tab('settings', make_box(80, 24), make_box(120, 40))
    tabs:_register_tab('profile', make_box(80, 24), make_box(120, 40))

    stage.baseSceneLayer:addChild(tabs)
    stage:update()

    local home = rawget(tabs, '_trigger_nodes').home
    local settings = rawget(tabs, '_trigger_nodes').settings
    local profile = rawget(tabs, '_trigger_nodes').profile

    local home_bounds = home:getWorldBounds()
    local settings_bounds = settings:getWorldBounds()
    local profile_bounds = profile:getWorldBounds()

    assert_true(settings_bounds.x > home_bounds.x,
        'Tabs trigger list should place later horizontal triggers after earlier triggers')
    assert_true(profile_bounds.x > settings_bounds.x,
        'Tabs trigger list should keep registered triggers in sibling order within the list region')
    assert_equal(home_bounds.y, settings_bounds.y,
        'Tabs horizontal trigger list should keep triggers on the same row')

    stage:destroy()
end

local function run_panel_visibility_tests()
    local stage = UI.Stage.new({
        width = 640,
        height = 320,
    })
    local tabs = UI.Tabs.new({
        width = 400,
        height = 220,
        value = 'settings',
        onValueChange = function() end,
        activationMode = 'manual',
        orientation = 'horizontal',
        listScrollable = false,
    })

    tabs:_register_tab('home', make_box(80, 24), make_box(120, 40))
    tabs:_register_tab('settings', make_box(80, 24), make_box(120, 40))

    stage.baseSceneLayer:addChild(tabs)
    stage:update()

    local panels = rawget(tabs, '_panel_nodes')
    local home_panel_values = rawget(panels.home, '_effective_values') or {}
    local settings_panel_values = rawget(panels.settings, '_effective_values') or {}

    assert_true(home_panel_values.visible == false,
        'Tabs should hide inactive panels')
    assert_true(settings_panel_values.visible == true,
        'Tabs should keep only the active panel visible')

    stage:destroy()
end

local M = {}

function M.run()
    run_trigger_list_layout_tests()
    run_panel_visibility_tests()
end

return M
