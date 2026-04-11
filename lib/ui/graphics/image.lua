local Drawable = require('lib.ui.core.drawable')
local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')
local Rectangle = require('lib.ui.core.rectangle')
local Texture = require('lib.ui.graphics.texture')
local Sprite = require('lib.ui.graphics.sprite')
local ControlUtils = require('lib.ui.controls.control_utils')
local Utils = require('lib.ui.utils.common')

local Image = Drawable:extends('Image')

local function validate_source(_, value, _, level)
    if Types.is_instance(value, Texture) or Types.is_instance(value, Sprite) then
        return value
    end

    Assert.fail('Image.source must be a Texture or Sprite', level or 1)
end

local function validate_enum(name, allowed)
    return function(_, value, _, level)
        if not Types.is_string(value) or not allowed[value] then
            Assert.fail(name .. ' is invalid', level or 1)
        end
        return value
    end
end

Image._schema = Utils.merge_tables(Utils.copy_table(Drawable._schema), {
    source = { validate = validate_source, required = true },
    fit = {
        validate = validate_enum('Image.fit', {
            contain = true,
            cover = true,
            stretch = true,
            none = true,
        }),
        default = 'contain',
    },
    alignX = {
        validate = validate_enum('Image.alignX', {
            start = true,
            center = true,
            ['end'] = true,
        }),
        default = 'center',
    },
    alignY = {
        validate = validate_enum('Image.alignY', {
            start = true,
            center = true,
            ['end'] = true,
        }),
        default = 'center',
    },
    sampling = {
        validate = validate_enum('Image.sampling', {
            nearest = true,
            linear = true,
        }),
        default = 'linear',
    },
    decorative = { type = 'boolean', default = false },
    accessibleName = { type = 'string' },
})

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

local function resolve_axis(origin, available, content, align)
    if align == 'center' then
        return origin + ((available - content) * 0.5)
    end

    if align == 'end' then
        return origin + (available - content)
    end

    return origin
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

    rawset(self, '_ui_image_control', true)
    rawset(self, 'root', self)
    rawset(self, 'content', self)
end

function Image.new(opts)
    return Image(opts)
end

function Image:addChild()
    Assert.fail('Image may not contain child nodes', 2)
end

function Image:removeChild()
    Assert.fail('Image may not contain child nodes', 2)
end

function Image:getIntrinsicSize()
    local texture, region = resolve_source_view(self.source)
    return texture:getWidth(), texture:getHeight(), region
end

function Image:resolveImageRect(content)
    content = content or self:getContentRect()
    local _, _, region = self:getIntrinsicSize()
    local source_width = region.width
    local source_height = region.height
    local fit = self.fit
    local draw_width = source_width
    local draw_height = source_height

    if fit == 'stretch' then
        draw_width = content.width
        draw_height = content.height
    elseif fit == 'contain' or fit == 'cover' then
        if source_width > 0 and source_height > 0 and content.width > 0 and content.height > 0 then
            local scale_x = content.width / source_width
            local scale_y = content.height / source_height
            local scale = fit == 'cover' and math.max(scale_x, scale_y) or math.min(scale_x, scale_y)
            draw_width = source_width * scale
            draw_height = source_height * scale
        end
    end

    return Rectangle(
        resolve_axis(content.x, content.width, draw_width, self.alignX),
        resolve_axis(content.y, content.height, draw_height, self.alignY),
        draw_width,
        draw_height
    ), region
end

function Image:_draw_control(graphics)
    if graphics == nil or not Types.is_function(graphics.draw) then
        return
    end

    local source = self.source
    local texture, region = resolve_source_view(source)
    local drawable = texture:getDrawable()
    if drawable == nil then
        return
    end

    local effective_values = rawget(self, '_effective_values') or {}
    local world_content = self:getWorldBounds():inset(effective_values.padding or 0)
    local draw_rect, resolved_region = self:resolveImageRect(world_content)
    local quad = nil
    local previous_scissor = nil
    local apply_cover_clip = self.fit == 'cover' and Types.is_function(graphics.setScissor)

    if love ~= nil and love.graphics ~= nil and Types.is_function(love.graphics.newQuad) then
        quad = love.graphics.newQuad(
            resolved_region.x,
            resolved_region.y,
            resolved_region.width,
            resolved_region.height,
            texture:getWidth(),
            texture:getHeight()
        )
    end

    if Types.is_function(drawable.setFilter) then
        drawable:setFilter(self.sampling, self.sampling)
    end

    local scale_x = resolved_region.width == 0 and 1 or (draw_rect.width / resolved_region.width)
    local scale_y = resolved_region.height == 0 and 1 or (draw_rect.height / resolved_region.height)

    if apply_cover_clip then
        if Types.is_function(graphics.getScissor) then
            previous_scissor = { graphics.getScissor() }
        end
        graphics.setScissor(world_content.x, world_content.y, world_content.width, world_content.height)
    end

    if quad ~= nil then
        graphics.draw(drawable, quad, draw_rect.x, draw_rect.y, 0, scale_x, scale_y)
    else
        graphics.draw(drawable, draw_rect.x, draw_rect.y, 0, scale_x, scale_y)
    end

    if apply_cover_clip then
        if previous_scissor ~= nil and previous_scissor[1] ~= nil then
            graphics.setScissor(previous_scissor[1], previous_scissor[2], previous_scissor[3], previous_scissor[4])
        else
            graphics.setScissor()
        end
    end
end

return Image
