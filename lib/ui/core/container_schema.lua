local Assert = require('lib.ui.utils.assert')
local Schema = require('lib.ui.utils.schema')
local Motion = require('lib.ui.motion')

local function validate_container_size(key, value, ctx, level)
    local prop_name = key:match("%.([^%.]+)$") or key
    return Schema.validate_size(key, value, ctx._config['allow_content_' .. prop_name] == true, level)
end

local function validate_optional_nonempty_string(key, value, _, level)
    Assert.string(key, value, level)
    if value == '' then
        Assert.fail(key .. ' must not be an empty string', level)
    end
    return value
end

local CONTAINER_SCHEMA = {
    id = { validate = validate_optional_nonempty_string },
    name = { validate = validate_optional_nonempty_string },
    tag = { validate = validate_optional_nonempty_string },
    internal = { type = 'boolean', default = false },
    visible = { type = 'boolean', default = true },
    interactive = { type = 'boolean', default = false },
    enabled = { type = 'boolean', default = true },
    focusable = { type = 'boolean', default = false },
    clipChildren = { type = 'boolean', default = false },
    zIndex = { type = 'number', default = 0 },
    anchorX = { type = 'number', default = 0 },
    anchorY = { type = 'number', default = 0 },
    pivotX = { type = 'number', default = 0.5 },
    pivotY = { type = 'number', default = 0.5 },
    x = { type = 'number', default = 0 },
    y = { type = 'number', default = 0 },
    width = { validate = validate_container_size, default = 0 },
    height = { validate = validate_container_size, default = 0 },
    minWidth = { type = 'number' },
    minHeight = { type = 'number' },
    maxWidth = { type = 'number' },
    maxHeight = { type = 'number' },
    scaleX = { type = 'number', default = 1 },
    scaleY = { type = 'number', default = 1 },
    rotation = { type = 'number', default = 0 },
    skewX = { type = 'number', default = 0 },
    skewY = { type = 'number', default = 0 },
    breakpoints = { 
        validate = function(key, value, ctx, level, full_opts)
            if value ~= nil then
                Assert.table('Container.breakpoints', value, level)
                local public_values = rawget(ctx, '_public_values')
                local allowed_public_keys = rawget(ctx, '_allowed_public_keys')
                
                local has_responsive = (full_opts and full_opts.responsive ~= nil) or 
                                     (public_values and public_values.responsive ~= nil)

                if allowed_public_keys and allowed_public_keys.responsive and has_responsive then
                    Assert.fail('responsive and breakpoints cannot both be supplied on the same node', level)
                end
            end
            return value
        end
    },
    motionPreset = { validate = Motion.validate_motion_preset },
    motion = { validate = Motion.validate_motion },
}

return CONTAINER_SCHEMA
