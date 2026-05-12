local Assert = require('lib.ui.utils.assert')
local Container = require('lib.ui.core.container')
local Types = require('lib.ui.utils.types')
-- Proxy removed

local Scene = Container:extends('Scene')

local SCENE_PUBLIC_KEYS = {
    params = true,
}

local function get_public_value(self, key)
    if key == 'params' then
        return self._scene_params
    end

    return rawget(self, key)
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
    if value ~= nil and not Types.is_table(value) then
        Assert.fail('Scene.params must be a table or nil', level or 1)
    end

    return value
end

local function set_params(self, value, level)
    local normalized = validate_params(value, level or 1)

    if get_public_value(self, 'params') == normalized then
        return normalized
    end

    self._scene_params = normalized
    return normalized
end


local function is_runtime_utility(node)
    return Types.is_table(node) and (
        node._ui_stage_instance == true or
        node._ui_scene_instance == true or
        node._ui_composer_instance == true
    )
end

local function subtree_contains_runtime_utility(node)
    if is_runtime_utility(node) then
        return true
    end

    local children = node._children

    if not Types.is_table(children) then
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
    if not Types.is_table(parent) or parent._ui_container_instance ~= true then
        return false
    end

    local stage = parent.parent

    if not Types.is_table(stage) or stage._ui_stage_instance ~= true then
        return false
    end

    return stage.baseSceneLayer == parent
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

function Scene:__index(key)
    -- Walk the class hierarchy for methods
    local cls = rawget(self, '_pclass') or getmetatable(self)
    local current = cls
    while current do
        local val = rawget(current, key)
        if val ~= nil then return val end
        current = rawget(current, "super")
    end

    if key == 'params' then
        return get_public_value(self, 'params')
    end

    local declared_props = rawget(self, '_declared_props')
    if declared_props and declared_props[key] then
        return Container._get_public_read_value(self, key)
    end

    return nil
end

function Scene:__newindex(key, value)
    if key == 'parent' then
        if value ~= nil then
            if not self._allow_runtime_parent_assignment then
                Assert.fail('Scene parent ownership is Composer-managed', 2)
            end

            assert_runtime_parent(value, 2)
        else
            self._scene_active = false
            self._scene_runtime_owner = nil
            rawset(self, 'enabled', false)
        end

        rawset(self, key, value)
        return
    end

    if key == 'params' then
        set_params(self, value, 2)
        return
    end

    local allowed_public_keys = rawget(self, '_declared_props')
    if allowed_public_keys and allowed_public_keys[key] then
        Assert.fail(
            'Scene does not support prop "' .. tostring(key) .. '"',
            2
        )
    end

    rawset(self, key, value)
end

function Scene:constructor(opts)
    opts = copy_options(opts)

    Container.constructor(self, {
        width = 'fill',
        height = 'fill',
    }, SCENE_PUBLIC_KEYS)
    Container._allow_fill_from_parent(self, { width = true, height = true })
    Container._allow_child_fill(self, { width = true, height = true })

    self.params = opts.params
    rawset(self, 'enabled', false)

    self._ui_scene_instance = true
    self._scene_created = false
    self._scene_active = false
    self._scene_runtime_owner = nil
    self._allow_runtime_parent_assignment = false
end

function Scene.new(opts)
    return Scene(opts)
end

function Scene.is_scene(value)
    return Types.is_instance(value, Scene)
end

function Scene.onCreate()
end

function Scene.onEnterBefore()
end

function Scene.onEnterAfter()
end

function Scene.onLeaveBefore()
end

function Scene.onLeaveAfter()
end

function Scene.onDestroy()
end

function Scene:_is_created()
    return self._scene_created == true
end

function Scene:_is_runtime_managed()
    return self._scene_runtime_owner ~= nil and self.parent ~= nil
end

function Scene:_is_runtime_active()
    return self._scene_active == true
end

function Scene:_set_runtime_owner(owner)
    self._scene_runtime_owner = owner
    return self
end

function Scene:_mount_to_runtime(parent, owner)
    assert_runtime_parent(parent, 2)

    self._allow_runtime_parent_assignment = true

    local ok, result = pcall(Container.addChild, parent, self)

    self._allow_runtime_parent_assignment = false

    if not ok then
        error(result, 0)
    end

    self._scene_runtime_owner = owner or true
    return self
end

function Scene:_detach_from_runtime()

    if self.parent ~= nil then
        Container.removeChild(self.parent, self)
    end

    return self
end

function Scene:_create_if_needed(params)

    if params ~= nil then
        set_params(self, params, 2)
    end

    if self._scene_created then
        return self
    end

    self:onCreate(get_public_value(self, 'params'))
    self._scene_created = true
    return self
end

function Scene:_run_enter_before()
    self:_create_if_needed()
    self:onEnterBefore()
    return self
end

function Scene:_run_enter_after()
    self:onEnterAfter()
    return self
end

function Scene:_run_leave_before()
    self:onLeaveBefore()
    return self
end

function Scene:_run_leave_after()
    self:onLeaveAfter()
    return self
end

function Scene:_set_runtime_active(active)
    Assert.boolean('active', active, 2)

    if active and self.parent == nil then
        Assert.fail('Scene must be mounted before it can become active', 2)
    end

    self.enabled = active
    self._scene_active = active
    return self
end

function Scene:_is_effectively_targetable(x, y, state)

    if not can_receive_input(self) then
        return false
    end

    return Container._is_effectively_targetable(self, x, y, state)
end

function Scene:_hit_test_resolved(x, y, state)

    if not can_receive_input(self) then
        return nil
    end

    return Container._hit_test_resolved(self, x, y, state)
end

function Scene:addChild(child)

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

function Scene:on_destroy()
    self:onDestroy()
    Container.on_destroy(self)
end

return Scene
