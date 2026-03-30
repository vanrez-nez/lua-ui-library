local Assert = require('lib.ui.core.assert')
local Scene = require('lib.ui.scene.scene')
local Stage = require('lib.ui.scene.stage')
local Transitions = require('lib.ui.scene.transitions')

local Composer = {}

local COMPOSER_PUBLIC_KEYS = {
    defaultTransition = true,
    defaultTransitionDuration = true,
}

local NAVIGATION_OPTION_KEYS = {
    transition = true,
    duration = true,
    params = true,
}

local max = math.max
local min = math.min

local function unwrap_canvas(canvas)
    if type(canvas) == 'table' and rawget(canvas, 'handle') ~= nil then
        return rawget(canvas, 'handle')
    end

    return canvas
end

local function get_current_canvas(graphics)
    if type(graphics.getCanvas) ~= 'function' then
        return nil
    end

    local ok, canvas = pcall(graphics.getCanvas)

    if not ok then
        return nil
    end

    return canvas
end

local function set_current_canvas(graphics, canvas)
    if type(graphics.setCanvas) ~= 'function' then
        Assert.fail(
            'graphics adapter must support setCanvas during active scene transitions',
            2
        )
    end

    graphics.setCanvas(unwrap_canvas(canvas))
end

local function create_transition_canvas(graphics, width, height)
    if type(graphics.newCanvas) ~= 'function' then
        Assert.fail(
            'graphics adapter must support newCanvas during active scene transitions',
            2
        )
    end

    return {
        handle = graphics.newCanvas(width, height),
        width = width,
        height = height,
    }
end

local function ensure_transition_canvas(graphics, canvas, width, height)
    if canvas ~= nil and canvas.width == width and canvas.height == height then
        return canvas
    end

    return create_transition_canvas(graphics, width, height)
end

local function clear_transition_canvas(graphics)
    if type(graphics.clear) == 'function' then
        graphics.clear(0, 0, 0, 0)
    end
end

local function get_public_value(self, key)
    local public_values = rawget(self, '_public_values')

    if public_values == nil then
        return nil
    end

    return public_values[key]
end

local function assert_not_destroyed(self, level)
    if rawget(self, '_destroyed') then
        Assert.fail('cannot use a destroyed Composer', level or 1)
    end
end

local function assert_scene_name(name, level)
    Assert.string('name', name, level or 1)

    if name == '' then
        Assert.fail('scene name must not be empty', level or 1)
    end
end

local function validate_duration(name, value, level)
    Assert.number(name, value, level or 1)

    if value < 0 then
        Assert.fail(name .. ' must be greater than or equal to 0', level or 1)
    end

    return value
end

local function copy_options(opts)
    if opts == nil then
        return {}
    end

    Assert.table('opts', opts, 2)

    local copy = {}

    for key, value in pairs(opts) do
        if not COMPOSER_PUBLIC_KEYS[key] then
            Assert.fail(
                'Composer does not support prop "' .. tostring(key) .. '"',
                3
            )
        end

        copy[key] = value
    end

    return copy
end

local function copy_navigation_options(options)
    if options == nil then
        return {}
    end

    Assert.table('options', options, 2)

    local copy = {}

    for key, value in pairs(options) do
        if not NAVIGATION_OPTION_KEYS[key] then
            Assert.fail(
                'gotoScene does not support option "' .. tostring(key) .. '"',
                3
            )
        end

        copy[key] = value
    end

    if copy.duration ~= nil then
        validate_duration('options.duration', copy.duration, 2)
    end

    if copy.params ~= nil and type(copy.params) ~= 'table' then
        Assert.fail('options.params must be a table or nil', 2)
    end

    return copy
end

local function resolve_navigation_configuration(self, options)
    local transition = options.transition

    if transition == nil then
        transition = get_public_value(self, 'defaultTransition')
    end

    local duration = options.duration

    if duration == nil then
        duration = get_public_value(self, 'defaultTransitionDuration') or 0
    end

    local transition_enabled = duration > 0 and
        transition ~= nil and
        transition ~= false

    if transition_enabled then
        transition = Transitions.resolve(transition)
    end

    return {
        params = options.params,
        transition = transition,
        duration = duration,
        transition_enabled = transition_enabled,
    }
