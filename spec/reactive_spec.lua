local Reactive = require('lib.ui.utils.reactive')

local function assert_equal(actual, expected, message)
    if actual ~= expected then
        error(message .. ': expected ' .. tostring(expected) ..
            ', got ' .. tostring(actual), 2)
    end
end

local function assert_true(value, message)
    if not value then
        error(message, 2)
    end
end

local function assert_nil(value, message)
    if value ~= nil then
        error(message .. ': expected nil, got ' .. tostring(value), 2)
    end
end

local function assert_error(fn, needle, message)
    local ok, err = pcall(fn)

    if ok then
        error(message .. ': expected an error', 2)
    end

    local text = tostring(err)

    if needle and not text:find(needle, 1, true) then
        error(message .. ': expected error containing "' .. needle ..
            '", got "' .. text .. '"', 2)
    end
end

local function run_hook_free_storage_tests()
    local obj = Reactive.create({
        width = { val = 100 },
        visible = { val = false },
    })

    assert_equal(obj.width, 100,
        'Reactive.create should expose hook-free properties through normal reads')
    assert_equal(rawget(obj, 'width'), 100,
        'Hook-free properties should be stored directly on the object')
    assert_equal(Reactive.raw_get(obj, 'width'), 100,
        'Reactive.raw_get should read hook-free raw storage')
    assert_equal(obj.visible, false,
        'Hook-free storage should preserve false values')

    obj.width = 120

    assert_equal(obj.width, 120,
        'Hook-free assignments should update the raw object key')
    assert_equal(Reactive.raw_get(obj, 'width'), 120,
        'Reactive.raw_get should observe later hook-free assignments')
end

local function run_hooked_storage_tests()
    local getter_calls = 0
    local getter_self = nil
    local setter_calls = 0
    local setter_self = nil
    local setter_new = nil
    local setter_old = nil

    local obj = Reactive.create({
        count = {
            val = 2,
            get = function(self, value)
                getter_calls = getter_calls + 1
                getter_self = self
                return value * 10
            end,
            set = function(self, value, old)
                setter_calls = setter_calls + 1
                setter_self = self
                setter_new = value
                setter_old = old
                return value + 1
            end,
        },
    })

    assert_nil(rawget(obj, 'count'),
        'Hooked properties should stay absent from the raw object')
    assert_equal(obj.count, 20,
        'Hooked reads should pass stored values through the getter')
    assert_equal(getter_self, obj,
        'Reactive getters should receive the reactive object')
    assert_equal(getter_calls, 1,
        'Hooked reads should invoke the getter once per read')
    assert_equal(Reactive.raw_get(obj, 'count'), 2,
        'Reactive.raw_get should bypass getters for hooked properties')

    obj.count = 4

    assert_equal(setter_calls, 1,
        'Hooked writes should invoke the setter')
    assert_equal(setter_self, obj,
        'Reactive setters should receive the reactive object')
    assert_equal(setter_new, 4,
        'Reactive setters should receive the assigned value')
    assert_equal(setter_old, 2,
        'Reactive setters should receive the previous stored value')
    assert_equal(Reactive.raw_get(obj, 'count'), 5,
        'Reactive setters should store their returned value')
    assert_equal(obj.count, 50,
        'Hooked reads should reflect setter-transformed storage')
end

local function run_equality_short_circuit_tests()
    local setter_calls = 0

    local obj = Reactive.create({
        value = {
            val = 'same',
            set = function(_, value)
                setter_calls = setter_calls + 1
                return value
            end,
        },
    })

    obj.value = 'same'

    assert_equal(setter_calls, 0,
        'Hooked writes should skip setters when the value is unchanged')

    obj.value = 'next'

    assert_equal(setter_calls, 1,
        'Hooked writes should call setters when the value changes')
    assert_equal(Reactive.raw_get(obj, 'value'), 'next',
        'Changed hooked writes should update stored values')
end

