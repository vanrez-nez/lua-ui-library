local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')
local Schema = require('lib.ui.utils.schema')
local CanvasPool = require('lib.ui.render.canvas_pool')
local StylingContract = require('lib.ui.render.styling_contract')
local ThemeRuntime = require('lib.ui.themes.runtime')
local GraphicsSource = require('lib.ui.render.graphics_source')
local GraphicsStencil = require('lib.ui.render.graphics_stencil')
local SourcePlacement = require('lib.ui.render.source_placement')
local DrawableSchema = require('lib.ui.core.drawable_schema')
local SideQuad = require('lib.ui.core.side_quad')
local CornerQuad = require('lib.ui.core.corner_quad')

local Styling = {}

-- Lerp scalar ported from reference/color.lua — plain arithmetic, [0,1] space, no class import.
local function lerp(a, b, s)
    return a + s * (b - a)
end

-- Per-graphics-adapter canvas pool, same pattern as container.lua.
local canvas_pools = {}
local function get_canvas_pool(graphics)
    local pool = canvas_pools[graphics]
    if pool == nil then
        pool = CanvasPool.new({ graphics = graphics })
        canvas_pools[graphics] = pool
    end
    return pool
end

-- ---------------------------------------------------------------------------
-- Corner radius resolution — spec §8 overflow protection.
-- Checks four sides in order: top, bottom, left, right.
-- ---------------------------------------------------------------------------

local function resolve_radii(props, bounds)
    local tl = props.cornerRadiusTopLeft     or 0
    local tr = props.cornerRadiusTopRight    or 0
    local br = props.cornerRadiusBottomRight or 0
    local bl = props.cornerRadiusBottomLeft  or 0

    -- Top side
    if tl + tr > bounds.width and tl + tr > 0 then
        local s = bounds.width / (tl + tr)
        tl = tl * s; tr = tr * s
    end
    -- Bottom side
    if bl + br > bounds.width and bl + br > 0 then
        local s = bounds.width / (bl + br)
        bl = bl * s; br = br * s
    end
    -- Left side
    if tl + bl > bounds.height and tl + bl > 0 then
        local s = bounds.height / (tl + bl)
        tl = tl * s; bl = bl * s
    end
    -- Right side
    if tr + br > bounds.height and tr + br > 0 then
        local s = bounds.height / (tr + br)
        tr = tr * s; br = br * s
    end

    return { tl = tl, tr = tr, br = br, bl = bl }
end

local function derive_inner_radii(props, radii)
    local wt = props.borderWidthTop or 0
    local wr = props.borderWidthRight or 0
    local wb = props.borderWidthBottom or 0
    local wl = props.borderWidthLeft or 0

    -- Corner radius applies to the stroke centerline. The inner silhouette
    -- therefore contracts inward by half of the local border width. For mixed
    -- per-side borders, use the same adjacent-side averaging already used by
    -- the border corner arcs so inset geometry stays visually aligned with the
    -- current border paint model.
    return {
        tl = math.max(0, radii.tl - ((wt + wl) * 0.5)),
        tr = math.max(0, radii.tr - ((wt + wr) * 0.5)),
        br = math.max(0, radii.br - ((wb + wr) * 0.5)),
        bl = math.max(0, radii.bl - ((wb + wl) * 0.5)),
    }
end

-- ---------------------------------------------------------------------------
-- Rounded rectangle polygon — flat {x,y,...} in clockwise winding (y-down).
-- TR → BR → BL → TL corner order. r=0 at a corner emits just that corner point.
-- ---------------------------------------------------------------------------

