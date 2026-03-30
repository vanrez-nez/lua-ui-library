local Assert = require('lib.ui.core.assert')
local Container = require('lib.ui.core.container')

local Scene = {}

local SCENE_PUBLIC_KEYS = {
    params = true,
}

local function get_public_value(self, key)
    local public_values = rawget(self, '_public_values')

    if public_values == nil then
        return nil
    end

    return public_values[key]
end

local function assert_not_destroyed(self, level)
    if self._destroyed then
        Assert.fail('cannot use a destroyed Scene', level or 1)
    end
end

local function copy_options(opts)
    if opts == nil then
        return {}
    end

    Assert.table('opts', opts, 2)

    local copy = {}

    for key, value in pairs(opts) do
        if not SCENE_PUBLIC_KEYS[key] then
            Assert.fail(
                'Scene does not support prop "' .. tostring(key) .. '"',
                3
            )
        end

        copy[key] = value
    end

    return copy
end

local function validate_params(value, level)
    if value ~= nil and type(value) ~= 'table' then
        Assert.fail('Scene.params must be a table or nil', level or 1)
    end

    return value
end

local function set_initial_params(self, value)
    local normalized = validate_params(value, 3)

    self._public_values.params = normalized
    self._effective_values.params = normalized
end

local function set_params(self, value, level)
    local normalized = validate_params(value, level or 1)

    if get_public_value(self, 'params') == normalized then
        return normalized
    end

    self._public_values.params = normalized
    self._effective_values.params = normalized
    return normalized
end

local function is_runtime_utility(node)
    return type(node) == 'table' and (
        node._ui_stage_instance == true or
        node._ui_scene_instance == true or
        node._ui_composer_instance == true
    )
end

local function subtree_contains_runtime_utility(node)
    if is_runtime_utility(node) then
        return true
    end

    local children = rawget(node, '_children')

    if type(children) ~= 'table' then
        return false
    end

    for index = 1, #children do
        if subtree_contains_runtime_utility(children[index]) then
            return true
        end
    end

    return false
end

local function is_base_scene_layer(parent)
    if type(parent) ~= 'table' or parent._ui_container_instance ~= true then
        return false
    end

    local stage = rawget(parent, 'parent')

    if type(stage) ~= 'table' or stage._ui_stage_instance ~= true then
        return false
    end

    return rawget(stage, 'baseSceneLayer') == parent
end

local function assert_runtime_parent(parent, level)
    if not is_base_scene_layer(parent) then
        Assert.fail(
            'Scene must be mounted only into the Stage base scene layer through Composer management',
            level or 1
        )
    end
end

local function can_receive_input(self)
    return self._scene_active == true and
        self._scene_runtime_owner ~= nil and
        is_base_scene_layer(self.parent)
end

Scene.__index = function(self, key)
    local method = rawget(Scene, key)

    if method ~= nil then
        return method
    end

    if key == 'params' then
        return get_public_value(self, 'params')
    end

    return Container.__index(self, key)
end

Scene.__newindex = function(self, key, value)
    if key == 'parent' then
        if value ~= nil then
            if not rawget(self, '_allow_runtime_parent_assignment') then
                Assert.fail('Scene parent ownership is Composer-managed', 2)
            end

            assert_runtime_parent(value, 2)
        else
            rawset(self, '_scene_active', false)
            rawset(self, '_scene_runtime_owner', nil)
            Container.__newindex(self, 'enabled', false)
        end

        rawset(self, key, value)
        return
    end

    if key == 'params' then
        assert_not_destroyed(self, 2)
        set_params(self, value, 2)
        return
    end

    if rawget(self, '_allowed_public_keys')[key] then
        Assert.fail(
            'Scene does not support prop "' .. tostring(key) .. '"',
            2
        )
    end

    rawset(self, key, value)
end

