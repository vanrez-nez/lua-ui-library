local Types = require('lib.ui.utils.types')
local GraphicsStencil = require('lib.ui.render.graphics_stencil')
local Texture = require('lib.ui.graphics.texture')
local Sprite = require('lib.ui.graphics.sprite')
local DrawHelpers = require('lib.ui.shapes.draw_helpers')
local RuntimeProfiler = require('profiler.runtime_profiler')

local FillRenderer = {}

local GRADIENT_MESH_FORMAT = {
    { 'VertexPosition', 'float', 2 },
    { 'VertexColor', 'float', 4 },
}

local TEXTURE_MESH_FORMAT = {
    { 'VertexPosition', 'float', 2 },
    { 'VertexTexCoord', 'float', 2 },
    { 'VertexColor', 'float', 4 },
}

local function error_message(prefix, source_prop, detail)
    local message = prefix .. ' for ' .. tostring(source_prop)
    if detail ~= nil and detail ~= '' then
        message = message .. ': ' .. detail
    end

    return message
end

local function raise_unsupported_renderer(source_prop, detail)
    error(error_message('Unsupported shape fill renderer path', source_prop, detail), 0)
end

local function raise_unusable_texture_source(source_prop)
    error('Active ' .. tostring(source_prop) .. ' source is unusable at draw time', 0)
end

local function get_renderer_scratch(shape)
    local scratch = rawget(shape, '_fill_renderer_scratch')

    if scratch == nil then
        -- Non-flat fill scratch stays shape-local because mesh builders mutate it between tiles/stops.
        scratch = {
            silhouette_points = {},
            gradient_vertices = {},
            textured_tile_vertices = {},
        }
        rawset(shape, '_fill_renderer_scratch', scratch)
    end

    return scratch
end

local function clear_tail(values, last_index)
    for index = #values, last_index + 1, -1 do
        values[index] = nil
    end
end

local function flatten_world_points(shape, local_points)
    local scratch = get_renderer_scratch(shape)
    local flattened = scratch.silhouette_points
    local flattened_index = 1

    for index = 1, #local_points do
        local point = local_points[index]
        local world_x, world_y = shape:localToWorld(point[1], point[2])
        flattened[flattened_index] = world_x
        flattened[flattened_index + 1] = world_y
        flattened_index = flattened_index + 2
    end

    clear_tail(flattened, flattened_index - 1)

    return flattened
end

local function set_mesh_vertex(vertices, index, x, y, z1, z2, z3, z4, z5, z6)
    local vertex = vertices[index]

    if vertex == nil then
        vertex = { x, y, z1, z2, z3, z4, z5, z6 }
        vertices[index] = vertex
        return
    end

    vertex[1] = x
    vertex[2] = y
    vertex[3] = z1
    vertex[4] = z2
    vertex[5] = z3
    vertex[6] = z4
    vertex[7] = z5
    vertex[8] = z6
end

