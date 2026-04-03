local UI = require('lib.ui')

local Stage = UI.Stage

local CommonScreenHelpers = {}

function CommonScreenHelpers.make_stage(scope)
    local stage = Stage.new({
        width = love.graphics.getWidth(),
        height = love.graphics.getHeight(),
    })

    scope:on_cleanup(function()
        stage:destroy()
    end)

    return stage
end

function CommonScreenHelpers.sync_stage(stage)
    stage:resize(love.graphics.getWidth(), love.graphics.getHeight())
    stage:update(0)
end

function CommonScreenHelpers.screen_wrapper(owner, helpers, description, build)
    return function(index, scope)
        local stage = CommonScreenHelpers.make_stage(scope)
        local state = build(scope, stage)
        local info_index = nil
        local header_description = state.description or description

        if state.sidebar ~= nil then
            info_index = owner:add_info_item(state.sidebar_title or state.title, {})
        end

        owner:set_title(state.title)
        owner:set_description(header_description)

        return {
            keypressed = function(_, key)
                if type(state.keypressed) == 'function' then
                    return state.keypressed(_, key) == true
                end

                return false
            end,
            mousepressed = function(_, x, y, button)
                if type(state.mousepressed) == 'function' then
                    return state.mousepressed(_, x, y, button) == true
                end

                return false
            end,
            update = function(_, dt)
                if type(state.update) == 'function' then
                    state.update(dt)
                end

                stage:resize(love.graphics.getWidth(), love.graphics.getHeight())
                stage:update(dt)
                owner:set_title(state.title)
                owner:set_description(header_description)
                if info_index ~= nil then
                    owner:set_info_title(info_index, state.sidebar_title or state.title)
                    owner:set_info_lines(info_index, state.sidebar(index, owner:get_screen_count()))
                end
            end,
            draw = function()
                if not rawget(stage, '_update_ran') then
                    CommonScreenHelpers.sync_stage(stage)
                end

                local mouse_x, mouse_y = love.mouse.getPosition()
                helpers._draw_context = {
                    mouse_x = mouse_x,
                    mouse_y = mouse_y,
                    hovered_node = nil,
                    hovered_area = nil,
                }

                if type(helpers.draw_stage) == 'function' then
                    helpers.draw_stage(stage, love.graphics)
                else
                    stage:draw(love.graphics, function(node)
                        if type(helpers.draw_demo_node) == 'function' then
                            helpers.draw_demo_node(love.graphics, node)
                        end

                        if type(helpers.draw_demo_markers) == 'function' then
                            helpers.draw_demo_markers(love.graphics, node)
                        end
                    end)
                end

                if type(state.draw_overlay) == 'function' then
                    state.draw_overlay(love.graphics)
                end

                if type(helpers.draw_hover_overlay) == 'function' then
                    helpers.draw_hover_overlay(love.graphics)
                end

                helpers._draw_context = nil
            end,
        }
    end
end

return CommonScreenHelpers