end

local function run_protected(callback)
    local ok, err = xpcall(callback, debug.traceback)

    if not ok then
        error(err, 0)
    end
end

function Composer.__index(self, key)
    local method = rawget(Composer, key)

    if method ~= nil then
        return method
    end

    if COMPOSER_PUBLIC_KEYS[key] then
        return get_public_value(self, key)
    end

    if key == 'stage' then
        return rawget(self, '_stage')
    end

    if key == 'transitionState' then
        return rawget(self, '_transition_state')
    end

    return rawget(self, key)
end

function Composer.__newindex(self, key, value)
    if key == 'parent' then
        if value ~= nil then
            Assert.fail('Composer must not have a parent', 2)
        end

        rawset(self, key, nil)
        return
    end

    if key == 'stage' or key == 'transitionState' then
        Assert.fail('Composer runtime ownership is internal', 2)
    end

    if key == 'defaultTransitionDuration' then
        assert_not_destroyed(self, 2)
        get_public_value(self, key)
        rawget(self, '_public_values')[key] =
            validate_duration('Composer.defaultTransitionDuration', value, 2)
        return
    end

    if key == 'defaultTransition' then
        assert_not_destroyed(self, 2)
        rawget(self, '_public_values')[key] = value
        return
    end

    rawset(self, key, value)
end

function Composer.new(opts)
    opts = copy_options(opts)

    local self = {
        _public_values = {
            defaultTransition = opts.defaultTransition,
            defaultTransitionDuration = 0,
        },
        _scene_registry = {},
        _current_scene = nil,
        _current_scene_name = nil,
        _transition_state = nil,
        _suppressed_leave_scene = nil,
        _running_lifecycle_hook = false,
        _destroyed = false,
    }

    if opts.defaultTransitionDuration ~= nil then
        self._public_values.defaultTransitionDuration =
            validate_duration(
                'Composer.defaultTransitionDuration',
                opts.defaultTransitionDuration,
                2
            )
    end

    rawset(self, '_ui_composer_instance', true)
    rawset(self, '_stage', Stage.new())

    return setmetatable(self, Composer)
end

function Composer.is_composer(value)
    return type(value) == 'table' and value._ui_composer_instance == true
end

function Composer:_run_lifecycle(callback)
    assert_not_destroyed(self, 2)

    if rawget(self, '_running_lifecycle_hook') then
        Assert.fail('Composer lifecycle hooks must not recurse', 2)
    end

    rawset(self, '_running_lifecycle_hook', true)

    local ok, err = xpcall(callback, debug.traceback)

    rawset(self, '_running_lifecycle_hook', false)

    if not ok then
        error(err, 0)
    end

    return self
end

function Composer:_resolve_registered_entry(name)
    assert_scene_name(name, 2)

    local entry = rawget(self, '_scene_registry')[name]

    if entry == nil then
        Assert.fail('unknown scene name "' .. name .. '"', 2)
    end

    return entry
end

function Composer:_instantiate_scene(entry)
    local definition = entry.definition
    local scene

    if type(definition) == 'function' then
        scene = definition()
    else
        scene = definition.new()
    end

    if not Scene.is_scene(scene) then
        Assert.fail('registered scene factory must return a Scene instance', 2)
    end

    if scene._destroyed then
        Assert.fail('registered scene factory must not return a destroyed Scene', 2)
    end

    if scene.parent ~= nil or rawget(scene, '_scene_runtime_owner') ~= nil then
        Assert.fail(
            'registered scenes must be detached before Composer ownership begins',
            2
        )
    end

    entry.instance = scene
    return scene
end

