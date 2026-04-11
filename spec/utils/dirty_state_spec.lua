local DirtyState = require('lib.ui.utils.dirty_state')

local function assert_equal(actual, expected, message)
    if actual ~= expected then
        error(message .. ': expected ' .. tostring(expected) .. ', got ' .. tostring(actual), 2)
    end
end

local function assert_true(value, message)
    if not value then
        error(message, 2)
    end
end

local function assert_false(value, message)
    if value then
        error(message, 2)
    end
end

local function run_construction_and_mark_tests()
    local dirty = DirtyState({ 'measurement', 'transform', 'paint' })

    assert_false(dirty:is_dirty('measurement'),
        'DirtyState should initialize declared flags as clean')
    assert_false(dirty:is_dirty('transform'),
        'DirtyState should initialize every declared flag as clean')
    assert_false(dirty:is_any(),
        'DirtyState should report no dirty flags immediately after construction')
    assert_false(dirty:is_all(),
        'DirtyState should not report all flags dirty immediately after construction')

    dirty:mark('measurement')

    assert_true(dirty:is_dirty('measurement'),
        'DirtyState mark should set a single flag dirty')
    assert_false(dirty:is_dirty('transform'),
        'DirtyState mark should not affect unrelated flags')

    dirty:mark('transform', 'paint')

    assert_true(dirty:is_dirty('transform'),
        'DirtyState mark should support varargs')
    assert_true(dirty:is_dirty('paint'),
        'DirtyState mark should set every requested flag dirty')
end

local function run_clear_tests()
    local dirty = DirtyState({ 'measurement', 'transform', 'paint' })
    dirty:mark('measurement', 'transform', 'paint')

    dirty:clear('measurement')

    assert_false(dirty:is_dirty('measurement'),
        'DirtyState clear should clear a single flag')
    assert_true(dirty:is_dirty('transform'),
        'DirtyState clear should leave other flags untouched')

    dirty:clear('transform', 'paint')

    assert_false(dirty:is_dirty('transform'),
        'DirtyState clear should support varargs')
    assert_false(dirty:is_dirty('paint'),
        'DirtyState clear should clear every requested flag')

    dirty:mark('measurement', 'transform', 'paint')
    dirty:clear_all()

    assert_false(dirty:is_any(),
        'DirtyState clear_all should clear every declared flag')
    assert_false(dirty:is_dirty('measurement'),
        'DirtyState clear_all should clear measurement')
    assert_false(dirty:is_dirty('transform'),
        'DirtyState clear_all should clear transform')
    assert_false(dirty:is_dirty('paint'),
        'DirtyState clear_all should clear paint')
end

local function run_is_any_tests()
    local dirty = DirtyState({ 'measurement', 'transform', 'paint' })

    assert_false(dirty:is_any('measurement', 'transform'),
        'DirtyState is_any should return false when none of the requested flags are dirty')

    dirty:mark('transform')

    assert_true(dirty:is_any('measurement', 'transform'),
        'DirtyState is_any should return true when any requested flag is dirty')
    assert_true(dirty:is_any(),
        'DirtyState is_any with no args should check all declared flags')
end

local function run_is_all_tests()
    local dirty = DirtyState({ 'measurement', 'transform', 'paint' })

    assert_false(dirty:is_all('measurement', 'transform'),
        'DirtyState is_all should return false when any requested flag is clean')

    dirty:mark('measurement', 'transform')

    assert_true(dirty:is_all('measurement', 'transform'),
        'DirtyState is_all should return true when all requested flags are dirty')
    assert_false(dirty:is_all(),
        'DirtyState is_all with no args should check every declared flag')

    dirty:mark('paint')

    assert_true(dirty:is_all(),
        'DirtyState is_all with no args should return true when every declared flag is dirty')
end

local function run_undeclared_flag_tests()
    local dirty = DirtyState({ 'measurement' })

    dirty:mark('other')

    assert_true(dirty:is_dirty('other'),
        'DirtyState should silently accept undeclared flags when marking')

    dirty:clear('other')

    assert_false(dirty:is_dirty('other'),
        'DirtyState should silently clear undeclared flags too')
    assert_equal(dirty._flags.other, false,
        'DirtyState should store undeclared flags directly in the backing table')
end

local function run()
    run_construction_and_mark_tests()
    run_clear_tests()
    run_is_any_tests()
    run_is_all_tests()
    run_undeclared_flag_tests()
end

return {
    run = run,
}
