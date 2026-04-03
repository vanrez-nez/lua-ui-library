local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')
local CanvasPool = require('lib.ui.render.canvas_pool')

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
    if Types.is_function(graphics.getStencilTest) then
        return { graphics.getStencilTest() }
    end
    return nil
end

local function restore_stencil(graphics, saved)
    if not Types.is_function(graphics.setStencilTest) then return end
    if saved == nil or saved[1] == nil then
        graphics.setStencilTest()
    else
        graphics.setStencilTest(saved[1], saved[2])
    end
end

local function save_line_state(graphics)
    local s = {}
    if Types.is_function(graphics.getLineWidth)  then s.width  = graphics.getLineWidth()  end
    if Types.is_function(graphics.getLineStyle)  then s.style  = graphics.getLineStyle()  end
    if Types.is_function(graphics.getLineJoin)   then s.join   = graphics.getLineJoin()   end
    if Types.is_function(graphics.getMiterLimit) then s.miter  = graphics.getMiterLimit() end
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
    if Types.is_function(graphics.stencil) and Types.is_function(graphics.polygon) then
        graphics.stencil(function()
            graphics.polygon('fill', pts)
        end, 'replace', 1)
    end
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

local function get_source_dims(img)
    local iw, ih = 0, 0
    if Types.is_function(img.getWidth)  then
        local ok, v = pcall(img.getWidth, img)
        if ok and Types.is_number(v) then iw = v end
    end
    if Types.is_function(img.getHeight) then
        local ok, v = pcall(img.getHeight, img)
        if ok and Types.is_number(v) then ih = v end
    end
    if iw == 0 and Types.is_number(rawget(img, 'width'))  then iw = img.width  end
    if ih == 0 and Types.is_number(rawget(img, 'height')) then ih = img.height end
    return iw, ih
end

local function paint_background_image(props, bounds, graphics, radii)
    local img = props.backgroundImage
    local opacity = props.backgroundOpacity or 1
    if opacity <= 0 then return end

    local src_w, src_h = get_source_dims(img)
    if src_w <= 0 or src_h <= 0 then return end
    if not Types.is_function(graphics.draw) then return end

    local align_x = props.backgroundAlignX or 'start'
    local align_y = props.backgroundAlignY or 'start'
    local off_x   = props.backgroundOffsetX or 0
    local off_y   = props.backgroundOffsetY or 0
    local rep_x   = props.backgroundRepeatX or false
    local rep_y   = props.backgroundRepeatY or false

    local base_x
    if align_x == 'center' then
        base_x = bounds.x + (bounds.width - src_w) / 2
    elseif align_x == 'end' then
        base_x = bounds.x + bounds.width - src_w
    else
        base_x = bounds.x
    end

    local base_y
    if align_y == 'center' then
        base_y = bounds.y + (bounds.height - src_h) / 2
    elseif align_y == 'end' then
        base_y = bounds.y + bounds.height - src_h
    else
        base_y = bounds.y
    end

    base_x = base_x + off_x
    base_y = base_y + off_y

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
            graphics.draw(img, ix, iy)
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

local function apply_border_line_state(props, graphics)
    local style = props.borderStyle
    local join  = props.borderJoin
    local miter = props.borderMiterLimit

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

    local a = c[4] * (props.borderOpacity or 1)
    local saved_color = save_color(graphics)
    local saved_line  = save_line_state(graphics)

    if Types.is_function(graphics.setColor) then
        graphics.setColor(c[1], c[2], c[3], a)
    end
    apply_border_line_state(props, graphics)

    local x, y, w, h = bounds.x, bounds.y, bounds.width, bounds.height

    if wt == wr and wr == wb and wb == wl and wt > 0 then
        -- Uniform width — single rounded-rectangle stroke.
        if Types.is_function(graphics.setLineWidth) then graphics.setLineWidth(wt) end
        local pts = rounded_rect_points(x, y, w, h, radii)
        if Types.is_function(graphics.polygon) then
            graphics.polygon('line', pts)
        end
    else
        -- Per-side — draw each side and corner independently.
        local pi = math.pi
        local function draw_side_line(lw, x1, y1, x2, y2)
            if lw <= 0 then return end
            if Types.is_function(graphics.setLineWidth) then graphics.setLineWidth(lw) end
            if Types.is_function(graphics.line) then
                graphics.line(x1, y1, x2, y2)
            end
        end
        local function draw_corner_arc(lw, cx, cy, r, a1, a2)
            if lw <= 0 or r <= 0 then return end
            if Types.is_function(graphics.setLineWidth) then graphics.setLineWidth(lw) end
            if Types.is_function(graphics.arc) then
                graphics.arc('line', cx, cy, r, a1, a2)
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

    local saved_stencil = save_stencil(graphics)
    local inner_pts = rounded_rect_points(inner_x, inner_y, inner_w, inner_h, radii)

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
            c[1], c[2], c[3], final_alpha, radii)
        restore_color(graphics, saved)
    else
        local margin = math.ceil(blur)
        render_shadow_soft(
            graphics, c, final_alpha, blur,
            margin, margin, inner_w, inner_h, radii,
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
-- STYLING_KEYS — all 29 flat styling property names introduced in Phase 12.
-- Ordered by property group: background, border, corner radius, shadow.
-- ---------------------------------------------------------------------------

local STYLING_KEYS = {
    -- background (10)
    'backgroundColor', 'backgroundOpacity', 'backgroundGradient', 'backgroundImage',
    'backgroundRepeatX', 'backgroundRepeatY', 'backgroundOffsetX', 'backgroundOffsetY',
    'backgroundAlignX', 'backgroundAlignY',
    -- border (9)
    'borderColor', 'borderOpacity', 'borderWidthTop', 'borderWidthRight',
    'borderWidthBottom', 'borderWidthLeft', 'borderStyle', 'borderJoin', 'borderMiterLimit',
    -- corner radius (4)
    'cornerRadiusTopLeft', 'cornerRadiusTopRight', 'cornerRadiusBottomRight', 'cornerRadiusBottomLeft',
    -- shadow (6)
    'shadowColor', 'shadowOpacity', 'shadowOffsetX', 'shadowOffsetY', 'shadowBlur', 'shadowInset',
}

-- ---------------------------------------------------------------------------
-- Styling.assemble_props — build a resolved props table for Styling.draw.
--
-- Resolution cascade (spec §4B):
--   1. Node instance property  (node[key] via __index / _public_values)
--   2. Node skin table         (node.skin[key] if node.skin is set)
--   3. nil                     (no styling tokens are defined in the defaults)
--
-- Boolean keys (backgroundRepeatX, backgroundRepeatY, shadowInset) are handled
-- with an explicit nil check so that `false` is not treated as absent and does
-- not fall through to the next resolution tier.
-- ---------------------------------------------------------------------------

function Styling.assemble_props(node, resolver_context)
    local skin = node.skin
    local props = {}
    for _, key in ipairs(STYLING_KEYS) do
        local v = node[key]
        if v == nil and skin ~= nil then
            v = skin[key]
        end
        props[key] = v
    end
    return props
end

return Styling
