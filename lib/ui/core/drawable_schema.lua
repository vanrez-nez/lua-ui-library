local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')
local SideQuad = require('lib.ui.core.side_quad')
local CornerQuad = require('lib.ui.core.corner_quad')
local Motion = require('lib.ui.motion')
local Color = require('lib.ui.render.color')
local GraphicsValidation = require('lib.ui.render.graphics_validation')
local SpacingSchema = require('lib.ui.core.spacing_schema')

local ALIGNMENT_VALUES = {
    start = true,
    center = true,
    ['end'] = true,
    stretch = true,
}

local function validate_alignment(key, value, ctx, level)
    if not Types.is_string(value) or not ALIGNMENT_VALUES[value] then
        Assert.fail(
            'Drawable.' .. key .. ' must be "start", "center", "end", or "stretch"',
            level or 1
        )
    end
    return value
end

-- Shared validator helpers (phase 12, task 04)

local function resolve_color(key, value, level)
    -- Hard failure propagates from Color.resolve unchanged
    return Color.resolve(value)
end

local check_finite_number = SpacingSchema.check_finite_number

local function check_opacity(key, value, level)
    return GraphicsValidation.validate_opacity(key, value, nil, level)
end

local function check_non_negative(key, value, level)
    check_finite_number(key, value, level)
    if value < 0 then
        Assert.fail(key .. ' must be >= 0, got ' .. value, level or 1)
    end
    return value
end

local function check_numeric(key, value, level)
    return GraphicsValidation.validate_numeric_offset(key, value, nil, level)
end

local function check_enum(key, value, allowed, level)
    for _, v in ipairs(allowed) do
        if value == v then return value end
    end
    local allowed_str = table.concat(allowed, ', ')
    Assert.fail(
        key .. ": '" .. tostring(value) .. "' is not a valid value — accepted: " .. allowed_str,
        level or 1
    )
end

