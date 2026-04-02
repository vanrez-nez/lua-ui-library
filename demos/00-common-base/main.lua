package.path = '../../?.lua;../../?/init.lua;' .. package.path

local DemoBase = require('demos.common.demo_base')

local demo_base

function love.load()
    demo_base = DemoBase.new({
        title = 'Common Demo Base',
        description = 'Reference demo for the shared DemoBase shell. Screens are created and cleaned up by the shared base.',
    })

    demo_base:push_screen(function(index, scope, owner)
        local font = scope:font(18)
        return {
            draw = function()
                local g = love.graphics
                local width, height = love.graphics.getDimensions()
                g.setFont(font)
                g.setColor(0.95, 0.96, 0.99, 1)
                g.printf(
                    string.format(
                        'Screen %d/%d\nThis screen is created through a demo-base-managed scope.',
                        index,
                        owner:get_screen_count()
                    ),
                    0,
                    (height * 0.5) - 28,
                    width,
                    'center'
                )
            end,
        }
    end)

    demo_base:push_screen(function(index, scope, owner)
        local font = scope:font(18)
        return {
            draw = function()
                local g = love.graphics
                local width, height = love.graphics.getDimensions()
                g.setFont(font)
                g.setColor(0.9, 0.78, 0.32, 1)
                g.printf(
                    string.format(
                        'Screen %d/%d\nSwitching screens forces cleanup and rebuild from the shared demo base.',
                        index,
                        owner:get_screen_count()
                    ),
                    0,
                    (height * 0.5) - 28,
                    width,
                    'center'
                )
            end,
        }
    end)
end

function love.update(dt)
    demo_base:update(dt)
end

function love.draw()
    demo_base:begin_frame()
    demo_base:draw()
end

function love.keypressed(key)
    demo_base:handle_keypressed(key)
end
