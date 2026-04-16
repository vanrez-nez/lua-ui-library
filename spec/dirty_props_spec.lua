if package.loaded.bit == nil and package.preload.bit == nil then
    package.preload.bit = function()
        local function lshift(value, count)
            return value * 2 ^ count
        end

        local function band(left, right)
            local result = 0
            local place = 1

            while left > 0 or right > 0 do
                local left_bit = left % 2
                local right_bit = right % 2

                if left_bit == 1 and right_bit == 1 then
                    result = result + place
                end

                left = math.floor(left / 2)
                right = math.floor(right / 2)
                place = place * 2
            end

            return result
        end

        local function bor(left, right)
            local result = 0
            local place = 1

            while left > 0 or right > 0 do
                local left_bit = left % 2
                local right_bit = right % 2

                if left_bit == 1 or right_bit == 1 then
                    result = result + place
                end

                left = math.floor(left / 2)
                right = math.floor(right / 2)
                place = place * 2
            end

            return result
        end

        return {
            band = band,
            bor = bor,
            lshift = lshift,
        }
    end
end

local DirtyProps = require('lib.ui.utils.dirty_props')

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

local function assert_false(value, message)
    if value then
        error(message, 2)
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

local function create_props()
    return DirtyProps.create({
        x = { val = 0, groups = { 'layout', 'position' } },
        y = { val = 0, groups = { 'layout', 'position' } },
        width = { val = 100, groups = { 'layout', 'size' } },
        height = { val = 40, groups = { 'layout', 'size' } },
        color = { val = 'red', groups = { 'paint' } },
        visible = { val = false },
    })
end

local function run_creation_and_clean_state_tests()
    local props = create_props()

    assert_equal(props.x, 0,
        'DirtyProps.create should expose default numeric values')
    assert_equal(props.width, 100,
        'DirtyProps.create should expose default size values')
    assert_equal(props.color, 'red',
        'DirtyProps.create should expose default string values')
    assert_equal(props.visible, false,
        'DirtyProps.create should preserve false values')

    assert_false(props:is_dirty('x'),
        'Fresh props should start clean')
    assert_false(props:any_dirty('x', 'width'),
        'Fresh props should report no dirty props for OR queries')
    assert_false(props:all_dirty('x', 'width'),
        'Fresh props should report no dirty props for AND queries')
    assert_false(props:group_dirty('layout'),
        'Fresh props should report registered groups as clean')
    assert_false(props:group_dirty('missing'),
        'Unknown groups should report clean')
end

local function run_sync_diff_tests()
    local props = create_props()

    props.x = 12
    props:sync()

    assert_true(props:is_dirty('x'),
        'DirtyProps.sync should mark changed props dirty')
    assert_false(props:is_dirty('y'),
        'DirtyProps.sync should leave unchanged sibling props clean')
    assert_true(props:group_dirty('layout'),
        'DirtyProps.sync should mark groups containing changed props dirty')
    assert_true(props:group_dirty('position'),
        'DirtyProps.sync should mark every group attached to the changed prop dirty')
    assert_false(props:group_dirty('size'),
        'DirtyProps.sync should leave unrelated groups clean')

    props:sync()

    assert_false(props:is_dirty('x'),
        'A second sync without changes should clear prop dirty state')
    assert_false(props:group_dirty('layout'),
        'A second sync without changes should clear group dirty state')
end

local function run_multi_prop_query_tests()
    local props = create_props()

    props.x = 4
    props.width = 120
    props:sync()

    assert_true(props:any_dirty('x', 'y'),
        'DirtyProps.any_dirty should return true when any queried prop is dirty')
    assert_false(props:all_dirty('x', 'y'),
        'DirtyProps.all_dirty should return false when any queried prop is clean')
    assert_true(props:all_dirty('x', 'width'),
        'DirtyProps.all_dirty should return true when all queried props are dirty')
    assert_false(props:any_dirty('height', 'color'),
        'DirtyProps.any_dirty should return false when all queried props are clean')
end

local function run_group_query_tests()
    local props = create_props()

    props.x = 4
    props.width = 120
    props:sync()

    assert_true(props:group_any_dirty('position', 'paint'),
        'DirtyProps.group_any_dirty should return true when any group is dirty')
    assert_false(props:group_all_dirty('position', 'paint'),
        'DirtyProps.group_all_dirty should return false when any group is clean')
    assert_true(props:group_all_dirty('layout', 'position', 'size'),
        'DirtyProps.group_all_dirty should return true when every group is dirty')
    assert_false(props:group_any_dirty('paint', 'missing'),
        'DirtyProps.group_any_dirty should ignore clean and unknown groups')
    assert_false(props:group_all_dirty('layout', 'missing'),
        'DirtyProps.group_all_dirty should fail when any group is unknown')