local DRAWABLE_SCHEMA = {
    padding = { validate = function(key, value, ctx, level)
        return SpacingSchema.normalize_padding(key, value, level)
    end, default = 0 },
    paddingTop = { validate = function(key, value, ctx, level)
        return check_non_negative(key, value, level)
    end },
    paddingRight = { validate = function(key, value, ctx, level)
        return check_non_negative(key, value, level)
    end },
    paddingBottom = { validate = function(key, value, ctx, level)
        return check_non_negative(key, value, level)
    end },
    paddingLeft = { validate = function(key, value, ctx, level)
        return check_non_negative(key, value, level)
    end },
    margin = { validate = function(key, value, ctx, level)
        return SpacingSchema.normalize_margin(key, value, level)
    end, default = 0 },
    marginTop = { validate = function(key, value, ctx, level)
        return check_finite_number(key, value, level)
    end },
    marginRight = { validate = function(key, value, ctx, level)
        return check_finite_number(key, value, level)
    end },
    marginBottom = { validate = function(key, value, ctx, level)
        return check_finite_number(key, value, level)
    end },
    marginLeft = { validate = function(key, value, ctx, level)
        return check_finite_number(key, value, level)
    end },
    alignX = { validate = validate_alignment, default = 'start' },
    alignY = { validate = validate_alignment, default = 'start' },
    skin = { type = 'table' },
    shader = { validate = GraphicsValidation.validate_root_shader },
    opacity = {
        validate = GraphicsValidation.validate_root_opacity,
        default = GraphicsValidation.ROOT_OPACITY_DEFAULT,
    },
    blendMode = {
        validate = GraphicsValidation.validate_root_blend_mode,
        default = GraphicsValidation.ROOT_BLEND_MODE_DEFAULT,
    },
    mask = { type = 'table' },
    motionPreset = { validate = Motion.validate_motion_preset },
    motion = { validate = Motion.validate_motion },

    -- background
    backgroundColor = { validate = function(key, value, ctx, level)
        return resolve_color(key, value, level)
    end },
    backgroundOpacity = { validate = function(key, value, ctx, level)
        return check_opacity(key, value, level)
    end },
    backgroundGradient = { validate = GraphicsValidation.validate_gradient },
    backgroundImage = { validate = GraphicsValidation.validate_texture_or_sprite_source },
    backgroundRepeatX = { type = 'boolean' },
    backgroundRepeatY = { type = 'boolean' },
    backgroundOffsetX = { validate = GraphicsValidation.validate_numeric_offset },
    backgroundOffsetY = { validate = GraphicsValidation.validate_numeric_offset },
    backgroundAlignX = { validate = GraphicsValidation.validate_source_align },
    backgroundAlignY = { validate = GraphicsValidation.validate_source_align },

    -- border
    borderColor = { validate = function(key, value, ctx, level)
        return resolve_color(key, value, level)
    end },
    borderOpacity = { validate = function(key, value, ctx, level)
        return check_opacity(key, value, level)
    end },
    borderWidth = { validate = function(key, value, ctx, level)
        return SideQuad.normalize(value, {
            label = key,
            validate_member = check_non_negative,
        }, level)
    end },
    borderWidthTop = { validate = function(key, value, ctx, level)
        return check_non_negative(key, value, level)
    end },
    borderWidthRight = { validate = function(key, value, ctx, level)
        return check_non_negative(key, value, level)
    end },
    borderWidthBottom = { validate = function(key, value, ctx, level)
        return check_non_negative(key, value, level)
    end },
    borderWidthLeft = { validate = function(key, value, ctx, level)
        return check_non_negative(key, value, level)
    end },
    borderStyle = { validate = function(key, value, ctx, level)
        return check_enum(key, value, { 'smooth', 'rough' }, level)
    end },
    borderJoin = { validate = function(key, value, ctx, level)
        return check_enum(key, value, { 'none', 'miter', 'bevel' }, level)
    end },
    borderMiterLimit = { validate = function(key, value, ctx, level)
        check_finite_number(key, value, level)
        if value <= 0 then
            Assert.fail(key .. ' must be > 0, got ' .. value, level or 1)
        end
        return value
    end },
    borderPattern = { validate = function(key, value, ctx, level)
        return check_enum(key, value, { 'solid', 'dashed' }, level)
    end },
    borderDashLength = { validate = function(key, value, ctx, level)
        check_finite_number(key, value, level)
        if value <= 0 then
            Assert.fail(key .. ' must be > 0, got ' .. value, level or 1)
        end
        if value > 255 then
            Assert.fail(key .. ' must be <= 255, got ' .. value, level or 1)
        end
        return value
    end },
    borderGapLength = { validate = function(key, value, ctx, level)
        check_finite_number(key, value, level)
        if value < 0 then
            Assert.fail(key .. ' must be >= 0, got ' .. value, level or 1)
        end
        if value > 255 then
            Assert.fail(key .. ' must be <= 255, got ' .. value, level or 1)
        end
        return value
    end },
    borderDashOffset = { validate = function(key, value, ctx, level)
        check_finite_number(key, value, level)
        return value
    end },

    -- corner radius
    cornerRadius = { validate = function(key, value, ctx, level)
        return CornerQuad.normalize(value, {
            label = key,
            validate_member = check_non_negative,
        }, level)
    end },
    cornerRadiusTopLeft = { validate = function(key, value, ctx, level)
        return check_non_negative(key, value, level)
    end },
    cornerRadiusTopRight = { validate = function(key, value, ctx, level)
        return check_non_negative(key, value, level)
    end },
    cornerRadiusBottomRight = { validate = function(key, value, ctx, level)
        return check_non_negative(key, value, level)
    end },
    cornerRadiusBottomLeft = { validate = function(key, value, ctx, level)
        return check_non_negative(key, value, level)
    end },

    -- shadow
    shadowColor = { validate = function(key, value, ctx, level)
        return resolve_color(key, value, level)
    end },
    shadowOpacity = { validate = function(key, value, ctx, level)
        return check_opacity(key, value, level)
    end },
    shadowOffsetX = { validate = function(key, value, ctx, level)
        return check_numeric(key, value, level)
    end },
    shadowOffsetY = { validate = function(key, value, ctx, level)
        return check_numeric(key, value, level)
    end },
    shadowBlur = { validate = function(key, value, ctx, level)
        return check_non_negative(key, value, level)
    end },
    shadowInset = { type = 'boolean' },
}

return DRAWABLE_SCHEMA
