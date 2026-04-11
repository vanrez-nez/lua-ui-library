local UI = require('lib.ui')
local Container = require('lib.ui.core.container')

local function assert_equal(actual, expected, message)
    if actual ~= expected then
        error(message .. ': expected ' .. tostring(expected) ..
            ', got ' .. tostring(actual), 2)
    end
end

local function assert_same(actual, expected, message)
    if actual ~= expected then
        error(message .. ': expected same reference', 2)
    end
end

local function assert_not_same(actual, expected, message)
    if actual == expected then
        error(message .. ': expected distinct references', 2)
    end
end

local function assert_true(value, message)
    if not value then
        error(message, 2)
    end
end

local function make_fake_graphics()
    local graphics = {
        calls = {},
        current_scissor = nil,
        stencil_compare = nil,
        stencil_value = nil,
    }

    function graphics.getScissor()
        local rect = graphics.current_scissor

        if rect == nil then
            return nil
        end

        return rect.x, rect.y, rect.width, rect.height
    end

    function graphics.setScissor(x, y, width, height)
        if x == nil then
            graphics.current_scissor = nil
            return
        end

        graphics.current_scissor = {
            x = x,
            y = y,
            width = width,
            height = height,
        }
    end

    function graphics.getStencilTest()
        return graphics.stencil_compare, graphics.stencil_value
    end

    function graphics.setStencilTest(compare, value)
        graphics.stencil_compare = compare
        graphics.stencil_value = value
    end

    function graphics.stencil(callback)
        callback()
    end

    function graphics.polygon(mode, points)
        graphics.calls[#graphics.calls + 1] = {
            kind = 'polygon',
            mode = mode,
            point_count = #points,
        }
    end

    return graphics
end

local function copy_rect(rect)
    if rect == nil then
        return nil
    end

    return {
        x = rect.x,
        y = rect.y,
        width = rect.width,
        height = rect.height,
    }
end

local function find_snapshot(snapshots, tag)
    for index = 1, #snapshots do
        if snapshots[index].tag == tag then
            return snapshots[index]
        end
    end

    error('missing snapshot for ' .. tostring(tag), 2)
end

local function run_shape_scratch_reuse_tests()
    local root = Container.new({
        width = 400,
        height = 400,
    })
    local first = UI.RectShape.new({
        x = 10,
        y = 20,
        width = 30,
        height = 15,
        strokeColor = { 1, 0, 0, 1 },
        strokeWidth = 2,
    })
    local second = UI.RectShape.new({
        x = 80,
        y = 40,
        width = 20,
        height = 25,
        strokeColor = { 0, 1, 0, 1 },
        strokeWidth = 3,
    })

    root:addChild(first)
    root:addChild(second)
    root:update()

    local first_local_points = first:_get_local_points()
    local first_local_points_again = first:_get_local_points()
    local second_local_points = second:_get_local_points()

    assert_same(first_local_points, first_local_points_again,
        'A shape should reuse its own local-point buffer between calls')
    assert_same(first_local_points[1], first_local_points_again[1],
        'A shape should reuse the nested local-point entries between calls')
    assert_not_same(first_local_points, second_local_points,
        'Sibling shapes must not share the same local-point buffer')
    assert_not_same(first_local_points[1], second_local_points[1],
        'Sibling shapes must not share nested local-point entries')

    first.width = 60
    root:update()

    local resized_local_points = first:_get_local_points()

    assert_same(first_local_points, resized_local_points,
        'Local-point scratch should stay stable when geometry changes')
    assert_equal(resized_local_points[2][1], 60,
        'Local-point scratch should refresh coordinates after geometry changes')

    local first_world_points = first:_transform_local_points(resized_local_points)
    local first_world_points_again = first:_transform_local_points(resized_local_points)
    local second_world_points = second:_transform_local_points(second_local_points)

    assert_same(first_world_points, first_world_points_again,
        'A shape should reuse its transformed world-point buffer')
    assert_not_same(first_world_points, second_world_points,
        'Sibling shapes must not share transformed world-point buffers')

    local first_flat_points = first:_flatten_points(first_world_points)
    local first_flat_points_again = first:_flatten_points(first_world_points)
    local second_flat_points = second:_flatten_points(second_world_points)

    assert_same(first_flat_points, first_flat_points_again,
        'A shape should reuse its flattened point buffer')
    assert_not_same(first_flat_points, second_flat_points,
        'Sibling shapes must not share flattened point buffers')

    local first_stroke = first:_resolve_polygon_stroke_options()
    local first_stroke_again = first:_resolve_polygon_stroke_options()
    local second_stroke = second:_resolve_polygon_stroke_options()

    assert_same(first_stroke, first_stroke_again,
        'A shape should reuse its stroke-option scratch table')
    assert_not_same(first_stroke, second_stroke,
        'Sibling shapes must not share stroke-option scratch tables')
    assert_true(first_stroke.node_opacity == nil,
        'Reusable stroke options should clear mask-only fields on the normal stroke path')

    first.strokeWidth = 6
    local resized_stroke = first:_resolve_polygon_stroke_options()

    assert_same(first_stroke, resized_stroke,
        'Stroke-option scratch should stay stable when stroke properties change')
    assert_equal(resized_stroke.width, 6,
        'Stroke-option scratch should refresh numeric fields after property changes')
end

