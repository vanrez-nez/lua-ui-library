package.path = '../../?.lua;../../?/init.lua;' .. package.path
require('demos.common.bootstrap').init()

local DemoBase = require('demos.common.demo_base')
local DemoColors = require('demos.common.colors')
local ScreenHelper = require('demos.common.screen_helper')

local demo_base

local function resolve_screens(definition, owner)
    local screen_modules = definition.screen_modules
    if screen_modules ~= nil then
        local helpers = screen_modules.helpers or ScreenHelper
        local screens = {}
        for index = 1, #screen_modules do
            screens[index] = screen_modules[index](owner, helpers)
        end
        return screens
    end

    local screens = definition.screens
    if screens ~= nil then
        return screens
    end

    return {}
end

local function run_demo(demo_definition)
    function love.load()
        demo_base = DemoBase.new({
            title = demo_definition.title,
            description = demo_definition.description,
            profiling = demo_definition.profiling,
        })

        local screens = resolve_screens(demo_definition, demo_base)
        for index = 1, #screens do
            demo_base:push_screen(screens[index])
        end
    end

    function love.update(dt)
        demo_base:update(dt)
    end

    function love.draw()
        demo_base:begin_frame()
        love.graphics.clear(DemoColors.roles.background_alt)
        demo_base:draw()
    end

    function love.keypressed(key)
        demo_base:handle_keypressed(key)
    end

    function love.mousepressed(x, y, button)
        demo_base:handle_mousepressed(x, y, button)
    end

    function love.quit()
        if demo_base ~= nil then
            demo_base:shutdown()
        end
    end
end

if ... ~= nil then
    return run_demo
end
