local Assert = require('lib.ui.utils.assert')
local Container = require('lib.ui.core.container')
local Scene = require('lib.ui.scene.scene')
local Stage = require('lib.ui.scene.stage')
local Transitions = require('lib.ui.scene.transitions')
local Types = require('lib.ui.utils.types')
local Rule = require('lib.ui.utils.rule')
local Schema = require('lib.ui.utils.schema')
-- Proxy removed
local ComposerSchema = require('lib.ui.scene.composer_schema')

local Composer = Container:extends('Composer')
Composer.schema = Schema.extend(Container.schema, ComposerSchema.composer)



local max = math.max
local min = math.min

local function unwrap_canvas(canvas)
    if Types.is_table(canvas) and canvas.handle ~= nil then
        return canvas.handle
    end

    return canvas
end

local function get_current_canvas(graphics)
    if not Types.is_function(graphics.getCanvas) then
        return nil
    end

    local ok, canvas = pcall(graphics.getCanvas)

    if not ok then
        return nil
    end

    return canvas
end

local function set_current_canvas(graphics, canvas)
    if not Types.is_function(graphics.setCanvas) then
        Assert.fail(
            'graphics adapter must support setCanvas during active scene transitions',
            2
        )
    end

    graphics.setCanvas(unwrap_canvas(canvas))
end

local function create_transition_canvas(graphics, width, height)
    if not Types.is_function(graphics.newCanvas) then
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
    if Types.is_function(graphics.clear) then
        graphics.clear(0, 0, 0, 0)
    end
end

local function get_public_value(self, key)
    return rawget(self, key)
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
end

local function copy_options(opts)
    if opts == nil then
        opts = {}
    end

    for key, value in pairs(opts) do
        local rule = ComposerSchema.composer[key]
        if rule == nil then
            Assert.fail('Composer does not support prop "' .. tostring(key) .. '"', 2)
        end
        Rule.validate(rule, 'Composer.' .. tostring(key), value, nil, 2, opts)
    end

    local copy = {}
    for key, rule in pairs(ComposerSchema.composer) do
        if rule.default ~= nil then
            copy[key] = rule.default
        end
    end
    for key, value in pairs(opts) do
        copy[key] = value
    end

    return copy
end

local function copy_navigation_options(options)
    if options == nil then
        return {}
    end

    Assert.table('options', options, 2)

    for key, value in pairs(options) do
        local rule = ComposerSchema.navigation[key]
        if rule == nil then
            Assert.fail('gotoScene does not support option "' .. tostring(key) .. '"', 3)
        end
        Rule.validate(rule, 'gotoScene.' .. tostring(key), value, nil, 3, options)
    end

    local copy = {}
    for key, value in pairs(options) do
        copy[key] = value
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

function Composer:__index(key)
    if key == 'stage' then
        return self._stage
    end

    if key == 'transitionState' then
        return self._transition_state
    end

    local current = rawget(self, '_pclass') or getmetatable(self)
    while current ~= nil do
        local method = rawget(current, key)
        if method ~= nil then
            return method
        end
        current = rawget(current, 'super')
    end

    return nil
end

function Composer:__newindex(key, value)
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

    rawset(self, key, value)
end

function Composer:constructor(opts)
    opts = copy_options(opts)

    Container.constructor(self, {}, ComposerSchema.composer)

    for key, value in pairs(opts) do
        self[key] = value
    end

    self._scene_registry = {}
    self._current_scene = nil
    self._current_scene_name = nil
    self._transition_state = nil
    self._suppressed_leave_scene = nil
    self._running_lifecycle_hook = false

    self._ui_composer_instance = true
    self._stage = Stage.new()
end

function Composer.new(opts)
    return Composer(opts)
end

function Composer.is_composer(value)
    return Types.is_instance(value, Composer)
end

function Composer:_run_lifecycle(callback)

    if self._running_lifecycle_hook then
        Assert.fail('Composer lifecycle hooks must not recurse', 2)
    end

    self._running_lifecycle_hook = true

    local ok, err = xpcall(callback, debug.traceback)

    self._running_lifecycle_hook = false

    if not ok then
        error(err, 0)
    end

    return self
end

function Composer:_resolve_registered_entry(name)
    assert_scene_name(name, 2)

    local registry = self._scene_registry
    local entry = registry[name]

    if entry == nil then
        Assert.fail('unknown scene name "' .. name .. '"', 2)
    end

    return entry
end

function Composer._instantiate_scene(_, entry)
    local definition = entry.definition
    local scene

    if Types.is_function(definition) then
        scene = definition()
    else
        scene = definition.new()
    end

    if not Scene.is_scene(scene) then
        Assert.fail('registered scene factory must return a Scene instance', 2)
    end

    if scene.parent ~= nil or scene._scene_runtime_owner ~= nil then
        Assert.fail(
            'registered scenes must be detached before Composer ownership begins',
            2
        )
    end

    entry.instance = scene
    return scene
end

function Composer:_resolve_scene_instance(name)

    local entry = self:_resolve_registered_entry(name)
    local scene = entry.instance

    if scene == nil then
        scene = self:_instantiate_scene(entry)
    end

    return scene
end