local function rounded_rect_points(x, y, w, h, radii, segments)
    segments = segments or 8
    local pts = {}
    local pi = math.pi

    local function arc(cx, cy, r, a1, a2)
        if r <= 0 then
            pts[#pts + 1] = cx
            pts[#pts + 1] = cy
        else
            for s = 0, segments do
                local a = a1 + (a2 - a1) * s / segments
                pts[#pts + 1] = cx + math.cos(a) * r
                pts[#pts + 1] = cy + math.sin(a) * r
            end
        end
    end

    arc(x + w - radii.tr, y + radii.tr,      radii.tr, -pi / 2,     0)
    arc(x + w - radii.br, y + h - radii.br,  radii.br,  0,          pi / 2)
    arc(x + radii.bl,     y + h - radii.bl,  radii.bl,  pi / 2,     pi)
    arc(x + radii.tl,     y + radii.tl,      radii.tl,  pi,         pi * 3 / 2)

    return pts
end

-- ---------------------------------------------------------------------------
-- Graphics state helpers — guard every call with is_function checks.
-- ---------------------------------------------------------------------------

local function save_color(graphics)
    if Types.is_function(graphics.getColor) then
        return { graphics.getColor() }
    end
    return nil
end

local function restore_color(graphics, saved)
    if saved == nil or not Types.is_function(graphics.setColor) then return end
    graphics.setColor(saved[1], saved[2], saved[3], saved[4])
end

local function save_stencil(graphics)
    return GraphicsStencil.save(graphics)
end

local function restore_stencil(graphics, saved)
    GraphicsStencil.restore(graphics, saved)
end

local function save_line_state(graphics)
    local s = {}
    if Types.is_function(graphics.getLineWidth)   then s.width  = graphics.getLineWidth()  end
    if Types.is_function(graphics.getLineStyle)   then s.style  = graphics.getLineStyle()  end
    if Types.is_function(graphics.getLineJoin)    then s.join   = graphics.getLineJoin()   end
    if Types.is_function(graphics.getMiterLimit)  then s.miter  = graphics.getMiterLimit() end
    return s
end

local function restore_line_state(graphics, s)
    if s.width ~= nil and Types.is_function(graphics.setLineWidth)  then graphics.setLineWidth(s.width)   end
    if s.style ~= nil and Types.is_function(graphics.setLineStyle)  then graphics.setLineStyle(s.style)   end
    if s.join  ~= nil and Types.is_function(graphics.setLineJoin)   then graphics.setLineJoin(s.join)     end
    if s.miter ~= nil and Types.is_function(graphics.setMiterLimit) then graphics.setMiterLimit(s.miter)  end
end

-- Write the rounded rect silhouette into stencil buffer (value = 1).
local function write_rounded_stencil(graphics, pts)
    GraphicsStencil.write_polygon(graphics, pts)
end

-- ---------------------------------------------------------------------------
-- Background — color-backed.
-- ---------------------------------------------------------------------------

local function paint_background_color(props, bounds, graphics, radii)
    local c = props.backgroundColor
    local a = c[4] * (props.backgroundOpacity or 1)
    if a <= 0 then return end

    local saved = save_color(graphics)
    if Types.is_function(graphics.setColor) then
        graphics.setColor(c[1], c[2], c[3], a)
    end
    local pts = rounded_rect_points(bounds.x, bounds.y, bounds.width, bounds.height, radii)
    if Types.is_function(graphics.polygon) then
        graphics.polygon('fill', pts)
    end
    restore_color(graphics, saved)
end

-- ---------------------------------------------------------------------------
-- Background — gradient-backed.
-- Mesh format: VertexPosition (float2), VertexColor (float4).
-- ---------------------------------------------------------------------------

local MESH_FORMAT = {
    { 'VertexPosition', 'float', 2 },
    { 'VertexColor',    'float', 4 },
}

local function paint_background_gradient(props, bounds, graphics, radii)
    local grad = props.backgroundGradient
    local opacity = props.backgroundOpacity or 1
    if opacity <= 0 then return end
    if not Types.is_function(graphics.newMesh) then return end

    local colors = grad.colors
    local n = #colors
    if n < 2 then return end

    local x, y, w, h = bounds.x, bounds.y, bounds.width, bounds.height
    local horizontal = grad.direction == 'horizontal'

    -- Build interleaved vertex pairs: for each stop i, one "A" vertex and one "B" vertex
    -- where A and B are opposite ends of the strip perpendicular to the gradient axis.
    local verts = {}
    for i = 1, n do
        local t = (i - 1) / (n - 1)
        local c = colors[i]
        local ca = c[4] * opacity

        local ax, ay, bx, by
        if horizontal then
            ax = x + t * w;  ay = y
            bx = ax;          by = y + h
        else
            ax = x;           ay = y + t * h
            bx = x + w;       by = ay
        end

        verts[#verts + 1] = { ax, ay, c[1], c[2], c[3], ca }
        verts[#verts + 1] = { bx, by, c[1], c[2], c[3], ca }
    end

    -- Two triangles per segment: (A_i, B_i, A_{i+1}) and (B_i, B_{i+1}, A_{i+1})
    local idxs = {}
    for i = 1, n - 1 do
        local b = (i - 1) * 2
        idxs[#idxs + 1] = b + 1; idxs[#idxs + 1] = b + 2; idxs[#idxs + 1] = b + 3
        idxs[#idxs + 1] = b + 2; idxs[#idxs + 1] = b + 4; idxs[#idxs + 1] = b + 3
    end

    local mesh = graphics.newMesh(MESH_FORMAT, verts, 'triangles', 'static')
    if mesh == nil then return end
    if Types.is_function(mesh.setVertexMap) then
        mesh:setVertexMap(idxs)
    end

    local pts = rounded_rect_points(x, y, w, h, radii)
    local saved_stencil = save_stencil(graphics)
    local saved_color = save_color(graphics)

    write_rounded_stencil(graphics, pts)
    if Types.is_function(graphics.setStencilTest) then
        graphics.setStencilTest('equal', 1)
    end
    if Types.is_function(graphics.setColor) then
        graphics.setColor(1, 1, 1, 1)
    end
    if Types.is_function(graphics.draw) then
        graphics.draw(mesh)
    end

    restore_stencil(graphics, saved_stencil)
    restore_color(graphics, saved_color)
end

-- ---------------------------------------------------------------------------
-- Background — image-backed.
-- ---------------------------------------------------------------------------

local function paint_background_image(props, bounds, graphics, radii)
    local img = props.backgroundImage
    local opacity = props.backgroundOpacity or 1
    if opacity <= 0 then return end

    local drawable, quad, src_w, src_h = GraphicsSource.resolve_draw_source(img)
    if src_w <= 0 or src_h <= 0 then return end
    if drawable == nil then return end
    if not Types.is_function(graphics.draw) then return end

    local align_x = props.backgroundAlignX or 'start'
    local align_y = props.backgroundAlignY or 'start'
    local off_x   = props.backgroundOffsetX or 0
    local off_y   = props.backgroundOffsetY or 0
    local rep_x   = props.backgroundRepeatX or false
    local rep_y   = props.backgroundRepeatY or false

    local base_x = SourcePlacement.resolve_aligned_origin(
        bounds.x,
        bounds.width,
        src_w,
        align_x,
        off_x
    )
    local base_y = SourcePlacement.resolve_aligned_origin(
        bounds.y,
        bounds.height,
        src_h,
        align_y,
        off_y
    )

    local pts = rounded_rect_points(bounds.x, bounds.y, bounds.width, bounds.height, radii)
    local saved_stencil = save_stencil(graphics)
    local saved_color = save_color(graphics)

    write_rounded_stencil(graphics, pts)
    if Types.is_function(graphics.setStencilTest) then
        graphics.setStencilTest('equal', 1)
    end
    if Types.is_function(graphics.setColor) then
        graphics.setColor(1, 1, 1, opacity)
    end

    local x_start = rep_x and bounds.x            or base_x
    local x_end   = rep_x and (bounds.x + bounds.width)  or (base_x + src_w)
    local y_start = rep_y and bounds.y            or base_y
    local y_end   = rep_y and (bounds.y + bounds.height) or (base_y + src_h)

    local ix = x_start
    while ix < x_end do
        local iy = y_start
        while iy < y_end do
            if quad ~= nil then
                graphics.draw(drawable, quad, ix, iy)
            else
                graphics.draw(drawable, ix, iy)
            end
            iy = iy + src_h
            if not rep_y then break end
        end
        ix = ix + src_w
        if not rep_x then break end
    end

    restore_stencil(graphics, saved_stencil)
    restore_color(graphics, saved_color)
end

-- ---------------------------------------------------------------------------
-- Background — dispatcher (source selection per spec §6 priority order).
-- ---------------------------------------------------------------------------

local function paint_background(props, bounds, graphics, radii)
    if props.backgroundImage ~= nil then
        paint_background_image(props, bounds, graphics, radii)
    elseif props.backgroundGradient ~= nil then
        paint_background_gradient(props, bounds, graphics, radii)
    elseif props.backgroundColor ~= nil then
        paint_background_color(props, bounds, graphics, radii)
    end
end

-- ---------------------------------------------------------------------------
-- Border — center-aligned per spec §7.
-- ---------------------------------------------------------------------------

local function draw_dashed_line(graphics, x1, y1, x2, y2, dash_len, gap_len)
    if not Types.is_function(graphics.line) then
        return
    end

    local dx = x2 - x1
    local dy = y2 - y1
    local length = math.sqrt((dx * dx) + (dy * dy))

    if length <= 0 then
        return
    end

    if gap_len <= 0 then
        graphics.line(x1, y1, x2, y2)
        return
    end

    local ux = dx / length
    local uy = dy / length
    local step = dash_len + gap_len

    for offset = 0, length, step do
        local dash_end = math.min(offset + dash_len, length)
        graphics.line(
            x1 + (ux * offset),
            y1 + (uy * offset),
            x1 + (ux * dash_end),
            y1 + (uy * dash_end)
        )
    end
end

local function draw_dashed_arc(graphics, cx, cy, r, a1, a2, dash_len, gap_len)
    if r <= 0 or not Types.is_function(graphics.arc) then
        return
    end

    local span = a2 - a1
    local arc_length = math.abs(span) * r

    if arc_length <= 0 then
        return
    end

    if gap_len <= 0 then
        graphics.arc('line', 'open', cx, cy, r, a1, a2)
        return
    end

    local direction = (span >= 0) and 1 or -1
    local step = dash_len + gap_len

    for offset = 0, arc_length, step do
        local dash_end = math.min(offset + dash_len, arc_length)
        local dash_a1 = a1 + direction * (offset / r)
        local dash_a2 = a1 + direction * (dash_end / r)
        graphics.arc('line', 'open', cx, cy, r, dash_a1, dash_a2)
    end
end

local function draw_dashed_line_with_offset(graphics, x1, y1, x2, y2, dash_len, gap_len, offset)
    if not Types.is_function(graphics.line) then
        return
    end

    local dx = x2 - x1
    local dy = y2 - y1
    local length = math.sqrt((dx * dx) + (dy * dy))

    if length <= 0 then
        return
    end

    if gap_len <= 0 then
        graphics.line(x1, y1, x2, y2)
        return
    end

    local ux = dx / length
    local uy = dy / length
    local cycle = dash_len + gap_len
    local distance = (offset % cycle) - cycle

    while distance < length do
        local dash_start = math.max(0, distance)
        local dash_end = math.min(length, distance + dash_len)
        if dash_end > dash_start and (dash_end - dash_start) < 1 then
            dash_end = math.min(length, dash_start + 1)
        end
        if dash_end > dash_start then
            graphics.line(
                x1 + (ux * dash_start),
                y1 + (uy * dash_start),
                x1 + (ux * dash_end),
                y1 + (uy * dash_end)
            )
        end
        distance = distance + cycle
    end
end

local function draw_dashed_arc_with_offset(graphics, cx, cy, r, a1, a2, dash_len, gap_len, offset)
    if r <= 0 or not Types.is_function(graphics.arc) then
        return
    end

    local span = a2 - a1
    local arc_length = math.abs(span) * r

    if arc_length <= 0 then
        return
    end

    if gap_len <= 0 then
        graphics.arc('line', 'open', cx, cy, r, a1, a2)
        return
    end

    local direction = (span >= 0) and 1 or -1
    local cycle = dash_len + gap_len
    local distance = (offset % cycle) - cycle
    local target_step = math.max(0.5, math.min(dash_len * 0.5, 2))
    local arc_segments = math.max(16, math.min(96, math.ceil(arc_length / target_step)))

    while distance < arc_length do
        local dash_start = math.max(0, distance)
        local dash_end = math.min(arc_length, distance + dash_len)
        if dash_end > dash_start and (dash_end - dash_start) < 1 then
            dash_end = math.min(arc_length, dash_start + 1)
        end
        if dash_end > dash_start then
            local dash_a1 = a1 + direction * (dash_start / r)
            local dash_a2 = a1 + direction * (dash_end / r)
            graphics.arc('line', 'open', cx, cy, r, dash_a1, dash_a2, arc_segments)
        end
        distance = distance + cycle
    end
end

local function draw_uniform_dashed_border(graphics, x, y, w, h, radii, line_width, dash_len, gap_len, phase_offset)
    if line_width <= 0 then
        return
    end

    if Types.is_function(graphics.setLineWidth) then
        graphics.setLineWidth(line_width)
    end

    local tl = radii.tl or 0
    local tr = radii.tr or 0
    local br = radii.br or 0
    local bl = radii.bl or 0
    local pi = math.pi

    local segments = {
        {
            kind = 'line',
            x1 = x + tl, y1 = y,
            x2 = x + w - tr, y2 = y,
            length = math.max(0, w - tl - tr),
        },
        {
            kind = 'arc',
            cx = x + w - tr, cy = y + tr,
            r = tr, a1 = -pi / 2, a2 = 0,
            length = tr * (pi / 2),
        },
        {
            kind = 'line',
            x1 = x + w, y1 = y + tr,
            x2 = x + w, y2 = y + h - br,
            length = math.max(0, h - tr - br),
        },
        {
            kind = 'arc',
            cx = x + w - br, cy = y + h - br,
            r = br, a1 = 0, a2 = pi / 2,
            length = br * (pi / 2),
        },
        {
            kind = 'line',
            x1 = x + w - br, y1 = y + h,
            x2 = x + bl, y2 = y + h,
            length = math.max(0, w - br - bl),
        },
        {
            kind = 'arc',
            cx = x + bl, cy = y + h - bl,
            r = bl, a1 = pi / 2, a2 = pi,
            length = bl * (pi / 2),
        },
        {
            kind = 'line',
            x1 = x, y1 = y + h - bl,
            x2 = x, y2 = y + tl,
            length = math.max(0, h - bl - tl),
        },
        {
            kind = 'arc',
            cx = x + tl, cy = y + tl,
            r = tl, a1 = pi, a2 = pi * 3 / 2,
            length = tl * (pi / 2),
        },
    }

    local perimeter = 0
    for i = 1, #segments do
        perimeter = perimeter + segments[i].length
    end

    if perimeter <= 0 then
        return
    end

    local total = dash_len + gap_len
    local adjusted_dash = dash_len
    local adjusted_gap = gap_len
    local dash_count = math.floor((perimeter / total) + 0.5)
    if dash_count > 0 then
        local adjusted_total = perimeter / dash_count
        adjusted_dash = adjusted_total * (dash_len / total)
        adjusted_gap = adjusted_total - adjusted_dash
    end

    local current_distance = 0
    for i = 1, #segments do
        local segment = segments[i]
        if segment.length > 0 then
            local segment_offset = phase_offset - current_distance
            if segment.kind == 'line' then
                draw_dashed_line_with_offset(
                    graphics,
                    segment.x1, segment.y1,
                    segment.x2, segment.y2,
                    adjusted_dash, adjusted_gap, segment_offset
                )
            else
                draw_dashed_arc_with_offset(
                    graphics,
                    segment.cx, segment.cy, segment.r,
                    segment.a1, segment.a2,
                    adjusted_dash, adjusted_gap, segment_offset
                )
            end
            current_distance = current_distance + segment.length
        end
    end
end

local function apply_border_line_state(props, graphics)
    local style   = props.borderStyle
    local join    = props.borderJoin
    local miter   = props.borderMiterLimit

    if style ~= nil and Types.is_function(graphics.setLineStyle) then
        graphics.setLineStyle(style)
    end
    if join ~= nil and Types.is_function(graphics.setLineJoin) then
        graphics.setLineJoin(join)
    end
    if miter ~= nil and join == 'miter' and Types.is_function(graphics.setMiterLimit) then
        graphics.setMiterLimit(miter)
    end
end

local function paint_border(props, bounds, graphics, radii)
    local wt = props.borderWidthTop    or 0
    local wr = props.borderWidthRight  or 0
    local wb = props.borderWidthBottom or 0
    local wl = props.borderWidthLeft   or 0

    if wt == 0 and wr == 0 and wb == 0 and wl == 0 then return end

    local c = props.borderColor
    if c == nil then return end

    -- Cycle ceiling guard (spec §7.4)
    if props.borderPattern == 'dashed' then
        local dl = props.borderDashLength or 8
        local gl = props.borderGapLength  or 6
        if dl + gl > 255 then
            error('borderDashLength + borderGapLength must not exceed 255, got ' .. (dl + gl), 2)
        end
    end

    local a = c[4] * (props.borderOpacity or 1)
    local saved_color = save_color(graphics)
    local saved_line  = save_line_state(graphics)

    if Types.is_function(graphics.setColor) then
        graphics.setColor(c[1], c[2], c[3], a)
    end
    apply_border_line_state(props, graphics)

    local x, y, w, h = bounds.x, bounds.y, bounds.width, bounds.height
    local dashed = props.borderPattern == 'dashed'
    local dash_len = props.borderDashLength or 8
    local gap_len = props.borderGapLength or 6
    local dash_offset = props.borderDashOffset or 0
    local snap_dashed_motion = dashed and props.borderStyle == 'rough'

    if snap_dashed_motion then
        dash_offset = math.floor(dash_offset + 0.5)
    end

    if wt == wr and wr == wb and wb == wl and wt > 0
        and (not dashed or gap_len <= 0) then
        -- Uniform width — single rounded-rectangle stroke.
        if Types.is_function(graphics.setLineWidth) then graphics.setLineWidth(wt) end
        local pts = rounded_rect_points(x, y, w, h, radii)
        if Types.is_function(graphics.polygon) then
            graphics.polygon('line', pts)
        end
    elseif dashed and wt == wr and wr == wb and wb == wl and wt > 0 then
        draw_uniform_dashed_border(graphics, x, y, w, h, radii, wt, dash_len, gap_len, dash_offset)
    else
        -- Mixed-width or segmented fallback path.
        local pi = math.pi
        local function draw_side_line(lw, x1, y1, x2, y2)
            if lw <= 0 then return end
            if Types.is_function(graphics.setLineWidth) then graphics.setLineWidth(lw) end
            if dashed then
                draw_dashed_line_with_offset(graphics, x1, y1, x2, y2, dash_len, gap_len, dash_offset)
            elseif Types.is_function(graphics.line) then
                graphics.line(x1, y1, x2, y2)
            end
        end
        local function draw_corner_arc(lw, cx, cy, r, a1, a2)
            if lw <= 0 or r <= 0 then return end
            if Types.is_function(graphics.setLineWidth) then graphics.setLineWidth(lw) end
            if dashed then
                draw_dashed_arc_with_offset(graphics, cx, cy, r, a1, a2, dash_len, gap_len, dash_offset)
            elseif Types.is_function(graphics.arc) then
                graphics.arc('line', 'open', cx, cy, r, a1, a2)
            end
        end

        -- Straight segments between corner arcs
        draw_side_line(wt, x + radii.tl, y,       x + w - radii.tr, y)
        draw_side_line(wr, x + w,        y + radii.tr, x + w,        y + h - radii.br)
        draw_side_line(wb, x + w - radii.br, y + h, x + radii.bl,   y + h)
        draw_side_line(wl, x,            y + h - radii.bl, x,        y + radii.tl)

        -- Corner arcs at average of the two adjacent side widths
        draw_corner_arc((wt + wr) / 2, x + w - radii.tr, y + radii.tr,     radii.tr, -pi/2,       0)
        draw_corner_arc((wr + wb) / 2, x + w - radii.br, y + h - radii.br, radii.br,  0,           pi/2)
        draw_corner_arc((wb + wl) / 2, x + radii.bl,     y + h - radii.bl, radii.bl,  pi/2,        pi)
        draw_corner_arc((wl + wt) / 2, x + radii.tl,     y + radii.tl,     radii.tl,  pi,          pi * 3/2)
    end

    restore_line_state(graphics, saved_line)
    restore_color(graphics, saved_color)
end

-- ---------------------------------------------------------------------------
-- Shadow — shared canvas-based rendering.
-- blur > 0: multi-step concentric shapes at equal alpha produce a soft edge.
-- blur = 0: single hard-edged shape, no canvas required.
-- ---------------------------------------------------------------------------

-- Draw a filled rounded-rect shape at (sx, sy, sw, sh) with given color and alpha.
local function draw_shadow_shape(graphics, sx, sy, sw, sh, r, g, b, a, radii, seg_scale)
    seg_scale = seg_scale or 1
    if Types.is_function(graphics.setColor) then
        graphics.setColor(r, g, b, a)
    end
    local pts = rounded_rect_points(sx, sy, sw, sh, radii, math.max(4, math.floor(8 * seg_scale)))
    if Types.is_function(graphics.polygon) then
        graphics.polygon('fill', pts)
    end
end

-- Render a soft shadow to the current target using canvas-based multi-pass blur.
-- shape_x, shape_y, shape_w, shape_h: shadow source rectangle in current coordinate space.
-- The canvas is acquired from the pool and released after compositing.
local function render_shadow_soft(
    graphics, c, final_alpha, blur, shape_x, shape_y, shape_w, shape_h,
    radii, composite_x, composite_y
)
    local steps = math.max(1, math.ceil(blur * 2))
    local step_alpha = final_alpha / steps
    local margin = math.ceil(blur)
    local canvas_w = shape_w + margin * 2
    local canvas_h = shape_h + margin * 2

    if not Types.is_function(graphics.newCanvas) then
        -- Fallback: draw direct without blur
        draw_shadow_shape(graphics, shape_x, shape_y, shape_w, shape_h,
            c[1], c[2], c[3], final_alpha, radii, 1)
        return
    end

    local pool = get_canvas_pool(graphics)
    local canvas = pool:acquire(canvas_w, canvas_h)
    local prev_canvas = Types.is_function(graphics.getCanvas) and graphics.getCanvas() or nil

    if Types.is_function(graphics.setCanvas) then graphics.setCanvas(canvas) end
    if Types.is_function(graphics.origin)    then graphics.origin() end
    if Types.is_function(graphics.clear)     then graphics.clear(0, 0, 0, 0) end

    -- Draw N shapes from largest (outermost, most transparent) to smallest (most opaque).
    -- Each shape is offset to stay centered. Together they create a soft falloff.
    for i = 0, steps - 1 do
        local t = (steps > 1) and (i / (steps - 1)) or 0  -- 0 = largest, 1 = smallest
        local expand = blur * (1 - t)                       -- outermost step has max expand
        local sx = margin - expand
        local sy = margin - expand
        local sw = shape_w + expand * 2
        local sh = shape_h + expand * 2
        -- Scale radii proportionally to the expanded shape
        local s = (shape_w > 0) and (sw / shape_w) or 1
        local exp_radii = {
            tl = radii.tl * s, tr = radii.tr * s,
            br = radii.br * s, bl = radii.bl * s,
        }
        draw_shadow_shape(graphics, sx, sy, sw, sh, c[1], c[2], c[3], step_alpha, exp_radii)
    end

    if Types.is_function(graphics.setCanvas) then graphics.setCanvas(prev_canvas) end

    -- Composite shadow canvas back onto main target.
    local saved_color = save_color(graphics)
    if Types.is_function(graphics.setColor)  then graphics.setColor(1, 1, 1, 1) end
    if Types.is_function(graphics.draw)      then graphics.draw(canvas, composite_x, composite_y) end
    restore_color(graphics, saved_color)

    pool:release(canvas)
end

-- ---------------------------------------------------------------------------
-- Outer shadow — step 1 in paint order.
-- ---------------------------------------------------------------------------

local function paint_outer_shadow(props, bounds, graphics, radii)
    if props.shadowColor == nil then return end

    local c = props.shadowColor
    local final_alpha = c[4] * (props.shadowOpacity or 1)
    if final_alpha <= 0 then return end

    local blur = props.shadowBlur or 0
    local ox   = props.shadowOffsetX or 0
    local oy   = props.shadowOffsetY or 0
    local x, y, w, h = bounds.x, bounds.y, bounds.width, bounds.height

    if blur <= 0 then
        local saved = save_color(graphics)
        draw_shadow_shape(graphics, x + ox, y + oy, w, h, c[1], c[2], c[3], final_alpha, radii)
        restore_color(graphics, saved)
        return
    end

    local margin = math.ceil(blur)
    -- Canvas covers: (x+ox - margin, y+oy - margin) to (x+ox+w+margin, y+oy+h+margin)
    -- Shadow shape at canvas-local (margin, margin) with size (w, h)
    render_shadow_soft(
        graphics, c, final_alpha, blur,
        margin, margin, w, h, radii,
        x + ox - margin, y + oy - margin
    )
end

-- ---------------------------------------------------------------------------
-- Inset shadow — step 4 in paint order.
-- ---------------------------------------------------------------------------

local function paint_inset_shadow(props, bounds, graphics, radii)
    if props.shadowColor == nil then return end

    local c = props.shadowColor
    local final_alpha = c[4] * (props.shadowOpacity or 1)
    if final_alpha <= 0 then return end

    local blur = props.shadowBlur or 0
    local ox   = props.shadowOffsetX or 0
    local oy   = props.shadowOffsetY or 0

    -- Interior bounds inset by border widths.
    local inner_x = bounds.x + (props.borderWidthLeft   or 0)
    local inner_y = bounds.y + (props.borderWidthTop     or 0)
    local inner_w = bounds.width  - (props.borderWidthLeft or 0) - (props.borderWidthRight  or 0)
    local inner_h = bounds.height - (props.borderWidthTop  or 0) - (props.borderWidthBottom or 0)

    if inner_w <= 0 or inner_h <= 0 then return end

    local inner_radii = derive_inner_radii(props, radii)
    local saved_stencil = save_stencil(graphics)
    local inner_pts = rounded_rect_points(inner_x, inner_y, inner_w, inner_h, inner_radii)

    -- Clip all subsequent paint to the interior.
    if Types.is_function(graphics.stencil) and Types.is_function(graphics.polygon) then
        graphics.stencil(function()
            graphics.polygon('fill', inner_pts)
        end, 'replace', 1)
    end
    if Types.is_function(graphics.setStencilTest) then
        graphics.setStencilTest('equal', 1)
    end

    if blur <= 0 then
        local saved = save_color(graphics)
        draw_shadow_shape(graphics, inner_x + ox, inner_y + oy, inner_w, inner_h,
            c[1], c[2], c[3], final_alpha, inner_radii)
        restore_color(graphics, saved)
    else
        local margin = math.ceil(blur)
        render_shadow_soft(
            graphics, c, final_alpha, blur,
            margin, margin, inner_w, inner_h, inner_radii,
            inner_x + ox - margin, inner_y + oy - margin
        )
    end

    restore_stencil(graphics, saved_stencil)
end

-- ---------------------------------------------------------------------------
-- Public entry point — Styling.draw(props, bounds, graphics)
-- ---------------------------------------------------------------------------

function Styling.draw(props, bounds, graphics)
    Assert.table('props',    props,    2)
    Assert.table('bounds',   bounds,   2)
    Assert.table('graphics', graphics, 2)

    if bounds.x == nil or bounds.y == nil or bounds.width == nil or bounds.height == nil then
        error('Styling.draw: bounds must have x, y, width, and height', 2)
    end

    local radii = resolve_radii(props, bounds)
    local saved_color = save_color(graphics)

    -- Paint order: outer shadow → background → border → inset shadow  (spec §11A)
    if props.shadowInset ~= true then
        paint_outer_shadow(props, bounds, graphics, radii)
    end

    paint_background(props, bounds, graphics, radii)
    paint_border(props, bounds, graphics, radii)

    if props.shadowInset == true then
        paint_inset_shadow(props, bounds, graphics, radii)
    end

    restore_color(graphics, saved_color)
end

-- ---------------------------------------------------------------------------
-- Styling.assemble_props — build a resolved props table for Styling.draw.
--
-- This function is intentionally limited to the flat styling-property families
-- defined by docs/spec/ui-styling-spec.md §§6-9. It does not define aliases or
-- grouped style objects beyond those spec-owned fields.
--
-- Full styling precedence is defined by:
-- - ui-styling-spec §4B
-- - ui-foundation-spec §§8.3-8.4
--
-- The current implementation only assembles the documented property names onto
-- a props table for the renderer. It does not imply that undocumented token
-- bindings, aliases, or implicit selector matching are valid.
-- ---------------------------------------------------------------------------

local function resolve_root_skin_value(skin, property_name)
    if not Types.is_table(skin) then
        return nil
    end

    return skin[property_name]
end

local function normalize_styling_value(property_name, value, node)
    if value == nil then
        return nil
    end

    return Schema.validate(DrawableSchema, property_name, value, node, 3, 'Drawable')
end

local function normalize_resolver_context(node, resolver_context)
    if not Types.is_table(resolver_context) then
        return nil
    end

    local context = {}
    for key, value in pairs(resolver_context) do
        context[key] = value
    end

    if context.partSkin == nil and Types.is_table(rawget(node, 'skin')) then
        context.partSkin = rawget(node, 'skin')
    end

    if context.variant == nil then
        local explicit_variant = rawget(node, '_styling_variant')
        if explicit_variant ~= nil then
            context.variant = explicit_variant
        elseif Types.is_function(node._resolve_visual_variant) then
            context.variant = node:_resolve_visual_variant()
        end
    end

    return context
end

local QUAD_FAMILIES = {
    borderWidth = {
        aggregate = 'borderWidth',
        members = {
            top = 'borderWidthTop',
            right = 'borderWidthRight',
            bottom = 'borderWidthBottom',
            left = 'borderWidthLeft',
        },
        resolver = SideQuad,
    },
    cornerRadius = {
        aggregate = 'cornerRadius',
        members = {
            topLeft = 'cornerRadiusTopLeft',
            topRight = 'cornerRadiusTopRight',
            bottomRight = 'cornerRadiusBottomRight',
            bottomLeft = 'cornerRadiusBottomLeft',
        },
        resolver = CornerQuad,
    },
}

local QUAD_PROPERTY_KEYS = {
    borderWidth = true,
    borderWidthTop = true, borderWidthRight = true, borderWidthBottom = true, borderWidthLeft = true,
    cornerRadius = true,
    cornerRadiusTopLeft = true, cornerRadiusTopRight = true,
    cornerRadiusBottomRight = true, cornerRadiusBottomLeft = true,
}

local function resolve_override_value(source, part, property_name, variant)
    if not Types.is_table(source) then
        return nil
    end

    local part_table = source[part]
    if not Types.is_table(part_table) then
        return nil
    end

    local property_value = part_table[property_name]
    if not Types.is_table(property_value) then
        return property_value
    end

    if variant ~= nil and property_value[variant] ~= nil then
        return property_value[variant]
    end

    return property_value.base
end

local function resolve_token_value(tokens, component, part, property_name, variant)
    if not Types.is_table(tokens) then
        return nil
    end

    local key = table.concat({ component, part, property_name }, '.')
    if variant ~= nil and variant ~= 'base' then
        local variant_key = key .. '.' .. tostring(variant)
        if tokens[variant_key] ~= nil then
            return tokens[variant_key]
        end
    end

    return tokens[key]
end

local function resolve_quad_family_from_layers(node, family, layers)
    local resolved_layers = {}

    for layer_index = 1, #layers do
        local layer = layers[layer_index]
        if Types.is_table(layer) then
            local resolved = {}

            if layer.aggregate ~= nil then
                resolved.aggregate = normalize_styling_value(family.aggregate, layer.aggregate, node)
            end

            for member_name, property_name in pairs(family.members) do
                if layer[property_name] ~= nil then
                    resolved[member_name] = normalize_styling_value(property_name, layer[property_name], node)
                end
            end

            resolved_layers[#resolved_layers + 1] = resolved
        end
    end

    local quad = family.resolver.resolve_layers(resolved_layers, {
        label = family.aggregate,
    }, 3)

    if quad == nil then
        return nil
    end

    local props = {}
    props[family.aggregate] = quad

    for member_name, property_name in pairs(family.members) do
        props[property_name] = quad[member_name]
    end

    return props
end

local function resolve_contextual_props(node, resolver_context)
    local props = {}
    local part = resolver_context.part

    for _, key in ipairs(StylingContract.ROOT_PROPERTY_KEYS) do
        if QUAD_PROPERTY_KEYS[key] then
            goto continue
        end

        local ok, value = pcall(
            ThemeRuntime.resolve,
            resolver_context.component,
            part,
            key,
            resolver_context.variant,
            {
                instanceValue = node[key],
                instanceOverrides = resolver_context.instanceOverrides,
                partSkin = resolver_context.partSkin,
                theme = resolver_context.theme,
                defaults = resolver_context.defaults,
            }
        )

        if ok then
            props[key] = normalize_styling_value(key, value, node)
        else
            local message = tostring(value)
            if message:find('missing token "', 1, true) ~= nil then
                props[key] = nil
            else
                error(value, 0)
            end
        end

        ::continue::
    end

    for _, family in pairs(QUAD_FAMILIES) do
        local direct_layer = {
            aggregate = node[family.aggregate],
        }
        for _, property_name in pairs(family.members) do
            direct_layer[property_name] = node[property_name]
        end

        local override_layer = {
            aggregate = resolve_override_value(
                resolver_context.instanceOverrides,
                part,
                family.aggregate,
                resolver_context.variant
            ),
        }
        for _, property_name in pairs(family.members) do
            override_layer[property_name] = resolve_override_value(
                resolver_context.instanceOverrides,
                part,
                property_name,
                resolver_context.variant
            )
        end

        local skin_layer = {
            aggregate = resolve_override_value(
                resolver_context.partSkin,
                part,
                family.aggregate,
                resolver_context.variant
            ),
        }
        for _, property_name in pairs(family.members) do
            skin_layer[property_name] = resolve_override_value(
                resolver_context.partSkin,
                part,
                property_name,
                resolver_context.variant
            )
        end

        local theme_layer = {
            aggregate = resolve_token_value(
                resolver_context.theme and resolver_context.theme.tokens or nil,
                resolver_context.component,
                part,
                family.aggregate,
                resolver_context.variant
            ),
        }
        for _, property_name in pairs(family.members) do
            theme_layer[property_name] = resolve_token_value(
                resolver_context.theme and resolver_context.theme.tokens or nil,
                resolver_context.component,
                part,
                property_name,
                resolver_context.variant
            )
        end

        local defaults_layer = {
            aggregate = resolve_token_value(
                resolver_context.defaults,
                resolver_context.component,
                part,
                family.aggregate,
                resolver_context.variant
            ),
        }
        for _, property_name in pairs(family.members) do
            defaults_layer[property_name] = resolve_token_value(
                resolver_context.defaults,
                resolver_context.component,
                part,
                property_name,
                resolver_context.variant
            )
        end

        resolved = resolve_quad_family_from_layers(node, family, {
            direct_layer,
            override_layer,
            skin_layer,
            theme_layer,
            defaults_layer,
        })

        if resolved ~= nil then
            for property_name, value in pairs(resolved) do
                props[property_name] = value
            end
        end
    end

    return props
end

function Styling.assemble_props(node, resolver_context)
    resolver_context = normalize_resolver_context(node, resolver_context)

    if Types.is_table(resolver_context) then
        if resolver_context.component ~= nil and resolver_context.part ~= nil then
            return resolve_contextual_props(node, resolver_context)
        end
    end

    local skin = node.skin
    local props = {}
    for _, key in ipairs(StylingContract.ROOT_PROPERTY_KEYS) do
        if QUAD_PROPERTY_KEYS[key] then
            goto continue
        end

        local v = node[key]
        if v == nil then
            v = resolve_root_skin_value(skin, key)
        end
        props[key] = normalize_styling_value(key, v, node)

        ::continue::
    end

    for _, family in pairs(QUAD_FAMILIES) do
        local direct_layer = {
            aggregate = node[family.aggregate],
        }
        for _, property_name in pairs(family.members) do
            direct_layer[property_name] = node[property_name]
        end

        local skin_layer = {
            aggregate = resolve_root_skin_value(skin, family.aggregate),
        }
        for _, property_name in pairs(family.members) do
            skin_layer[property_name] = resolve_root_skin_value(skin, property_name)
        end

        local resolved = resolve_quad_family_from_layers(node, family, {
            direct_layer,
            skin_layer,
        })

        if resolved ~= nil then
            for property_name, value in pairs(resolved) do
                props[property_name] = value
            end
        end
    end

    return props
end

return Styling
