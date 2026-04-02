package.path = '../../?.lua;../../?/init.lua;' .. package.path
require('demos.common.bootstrap').init()

local DemoBase = require('demos.common.demo_base')
local DemoColors = require('demos.common.colors')
local ScreenHelpers = require('demos.01-container.screen_helpers')
local screen_modules = require('demos.01-container.screens')

local demo_base

function love.load()
    demo_base = DemoBase.new({
        title = '01-container',
        description = 'Container contract coverage.',
    })

    for _, screen_module in ipairs(screen_modules) do
        demo_base:push_screen(screen_module(demo_base, ScreenHelpers))
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