local function run_redefinition_tests()
    local obj = Reactive.create({
        mode = { val = 'raw' },
        title = {
            val = 'hooked',
            get = function(_, value)
                return value:upper()
            end,
        },
    })

    Reactive.define_property(obj, 'mode', {
        val = 'hooked',
        get = function(_, value)
            return '[' .. value .. ']'
        end,
    })

    assert_nil(rawget(obj, 'mode'),
        'Redefining hook-free properties as hooked should clear raw storage')
    assert_equal(obj.mode, '[hooked]',
        'Redefined hooked properties should use the new getter')
    assert_equal(Reactive.raw_get(obj, 'mode'), 'hooked',
        'Redefined hooked properties should store the new raw value')

    Reactive.define_property(obj, 'title', { val = 'plain' })

    assert_equal(rawget(obj, 'title'), 'plain',
        'Redefining hooked properties as hook-free should plant raw storage')
    assert_equal(obj.title, 'plain',
        'Redefined hook-free properties should bypass the old getter')
    assert_equal(Reactive.raw_get(obj, 'title'), 'plain',
        'Reactive.raw_get should route to raw storage after hook removal')
end

local function run_remove_property_tests()
    local obj = Reactive.create({
        raw_value = { val = 1 },
        hooked_value = {
            val = 2,
            get = function(_, value)
                return value * 2
            end,
            set = function(_, value)
                return value + 1
            end,
        },
    })

    Reactive.remove_property(obj, 'raw_value')
    Reactive.remove_property(obj, 'hooked_value')
    Reactive.remove_property({}, 'missing')

    assert_nil(obj.raw_value,
        'Reactive.remove_property should clear hook-free raw storage')
    assert_nil(obj.hooked_value,
        'Reactive.remove_property should clear hooked storage')
    assert_nil(Reactive.raw_get(obj, 'hooked_value'),
        'Reactive.remove_property should clear hooked raw values')

    obj.hooked_value = 5

    assert_equal(rawget(obj, 'hooked_value'), 5,
        'Removed hooked properties should no longer retain setter hooks')
    assert_equal(obj.hooked_value, 5,
        'Removed hooked properties should no longer retain getter hooks')
end

local function run_raw_set_tests()
    local setter_calls = 0
    local obj = Reactive.create({
        raw_value = { val = 1 },
        hooked_value = {
            val = 2,
            get = function(_, value)
                return value * 10
            end,
            set = function(_, value)
                setter_calls = setter_calls + 1
                return value + 1
            end,
        },
    })

    Reactive.raw_set(obj, 'raw_value', 8)
    Reactive.raw_set(obj, 'hooked_value', 9)

    assert_equal(obj.raw_value, 8,
        'Reactive.raw_set should update hook-free raw storage')
    assert_equal(Reactive.raw_get(obj, 'hooked_value'), 9,
        'Reactive.raw_set should update hooked storage directly')
    assert_equal(obj.hooked_value, 90,
        'Reactive.raw_set should preserve future getter behavior')
    assert_equal(setter_calls, 0,
        'Reactive.raw_set should bypass setters')

    assert_error(function()
        Reactive.raw_set(obj, 'raw_value', nil)
    end, 'Reactive.raw_set: val must not be nil',
        'Reactive.raw_set should reject nil writes')
end

local function run_pairs_tests()
    local obj = Reactive.create({
        raw_value = { val = 'raw' },
        hooked_value = {
            val = 'hooked',
            get = function(_, value)
                return value:upper()
            end,
        },
    })
    local seen = {}
    local count = 0

    for key, value in pairs(obj) do
        count = count + 1
        seen[key] = value
    end

    assert_equal(count, 2,
        'Reactive pairs should expose only public properties')
    assert_equal(seen.raw_value, 'raw',
        'Reactive pairs should include hook-free raw properties')
    assert_equal(seen.hooked_value, 'hooked',
        'Reactive pairs should include hooked stored values')
end

local function run_validation_error_tests()
    local obj = {}

    assert_error(function()
        Reactive.define_property(obj, 'bad_get', { val = 1, get = true })
    end, 'Reactive.define_property: def.get must be a function or nil',
        'Reactive.define_property should reject non-function getters')

    assert_error(function()
        Reactive.define_property(obj, 'bad_set', { val = 1, set = true })
    end, 'Reactive.define_property: def.set must be a function or nil',
        'Reactive.define_property should reject non-function setters')

    Reactive.define_property(obj, 'value', {
        val = 1,
        set = function()
            return nil
        end,
    })

    assert_error(function()
        obj.value = 2
    end, 'Reactive: setter for key "value" must return a value',
        'Reactive setters should fail when returning nil')
end

local function run()
    run_hook_free_storage_tests()
    run_hooked_storage_tests()
    run_equality_short_circuit_tests()
    run_redefinition_tests()
    run_remove_property_tests()
    run_raw_set_tests()
    run_pairs_tests()
    run_validation_error_tests()
end

return {
    run = run,
}
