local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')

local SideQuad = {}

local MEMBERS = { 'top', 'right', 'bottom', 'left' }

local function build(values, opts)
    opts = opts or {}

    if Types.is_function(opts.factory) then
        return opts.factory(values.top, values.right, values.bottom, values.left)
    end

    return {
        top = values.top,
        right = values.right,
        bottom = values.bottom,
        left = values.left,
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
    local members = {}

    if value.top ~= nil or value.right ~= nil or value.bottom ~= nil or value.left ~= nil then
        members.top = validate_member((opts.label or 'side quad') .. '.top', value.top or 0, opts, level)
        members.right = validate_member((opts.label or 'side quad') .. '.right', value.right or 0, opts, level)
        members.bottom = validate_member((opts.label or 'side quad') .. '.bottom', value.bottom or 0, opts, level)
        members.left = validate_member((opts.label or 'side quad') .. '.left', value.left or 0, opts, level)
        return build(members, opts)
    end

    if #value == 2 then
        local vertical = validate_member((opts.label or 'side quad') .. '[1]', value[1], opts, level)
        local horizontal = validate_member((opts.label or 'side quad') .. '[2]', value[2], opts, level)
        return build({
            top = vertical,
            right = horizontal,
            bottom = vertical,
            left = horizontal,
        }, opts)
    end

    if #value == 4 then
        return build({
            top = validate_member((opts.label or 'side quad') .. '[1]', value[1], opts, level),
            right = validate_member((opts.label or 'side quad') .. '[2]', value[2], opts, level),
            bottom = validate_member((opts.label or 'side quad') .. '[3]', value[3], opts, level),
            left = validate_member((opts.label or 'side quad') .. '[4]', value[4], opts, level),
        }, opts)
    end

    Assert.fail((opts.label or 'side quad') ..
        ' must be a number, a keyed table, or contain 2 or 4 values', level or 1)
end

function SideQuad.normalize(value, opts, level)
    opts = opts or {}
    level = (level or 1) + 1

    if value == nil then
        return build({ top = 0, right = 0, bottom = 0, left = 0 }, opts)
    end

    if Types.is_number(value) then
        local resolved = validate_member(opts.label or 'side quad', value, opts, level)
        return build({
            top = resolved,
            right = resolved,
            bottom = resolved,
            left = resolved,
        }, opts)
    end

    if Types.is_table(value) then
        return normalize_table(value, opts, level)
    end

    Assert.fail((opts.label or 'side quad') .. ' must be nil, a number, or a table', level)
end

function SideQuad.resolve_layers(layers, opts, level)
    opts = opts or {}
    level = (level or 1) + 1

    local resolved = {}
    local has_any = false

    for index = 1, #layers do
        local layer = layers[index]
        if Types.is_table(layer) then
            local aggregate = nil
            if layer.aggregate ~= nil then
                aggregate = SideQuad.normalize(layer.aggregate, opts, level)
            end

            for member_index = 1, #MEMBERS do
                local member = MEMBERS[member_index]
                if resolved[member] == nil then
                    local explicit = layer[member]
                    if explicit ~= nil then
                        resolved[member] = validate_member((opts.label or 'side quad') .. '.' .. member, explicit, opts, level)
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
            resolved[member] = validate_member((opts.label or 'side quad') .. '.' .. member, 0, opts, level)
        end
    end

    return build(resolved, opts)
end

return SideQuad
