local UI = require('lib.ui')

local Stage = UI.Stage

local CommonScreenHelpers = {}

local function normalize_module_path(path)
    if type(path) ~= 'string' or path == '' then
        return nil
    end

    path = path:gsub('\\', '/')

    local demos_index = path:find('/demos/', 1, true)
    if demos_index ~= nil then
        path = path:sub(demos_index + 1)
    end

    if path:sub(1, 6) ~= 'demos/' then
        local relative_demos_index = path:find('demos/', 1, true)
        if relative_demos_index == nil then
            return nil
        end
        path = path:sub(relative_demos_index)
    end

    if not path:match('%.lua$') then
        return nil
    end

    path = path:gsub('%.lua$', '')
    path = path:gsub('[/\\]+', '.')
    path = path:gsub('^%.+', '')

    return path
end

local function resolve_companion_setup_module(build)
    local info = debug.getinfo(build, 'S')
    local source = info and info.source or nil
    if type(source) ~= 'string' or source:sub(1, 1) ~= '@' then
        return nil
    end

    local path = source:sub(2)
    local module_path = normalize_module_path(path)
    if module_path == nil then
        return nil
    end

    return module_path .. '_setup'
end

local function try_install_companion_setup(build, args)
    local module_name = resolve_companion_setup_module(build)
    if module_name == nil then
        return
    end

    local ok, result = pcall(require, module_name)
    if not ok then
        if type(result) == 'string' and result:find("module '" .. module_name .. "' not found", 1, true) ~= nil then
            return
        end
        error(result, 0)
    end

    if type(result) == 'table' and type(result.install) == 'function' then
        result.install(args)
    end
end

function CommonScreenHelpers.make_stage(scope)
    local stage = Stage.new({
        width = love.graphics.getWidth(),
        height = love.graphics.getHeight(),
    })

    return stage
end

function CommonScreenHelpers.sync_stage(stage)
    stage:resize(love.graphics.getWidth(), love.graphics.getHeight())
    stage:update(0)
end

function CommonScreenHelpers.screen_wrapper(owner, helpers, description, build)
    if type(description) == 'function' and build == nil then
        build = description
        description = nil
    end

    return function(index, scope)
        local stage = CommonScreenHelpers.make_stage(scope)
        local state = build(scope, stage)
        try_install_companion_setup(build, {
            scope = scope,
            owner = owner,
            helpers = helpers,
            stage = stage,
            root = stage.baseSceneLayer,
            state = state,
        })
        local stage_hooks = rawget(stage, '_demo_screen_hooks') or {}
        local info_index = nil
        local screen_title = state.title or 'No Title'
        local header_description = state.description
        if header_description == nil then
            header_description = description
        end

        if state.sidebar ~= nil then
            info_index = owner:add_info_item(state.sidebar_title or screen_title, {})
        end

        owner:set_title(screen_title)
        owner:set_description(header_description)

        return {
            release = function()
                if rawget(stage, '_destroyed') ~= true then
                    stage:destroy()
                end
            end,
            keypressed = function(_, key)
                if type(stage_hooks.keypressed) == 'function' then
                    return stage_hooks.keypressed(key) == true
                end

                if type(state.keypressed) == 'function' then
                    return state.keypressed(key) == true
                end

                return false
            end,
            mousepressed = function(_, x, y, button)
                if type(stage_hooks.mousepressed) == 'function' then
                    return stage_hooks.mousepressed(x, y, button) == true
                end

                if type(state.mousepressed) == 'function' then
                    return state.mousepressed(x, y, button) == true
                end

                return false
            end,
            update = function(_, dt)
                stage:resize(love.graphics.getWidth(), love.graphics.getHeight())

                if type(stage_hooks.update) == 'function' then
                    stage_hooks.update(dt)
                end

                if type(state.update) == 'function' then
                    state.update(dt)
                end

                stage:update(dt)
                owner:set_title(screen_title)
                owner:set_description(header_description)
                if info_index ~= nil then
                    owner:set_info_title(info_index, state.sidebar_title or screen_title)
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

                if type(stage_hooks.draw_overlay) == 'function' then
                    stage_hooks.draw_overlay(love.graphics)
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