function Composer:_mount_scene(scene)

    if scene.parent == self.stage.baseSceneLayer then
        scene:_set_runtime_owner(self)
        return scene
    end

    scene:_mount_to_runtime(self.stage.baseSceneLayer, self)
    return scene
end

function Composer._detach_scene(_, scene)

    if scene.parent ~= nil then
        scene:_detach_from_runtime()
    end

    return scene
end

function Composer:_run_scene_enter_before(scene, params)

    scene:_create_if_needed(params)

    return self:_run_lifecycle(function()
        scene:onEnterBefore()
    end)
end

function Composer:_run_scene_enter_after(scene)

    return self:_run_lifecycle(function()
        scene:_run_enter_after()
    end)
end

function Composer:_run_scene_leave_before(scene)

    return self:_run_lifecycle(function()
        scene:_run_leave_before()
    end)
end

function Composer:_run_scene_leave_after(scene)

    return self:_run_lifecycle(function()
        scene:_run_leave_after()
    end)
end

function Composer:_commit_navigation(outgoing_scene, target_name, target_scene, suppress_leave_hooks)

    local transition_state = self._transition_state
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

    self._current_scene = target_scene
    self._current_scene_name = target_name
    self._transition_state = nil
    self._suppressed_leave_scene = nil

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

    if outgoing_scene ~= nil then
        self:_mount_scene(outgoing_scene)
    end

    self:_mount_scene(target_scene)

    self._transition_state = {
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
    }

    return self
end

function Composer:_begin_navigation(target_name, options)

    local target_scene = self:_resolve_scene_instance(target_name)
    local navigation = resolve_navigation_configuration(self, options)
    local current_scene = self._current_scene
    local current_name = self._current_scene_name
    local suppress_leave_hooks =
        current_scene ~= nil and
        current_scene == self._suppressed_leave_scene

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

    local transition_state = self._transition_state

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

    self._current_scene = incoming_scene
    self._current_scene_name = transition_state.incoming_name
    self._transition_state = nil

    if commit_incoming_scene == true then
        self._suppressed_leave_scene = nil
    elseif incoming_scene ~= nil and incoming_scene ~= outgoing_scene then
        self._suppressed_leave_scene = incoming_scene
    else
        self._suppressed_leave_scene = nil
    end

    return self
end

function Composer:_process_navigation_request(target_name, options)

    if self._transition_state ~= nil then
        self:_interrupt_transition(false)
    end

    return self:_begin_navigation(target_name, options)
end

function Composer:_render_scene_to_canvas(scene, graphics, draw_callback, canvas)

    local previous_canvas = get_current_canvas(graphics)

    if Types.is_function(graphics.push) then
        graphics.push('all')
    end

    if Types.is_function(graphics.origin) then
        graphics.origin()
    end

    set_current_canvas(graphics, canvas)
    clear_transition_canvas(graphics)
    scene:_draw_subtree_resolved(graphics, draw_callback)
    set_current_canvas(graphics, previous_canvas)

    if Types.is_function(graphics.pop) then
        graphics.pop()
    end

    return self
end

function Composer:_draw_transition(graphics, draw_callback)

    local transition_state = self._transition_state

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

    local transition_state = self._transition_state

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
    assert_scene_name(name, 2)

    if not Types.is_function(definition) and not (
        Types.is_table(definition) and Types.is_function(definition.new)
    ) then
        Assert.fail(
            'definition must be a factory function or a table with .new()',
            2
        )
    end

    local registry = self._scene_registry

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
    assert_scene_name(name, 2)

    if self._running_lifecycle_hook then
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

    if dt ~= nil then
        validate_duration('dt', dt, 2)
    end

    if self._transition_state ~= nil then
        self.stage:_queue_state_change(function()
            self:_advance_transition(dt or 0)
        end)
    end

    self.stage:update(dt)
    return self
end

function Composer:draw(graphics, draw_callback)

    if self._transition_state == nil then
        self.stage:draw(graphics, draw_callback)
        return self
    end

    graphics, draw_callback = self.stage:_prepare_draw(graphics, draw_callback)
    self:_draw_transition(graphics, draw_callback)
    self.stage:_draw_overlay_layer_resolved(graphics, draw_callback)

    return self
end

function Composer:resize(width, height, safe_area_insets)

    if self._transition_state ~= nil then
        self:_interrupt_transition(true)
    end

    self.stage:resize(width, height, safe_area_insets)
    return self
end

function Composer:deliverInput(raw_event)
    return self.stage:deliverInput(raw_event)
end

function Composer:on_destroy()
    local destroyed = {}
    local registry = self._scene_registry

    for _, entry in pairs(registry) do
        local scene = entry.instance

        if scene ~= nil and not destroyed[scene] then
            destroyed[scene] = true

            run_protected(function()
                scene:destroy()
            end)
        end

        entry.instance = nil
    end

    self.stage:destroy()

    self._current_scene = nil
    self._current_scene_name = nil

    local transition_state = self._transition_state

    if transition_state ~= nil then
        transition_state.outgoing_canvas = nil
        transition_state.incoming_canvas = nil
    end

    self._transition_state = nil
    self._suppressed_leave_scene = nil
    Container.on_destroy(self)
end

return Composer