end

local function run_reset_tests()
    local props = create_props()

    props.x = 9
    props.color = 'blue'
    props:sync()

    assert_true(props:is_dirty('x'),
        'DirtyProps.sync should mark x dirty before reset')
    assert_true(props:is_dirty('color'),
        'DirtyProps.sync should mark color dirty before reset')
    assert_equal(props:reset(), props,
        'DirtyProps.reset should return self')
    assert_false(props:is_dirty('x'),
        'DirtyProps.reset should clear prop dirty state')
    assert_false(props:group_dirty('paint'),
        'DirtyProps.reset should clear group dirty state')

    props:sync()

    assert_false(props:is_dirty('x'),
        'DirtyProps.reset should align cached values to current values')
    assert_false(props:is_dirty('color'),
        'DirtyProps.reset should keep reset values clean on the next sync')
end

local function run_manual_group_marking_tests()
    local props = create_props()

    assert_equal(props:mark_dirty('paint', 'missing'), props,
        'DirtyProps.mark_dirty should return self')
    assert_true(props:is_dirty('color'),
        'DirtyProps.mark_dirty should mark props in the requested group dirty')
    assert_true(props:group_dirty('paint'),
        'DirtyProps.mark_dirty should mark the requested group dirty')
    assert_false(props:group_dirty('layout'),
        'DirtyProps.mark_dirty should ignore unknown groups without dirtying others')

    props:mark_dirty('position', 'size')

    assert_true(props:group_dirty('position'),
        'DirtyProps.mark_dirty should accept multiple groups')
    assert_true(props:group_dirty('size'),
        'DirtyProps.mark_dirty should mark every requested known group')
    assert_true(props:all_dirty('x', 'y', 'width', 'height', 'color'),
        'DirtyProps.mark_dirty should mark all member props across requested groups')
end

local function run_snapshot_tests()
    local props = create_props()

    props.x = 3
    props.color = 'green'
    props:sync()

    local dirty_props = props:get_dirty_props()
    local dirty_groups = props:get_dirty_groups()

    assert_true(dirty_props.x,
        'DirtyProps.get_dirty_props should include dirty props')
    assert_false(dirty_props.y,
        'DirtyProps.get_dirty_props should include clean tracked props')
    assert_true(dirty_props.color,
        'DirtyProps.get_dirty_props should include all dirty tracked props')
    assert_true(dirty_groups.layout,
        'DirtyProps.get_dirty_groups should include dirty groups')
    assert_true(dirty_groups.position,
        'DirtyProps.get_dirty_groups should include secondary dirty groups')
    assert_true(dirty_groups.paint,
        'DirtyProps.get_dirty_groups should include dirty paint groups')
    assert_false(dirty_groups.size,
        'DirtyProps.get_dirty_groups should include clean registered groups')

    dirty_props.y = true
    dirty_groups.size = true

    assert_false(props:is_dirty('y'),
        'DirtyProps.get_dirty_props should return a detached map')
    assert_false(props:group_dirty('size'),
        'DirtyProps.get_dirty_groups should return a detached map')
end

local function run_value_edge_case_tests()
    local props = create_props()

    props.visible = true
    props.color = nil
    props:sync()

    assert_true(props:is_dirty('visible'),
        'DirtyProps.sync should detect false-to-true changes')
    assert_true(props:is_dirty('color'),
        'DirtyProps.sync should detect assignment to nil')

    props.visible = false
    props.color = 'red'
    props:sync()

    assert_true(props:is_dirty('visible'),
        'DirtyProps.sync should detect true-to-false changes')
    assert_true(props:is_dirty('color'),
        'DirtyProps.sync should detect nil-to-value changes')
end

local function run_capacity_limit_tests()
    local ok_defs = {}
    local too_many_defs = {}

    for index = 1, 31 do
        local key = 'prop_' .. tostring(index)
        ok_defs[key] = { val = index }
        too_many_defs[key] = { val = index }
    end

    too_many_defs.prop_32 = { val = 32 }

    local props = DirtyProps.create(ok_defs)
    props:sync()

    assert_false(props:any_dirty('prop_1', 'prop_31'),
        'DirtyProps should support exactly 31 tracked props')

    assert_error(function()
        DirtyProps.create(too_many_defs)
    end, 'DirtyProps: max 31 props per object',
        'DirtyProps should reject more than 31 tracked props')
end

local function run()
    run_creation_and_clean_state_tests()
    run_sync_diff_tests()
    run_multi_prop_query_tests()
    run_group_query_tests()
    run_reset_tests()
    run_manual_group_marking_tests()
    run_snapshot_tests()
    run_value_edge_case_tests()
    run_capacity_limit_tests()
end

return {
    run = run,
}
