local Shape = require('lib.ui.core.shape')
local Container = require('lib.ui.core.container')
local RectShape = require('lib.ui.shapes.rect_shape')
local CircleShape = require('lib.ui.shapes.circle_shape')

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

local function assert_same(actual, expected, message)
    if actual ~= expected then
        error(message .. ': expected same reference', 2)
    end
end

local function run_concrete_class_method_precedence_tests()
    local rect = RectShape.new({ width = 10, height = 10 })
    local circle = CircleShape.new({ width = 10, height = 10 })

    assert_same(rect.draw, RectShape.draw,
        'Concrete class method (RectShape.draw) should take precedence over Shape.draw')
    assert_true(rect.draw ~= Shape.draw,
        'RectShape instance should not resolve draw to the Shape base method')
    assert_same(rect._get_local_points, RectShape._get_local_points,
        'Concrete _get_local_points should shadow the Shape base implementation')

    assert_same(circle.draw, CircleShape.draw,
        'Concrete class method (CircleShape.draw) should take precedence over Shape.draw')
end

local function run_shape_base_method_lookup_tests()
    local rect = RectShape.new({ width = 10, height = 10 })

    assert_same(rect._invalidate_fill_resolution_cache, Shape._invalidate_fill_resolution_cache,
        'Shape base methods not overridden by the concrete class should resolve via the base')
    assert_same(rect._resolve_fill_surface, Shape._resolve_fill_surface,
        'Shape._resolve_fill_surface should be reachable from a concrete shape instance')
    assert_same(rect._get_world_bounds_points, Shape._get_world_bounds_points,
        'Shape._get_world_bounds_points should be reachable from a concrete shape instance')

    local plain_shape = Shape.new({ width = 10, height = 10 })
    assert_same(plain_shape.draw, Shape.draw,
        'A Shape instance with no concrete subclass should resolve draw to Shape.draw')
end

local function run_container_super_method_lookup_tests()
    local rect = RectShape.new({ width = 10, height = 10 })

    assert_same(rect.getWorldBounds, Container.getWorldBounds,
        'Container-defined methods should remain reachable on shape instances')
    assert_same(rect.worldToLocal, Container.worldToLocal,
        'Container.worldToLocal should resolve from a concrete shape instance')
end

local function run_public_prop_precedence_tests()
    local rect = RectShape.new({
        width = 80,
        height = 40,
        fillColor = { 0.25, 0.5, 0.75, 1 },
        fillOpacity = 0.4,
        strokeWidth = 3,
        opacity = 0.5,
    })

    assert_equal(rect.width, 80,
        'Public prop reads should return the effective width')
    assert_equal(rect.height, 40,
        'Public prop reads should return the effective height')
    assert_equal(rect.fillOpacity, 0.4,
        'Public prop reads should return the effective fillOpacity')
    assert_equal(rect.strokeWidth, 3,
        'Public prop reads should return the effective strokeWidth')
    assert_equal(rect.opacity, 0.5,
        'Container-schema props should read through the public-surface fallback')

    local color = rect.fillColor
    assert_true(type(color) == 'table',
        'fillColor should resolve to a table through the public-surface fallback')
    assert_equal(color[1], 0.25,
        'fillColor component should survive the public-read path')
    assert_equal(color[4], 1,
        'fillColor alpha should survive the public-read path')
end

local function run_unsupported_key_nil_tests()
    local rect = RectShape.new({ width = 10, height = 10 })

    assert_nil(rect.__shape_read_path_bogus_key,
        'Unsupported key reads must return nil')
    assert_nil(rect.not_a_real_prop,
        'Unsupported key reads must return nil (second probe)')
    assert_nil(rect._allowed_public_keys_is_private_but_has_no_method,
        'Keys that match no method, no super, and no public prop must return nil')
end

local function run_method_shadowing_via_public_prop_tests()
    local rect = RectShape.new({
        width = 10,
        height = 10,
        fillColor = { 1, 0, 0, 1 },
    })

    assert_true(type(rect.draw) == 'function',
        'Method lookup should always win over public-prop lookup for method keys')
    assert_true(type(rect.fillColor) == 'table',
        'Public-prop lookup should resolve non-method keys')
end

local function run()
    run_concrete_class_method_precedence_tests()
    run_shape_base_method_lookup_tests()
    run_container_super_method_lookup_tests()
    run_public_prop_precedence_tests()
    run_unsupported_key_nil_tests()
    run_method_shadowing_via_public_prop_tests()
end

return {
    run = run,
}
