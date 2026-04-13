local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')
local Easing = require('lib.ui.core.easing')
local Color = require('lib.ui.render.color')
local GraphicsValidation = require('lib.ui.render.graphics_validation')

local Runtime = {}

local SHARED_PROPERTIES = {
    opacity = true,
    blendMode = true,
    shader = true,
    fillColor = true,
    fillOpacity = true,
    fillGradient = true,
    fillTexture = true,
    fillOffsetX = true,
    fillOffsetY = true,
    fillAlignX = true,
    fillAlignY = true,
    translationX = true,
    translationY = true,
    scaleX = true,
    scaleY = true,
    rotation = true,
    color = true,
    shaderParameter = true,
}

local DISCRETE_STEP_PROPERTIES = {
    blendMode = true,
    shader = true,
    fillTexture = true,
    fillAlignX = true,
    fillAlignY = true,
}

local function fail(message, level)
    error(message, (level or 1) + 1)
end

local function validate_easing(value, level)
    if value == nil then
        return value
    end

    if Types.is_string(value) or Types.is_function(value) then
        return value
    end

    fail('motion easing must be a string, function, or nil', level or 1)
end

local function validate_property_rule(name, rule, level)
    if not Types.is_table(rule) then
        fail('motion property "' .. tostring(name) .. '" must be a table', level or 1)
    end

    if rule.duration ~= nil then
        Assert.number('motion property duration', rule.duration, level or 1)
        if rule.duration < 0 then
            fail('motion property duration must be >= 0', level or 1)
        end
    end

    if rule.delay ~= nil then
        Assert.number('motion property delay', rule.delay, level or 1)
        if rule.delay < 0 then
            fail('motion property delay must be >= 0', level or 1)
        end
    end

    validate_easing(rule.easing, level or 1)

    return rule
end

local function validate_properties(properties, level)
    Assert.table('motion properties', properties, level or 1)

    for name, rule in pairs(properties) do
        if not SHARED_PROPERTIES[name] and name ~= 'progress' and
            name ~= 'offset' and name ~= 'placementOffset' then
            fail('unsupported motion property "' .. tostring(name) .. '"', level or 1)
        end

        validate_property_rule(name, rule, level or 1)
    end

    return properties
end

local function validate_descriptor(descriptor, level)
    Assert.table('motion descriptor', descriptor, level or 1)

    if descriptor.target ~= nil and not Types.is_string(descriptor.target) then
        fail('motion descriptor target must be a string or nil', level or 1)
    end

    if descriptor.preset ~= nil and not Types.is_string(descriptor.preset) then
        fail('motion descriptor preset must be a string or nil', level or 1)
    end

    if descriptor.adapter ~= nil and not Types.is_table(descriptor.adapter) and
        not Types.is_function(descriptor.adapter) then
        fail('motion descriptor adapter must be a table, function, or nil', level or 1)
    end

    if descriptor.onStep ~= nil and not Types.is_function(descriptor.onStep) then
        fail('motion descriptor onStep must be a function or nil', level or 1)
    end

    if descriptor.properties ~= nil then
        validate_properties(descriptor.properties, level or 1)
    end

    return descriptor
end

function Runtime.validate_motion_preset(_, value, _, level)
    if value == nil then
        return value
    end

    if Types.is_string(value) then
        return value
    end

    if Types.is_table(value) then
        for phase, preset in pairs(value) do
            if not Types.is_string(phase) or not Types.is_string(preset) then
                fail('motionPreset phase mappings must be string -> string', level or 1)
            end
        end
        return value
    end

    fail('motionPreset must be a string, table, or nil', level or 1)
end

function Runtime.validate_motion(_, value, _, level)
    if value == nil then
        return value
    end

    if not Types.is_table(value) then
        fail('motion must be a table or nil', level or 1)
    end

    local has_descriptor_fields = value.target ~= nil or value.properties ~= nil or
        value.preset ~= nil or value.adapter ~= nil or value.onStep ~= nil

    if has_descriptor_fields then
        return validate_descriptor(value, level or 1)
    end

    for key, entry in pairs(value) do
        if Types.is_table(entry) and (entry.target ~= nil or entry.properties ~= nil or
            entry.preset ~= nil or entry.adapter ~= nil or entry.onStep ~= nil) then
            validate_descriptor(entry, level or 1)
        elseif Types.is_table(entry) then
            for index = 1, #entry do
                validate_descriptor(entry[index], level or 1)
            end
        else
            fail('motion["' .. tostring(key) .. '"] must be a descriptor or descriptor list', level or 1)
        end
    end

    return value
end

