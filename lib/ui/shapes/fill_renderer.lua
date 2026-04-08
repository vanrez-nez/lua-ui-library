local Types = require('lib.ui.utils.types')
local GraphicsStencil = require('lib.ui.render.graphics_stencil')
local Texture = require('lib.ui.graphics.texture')
local Sprite = require('lib.ui.graphics.sprite')

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

local function save_color(graphics)
    if Types.is_function(graphics.getColor) then
        return { graphics.getColor() }
    end

    return nil
end

local function restore_color(graphics, saved_color)
    if saved_color == nil or not Types.is_function(graphics.setColor) then
        return
    end

    graphics.setColor(
        saved_color[1],
        saved_color[2],
        saved_color[3],
        saved_color[4]
    )
end

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

local function flatten_world_points(shape, local_points)
    local flattened = {}

    for index = 1, #local_points do
        local point = local_points[index]
        local world_x, world_y = shape:localToWorld(point[1], point[2])
        flattened[#flattened + 1] = world_x
        flattened[#flattened + 1] = world_y
    end

    return flattened
end

local function append_gradient_triangle(vertices, ax, ay, bx, by, color_a, cx, cy, color_c)
    vertices[#vertices + 1] = { ax, ay, color_a[1], color_a[2], color_a[3], color_a[4] }
    vertices[#vertices + 1] = { bx, by, color_a[1], color_a[2], color_a[3], color_a[4] }
    vertices[#vertices + 1] = { cx, cy, color_c[1], color_c[2], color_c[3], color_c[4] }
end

local function build_gradient_vertices(shape, placement)
    local bounds = placement.localBounds
    local gradient = placement.gradient
    local colors = gradient.colors
    local horizontal = placement.direction == 'horizontal'
    local vertices = {}

    for index = 1, #colors - 1 do
        local start_t = (index - 1) / (#colors - 1)
        local end_t = index / (#colors - 1)
        local start_color = colors[index]
        local end_color = colors[index + 1]
        local color_a = {
            start_color[1],
            start_color[2],
            start_color[3],
            (start_color[4] or 1) * placement.opacity,
        }
        local color_b = {
            end_color[1],
            end_color[2],
            end_color[3],
            (end_color[4] or 1) * placement.opacity,
        }

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

        append_gradient_triangle(vertices, start_ax, start_ay, start_bx, start_by, color_a, end_ax, end_ay, color_b)
        append_gradient_triangle(vertices, start_bx, start_by, end_bx, end_by, color_a, end_ax, end_ay, color_b)
    end

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

    return {
        { top_left_x, top_left_y, u1, v1, 1, 1, 1, alpha },
        { top_right_x, top_right_y, u2, v1, 1, 1, 1, alpha },
        { bottom_right_x, bottom_right_y, u2, v2, 1, 1, 1, alpha },
        { top_left_x, top_left_y, u1, v1, 1, 1, 1, alpha },
        { bottom_right_x, bottom_right_y, u2, v2, 1, 1, 1, alpha },
        { bottom_left_x, bottom_left_y, u1, v2, 1, 1, 1, alpha },
    }
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
    local saved_color = save_color(graphics)

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

    restore_color(graphics, saved_color)
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

    local meshes = {}
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
        meshes[#meshes + 1] = mesh
    end

    with_silhouette_clip(graphics, flatten_world_points(shape, local_points), function()
        for index = 1, #meshes do
            graphics.draw(meshes[index])
        end
    end)

    return #meshes > 0
end

function FillRenderer.draw(shape, graphics, local_points, placement)
    placement = placement or shape:_resolve_active_fill_placement()
    local_points = local_points or shape:_get_local_points()

    if placement.kind == 'gradient' then
        return draw_gradient_fill(shape, graphics, local_points, placement)
    end

    if placement.kind == 'texture' then
        return draw_texture_fill(shape, graphics, local_points, placement)
    end

    return false
end

return FillRenderer