function Composer:_resolve_scene_instance(name)
    assert_not_destroyed(self, 2)

    local entry = self:_resolve_registered_entry(name)
    local scene = entry.instance

    if scene ~= nil and scene._destroyed then
        entry.instance = nil
        scene = nil
    end

    if scene == nil then
        scene = self:_instantiate_scene(entry)
    end

    return scene
end

function Composer:_mount_scene(scene)
    assert_not_destroyed(self, 2)

    if scene.parent == self.stage.baseSceneLayer then
        scene:_set_runtime_owner(self)
        return scene
    end

    scene:_mount_to_runtime(self.stage.baseSceneLayer, self)
    return scene
end

function Composer:_detach_scene(scene)
    assert_not_destroyed(self, 2)

    if scene.parent ~= nil then
        scene:_detach_from_runtime()
    end

    return scene
end

function Composer:_run_scene_enter_before(scene, params)
    assert_not_destroyed(self, 2)

    scene:_create_if_needed(params)

    return self:_run_lifecycle(function()
        scene:onEnterBefore()
    end)
end

function Composer:_run_scene_enter_after(scene)
    assert_not_destroyed(self, 2)

    return self:_run_lifecycle(function()
        scene:_run_enter_after()
    end)
end

function Composer:_run_scene_leave_before(scene)
    assert_not_destroyed(self, 2)

    return self:_run_lifecycle(function()
        scene:_run_leave_before()
    end)
end

function Composer:_run_scene_leave_after(scene)
    assert_not_destroyed(self, 2)

    return self:_run_lifecycle(function()
        scene:_run_leave_after()
    end)
end

function Composer:_commit_navigation(outgoing_scene, target_name, target_scene, suppress_leave_hooks)
    assert_not_destroyed(self, 2)

    local transition_state = rawget(self, '_transition_state')
    local same_scene = outgoing_scene ~= nil and outgoing_scene == target_scene

    if outgoing_scene ~= nil then
        outgoing_scene:_set_runtime_active(false)

        if not suppress_leave_hooks then
            self:_run_scene_leave_after(outgoing_scene)
        end

        if not same_scene then
            self:_detach_scene(outgoing_scene)
        end
    end

    self:_mount_scene(target_scene)
    target_scene:_set_runtime_active(true)
    self:_run_scene_enter_after(target_scene)

    rawset(self, '_current_scene', target_scene)
    rawset(self, '_current_scene_name', target_name)
    rawset(self, '_transition_state', nil)
    rawset(self, '_suppressed_leave_scene', nil)

    if transition_state ~= nil then
        transition_state.outgoing_canvas = nil
        transition_state.incoming_canvas = nil
    end

    return self
end

function Composer:_initialize_transition(
    outgoing_name,
    outgoing_scene,
    target_name,
    target_scene,
    navigation,
    suppress_leave_hooks
)
    assert_not_destroyed(self, 2)

    if outgoing_scene ~= nil then
        self:_mount_scene(outgoing_scene)
    end

    self:_mount_scene(target_scene)

    rawset(self, '_transition_state', {
        outgoing_name = outgoing_name,
        outgoing_scene = outgoing_scene,
        incoming_name = target_name,
        incoming_scene = target_scene,
        definition = navigation.transition,
        duration = navigation.duration,
        elapsed = 0,
        progress = 0,
        suppress_outgoing_leave_hooks = suppress_leave_hooks == true,
        outgoing_canvas = nil,
        incoming_canvas = nil,
    })

    return self
end

function Composer:_begin_navigation(target_name, options)
    assert_not_destroyed(self, 2)

    local target_scene = self:_resolve_scene_instance(target_name)
    local navigation = resolve_navigation_configuration(self, options)
    local current_scene = rawget(self, '_current_scene')
    local current_name = rawget(self, '_current_scene_name')
    local suppress_leave_hooks =
        current_scene ~= nil and
        current_scene == rawget(self, '_suppressed_leave_scene')

    if current_scene ~= nil and not suppress_leave_hooks then
        self:_run_scene_leave_before(current_scene)
    end

    self:_run_scene_enter_before(target_scene, navigation.params)

    if navigation.transition_enabled then
        return self:_initialize_transition(
            current_name,
            current_scene,
            target_name,
            target_scene,
            navigation,
            suppress_leave_hooks
        )
    end

    return self:_commit_navigation(
        current_scene,
        target_name,
        target_scene,
        suppress_leave_hooks
    )