local function normalize_descriptors(instance, phase, payload)
    local motion = instance.motion
    local preset = instance.motionPreset
    local descriptors = {}

    if Types.is_table(motion) then
        local by_phase = motion[phase]
        if by_phase ~= nil then
            if by_phase.target ~= nil or by_phase.properties ~= nil or by_phase.preset ~= nil or
                by_phase.adapter ~= nil or by_phase.onStep ~= nil then
                descriptors[1] = by_phase
            else
                for index = 1, #by_phase do
                    descriptors[#descriptors + 1] = by_phase[index]
                end
            end
        elseif motion.target ~= nil or motion.properties ~= nil or motion.preset ~= nil or
            motion.adapter ~= nil or motion.onStep ~= nil then
            descriptors[1] = motion
        end
    end

    local preset_value = nil

    if Types.is_string(preset) then
        preset_value = preset
    elseif Types.is_table(preset) then
        preset_value = preset[phase]
    end

    if #descriptors == 0 and preset_value ~= nil then
        descriptors[1] = {
            target = payload.defaultTarget or 'root',
            preset = preset_value,
        }
    end

    return descriptors
end

local function resolve_easing(rule)
    local easing = rule and rule.easing

    if easing == nil then
        return nil
    end

    if Types.is_function(easing) then
        return easing
    end

    if Types.is_string(easing) and Types.is_function(Easing[easing]) then
        return Easing[easing]
    end

    return nil
end

local function validate_motion_property_value(property_name, value, level)
    if value == nil then
        return value
    end

    if property_name == 'opacity' then
        return GraphicsValidation.validate_root_opacity(property_name, value, nil, level or 1)
    end

    if property_name == 'blendMode' then
        return GraphicsValidation.validate_root_blend_mode(property_name, value, nil, level or 1)
    end

    if property_name == 'shader' then
        return GraphicsValidation.validate_root_shader(property_name, value, nil, level or 1)
    end

    if property_name == 'fillColor' then
        return Color.resolve(value)
    end

    if property_name == 'fillOpacity' then
        return GraphicsValidation.validate_opacity(property_name, value, nil, level or 1)
    end

    if property_name == 'fillGradient' then
        return GraphicsValidation.validate_gradient(property_name, value, nil, level or 1)
    end

    if property_name == 'fillTexture' then
        return GraphicsValidation.validate_texture_or_sprite_source(property_name, value, nil, level or 1)
    end

    if property_name == 'fillOffsetX' or property_name == 'fillOffsetY' then
        return GraphicsValidation.validate_numeric_offset(property_name, value, nil, level or 1)
    end

    if property_name == 'fillAlignX' or property_name == 'fillAlignY' then
        return GraphicsValidation.validate_source_align(property_name, value, nil, level or 1)
    end

    return value
end

local function apply_descriptor(instance, phase, descriptor, payload)
    local target_name = descriptor.target or payload.defaultTarget or 'root'
    local target = instance:_get_motion_surface(target_name)

    if target == nil then
        fail('motion target "' .. tostring(target_name) .. '" is not a documented surface on ' .. tostring(instance), 3)
    end

    if descriptor.properties ~= nil then
        for property_name, rule in pairs(descriptor.properties) do
            if DISCRETE_STEP_PROPERTIES[property_name] then
                local next_value = validate_motion_property_value(
                    property_name,
                    rule.to,
                    3
                )

                if next_value ~= nil then
                    instance:_apply_motion_value(target_name, property_name, next_value)
                end
            else
                local next_value = rule.to
                if next_value == nil then
                    next_value = rule.from
                end

                next_value = validate_motion_property_value(property_name, next_value, 3)
                instance:_apply_motion_value(target_name, property_name, next_value)

                local easing = resolve_easing(rule)
                if easing ~= nil then
                    easing(1)
                end
            end
        end
    end

    if Types.is_function(descriptor.onStep) then
        descriptor.onStep({
            phase = phase,
            target = target_name,
            progress = 1,
            instance = instance,
            surface = target,
            resolvedPlacement = payload.resolvedPlacement,
            previousValue = payload.previousValue,
            nextValue = payload.nextValue,
        })
    end

    return {
        phase = phase,
        descriptor = descriptor,
        target = target_name,
    }
end

local function run_external_adapter(adapter, instance, phase, descriptor, payload)
    if Types.is_function(adapter) then
        return adapter(instance, phase, descriptor, payload)
    end

    if Types.is_table(adapter) then
        if Types.is_function(adapter.request) then
            return adapter:request(instance, phase, descriptor, payload)
        end

        if Types.is_function(adapter.start) then
            return adapter:start(instance, phase, descriptor, payload)
        end
    end

    fail('motion adapter must expose request(...) or start(...)', 3)
end

function Runtime.request(instance, phase, payload)
    Assert.table('instance', instance, 2)
    Assert.string('phase', phase, 2)
    payload = payload or {}

    local descriptors = normalize_descriptors(instance, phase, payload)
    local completed = {}

    for index = 1, #descriptors do
        local descriptor = descriptors[index]
        local adapter = descriptor.adapter
        local result = nil

        if adapter ~= nil then
            result = run_external_adapter(adapter, instance, phase, descriptor, payload)
        else
            result = apply_descriptor(instance, phase, descriptor, payload)
        end

        completed[#completed + 1] = result
    end

    instance._motion_last_request = {
        phase = phase,
        payload = payload,
        descriptors = descriptors,
        completed = completed,
    }

    return completed
end

return Runtime
