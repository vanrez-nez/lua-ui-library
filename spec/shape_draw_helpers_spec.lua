local DrawHelpers = require('lib.ui.shapes.draw_helpers')

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

local function assert_near(actual, expected, tolerance, message)
    tolerance = tolerance or 0.01

    if math.abs(actual - expected) > tolerance then
        error(message .. ': expected ' .. tostring(expected) ..
            ', got ' .. tostring(actual), 2)
    end
end

local function make_fake_graphics()
    local graphics = {
        calls = {},
        color = { 0.2, 0.4, 0.6, 0.8 },
        line_width = 1,
        line_style = 'smooth',
        line_join = 'none',
        miter_limit = 4,
    }

    function graphics.getColor()
        return graphics.color[1], graphics.color[2], graphics.color[3], graphics.color[4]
    end

    function graphics.setColor(r, g, b, a)
        graphics.color = { r, g, b, a }
        graphics.calls[#graphics.calls + 1] = {
            kind = 'color',
            r = r,
            g = g,
            b = b,
            a = a,
        }
    end

    function graphics.getLineWidth()
        return graphics.line_width
    end

    function graphics.setLineWidth(value)
        graphics.line_width = value
        graphics.calls[#graphics.calls + 1] = {
            kind = 'line_width',
            value = value,
        }
    end

    function graphics.getLineStyle()
        return graphics.line_style
    end

    function graphics.setLineStyle(value)
        graphics.line_style = value
        graphics.calls[#graphics.calls + 1] = {
            kind = 'line_style',
            value = value,
        }
    end

    function graphics.getLineJoin()
        return graphics.line_join
    end

    function graphics.setLineJoin(value)
        graphics.line_join = value
        graphics.calls[#graphics.calls + 1] = {
            kind = 'line_join',
            value = value,
        }
    end

    function graphics.getMiterLimit()
        return graphics.miter_limit
    end

    function graphics.setMiterLimit(value)
        graphics.miter_limit = value
        graphics.calls[#graphics.calls + 1] = {
            kind = 'miter_limit',
            value = value,
        }
    end

    function graphics.line(x1, y1, x2, y2)
        graphics.calls[#graphics.calls + 1] = {
            kind = 'line',
            x1 = x1,
            y1 = y1,
            x2 = x2,
            y2 = y2,
        }
    end

    return graphics
end

local function run_with_fill_color_tests()
    local graphics = make_fake_graphics()
    local invoked = false

    local result = DrawHelpers.with_fill_color(
        graphics,
        { 1, 0.5, 0.25, 0.5 },
        0.4,
        function()
            invoked = true
        end
    )

    assert_true(result,
        'with_fill_color should report a draw when alpha is positive')
    assert_true(invoked,
        'with_fill_color should invoke the draw callback')
    assert_equal(#graphics.calls, 2,
        'with_fill_color should set and restore color')
    assert_near(graphics.calls[1].a, 0.2, 0.001,
        'with_fill_color should multiply fill color alpha by fillOpacity')
    assert_near(graphics.color[1], 0.2, 0.001,
        'with_fill_color should restore the previous color state')

    local transparent_graphics = make_fake_graphics()
    local transparent_result = DrawHelpers.with_fill_color(
        transparent_graphics,
        { 1, 1, 1, 0 },
        1,
        function()
            error('transparent fill should not draw', 2)
        end
    )

    assert_true(not transparent_result,
        'with_fill_color should report no draw when alpha resolves to zero')
    assert_equal(#transparent_graphics.calls, 0,
        'with_fill_color should skip graphics state mutation when alpha is zero')
end

local function run_with_stroke_color_tests()
    local graphics = make_fake_graphics()

    DrawHelpers.with_stroke_color(
        graphics,
        { 0.8, 0.6, 0.4, 0.5 },
        0.4,
        0.5,
        function()
        end
    )

    assert_equal(#graphics.calls, 2,
        'with_stroke_color should set and restore color')
    assert_near(graphics.calls[1].a, 0.1, 0.001,
        'with_stroke_color should compose stroke alpha with strokeOpacity and node opacity')
end

local function run_line_state_tests()
    local graphics = make_fake_graphics()

    DrawHelpers.with_stroke_state(
        graphics,
        3,
        'rough',
        'miter',
        11,
        function()
            assert_equal(graphics.line_width, 3,
                'with_stroke_state should apply line width before drawing')
            assert_equal(graphics.line_style, 'rough',
                'with_stroke_state should apply line style before drawing')
            assert_equal(graphics.line_join, 'miter',
                'with_stroke_state should apply line join before drawing')
            assert_equal(graphics.miter_limit, 11,
                'with_stroke_state should apply miter limit before drawing')
        end
    )

    assert_equal(graphics.line_width, 1,
        'with_stroke_state should restore line width')
    assert_equal(graphics.line_style, 'smooth',
        'with_stroke_state should restore line style')
    assert_equal(graphics.line_join, 'none',
        'with_stroke_state should restore line join')
    assert_equal(graphics.miter_limit, 4,
        'with_stroke_state should restore miter limit')
