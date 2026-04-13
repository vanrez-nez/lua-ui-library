local Container = require('lib.ui.core.container')
local Rectangle = require('lib.ui.core.rectangle')

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

local function assert_almost_equal(actual, expected, epsilon, message)
    epsilon = epsilon or 1e-9

    if math.abs(actual - expected) > epsilon then
        error(message .. ': expected ' .. tostring(expected) ..
            ', got ' .. tostring(actual), 2)
    end
end

local function assert_rectangle_equal(actual, expected, message)
    assert_true(actual:equals(expected, 1e-9),
        message .. ': expected ' .. tostring(expected) ..
        ', got ' .. tostring(actual))
end

local function run_coordinate_round_trip_tests()
    local root = Container.new({
        x = 10,
        y = 20,
        width = 300,
        height = 200,
        rotation = math.rad(10),
    })
    local child = Container.new({
        x = 15,
        y = -10,
        anchorX = 0.5,
        anchorY = 1,
        pivotX = 0.25,
        pivotY = 0.75,
        width = 60,
        height = 40,
        scaleX = 1.2,
        scaleY = 0.8,
        rotation = math.rad(-15),
        skewX = 0.04,
        skewY = -0.02,
    })

    root:addChild(child)
    root:update()

    local local_bounds = child:getLocalBounds()
    local point_x = 11.5
    local point_y = 9.25
    local world_x, world_y = child:localToWorld(point_x, point_y)
    local round_trip_x, round_trip_y = child:worldToLocal(world_x, world_y)

    assert_rectangle_equal(local_bounds, Rectangle.new(0, 0, 60, 40),
        'Container should expose local bounds from the resolved measurement')
    assert_almost_equal(round_trip_x, point_x, 1e-9,
        'localToWorld/worldToLocal should round-trip x coordinates')
    assert_almost_equal(round_trip_y, point_y, 1e-9,
        'localToWorld/worldToLocal should round-trip y coordinates')
end

local function run_hidden_node_resolution_tests()
    local root = Container.new({
        x = 12,
        y = 18,
        width = 200,
        height = 100,
    })
    local hidden = Container.new({
        visible = false,
        x = 30,
        y = 40,
        width = 80,
        height = 50,
    })
    local leaf = Container.new({
        x = 5,
        y = 6,
        width = 10,
        height = 10,
    })

    root:addChild(hidden)
    hidden:addChild(leaf)
    root:update()

    local world_x, world_y = leaf:localToWorld(0, 0)

    assert_almost_equal(world_x, 47, 1e-9,
        'visible=false should not detach hidden ancestors from world resolution')
    assert_almost_equal(world_y, 64, 1e-9,
        'visible=false should still allow descendant world transforms to resolve')
end

local function run_parent_transform_invalidation_tests()
    local root = Container.new({
        x = 0,
        y = 0,
        width = 200,
        height = 100,
    })
    local child = Container.new({
        x = 10,
        y = 15,
        width = 40,
        height = 20,
    })

    root:addChild(child)
    root:update()

    local before = child:getWorldTransform()

    root.x = 25

    assert_true(root.dirty:is_dirty('local_transform'),
        'Direct geometry mutation should invalidate the local transform cache')
    assert_true(child.dirty:is_dirty('world_transform'),
        'Parent transform changes should invalidate descendant world transforms')
    assert_true(not child.dirty:is_dirty('measurement'),
        'Pure parent transform changes should not invalidate descendant measurement')

    root:update()

    local after = child:getWorldTransform()

    assert_true(not before:equals(after, 1e-9),
        'Descendant world transforms should change after parent transform mutation')
    assert_true(not child.dirty:is_dirty('world_transform'),
        'The update pass should clear descendant world-transform dirtiness')
end

local function run_parent_measurement_invalidation_tests()
    local root = Container.new({
        width = 200,
        height = 100,
    })
    local child = Container.new({
        anchorX = 1,
        anchorY = 1,
        width = '50%',
        height = '50%',
    })

    root:addChild(child)
    root:update()

    assert_rectangle_equal(child:getLocalBounds(), Rectangle.new(0, 0, 100, 50),
        'Percentage measurement should resolve against the parent bounds')

    root.width = 320

    assert_true(child.dirty:is_dirty('measurement'),
        'Parent size changes should invalidate descendant measurement caches')
    assert_true(child.dirty:is_dirty('local_transform'),
        'Parent size changes should invalidate descendant local transforms')

    root:update()

    local updated_bounds = child:getLocalBounds()
    local world_x, world_y = child:localToWorld(0, 0)

    assert_rectangle_equal(updated_bounds, Rectangle.new(0, 0, 160, 50),
        'Descendants should re-measure from the latest parent size on update')
    assert_almost_equal(world_x, 320, 1e-9,
        'Anchor-based placement should re-resolve after parent size changes')
    assert_almost_equal(world_y, 100, 1e-9,
        'Anchor-based y placement should remain tied to the parent size')
end

