local Drawable = require('lib.ui.core.drawable')
local Container = require('lib.ui.core.container')
local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')
local Rectangle = require('lib.ui.core.rectangle')
local Texture = require('lib.ui.graphics.texture')
local ControlUtils = require('lib.ui.controls.control_utils')
local Schema = require('lib.ui.utils.schema')
local Constants = require('lib.ui.core.constants')
local Enum = require('lib.ui.utils.enum')
local ImageSchema = require('lib.ui.graphics.image_schema')

local Image = Drawable:extends('Image')
local max = math.max
local min = math.min
local enum = Enum.enum

Image.FIT_CONTAIN = 'contain'
Image.FIT_COVER = 'cover'
Image.FIT_STRETCH = 'stretch'
Image.FIT_NONE = 'none'
Image.SAMPLING_NEAREST = 'nearest'
Image.SAMPLING_LINEAR = 'linear'

Image.Fit = enum(
    { CONTAIN = Image.FIT_CONTAIN },
    { COVER = Image.FIT_COVER },
    { STRETCH = Image.FIT_STRETCH },
    { NONE = Image.FIT_NONE }
)
Image.Align = enum(
    { START = Constants.ALIGN_START },
    { CENTER = Constants.ALIGN_CENTER },
    { END = Constants.ALIGN_END }
)
Image.Sampling = enum(
    { NEAREST = Image.SAMPLING_NEAREST },
    { LINEAR = Image.SAMPLING_LINEAR }
)

Image.schema = Schema.extend(Drawable.schema, ImageSchema)

local function resolve_source_view(source)
    if Types.is_instance(source, Texture) then
        return source, {
            x = 0,
            y = 0,
            width = source:getWidth(),
            height = source:getHeight(),
        }
    end

    return source:getTexture(), source:getRegion()
end

local function resolve_source_metrics(source)
    if Types.is_instance(source, Texture) then
        return source, 0, 0, source:getWidth(), source:getHeight()
    end

    local region = source.getRegionRef and source:getRegionRef() or source:getRegion()
    local texture = source:getTexture()

    return texture, region.x, region.y, region.width, region.height
end

local function resolve_axis(origin, available, content, align)
    if align == Constants.ALIGN_CENTER then
        return origin + ((available - content) * 0.5)
    end

    if align == Constants.ALIGN_END then
        return origin + (available - content)
    end

    return origin
end

local function resolve_padding_edges(padding)
    if padding == nil then
        return 0, 0, 0, 0
    end

    if Types.is_number(padding) then
        return padding, padding, padding, padding
    end

    return padding.left or 0, padding.top or 0, padding.right or 0, padding.bottom or 0
end

local function resolve_draw_geometry(
    self,
    content_x,
    content_y,
    content_width,
    content_height,
    source_width,
    source_height
)
    local fit = self.fit
    local draw_width = source_width
    local draw_height = source_height

    if fit == Image.Fit.STRETCH then
        draw_width = content_width
        draw_height = content_height
    elseif fit == 'contain' or fit == 'cover' then
        if source_width > 0 and source_height > 0 and content_width > 0 and content_height > 0 then
            local scale_x = content_width / source_width
            local scale_y = content_height / source_height
            local scale = fit == 'cover' and max(scale_x, scale_y) or min(scale_x, scale_y)
            draw_width = source_width * scale
            draw_height = source_height * scale
        end
    end

    return
        resolve_axis(content_x, content_width, draw_width, self.alignX),
        resolve_axis(content_y, content_height, draw_height, self.alignY),
        draw_width,
        draw_height
end

local function resolve_quad(self, texture, region_x, region_y, region_width, region_height)
    if texture == nil then
        return nil
    end

    local texture_width = texture:getWidth()
    local texture_height = texture:getHeight()

    if region_x == 0 and region_y == 0 and region_width == texture_width and region_height == texture_height then
        return nil
    end

    local cached = self._cached_quad
    if cached ~= nil and
        cached.texture == texture and
        cached.x == region_x and
        cached.y == region_y and
        cached.width == region_width and
        cached.height == region_height and
        cached.texture_width == texture_width and
        cached.texture_height == texture_height then
        return cached.quad
    end

    if love == nil or love.graphics == nil or not Types.is_function(love.graphics.newQuad) then
        return nil
    end

    local quad = love.graphics.newQuad(
        region_x,
        region_y,
        region_width,
        region_height,
        texture_width,
        texture_height
    )

    self._cached_quad = {
        texture = texture,
        x = region_x,
        y = region_y,
        width = region_width,
        height = region_height,
        texture_width = texture_width,
        texture_height = texture_height,
        quad = quad,
    }

    return quad
