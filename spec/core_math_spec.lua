local Insets = require('lib.ui.core.insets')
local MathUtils = require('lib.ui.utils.math')
local Matrix = require('lib.ui.utils.matrix')
local Rectangle = require('lib.ui.core.rectangle')
local Vec2 = require('lib.ui.utils.vec2')

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

local function run_vec2_tests()
    local value = Vec2.new(3, 4)
    local normalized = value:normalize()

    assert_almost_equal(value:length(), 5, 1e-12, 'Vec2 length should be stable')
    assert_true(normalized:equals(Vec2.new(0.6, 0.8), 1e-12),
        'Vec2 normalize should return a new normalized vector')
    assert_true((value + Vec2.new(1, 2)) == Vec2.new(4, 6),
        'Vec2 addition should preserve value semantics')
    assert_equal(value:dot(Vec2.new(2, 1)), 10,
        'Vec2 dot product should be correct')
end

local function run_matrix_tests()
    local parent = Matrix.from_transform(
        120,
        -35,
        8,
        12,
        1.5,
        0.75,
        math.rad(25),
        0.1,
        -0.2
    )
    local child = Matrix.from_transform(
        -14,
        9,
        3,
        5,
        0.5,
        2.0,
        math.rad(-15),
        -0.05,
        0.15
    )
    local world = parent * child
    local inverse, err = world:inverse()

    assert_true(inverse ~= nil, 'Matrix inverse should succeed for invertible values')
    assert_equal(err, nil, 'Matrix inverse should not return an error here')

    local points = {
        { x = 0, y = 0 },
        { x = 10.5, y = -3.25 },
        { x = -18.125, y = 42.75 },
        { x = 7, y = 9 },
    }

    for _, point in ipairs(points) do
        local world_x, world_y = world:transform_point(point.x, point.y)
        local local_x, local_y = inverse:transform_point(world_x, world_y)

        assert_almost_equal(local_x, point.x, 1e-9,
            'Matrix inverse should round-trip x coordinates')
        assert_almost_equal(local_y, point.y, 1e-9,
            'Matrix inverse should round-trip y coordinates')
    end

    local singular = Matrix.new(1, 2, 2, 4, 0, 0)
    local singular_inverse, singular_error = singular:inverse()

    assert_equal(singular_inverse, nil,
        'Singular matrices should fail inversion deterministically')
    assert_equal(singular_error, 'matrix is not invertible',
        'Singular matrices should expose a stable error')
end

local function run_rectangle_tests()
    local bounds = Rectangle.new(10, 20, 40, 30)
    local clip = Rectangle.new(25, 15, 10, 40)
    local miss = Rectangle.new(100, 100, 25, 25)
    local touch = Rectangle.new(50, 20, 10, 10)
    local intersection = bounds:intersection(clip)
    local empty = bounds:intersection(miss)
    local padded = bounds:inset(Insets.normalize({ 4, 6, 8, 10 }))
    local top_left, top_right, bottom_right, bottom_left = bounds:corners()

    assert_true(intersection == Rectangle.new(25, 20, 10, 30),
        'Rectangle intersection should preserve overlapping area')
    assert_true(empty == Rectangle.new(100, 100, 0, 0),
        'Rectangle intersection should clamp misses to zero-area rectangles')
    assert_true(empty:is_empty(),
        'Rectangle misses should report as empty')
    assert_true(not bounds:intersects(touch),
        'Rectangle edge-touching cases should remain empty intersections')
    assert_true(not empty:contains_point(100, 100),
        'Empty rectangles should not contain points')
    assert_true(bounds:contains_point(10, 20),
        'Rectangle containment should include the top-left edge')
    assert_true(bounds:contains_point(50, 50),
        'Rectangle containment should include the bottom-right edge')
    assert_true(padded == Rectangle.new(20, 24, 24, 18),
        'Rectangle inset should use canonical top/right/bottom/left values')
    assert_true(top_left == Vec2.new(10, 20),
        'Rectangle corners should expose the top-left point')
    assert_true(top_right == Vec2.new(50, 20),
        'Rectangle corners should expose the top-right point')
    assert_true(bottom_right == Vec2.new(50, 50),
        'Rectangle corners should expose the bottom-right point')
    assert_true(bottom_left == Vec2.new(10, 50),
        'Rectangle corners should expose the bottom-left point')
end

local function run_insets_tests()
    local scalar = Insets.normalize(12)
    local pair = Insets.normalize({ 3, 7 })
    local quad = Insets.normalize({ 1, 2, 3, 4 })
    local named = Insets.normalize({
        top = 9,
        right = 8,
        bottom = 7,
        left = 6,
    })

    assert_true(scalar == Insets.new(12, 12, 12, 12),
        'Scalar inset normalization should expand to all four edges')
    assert_true(pair == Insets.new(3, 7, 3, 7),
        'Two-value inset normalization should map to vertical and horizontal')
    assert_true(quad == Insets.new(1, 2, 3, 4),
        'Four-value inset normalization should preserve edge order')
    assert_true(named == Insets.new(9, 8, 7, 6),
        'Named inset normalization should preserve canonical edges')
    assert_equal(pair:horizontal(), 14,
        'Insets horizontal helper should sum left and right')
    assert_equal(pair:vertical(), 6,
        'Insets vertical helper should sum top and bottom')
end

local function run_math_utils_tests()
    assert_true(MathUtils.is_percentage_string('50%'),
        'MathUtils should accept percentage strings')
    assert_true(not MathUtils.is_percentage_string('50'),
        'MathUtils should reject non-percentage strings')
    assert_almost_equal(MathUtils.parse_percentage('12.5%'), 0.125, 1e-12,
        'MathUtils should parse percentage strings')
    assert_equal(MathUtils.parse_percentage('auto'), nil,
        'MathUtils should return nil for non-percentage values')
    assert_equal(MathUtils.default(nil, 8), 8,
        'MathUtils default should use fallback for nil values')
    assert_equal(MathUtils.default(false, true), false,
        'MathUtils default should preserve false values')
    assert_equal(MathUtils.clamp_number(-5, nil, nil), 0,
        'MathUtils clamp should enforce a zero floor')
    assert_equal(MathUtils.clamp_number(15, 2, 10), 10,
        'MathUtils clamp should enforce max bounds')
    assert_equal(MathUtils.resolve_axis_size('25%', 200), 50,
        'MathUtils should resolve percentage axis sizes')
    assert_equal(MathUtils.resolve_axis_size('fill', 120), 0,
        'MathUtils should not resolve fill axis sizes generically')
end

local function run()
    run_vec2_tests()
    run_matrix_tests()
    run_rectangle_tests()
    run_insets_tests()
    run_math_utils_tests()
end

return {
    run = run,
}