end

local function run_path_segment_tests()
    local segments, total_length = DrawHelpers.build_path_segments({
        { 0, 0 },
        { 10, 0 },
        { 10, 10 },
    }, false)

    assert_equal(#segments, 2,
        'build_path_segments should produce one segment per edge in an open path')
    assert_near(total_length, 20, 0.001,
        'build_path_segments should accumulate total path length')
    assert_near(segments[2].start_distance, 10, 0.001,
        'build_path_segments should preserve cumulative distance metadata')

    local closed_segments, closed_total = DrawHelpers.build_path_segments({
        { 0, 0 },
        { 10, 0 },
        { 10, 10 },
        { 0, 10 },
    }, true)

    assert_equal(#closed_segments, 4,
        'build_path_segments should include the closing edge when requested')
    assert_near(closed_total, 40, 0.001,
        'build_path_segments should include the closing segment length in closed mode')
end

local function run_rotate_closed_path_tests()
    local rotated, total_length = DrawHelpers.rotate_closed_path({
        { 0, 0 },
        { 10, 0 },
        { 10, 10 },
        { 0, 10 },
    }, 2)

    assert_near(total_length, 40, 0.001,
        'rotate_closed_path should preserve the original closed-path length')
    assert_equal(#rotated, 5,
        'rotate_closed_path should preserve one perimeter point per original edge plus the shifted start')
    assert_near(rotated[1][1], 2, 0.001,
        'rotate_closed_path should begin at the shifted start position')
    assert_near(rotated[1][2], 0, 0.001,
        'rotate_closed_path should preserve the shifted start segment coordinates')
    assert_near(rotated[5][1], 0, 0.001,
        'rotate_closed_path should wrap the remaining vertices in order')
    assert_near(rotated[5][2], 0, 0.001,
        'rotate_closed_path should stop before duplicating the shifted start point')
end

local function run_dashed_polyline_tests()
    local graphics = make_fake_graphics()
    local emitted, total_length = DrawHelpers.draw_dashed_polyline(
        graphics,
        {
            { 0, 0 },
            { 10, 0 },
            { 10, 10 },
        },
        6,
        4,
        0,
        false
    )

    assert_equal(emitted, 2,
        'draw_dashed_polyline should emit two dashes across the open path')
    assert_near(total_length, 20, 0.001,
        'draw_dashed_polyline should report the total path length')
    assert_equal(#graphics.calls, 2,
        'draw_dashed_polyline should call graphics.line once per emitted dash')
    assert_near(graphics.calls[1].x1, 0, 0.001,
        'draw_dashed_polyline should start the first dash at the start of the path')
    assert_near(graphics.calls[1].x2, 6, 0.001,
        'draw_dashed_polyline should keep the first dash on the first segment')
    assert_near(graphics.calls[2].x1, 10, 0.001,
        'draw_dashed_polyline should continue dash phase across segment boundaries')
    assert_near(graphics.calls[2].y2, 6, 0.001,
        'draw_dashed_polyline should place the second dash on the second segment')

    local offset_graphics = make_fake_graphics()

    DrawHelpers.draw_dashed_polyline(
        offset_graphics,
        {
            { 0, 0 },
            { 10, 0 },
        },
        6,
        4,
        8,
        false
    )

    assert_equal(#offset_graphics.calls, 2,
        'draw_dashed_polyline should emit the wrapped leading dash and the trailing partial dash')
    assert_near(offset_graphics.calls[1].x1, 0, 0.001,
        'draw_dashed_polyline should wrap positive dash offsets onto the segment')
    assert_near(offset_graphics.calls[1].x2, 4, 0.001,
        'draw_dashed_polyline should keep cumulative phase after offset wrapping')
    assert_near(offset_graphics.calls[2].x1, 8, 0.001,
        'draw_dashed_polyline should preserve the later partial dash after wrapping')
    assert_near(offset_graphics.calls[2].x2, 10, 0.001,
        'draw_dashed_polyline should clip the trailing dash to the segment end')

end

local function run()
    run_with_fill_color_tests()
    run_with_stroke_color_tests()
    run_line_state_tests()
    run_path_segment_tests()
    run_rotate_closed_path_tests()
    run_dashed_polyline_tests()
end

return {
    run = run,
}