end

function Composer:_interrupt_transition(commit_incoming_scene)
    assert_not_destroyed(self, 2)

    local transition_state = rawget(self, '_transition_state')

    if transition_state == nil then
        return self
    end

    local outgoing_scene = transition_state.outgoing_scene
    local incoming_scene = transition_state.incoming_scene

    if outgoing_scene ~= nil and outgoing_scene ~= incoming_scene then
        outgoing_scene:_set_runtime_active(false)
        self:_run_scene_leave_after(outgoing_scene)
        self:_detach_scene(outgoing_scene)
    end

    if incoming_scene ~= nil then
        self:_mount_scene(incoming_scene)
        incoming_scene:_set_runtime_active(true)

        if commit_incoming_scene == true then
            self:_run_scene_enter_after(incoming_scene)
        end
    end

    transition_state.outgoing_canvas = nil
    transition_state.incoming_canvas = nil

    rawset(self, '_current_scene', incoming_scene)
    rawset(self, '_current_scene_name', transition_state.incoming_name)
    rawset(self, '_transition_state', nil)

    if commit_incoming_scene == true then
        rawset(self, '_suppressed_leave_scene', nil)
    elseif incoming_scene ~= nil and incoming_scene ~= outgoing_scene then
        rawset(self, '_suppressed_leave_scene', incoming_scene)
    else
        rawset(self, '_suppressed_leave_scene', nil)
    end

    return self
end

function Composer:_process_navigation_request(target_name, options)
    assert_not_destroyed(self, 2)

    if rawget(self, '_transition_state') ~= nil then
        self:_interrupt_transition(false)
    end

    return self:_begin_navigation(target_name, options)
end

function Composer:_render_scene_to_canvas(scene, graphics, draw_callback, canvas)
    assert_not_destroyed(self, 2)

    local previous_canvas = get_current_canvas(graphics)

    if type(graphics.push) == 'function' then
        graphics.push('all')
    end

    if type(graphics.origin) == 'function' then
        graphics.origin()
    end

    set_current_canvas(graphics, canvas)
    clear_transition_canvas(graphics)
    scene:_draw_subtree_resolved(graphics, draw_callback)
    set_current_canvas(graphics, previous_canvas)

    if type(graphics.pop) == 'function' then
        graphics.pop()
    end

    return self
end

function Composer:_draw_transition(graphics, draw_callback)
    assert_not_destroyed(self, 2)

    local transition_state = rawget(self, '_transition_state')

    if transition_state == nil then
        return self
    end

    local width = max(0, self.stage.width or 0)
    local height = max(0, self.stage.height or 0)

    transition_state.outgoing_canvas =
        ensure_transition_canvas(
            graphics,
            transition_state.outgoing_canvas,
            width,
            height
        )
    transition_state.incoming_canvas =
        ensure_transition_canvas(
            graphics,
            transition_state.incoming_canvas,
            width,
            height
        )

    if transition_state.outgoing_scene ~= nil then
        self:_render_scene_to_canvas(
            transition_state.outgoing_scene,
            graphics,
            draw_callback,
            transition_state.outgoing_canvas
        )
    else
        self:_render_scene_to_canvas(
            self.stage.baseSceneLayer,
            graphics,
            function()
            end,
            transition_state.outgoing_canvas
        )
    end

    self:_render_scene_to_canvas(
        transition_state.incoming_scene,
        graphics,
        draw_callback,
        transition_state.incoming_canvas
    )

    transition_state.definition.compose(
        graphics,
        transition_state.progress,
        transition_state.outgoing_canvas,
        transition_state.incoming_canvas,
        width,
        height
    )

    return self
end