local function run_default_anchor_and_pivot_semantics_tests()
    local root = Container.new({
        width = 200,
        height = 100,
    })
    local anchored = Container.new({
        width = 40,
        height = 20,
    })
    local rotated_default = Container.new({
        x = 100,
        y = 50,
        width = 40,
        height = 20,
        rotation = math.pi,
    })
    local rotated_origin = Container.new({
        x = 100,
        y = 50,
        width = 40,
        height = 20,
        pivotX = 0,
        pivotY = 0,
        rotation = math.pi,
    })

    root:addChild(anchored)
    root:addChild(rotated_default)
    root:addChild(rotated_origin)
    root:update()

    local anchored_world_x, anchored_world_y = anchored:localToWorld(0, 0)
    local default_world_x, default_world_y = rotated_default:localToWorld(20, 10)
    local origin_world_x, origin_world_y = rotated_origin:localToWorld(0, 0)

    assert_almost_equal(anchored_world_x, 0, 1e-9,
        'Omitted anchorX should keep parent-relative attachment at the parent origin')
    assert_almost_equal(anchored_world_y, 0, 1e-9,
        'Omitted anchorY should keep parent-relative attachment at the parent origin')
    assert_almost_equal(default_world_x, 120, 1e-9,
        'Omitted pivotX should rotate around the local horizontal center')
    assert_almost_equal(default_world_y, 60, 1e-9,
        'Omitted pivotY should rotate around the local vertical center')
    assert_almost_equal(origin_world_x, 100, 1e-9,
        'Explicit pivotX=0 should keep the local origin fixed during rotation')
    assert_almost_equal(origin_world_y, 50, 1e-9,
        'Explicit pivotY=0 should keep the local origin fixed during rotation')
end

local function run_breakpoint_placeholder_tests()
    local root = Container.new({
        width = 300,
        height = 200,
    })
    local child = Container.new({
        x = 5,
        y = 7,
        width = 100,
        height = 50,
        breakpoints = {
            compact = true,
        },
    })
    local overrides = {
        x = 30,
        width = '50%',
    }

    root:addChild(child)
    root:update()

    child:_set_resolved_responsive_overrides('compact', overrides)

    assert_true(child.dirty:is_dirty('responsive'),
        'Breakpoint-resolution changes should participate in the dirty-state model')
    assert_true(child.dirty:is_dirty('measurement'),
        'Breakpoint-resolution changes should invalidate measurement')
    assert_true(child.dirty:is_dirty('local_transform'),
        'Breakpoint-resolution changes should invalidate transforms')

    root:update()

    local updated_bounds = child:getLocalBounds()
    local world_x = child:localToWorld(0, 0)
    local before_cache = child._world_transform_cache

    assert_rectangle_equal(updated_bounds, Rectangle.new(0, 0, 150, 50),
        'Responsive overrides should affect resolved measurement')
    assert_almost_equal(world_x, 30, 1e-9,
        'Responsive overrides should affect resolved local transform inputs')

    child:_set_resolved_responsive_overrides('compact', overrides)

    assert_true(not child.dirty:is_dirty('responsive'),
        'Reapplying the same breakpoint token and override reference should be stable')
    assert_true(rawequal(before_cache, child._world_transform_cache),
        'A clean node should not drop cached world transforms when nothing changed')
end

local function run_clean_pass_stability_tests()
    local root = Container.new({
        x = 10,
        y = 20,
        width = 120,
        height = 80,
    })
    local child = Container.new({
        x = 15,
        y = 5,
        width = 40,
        height = 30,
    })

    root:addChild(child)
    root:update()

    local root_local = root._local_transform_cache
    local root_world = root._world_transform_cache
    local root_bounds = root._world_bounds_cache
    local child_local = child._local_transform_cache
    local child_world = child._world_transform_cache
    local child_bounds = child._world_bounds_cache

    root:update()

    assert_true(rawequal(root_local, root._local_transform_cache),
        'A clean update pass should preserve the cached root local transform')
    assert_true(rawequal(root_world, root._world_transform_cache),
        'A clean update pass should preserve the cached root world transform')
    assert_true(rawequal(root_bounds, root._world_bounds_cache),
        'A clean update pass should preserve the cached root bounds')
    assert_true(rawequal(child_local, child._local_transform_cache),
        'A clean update pass should preserve descendant local transform caches')
    assert_true(rawequal(child_world, child._world_transform_cache),
        'A clean update pass should preserve descendant world transform caches')
    assert_true(rawequal(child_bounds, child._world_bounds_cache),
        'A clean update pass should preserve descendant bounds caches')
end

local function run()
    run_coordinate_round_trip_tests()
    run_hidden_node_resolution_tests()
    run_parent_transform_invalidation_tests()
    run_parent_measurement_invalidation_tests()
    run_default_anchor_and_pivot_semantics_tests()
    run_breakpoint_placeholder_tests()
    run_clean_pass_stability_tests()
end

return {
    run = run,
}
