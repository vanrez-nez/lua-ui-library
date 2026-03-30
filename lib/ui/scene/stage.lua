local Container = require('lib.ui.core.container')
local Insets = require('lib.ui.core.insets')
local Rectangle = require('lib.ui.core.rectangle')

local max = math.max

local Stage = {}

local STAGE_PUBLIC_KEYS = {
    width = true,
    height = true,
    safeAreaInsets = true,
}

local TWO_PASS_VIOLATION =
    'Stage.draw() called without a preceding Stage.update() in this frame. ' ..
    'The two-pass contract requires update to complete before draw begins.'

local active_stage = nil

local function fail(message, level)
    error(message, (level or 1) + 1)
end

local function assert_number(name, value, level)
    if type(value) ~= 'number' then
        fail(name .. ' must be a number', level or 1)
    end
end

local function assert_table(name, value, level)
    if type(value) ~= 'table' then
        fail(name .. ' must be a table', level or 1)
    end
end

local function assert_not_destroyed(self, level)
    if self._destroyed then
        fail('cannot use a destroyed Stage', level or 1)
    end
end

local function copy_options(opts)
    if opts == nil then
        return {}
    end

    assert_table('opts', opts, 2)

    local copy = {}

    for key, value in pairs(opts) do
        if not STAGE_PUBLIC_KEYS[key] then
            fail('Stage does not support prop "' .. tostring(key) .. '"', 3)
        end

        copy[key] = value
    end

    return copy
end

local function read_host_viewport()
    if love == nil or love.graphics == nil or
        type(love.graphics.getDimensions) ~= 'function' then
        return nil, nil
    end

    local ok, width, height = pcall(love.graphics.getDimensions)

    if not ok or type(width) ~= 'number' or type(height) ~= 'number' then
        return nil, nil
    end

    return width, height
end

local function read_host_safe_area_bounds()
    if love == nil or love.window == nil or
        type(love.window.getSafeArea) ~= 'function' then
        return nil
    end

    local ok, x, y, width, height = pcall(love.window.getSafeArea)

    if not ok or type(x) ~= 'number' or type(y) ~= 'number' or
        type(width) ~= 'number' or type(height) ~= 'number' then
        return nil
    end

    return Rectangle.new(x, y, max(0, width), max(0, height))
end

local function normalize_safe_area_insets(value, level)
    local ok, insets = pcall(Insets.normalize, value)

    if not ok then
        fail(tostring(insets), level or 1)
    end

    return insets
end

local function derive_safe_area_insets(viewport_width, viewport_height, bounds)
    if bounds == nil then
        return Insets.zero()
    end

    local viewport = Rectangle.new(
        0,
        0,
        max(0, viewport_width or 0),
        max(0, viewport_height or 0)
    )
    local safe_area = viewport:intersection(bounds)

    return Insets.new(
        safe_area.y,
        max(0, viewport.width - safe_area:right()),
        max(0, viewport.height - safe_area:bottom()),
        safe_area.x
    )
end

local function read_host_safe_area_insets(viewport_width, viewport_height)
    local bounds = read_host_safe_area_bounds()

    if bounds == nil then
        return nil
    end

    return derive_safe_area_insets(viewport_width, viewport_height, bounds)
end

local function refresh_environment_bounds(self)
    local viewport = Rectangle.new(
        0,
        0,
        max(0, self.width or 0),
        max(0, self.height or 0)
    )

    rawset(self, '_viewport_bounds_cache', viewport)
    rawset(self, '_safe_area_bounds_cache', viewport:inset(self.safeAreaInsets))
end

local function set_initial_safe_area_insets(self, value)
    local normalized = normalize_safe_area_insets(value, 3)

    self._public_values.safeAreaInsets = normalized
    self._effective_values.safeAreaInsets = normalized
end

local function set_safe_area_insets(self, value, level)
    local normalized = normalize_safe_area_insets(value, level or 1)
    local current = self._public_values.safeAreaInsets

    if current ~= nil and current == normalized then
        return normalized
    end

    self._public_values.safeAreaInsets = normalized
    self._effective_values.safeAreaInsets = normalized
    refresh_environment_bounds(self)
    Container.markDirty(self)
    return normalized
end