function Composer:_advance_transition(dt)
    assert_not_destroyed(self, 2)

    local transition_state = rawget(self, '_transition_state')

    if transition_state == nil then
        return self
    end

    dt = dt or 0
    validate_duration('dt', dt, 2)

    transition_state.elapsed = transition_state.elapsed + dt

    if transition_state.duration <= 0 then
        transition_state.progress = 1
    else
        transition_state.progress = min(
            1,
            max(0, transition_state.elapsed / transition_state.duration)
        )
    end

    if transition_state.progress >= 1 then
        return self:_commit_navigation(
            transition_state.outgoing_scene,
            transition_state.incoming_name,
            transition_state.incoming_scene,
            transition_state.suppress_outgoing_leave_hooks
        )
    end

    return self
end

function Composer:register(name, definition)
    assert_not_destroyed(self, 2)
    assert_scene_name(name, 2)

    local definition_type = type(definition)

    if definition_type ~= 'function' and not (
        definition_type == 'table' and type(definition.new) == 'function'
    ) then
        Assert.fail(
            'definition must be a factory function or a table with .new()',
            2
        )
    end

    local registry = rawget(self, '_scene_registry')

    if registry[name] ~= nil then
        Assert.fail('scene "' .. name .. '" is already registered', 2)
    end

    registry[name] = {
        definition = definition,
        instance = nil,
    }

    return self
end

function Composer:gotoScene(name, options)
    assert_not_destroyed(self, 2)
    assert_scene_name(name, 2)

    if rawget(self, '_running_lifecycle_hook') then
        Assert.fail(
            'Composer navigation is invalid during scene enter/leave lifecycle hooks',
            2
        )
    end

    self:_resolve_registered_entry(name)
    options = copy_navigation_options(options)

    self.stage:_queue_state_change(function()
        self:_process_navigation_request(name, options)
    end)

    return self
end

function Composer:update(dt)
    assert_not_destroyed(self, 2)

    if dt ~= nil then
        validate_duration('dt', dt, 2)
    end

    if rawget(self, '_transition_state') ~= nil then
        self.stage:_queue_state_change(function()
            self:_advance_transition(dt or 0)
        end)
    end

    self.stage:update(dt)
    return self
end

function Composer:draw(graphics, draw_callback)
    assert_not_destroyed(self, 2)

    if rawget(self, '_transition_state') == nil then
        self.stage:draw(graphics, draw_callback)
        return self
    end

    graphics, draw_callback = self.stage:_prepare_draw(graphics, draw_callback)
    self:_draw_transition(graphics, draw_callback)
    self.stage:_draw_overlay_layer_resolved(graphics, draw_callback)

    return self
end

function Composer:resize(width, height, safe_area_insets)
    assert_not_destroyed(self, 2)

    if rawget(self, '_transition_state') ~= nil then
        self:_interrupt_transition(true)
    end

    self.stage:resize(width, height, safe_area_insets)
    return self
end

function Composer:deliverInput(raw_event)
    assert_not_destroyed(self, 2)
    return self.stage:deliverInput(raw_event)
end

function Composer:destroy()
    assert_not_destroyed(self, 2)

    local destroyed = {}

    for _, entry in pairs(rawget(self, '_scene_registry')) do
        local scene = entry.instance

        if scene ~= nil and not destroyed[scene] and not scene._destroyed then
            destroyed[scene] = true

            run_protected(function()
                scene:destroy()
            end)
        end

        entry.instance = nil
    end

    if not self.stage._destroyed then
        self.stage:destroy()
    end

    rawset(self, '_current_scene', nil)
    rawset(self, '_current_scene_name', nil)

    local transition_state = rawget(self, '_transition_state')

    if transition_state ~= nil then
        transition_state.outgoing_canvas = nil
        transition_state.incoming_canvas = nil
    end

    rawset(self, '_transition_state', nil)
    rawset(self, '_suppressed_leave_scene', nil)
    rawset(self, '_destroyed', true)

    return nil
end

return Composer