local function build_gradient_vertices(shape, placement)
    local bounds = placement.localBounds
    local gradient = placement.gradient
    local colors = gradient.colors
    local horizontal = placement.direction == 'horizontal'
    local vertices = get_renderer_scratch(shape).gradient_vertices
    local vertex_index = 1

    for index = 1, #colors - 1 do
        local start_t = (index - 1) / (#colors - 1)
        local end_t = index / (#colors - 1)
        local start_color = colors[index]
        local end_color = colors[index + 1]
        local start_alpha = (start_color[4] or 1) * placement.opacity
        local end_alpha = (end_color[4] or 1) * placement.opacity

        local start_ax = nil
        local start_ay = nil
        local start_bx = nil
        local start_by = nil
        local end_ax = nil
        local end_ay = nil
        local end_bx = nil
        local end_by = nil

        if horizontal then
            local start_x = bounds.x + (bounds.width * start_t)
            local end_x = bounds.x + (bounds.width * end_t)
            start_ax, start_ay = shape:localToWorld(start_x, bounds.y)
            start_bx, start_by = shape:localToWorld(start_x, bounds.y + bounds.height)
            end_ax, end_ay = shape:localToWorld(end_x, bounds.y)
            end_bx, end_by = shape:localToWorld(end_x, bounds.y + bounds.height)
        else
            local start_y = bounds.y + (bounds.height * start_t)
            local end_y = bounds.y + (bounds.height * end_t)
            start_ax, start_ay = shape:localToWorld(bounds.x, start_y)
            start_bx, start_by = shape:localToWorld(bounds.x + bounds.width, start_y)
            end_ax, end_ay = shape:localToWorld(bounds.x, end_y)
            end_bx, end_by = shape:localToWorld(bounds.x + bounds.width, end_y)
        end

        set_mesh_vertex(
            vertices,
            vertex_index,
            start_ax,
            start_ay,
            start_color[1],
            start_color[2],
            start_color[3],
            start_alpha
        )
        set_mesh_vertex(
            vertices,
            vertex_index + 1,
            start_bx,
            start_by,
            start_color[1],
            start_color[2],
            start_color[3],
            start_alpha
        )
        set_mesh_vertex(
            vertices,
            vertex_index + 2,
            end_ax,
            end_ay,
            end_color[1],
            end_color[2],
            end_color[3],
            end_alpha
        )
        set_mesh_vertex(
            vertices,
            vertex_index + 3,
            start_bx,
            start_by,
            start_color[1],
            start_color[2],
            start_color[3],
            start_alpha
        )
        set_mesh_vertex(
            vertices,
            vertex_index + 4,
            end_bx,
            end_by,
            start_color[1],
            start_color[2],
            start_color[3],
            start_alpha
        )
        set_mesh_vertex(
            vertices,
            vertex_index + 5,
            end_ax,
            end_ay,
            end_color[1],
            end_color[2],
            end_color[3],
            end_alpha
        )
        vertex_index = vertex_index + 6
    end

    clear_tail(vertices, vertex_index - 1)

    return vertices
end

local function resolve_texture_uvs(source)
    if Types.is_instance(source, Sprite) then
        local texture = source:getTexture()
        local drawable = texture and texture:getDrawable() or nil
        local region = source:getRegion()
        local texture_width = texture and texture:getWidth() or 0
        local texture_height = texture and texture:getHeight() or 0

        if drawable == nil or texture_width <= 0 or texture_height <= 0 then
            return nil, nil, nil, nil, nil
        end

        return drawable,
            region.x / texture_width,
            region.y / texture_height,
            (region.x + region.width) / texture_width,
            (region.y + region.height) / texture_height
    end

    if Types.is_instance(source, Texture) then
        return source:getDrawable(), 0, 0, 1, 1
    end

    return nil, nil, nil, nil, nil
end

local function build_textured_tile_vertices(shape, tile, u1, v1, u2, v2, opacity)
    local top_left_x, top_left_y = shape:localToWorld(tile.x, tile.y)
    local top_right_x, top_right_y = shape:localToWorld(tile.x + tile.width, tile.y)
    local bottom_right_x, bottom_right_y = shape:localToWorld(tile.x + tile.width, tile.y + tile.height)
    local bottom_left_x, bottom_left_y = shape:localToWorld(tile.x, tile.y + tile.height)
    local alpha = opacity or 1
    local vertices = get_renderer_scratch(shape).textured_tile_vertices

    set_mesh_vertex(vertices, 1, top_left_x, top_left_y, u1, v1, 1, 1, 1, alpha)
    set_mesh_vertex(vertices, 2, top_right_x, top_right_y, u2, v1, 1, 1, 1, alpha)
    set_mesh_vertex(vertices, 3, bottom_right_x, bottom_right_y, u2, v2, 1, 1, 1, alpha)
    set_mesh_vertex(vertices, 4, top_left_x, top_left_y, u1, v1, 1, 1, 1, alpha)
    set_mesh_vertex(vertices, 5, bottom_right_x, bottom_right_y, u2, v2, 1, 1, 1, alpha)
    set_mesh_vertex(vertices, 6, bottom_left_x, bottom_left_y, u1, v2, 1, 1, 1, alpha)

    return vertices
end

local function ensure_non_flat_renderer_support(graphics, source_prop)
    if not Types.is_function(graphics.polygon) or
        not Types.is_function(graphics.stencil) or
        not Types.is_function(graphics.setStencilTest) or
        not Types.is_function(graphics.newMesh) or
        not Types.is_function(graphics.draw) then
        raise_unsupported_renderer(
            source_prop,
            'requires polygon, stencil, setStencilTest, newMesh, and draw'
        )
    end
end

local function with_silhouette_clip(graphics, clip_points, draw_fn)
    local saved_stencil = GraphicsStencil.save(graphics)
    local saved_color = DrawHelpers.save_color(graphics)

    local ok, err = xpcall(function()
        if not GraphicsStencil.write_polygon(graphics, clip_points) then
            error('shape silhouette clip is unavailable', 0)
        end

        graphics.setStencilTest('equal', 1)

        if Types.is_function(graphics.setColor) then
            graphics.setColor(1, 1, 1, 1)
        end

        draw_fn()
    end, function(failure)
        return failure
    end)

    DrawHelpers.restore_color(graphics, saved_color)
    GraphicsStencil.restore(graphics, saved_stencil)

    if not ok then
        error(err, 0)
    end
end

local function draw_gradient_fill(shape, graphics, local_points, placement)
    ensure_non_flat_renderer_support(graphics, placement.source_prop)

    local gradient = placement.gradient
    local colors = gradient and gradient.colors or nil
    if not Types.is_table(colors) or #colors < 2 then
        error('Active ' .. tostring(placement.source_prop) .. ' is invalid at draw time', 0)
    end

    local mesh = graphics.newMesh(
        GRADIENT_MESH_FORMAT,
        build_gradient_vertices(shape, placement),
        'triangles',
        'static'
    )
    if mesh == nil then
        raise_unsupported_renderer(placement.source_prop, 'graphics.newMesh returned nil')
    end

    with_silhouette_clip(graphics, flatten_world_points(shape, local_points), function()
        graphics.draw(mesh)
    end)

    return true
end

local function draw_texture_fill(shape, graphics, local_points, placement)
    ensure_non_flat_renderer_support(graphics, placement.source_prop)

    if placement.opacity <= 0 then
        return false
    end

    local drawable, u1, v1, u2, v2 = resolve_texture_uvs(placement.source)
    if drawable == nil or
        placement.drawable == nil or
        placement.sourceWidth <= 0 or
        placement.sourceHeight <= 0 then
        raise_unusable_texture_source(placement.source_prop)
    end

    local emitted_meshes = 0

    with_silhouette_clip(graphics, flatten_world_points(shape, local_points), function()
        for index = 1, #placement.placements do
            local tile = placement.placements[index]
            local mesh = graphics.newMesh(
                TEXTURE_MESH_FORMAT,
                build_textured_tile_vertices(shape, tile, u1, v1, u2, v2, placement.opacity),
                'triangles',
                'static'
            )

            if mesh == nil then
                raise_unsupported_renderer(placement.source_prop, 'graphics.newMesh returned nil')
            end

            if not Types.is_function(mesh.setTexture) then
                raise_unsupported_renderer(placement.source_prop, 'mesh texture binding is unavailable')
            end

            mesh:setTexture(drawable)
            graphics.draw(mesh)
            emitted_meshes = emitted_meshes + 1
        end
    end)

    return emitted_meshes > 0
end

function FillRenderer.draw(shape, graphics, local_points, placement)
    local profile_token = RuntimeProfiler.push_zone('FillRenderer.draw')
    placement = placement or shape:_resolve_active_fill_placement()
    local_points = local_points or shape:_get_local_points()

    if placement.kind == 'gradient' then
        local result = draw_gradient_fill(shape, graphics, local_points, placement)
        RuntimeProfiler.pop_zone(profile_token)
        return result
    end

    if placement.kind == 'texture' then
        local result = draw_texture_fill(shape, graphics, local_points, placement)
        RuntimeProfiler.pop_zone(profile_token)
        return result
    end

    RuntimeProfiler.pop_zone(profile_token)
    return false
end

return FillRenderer