end

local function apply_sampling(texture, drawable, sampling)
    if drawable == nil or not Types.is_function(drawable.setFilter) then
        return
    end

    local applied_sampling = texture._ui_applied_sampling
    if applied_sampling == sampling then
        return
    end

    drawable:setFilter(sampling, sampling)
    texture._ui_applied_sampling = sampling
end

function Image:constructor(opts)
    opts = opts or {}
    local drawable_opts = ControlUtils.base_opts(opts, {
        interactive = false,
        focusable = false,
    })

    drawable_opts.source = opts.source
    drawable_opts.fit = opts.fit
    drawable_opts.alignX = opts.alignX
    drawable_opts.alignY = opts.alignY
    drawable_opts.sampling = opts.sampling
    drawable_opts.decorative = opts.decorative
    drawable_opts.accessibleName = opts.accessibleName

    Drawable.constructor(self, drawable_opts)

    self._ui_image_control = true
    self.root = self
    self.content = self
end

function Image.new(opts)
    return Image(opts)
end

function Image.addChild()
    Assert.fail('Image may not contain child nodes', 2)
end

function Image.removeChild()
    Assert.fail('Image may not contain child nodes', 2)
end

function Image:getIntrinsicSize()
    local texture, region = resolve_source_view(self.source)
    return texture:getWidth(), texture:getHeight(), region
end

function Image:resolveImageRect(content)
    content = content or self:getContentRect()
    local _, _, region = self:getIntrinsicSize()
    local draw_x, draw_y, draw_width, draw_height = resolve_draw_geometry(
        self,
        content.x,
        content.y,
        content.width,
        content.height,
        region.width,
        region.height
    )

    return Rectangle(
        draw_x,
        draw_y,
        draw_width,
        draw_height
    ), region
end

function Image.draw()
    -- Image is a closed graphics primitive. It does not expose Drawable styling
    -- surfaces such as background, border, corner radius, or shadow.
end

function Image:update(dt)
    local root = self._attachment_root

    if root ~= nil and root._ui_stage_instance == true and root._updating == true then
        self:_refresh_if_dirty()
        return self
    end

    return Container.update(self, dt)
end

function Image:_draw_control(graphics)
    if graphics == nil or not Types.is_function(graphics.draw) then
        return
    end

    local source = self.source
    local texture, region_x, region_y, region_width, region_height = resolve_source_metrics(source)
    local drawable = texture:getDrawable()
    if drawable == nil then
        return
    end

    local effective_values = self._effective_values
    local padding_left, padding_top, padding_right, padding_bottom = resolve_padding_edges(effective_values.padding)
    local world_bounds = self:getWorldBounds()
    local content_x = world_bounds.x + padding_left
    local content_y = world_bounds.y + padding_top
    local content_width = max(0, world_bounds.width - padding_left - padding_right)
    local content_height = max(0, world_bounds.height - padding_top - padding_bottom)
    local draw_x, draw_y, draw_width, draw_height = resolve_draw_geometry(
        self,
        content_x,
        content_y,
        content_width,
        content_height,
        region_width,
        region_height
    )
    local quad = resolve_quad(self, texture, region_x, region_y, region_width, region_height)
    local previous_scissor_x = nil
    local previous_scissor_y = nil
    local previous_scissor_width = nil
    local previous_scissor_height = nil
    local apply_cover_clip = self.fit == Image.Fit.COVER and Types.is_function(graphics.setScissor)
    local scale_x = region_width == 0 and 1 or (draw_width / region_width)
    local scale_y = region_height == 0 and 1 or (draw_height / region_height)

    apply_sampling(texture, drawable, self.sampling)

    if apply_cover_clip then
        if Types.is_function(graphics.getScissor) then
            previous_scissor_x, previous_scissor_y, previous_scissor_width, previous_scissor_height =
                graphics.getScissor()
        end
        graphics.setScissor(content_x, content_y, content_width, content_height)
    end

    if quad ~= nil then
        graphics.draw(drawable, quad, draw_x, draw_y, 0, scale_x, scale_y)
    else
        graphics.draw(drawable, draw_x, draw_y, 0, scale_x, scale_y)
    end

    if apply_cover_clip then
        if previous_scissor_x ~= nil then
            graphics.setScissor(
                previous_scissor_x,
                previous_scissor_y,
                previous_scissor_width,
                previous_scissor_height
            )
        else
            graphics.setScissor()
        end
    end
end

return Image
