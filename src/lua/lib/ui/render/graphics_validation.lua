local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')
local Color = require('lib.ui.render.color')
local Texture = require('lib.ui.graphics.texture')
local Sprite = require('lib.ui.graphics.sprite')
local Enums = require('lib.ui.core.enums')
local Enum = require('lib.ui.utils.enum')

local GraphicsValidation = {}

local enum_has = Enum.enum_has

GraphicsValidation.ROOT_OPACITY_DEFAULT = 1
GraphicsValidation.ROOT_BLEND_MODE_DEFAULT = Enums.BlendMode.NORMAL
GraphicsValidation.ROOT_BLEND_MODE_VALUES = Enums.BlendMode
GraphicsValidation.SOURCE_ALIGN_VALUES = Enums.SourceAlign

local function validate_enum(key, value, allowed, level)
    if enum_has(allowed, value) then return value end

    Assert.fail(
        key .. ": '" .. tostring(value) .. "' is not a valid value — accepted: " .. table.concat(allowed, ', '),
        level or 1
    )
end

local function check_finite_number(key, value, level)
    Assert.number(key, value, level or 1)
    Assert.finite(key, value, level or 1)
    return value
end

function GraphicsValidation.validate_opacity(key, value, _, level)
    check_finite_number(key, value, level)

    if value < 0 or value > 1 then
        Assert.fail(key .. ' must be in [0, 1], got ' .. value, level or 1)
    end

    return value
end

function GraphicsValidation.validate_root_opacity(key, value, ctx, level)
    return GraphicsValidation.validate_opacity(key, value, ctx, level)
end

function GraphicsValidation.validate_root_shader(key, value, _, level)
    if not (Types.is_table(value) or Types.is_userdata(value)) then
        Assert.fail(
            key .. ' must be a shader object reference (table or userdata)',
            level or 1
        )
    end

    return value
end

function GraphicsValidation.validate_root_blend_mode(key, value, _, level)
    return validate_enum(key, value, GraphicsValidation.ROOT_BLEND_MODE_VALUES, level)
end

function GraphicsValidation.normalize_root_compositing_state(state)
    state = state or {}

    return {
        opacity = state.opacity ~= nil and state.opacity or GraphicsValidation.ROOT_OPACITY_DEFAULT,
        shader = state.shader,
        blendMode = state.blendMode or GraphicsValidation.ROOT_BLEND_MODE_DEFAULT,
    }
end

function GraphicsValidation.is_default_root_compositing_state(state)
    state = GraphicsValidation.normalize_root_compositing_state(state)

    return state.opacity == GraphicsValidation.ROOT_OPACITY_DEFAULT and
        state.shader == nil and
        state.blendMode == GraphicsValidation.ROOT_BLEND_MODE_DEFAULT
end

function GraphicsValidation.validate_numeric_offset(key, value, _, level)
    return check_finite_number(key, value, level)
end

function GraphicsValidation.validate_source_align(key, value, _, level)
    return validate_enum(key, value, GraphicsValidation.SOURCE_ALIGN_VALUES, level)
end

function GraphicsValidation.validate_gradient(key, value, _, level)
    if not Types.is_table(value) then
        Assert.fail(key .. ' must be a table', level or 1)
    end

    if value.kind ~= 'linear' then
        Assert.fail(key .. '.kind must be "linear"', level or 1)
    end

    if not enum_has(Enums.Orientation, value.direction) then
        Assert.fail(key .. '.direction must be "horizontal" or "vertical"', level or 1)
    end

    if not Types.is_table(value.colors) then
        Assert.fail(key .. '.colors must be a table', level or 1)
    end

    if #value.colors < 2 then
        Assert.fail(key .. '.colors must contain at least two color inputs', level or 1)
    end

    local resolved_colors = {}
    for index = 1, #value.colors do
        resolved_colors[index] = Color.resolve(value.colors[index])
    end

    return {
        kind = value.kind,
        direction = value.direction,
        colors = resolved_colors,
    }
end

function GraphicsValidation.validate_texture_or_sprite_source(key, value, _, level)
    local Image = require('lib.ui.graphics.image')

    if Types.is_instance(value, Image) then
        Assert.fail(
            key .. ': Image component is not a valid source — use Texture or Sprite',
            level or 1
        )
    end

    if not (Types.is_instance(value, Texture) or Types.is_instance(value, Sprite)) then
        Assert.fail(key .. ' must be a Texture or Sprite instance', level or 1)
    end

    return value
end

return GraphicsValidation