function Scene.new(opts)
    opts = copy_options(opts)

    local self = {}

    Container._initialize(self, {
        width = 'fill',
        height = 'fill',
    }, SCENE_PUBLIC_KEYS)

    set_initial_params(self, opts.params)
    self._public_values.enabled = false
    self._effective_values.enabled = false

    rawset(self, '_ui_scene_instance', true)
    rawset(self, '_scene_created', false)
    rawset(self, '_scene_active', false)
    rawset(self, '_scene_runtime_owner', nil)
    rawset(self, '_allow_runtime_parent_assignment', false)

    return setmetatable(self, Scene)
end

function Scene.is_scene(value)
    return type(value) == 'table' and value._ui_scene_instance == true
end

function Scene:onCreate(_)
end

function Scene:onEnterBefore()
end

function Scene:onEnterAfter()
end

function Scene:onLeaveBefore()
end

function Scene:onLeaveAfter()
end

function Scene:onDestroy()
end

function Scene:_is_created()
    assert_not_destroyed(self, 2)
    return rawget(self, '_scene_created') == true
end

function Scene:_is_runtime_managed()
    assert_not_destroyed(self, 2)
    return rawget(self, '_scene_runtime_owner') ~= nil and self.parent ~= nil
end

function Scene:_is_runtime_active()
    assert_not_destroyed(self, 2)
    return rawget(self, '_scene_active') == true
end

function Scene:_set_runtime_owner(owner)
    assert_not_destroyed(self, 2)
    rawset(self, '_scene_runtime_owner', owner)
    return self
end

function Scene:_mount_to_runtime(parent, owner)
    assert_not_destroyed(self, 2)
    assert_runtime_parent(parent, 2)

    rawset(self, '_allow_runtime_parent_assignment', true)

    local ok, result = pcall(Container.addChild, parent, self)

    rawset(self, '_allow_runtime_parent_assignment', false)

    if not ok then
        error(result, 0)
    end

    rawset(self, '_scene_runtime_owner', owner or true)
    return self
end

function Scene:_detach_from_runtime()
    assert_not_destroyed(self, 2)

    if self.parent ~= nil then
        Container.removeChild(self.parent, self)
    end

    return self
end

function Scene:_create_if_needed(params)
    assert_not_destroyed(self, 2)

    if params ~= nil then
        set_params(self, params, 2)
    end

    if self._scene_created then
        return self
    end

    self:onCreate(get_public_value(self, 'params'))
    rawset(self, '_scene_created', true)
    return self
end

function Scene:_run_enter_before()
    assert_not_destroyed(self, 2)
    self:_create_if_needed()
    self:onEnterBefore()
    return self
end

function Scene:_run_enter_after()
    assert_not_destroyed(self, 2)
    self:onEnterAfter()
    return self
end

function Scene:_run_leave_before()
    assert_not_destroyed(self, 2)
    self:onLeaveBefore()
    return self
end

function Scene:_run_leave_after()
    assert_not_destroyed(self, 2)
    self:onLeaveAfter()
    return self
end

function Scene:_set_runtime_active(active)
    assert_not_destroyed(self, 2)
    Assert.boolean('active', active, 2)

    if active and self.parent == nil then
        Assert.fail('Scene must be mounted before it can become active', 2)
    end

    Container.__newindex(self, 'enabled', active)
    rawset(self, '_scene_active', active)
    return self
end

function Scene:_is_effectively_targetable(x, y, state)
    assert_not_destroyed(self, 2)

    if not can_receive_input(self) then
        return false
    end

    return Container._is_effectively_targetable(self, x, y, state)
end

function Scene:_hit_test_resolved(x, y, state)
    assert_not_destroyed(self, 2)

    if not can_receive_input(self) then
        return nil
    end

    return Container._hit_test_resolved(self, x, y, state)
end

function Scene:addChild(child)
    assert_not_destroyed(self, 2)

    if Scene.is_scene(child) then
        Assert.fail('Scene cannot contain direct child scenes', 2)
    end

    if subtree_contains_runtime_utility(child) then
        Assert.fail(
            'Scene content cannot contain runtime utility descendants',
            2
        )
    end

    return Container.addChild(self, child)
end

function Scene:destroy()
    assert_not_destroyed(self, 2)
    self:onDestroy()
    Container.destroy(self)
end

return Scene
