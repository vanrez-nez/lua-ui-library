local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')

local CornerQuad = {}

local MEMBERS = { 'topLeft', 'topRight', 'bottomRight', 'bottomLeft' }

local function build(values, opts)
    opts = opts or {}

    if Types.is_function(opts.factory) then
        return opts.factory(values.topLeft, values.topRight, values.bottomRight, values.bottomLeft)
    end

    return {
        topLeft = values.topLeft,
        topRight = values.topRight,
        bottomRight = values.bottomRight,
        bottomLeft = values.bottomLeft,
    }
end

local function validate_member(member_name, value, opts, level)
    if Types.is_function(opts and opts.validate_member) then
        return opts.validate_member(member_name, value, level or 1)
    end

    Assert.number(member_name, value, level or 1)
    return value
end

local function normalize_table(value, opts, level)
    if value.topLeft ~= nil or value.topRight ~= nil or value.bottomRight ~= nil or value.bottomLeft ~= nil then
        return build({
            topLeft = validate_member((opts.label or 'corner quad') .. '.topLeft', value.topLeft or 0, opts, level),
            topRight = validate_member((opts.label or 'corner quad') .. '.topRight', value.topRight or 0, opts, level),
            bottomRight = validate_member((opts.label or 'corner quad') .. '.bottomRight', value.bottomRight or 0, opts, level),
            bottomLeft = validate_member((opts.label or 'corner quad') .. '.bottomLeft', value.bottomLeft or 0, opts, level),
        }, opts)
    end

    if #value == 4 then
        return build({
            topLeft = validate_member((opts.label or 'corner quad') .. '[1]', value[1], opts, level),
            topRight = validate_member((opts.label or 'corner quad') .. '[2]', value[2], opts, level),
            bottomRight = validate_member((opts.label or 'corner quad') .. '[3]', value[3], opts, level),
            bottomLeft = validate_member((opts.label or 'corner quad') .. '[4]', value[4], opts, level),
        }, opts)
    end

    Assert.fail((opts.label or 'corner quad') ..
        ' must be a number, a keyed table, or contain 4 values', level or 1)
end

function CornerQuad.normalize(value, opts, level)
    opts = opts or {}
    level = (level or 1) + 1

    if value == nil then
        return build({ topLeft = 0, topRight = 0, bottomRight = 0, bottomLeft = 0 }, opts)
    end

    if Types.is_number(value) then
        local resolved = validate_member(opts.label or 'corner quad', value, opts, level)
        return build({
            topLeft = resolved,
            topRight = resolved,
            bottomRight = resolved,
            bottomLeft = resolved,
        }, opts)
    end

    if Types.is_table(value) then
        return normalize_table(value, opts, level)
    end

    Assert.fail((opts.label or 'corner quad') .. ' must be nil, a number, or a table', level)
end

function CornerQuad.resolve_layers(layers, opts, level)
    opts = opts or {}
    level = (level or 1) + 1

    local resolved = {}
    local has_any = false

    for index = 1, #layers do
        local layer = layers[index]
        if Types.is_table(layer) then
            local aggregate = nil
            if layer.aggregate ~= nil then
                aggregate = CornerQuad.normalize(layer.aggregate, opts, level)
            end

            for member_index = 1, #MEMBERS do
                local member = MEMBERS[member_index]
                if resolved[member] == nil then
                    local explicit = layer[member]
                    if explicit ~= nil then
                        resolved[member] = validate_member((opts.label or 'corner quad') .. '.' .. member, explicit, opts, level)
                        has_any = true
                    elseif aggregate ~= nil then
                        resolved[member] = aggregate[member]
                        has_any = true
                    end
                end
            end
        end
    end

    if not has_any then
        return nil
    end

    for member_index = 1, #MEMBERS do
        local member = MEMBERS[member_index]
        if resolved[member] == nil then
            resolved[member] = validate_member((opts.label or 'corner quad') .. '.' .. member, 0, opts, level)
        end
    end

    return build(resolved, opts)
end

return CornerQuad