local function resolve_draw_args(graphics, draw_callback)
    if draw_callback == nil and type(graphics) == 'function' then
        draw_callback = graphics
        graphics = nil
    end

    if graphics == nil then
        if love ~= nil and love.graphics ~= nil then
            graphics = love.graphics
        else
            graphics = {}
        end
    end

    if draw_callback == nil then
        draw_callback = function()
        end
    end

    if type(graphics) ~= 'table' then
        fail('graphics must be a graphics adapter table', 3)
    end

    if type(draw_callback) ~= 'function' then
        fail('draw_callback must be a function', 3)
    end

    return graphics, draw_callback
end

local function build_target_path(self, target)
    local reversed = {}
    local current = target

    while current ~= nil do
        reversed[#reversed + 1] = current

        if current == self then
            break
        end

        current = current.parent
    end

    if reversed[#reversed] ~= self then
        return nil
    end

    local path = {}

    for index = #reversed, 1, -1 do
        path[#path + 1] = reversed[index]
    end

    return path
end

local function translate_raw_input(raw_event)
    local kind = raw_event.kind

    if kind == 'mousepressed' or kind == 'mousereleased' or
        kind == 'touchpressed' or kind == 'touchreleased' then
        return 'Activate'
    end

    if kind == 'mousemoved' or kind == 'touchmoved' then
        return 'Drag'
    end

    if kind == 'wheelmoved' then
        return 'Scroll'
    end

    if kind == 'textinput' then
        return 'TextInput'
    end

    if kind == 'textedited' then
        return 'TextCompose'
    end

    if kind ~= 'keypressed' then
        return nil
    end

    local key = raw_event.key

    if key == 'space' then
        return 'Activate'
    end

    if key == 'tab' or key == 'up' or key == 'down' or key == 'left' or
        key == 'right' then
        return 'Navigate'
    end

    if key == 'escape' then
        return 'Dismiss'
    end

    if key == 'return' or key == 'kpenter' then
        return 'Submit'
    end

    return nil
end

local function apply_environment(self, width, height, safe_area_insets)
    local viewport_changed = false

    if width ~= nil and self.width ~= width then
        assert_number('Stage.width', width, 3)
        Container.__newindex(self, 'width', width)
        viewport_changed = true
    end

    if height ~= nil and self.height ~= height then
        assert_number('Stage.height', height, 3)
        Container.__newindex(self, 'height', height)
        viewport_changed = true
    end

    if viewport_changed then
        refresh_environment_bounds(self)
    end

    if safe_area_insets ~= nil then
        set_safe_area_insets(self, safe_area_insets, 3)
    end

    refresh_environment_bounds(self)
end

Stage.__index = function(self, key)
    local method = rawget(Stage, key)

    if method ~= nil then
        return method
    end

    if STAGE_PUBLIC_KEYS[key] then
        return rawget(self, '_public_values')[key]
    end

    if key == 'baseSceneLayer' or key == 'overlayLayer' then
        return rawget(self, key)
    end

    local container_method = rawget(Container, key)

    if container_method ~= nil then
        return container_method
    end

    return nil
end

Stage.__newindex = function(self, key, value)
    if key == 'parent' then
        if value ~= nil then
            fail('Stage must not have a parent', 2)
        end

        rawset(self, key, value)
        return
    end

    if key == 'baseSceneLayer' or key == 'overlayLayer' then
        fail('Stage layer ownership is runtime-managed', 2)
    end

    if key == 'safeAreaInsets' then
        assert_not_destroyed(self, 2)
        set_safe_area_insets(self, value, 2)
        return
    end

    if key == 'width' or key == 'height' then
        assert_not_destroyed(self, 2)
        assert_number('Stage.' .. key, value, 2)
        Container.__newindex(self, key, value)
        refresh_environment_bounds(self)
        return
    end

    if rawget(self, '_allowed_public_keys')[key] then
        fail('Stage does not support prop "' .. tostring(key) .. '"', 2)
    end

    rawset(self, key, value)
end

function Stage.new(opts)
    opts = copy_options(opts)

    local host_width, host_height = read_host_viewport()

    if opts.width == nil then
        opts.width = host_width or 0
    end

    if opts.height == nil then
        opts.height = host_height or 0
    end

    assert_number('Stage.width', opts.width, 2)
    assert_number('Stage.height', opts.height, 2)

    if opts.safeAreaInsets == nil then
        opts.safeAreaInsets =
            read_host_safe_area_insets(opts.width, opts.height) or Insets.zero()
    end

    if active_stage ~= nil and not active_stage._destroyed then
        fail('creating more than one Stage instance is invalid', 2)
    end

    local self = {}

    Container._initialize(self, {
        width = opts.width,
        height = opts.height,
    }, {
        safeAreaInsets = true,
    })

    set_initial_safe_area_insets(self, opts.safeAreaInsets)

    rawset(self, '_ui_stage_instance', true)
    rawset(self, '_update_ran', false)
    rawset(self, '_last_input_delivery', nil)
    rawset(self, '_viewport_bounds_cache', Rectangle.new(0, 0, 0, 0))
    rawset(self, '_safe_area_bounds_cache', Rectangle.new(0, 0, 0, 0))

    refresh_environment_bounds(self)

    local base_scene_layer = Container.new({
        tag = 'base scene layer',
        width = 'fill',
        height = 'fill',
    })
    local overlay_layer = Container.new({
        tag = 'overlay layer',
        width = 'fill',
        height = 'fill',
    })

    rawset(self, 'baseSceneLayer', base_scene_layer)
    rawset(self, 'overlayLayer', overlay_layer)

    Container.addChild(self, base_scene_layer)
    Container.addChild(self, overlay_layer)

    active_stage = self

    return setmetatable(self, Stage)
end

function Stage.is_stage(value)
    return type(value) == 'table' and value._ui_stage_instance == true
end

function Stage:_sync_environment_from_host()
    assert_not_destroyed(self, 2)

    local width, height = read_host_viewport()

    if width == nil or height == nil then
        return self
    end

    apply_environment(
        self,
        width,
        height,
        read_host_safe_area_insets(width, height) or self.safeAreaInsets
    )

    return self
end

function Stage:_get_focus_scope_root()
    assert_not_destroyed(self, 2)
    return self
end

function Stage:getViewport()
    self:_sync_environment_from_host()
    return self._viewport_bounds_cache:clone()
end

function Stage:getSafeArea()
    self:_sync_environment_from_host()
    return self.safeAreaInsets:clone()
end

function Stage:getSafeAreaBounds()
    self:_sync_environment_from_host()
    return self._safe_area_bounds_cache:clone()
end

function Stage:resize(width, height, safe_area_insets)
    assert_not_destroyed(self, 2)
    assert_number('width', width, 2)
    assert_number('height', height, 2)

    if safe_area_insets == nil then
        safe_area_insets =
            read_host_safe_area_insets(width, height) or self.safeAreaInsets
    end

    apply_environment(self, width, height, safe_area_insets)
    return self
end

function Stage:update(dt)
    assert_not_destroyed(self, 2)
    self:_sync_environment_from_host()
    Container.update(self, dt)
    rawset(self, '_update_ran', true)
    return self
end

function Stage:draw(graphics, draw_callback)
    assert_not_destroyed(self, 2)

    if not self._update_ran then
        fail(TWO_PASS_VIOLATION, 2)
    end

    graphics, draw_callback = resolve_draw_args(graphics, draw_callback)
    rawset(self, '_update_ran', false)

    self.baseSceneLayer:_draw_subtree_resolved(graphics, draw_callback)
    self.overlayLayer:_draw_subtree_resolved(graphics, draw_callback)

    return self
end

function Stage:resolveTarget(x, y)
    assert_not_destroyed(self, 2)
    assert_number('x', x, 2)
    assert_number('y', y, 2)

    self:_sync_environment_from_host()
    Container.update(self)

    local target = self.overlayLayer:_hit_test_resolved(x, y)

    if target ~= nil then
        return target
    end

    return self.baseSceneLayer:_hit_test_resolved(x, y)
end

function Stage:deliverInput(raw_event)
    assert_not_destroyed(self, 2)
    assert_table('raw_event', raw_event, 2)

    if type(raw_event.kind) ~= 'string' then
        fail('raw_event.kind must be a string', 2)
    end

    local delivery = {
        raw = raw_event,
        intent = translate_raw_input(raw_event),
        target = nil,
        path = nil,
    }

    if type(raw_event.x) == 'number' and type(raw_event.y) == 'number' then
        delivery.target = self:resolveTarget(raw_event.x, raw_event.y)

        if delivery.target ~= nil then
            delivery.path = build_target_path(self, delivery.target)
        end
    end

    rawset(self, '_last_input_delivery', delivery)

    return delivery
end

function Stage:addChild(_)
    fail('Stage children are runtime-managed; mount content into baseSceneLayer or overlayLayer', 2)
end

function Stage:removeChild(_)
    fail('Stage children are runtime-managed; Stage layers cannot be removed directly', 2)
end

function Stage:destroy()
    if active_stage == self then
        active_stage = nil
    end

    Container.destroy(self)
end

return Stage