local function run_axis_clip_restoration_tests()
    local root = Container.new({
        width = 300,
        height = 300,
    })
    local parent_clip = Container.new({
        tag = 'parent-clip',
        x = 20,
        y = 30,
        width = 120,
        height = 120,
        clipChildren = true,
    })
    local nested_clip = Container.new({
        tag = 'nested-clip',
        x = 10,
        y = 15,
        width = 40,
        height = 50,
        clipChildren = true,
    })
    local nested_leaf = Container.new({
        tag = 'nested-leaf',
        width = 10,
        height = 10,
    })
    local branch_sibling = Container.new({
        tag = 'branch-sibling',
        x = 80,
        y = 5,
        width = 10,
        height = 10,
    })
    local root_sibling = Container.new({
        tag = 'root-sibling',
        x = 220,
        y = 20,
        width = 10,
        height = 10,
    })
    local graphics = make_fake_graphics()
    local snapshots = {}

    nested_clip:addChild(nested_leaf)
    parent_clip:addChild(nested_clip)
    parent_clip:addChild(branch_sibling)
    root:addChild(parent_clip)
    root:addChild(root_sibling)
    root:update()

    root:_draw_subtree(graphics, function(node)
        snapshots[#snapshots + 1] = {
            tag = node.tag,
            scissor = copy_rect(graphics.current_scissor),
            stencil_compare = graphics.stencil_compare,
            stencil_value = graphics.stencil_value,
        }
    end)

    local parent_snapshot = find_snapshot(snapshots, 'parent-clip')
    local nested_snapshot = find_snapshot(snapshots, 'nested-clip')
    local nested_leaf_snapshot = find_snapshot(snapshots, 'nested-leaf')
    local branch_sibling_snapshot = find_snapshot(snapshots, 'branch-sibling')
    local root_sibling_snapshot = find_snapshot(snapshots, 'root-sibling')

    assert_equal(parent_snapshot.scissor.x, 20,
        'The parent axis clip should apply its world-space scissor before drawing')
    assert_equal(parent_snapshot.scissor.y, 30,
        'The parent axis clip should apply its world-space scissor before drawing')
    assert_equal(parent_snapshot.scissor.width, 120,
        'The parent axis clip should preserve its width in scissor state')
    assert_equal(parent_snapshot.scissor.height, 120,
        'The parent axis clip should preserve its height in scissor state')

    assert_equal(nested_snapshot.scissor.x, 30,
        'Nested axis clips should intersect into the child world-space scissor')
    assert_equal(nested_snapshot.scissor.y, 45,
        'Nested axis clips should intersect into the child world-space scissor')
    assert_equal(nested_snapshot.scissor.width, 40,
        'Nested axis clips should preserve the intersected width')
    assert_equal(nested_snapshot.scissor.height, 50,
        'Nested axis clips should preserve the intersected height')
    assert_equal(nested_leaf_snapshot.scissor.x, 30,
        'Children inside the nested clip should inherit the nested scissor')
    assert_equal(nested_leaf_snapshot.scissor.y, 45,
        'Children inside the nested clip should inherit the nested scissor')

    assert_equal(branch_sibling_snapshot.scissor.x, 20,
        'Axis clip scissor state should restore to the parent branch after a nested clip returns')
    assert_equal(branch_sibling_snapshot.scissor.y, 30,
        'Axis clip scissor state should restore to the parent branch after a nested clip returns')
    assert_equal(branch_sibling_snapshot.scissor.width, 120,
        'Axis clip scissor state should restore the parent width after a nested clip returns')
    assert_equal(branch_sibling_snapshot.scissor.height, 120,
        'Axis clip scissor state should restore the parent height after a nested clip returns')
    assert_true(root_sibling_snapshot.scissor == nil,
        'Axis clip scissor state should clear after the clipped branch completes')
end

local function run_rotated_clip_restoration_tests()
    local root = Container.new({
        width = 300,
        height = 300,
    })
    local rotated = Container.new({
        tag = 'rotated',
        x = 120,
        y = 120,
        width = 80,
        height = 80,
        pivotX = 0.5,
        pivotY = 0.5,
        rotation = math.rad(25),
        clipChildren = true,
        zIndex = 0,
    })
    local rotated_leaf = Container.new({
        tag = 'rotated-leaf',
        x = 10,
        y = 10,
        width = 20,
        height = 20,
    })
    local sibling = Container.new({
        tag = 'post-rotated-sibling',
        x = 10,
        y = 10,
        width = 20,
        height = 20,
        zIndex = 1,
    })
    local graphics = make_fake_graphics()
    local snapshots = {}

    rotated:addChild(rotated_leaf)
    root:addChild(rotated)
    root:addChild(sibling)
    root:update()

    root:_draw_subtree(graphics, function(node)
        snapshots[#snapshots + 1] = {
            tag = node.tag,
            scissor = copy_rect(graphics.current_scissor),
            stencil_compare = graphics.stencil_compare,
            stencil_value = graphics.stencil_value,
        }
    end)

    local rotated_snapshot = find_snapshot(snapshots, 'rotated')
    local rotated_leaf_snapshot = find_snapshot(snapshots, 'rotated-leaf')
    local sibling_snapshot = find_snapshot(snapshots, 'post-rotated-sibling')

    assert_equal(rotated_snapshot.stencil_compare, 'equal',
        'Rotated clips should enable stencil testing while the clipped branch draws')
    assert_equal(rotated_snapshot.stencil_value, 1,
        'Rotated clips should increment stencil depth for the clipped branch')
    assert_equal(rotated_leaf_snapshot.stencil_compare, 'equal',
        'Children inside a rotated clip should inherit stencil compare state')
    assert_equal(rotated_leaf_snapshot.stencil_value, 1,
        'Children inside a rotated clip should inherit stencil value state')
    assert_true(sibling_snapshot.stencil_compare == nil,
        'Stencil state should restore after the rotated clip branch completes')
    assert_true(sibling_snapshot.stencil_value == nil,
        'Stencil value should restore after the rotated clip branch completes')
end

local function run()
    run_shape_scratch_reuse_tests()
    run_axis_clip_restoration_tests()
    run_rotated_clip_restoration_tests()
end

return {
    run = run,
}
