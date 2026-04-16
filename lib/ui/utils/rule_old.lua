local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')
local Color = require('lib.ui.render.color')
local GraphicsValidation = require('lib.ui.render.graphics_validation')

local Rule = {}

local TIER_PRIORITY = {
    always = 0,
    dev = 1,
    heavy = 2,
}

local function apply_side_fields(rule, opts, default_tier)
    opts = opts or {}
    rule._is_rule = true
    rule.default = opts.default
    rule.set = opts.set
    rule.required = opts.required
    rule.deferred = opts.deferred
    rule.tier = opts.tier or default_tier
    return rule
end

local function validate_inner_rule(rule, key, value, ctx, level, opts)
    if rule.type == 'string' then
        Assert.string(key, value, level)
        return value
    end

    if rule.type == 'boolean' then
        Assert.boolean(key, value, level)
        return value
    end

    if rule.type == 'number' then
        Assert.number(key, value, level)
        return value
    end

    if rule.type == 'table' then
        Assert.table(key, value, level)
        return value
    end

    if rule.type == 'userdata' then
        Assert.userdata(key, value, level)
        return value
    end

    if rule.type == 'any' then
        return value
    end

    if Types.is_function(rule.validate) then
        return rule.validate(key, value, ctx, level, opts)
    end

    Assert.fail('Unknown schema rule type for "' .. tostring(key) .. '"', level)
end

function Rule.validate(rule, key, value, ctx, level, opts)
    level = level or 1

    if rule == nil then
        Assert.fail('Unsupported prop "' .. tostring(key) .. '"', level)
    end

    if not Rule.tier_passes(rule.tier) then
        return value
    end

    if value == nil and not rule.required then
        return value
    end

    if value == nil and rule.required then
        Assert.fail('property "' .. tostring(key) .. '" is required', level)
    end

    return validate_inner_rule(rule, key, value, ctx, level, opts)
end

function Rule.tier_passes(rule_tier)
    local Schema = require('lib.ui.utils.schema')
    local active_tier = Schema.VALIDATION_TIER or 'heavy'
    local rule_priority = TIER_PRIORITY[rule_tier or 'always'] or TIER_PRIORITY.always
    local active_priority = TIER_PRIORITY[active_tier] or TIER_PRIORITY.heavy

    return rule_priority <= active_priority
end

function Rule.enum(allowed, default, opts)
    local lookup = {}

    for index = 1, #allowed do
        lookup[allowed[index]] = true
    end

    return apply_side_fields({
        validate = function(key, value, _, level)
            if lookup[value] then
                return value
            end

            Assert.fail(
                key .. ": '" .. tostring(value) .. "' is not a valid value — accepted: " .. table.concat(allowed, ', '),
                level or 1
            )
        end,
    }, {
        default = default,
        set = opts and opts.set,
        required = opts and opts.required,
        tier = opts and opts.tier,
    }, 'dev')
end

function Rule.number(opts)
    opts = opts or {}

    return apply_side_fields({
        validate = function(key, value, _, level)
            Assert.number(key, value, level)

            if opts.finite and (value ~= value or value == math.huge or value == -math.huge) then
                Assert.fail(key .. ' must be finite, got ' .. tostring(value), level or 1)
            end

            if opts.min ~= nil and value < opts.min then
                Assert.fail(key .. ' must be >= ' .. tostring(opts.min) .. ', got ' .. tostring(value), level or 1)
            end

            if opts.max ~= nil and value > opts.max then
                Assert.fail(key .. ' must be <= ' .. tostring(opts.max) .. ', got ' .. tostring(value), level or 1)
            end

            if opts.min_exclusive ~= nil and value <= opts.min_exclusive then
                Assert.fail(key .. ' must be > ' .. tostring(opts.min_exclusive) .. ', got ' .. tostring(value), level or 1)
            end

            if opts.max_exclusive ~= nil and value >= opts.max_exclusive then
                Assert.fail(key .. ' must be < ' .. tostring(opts.max_exclusive) .. ', got ' .. tostring(value), level or 1)
            end

            return value
        end,
    }, opts, 'dev')
end

function Rule.boolean(default, opts)
    if opts == nil and Types.is_table(default) and (default.default ~= nil or default.set ~= nil or default.required ~= nil or default.tier ~= nil) then
        opts = default
        default = default.default
    end

    return apply_side_fields({
        type = 'boolean',
    }, {
        default = default,
        set = opts and opts.set,
        required = opts and opts.required,
        tier = opts and opts.tier,
    }, 'dev')
end

function Rule.color(default, opts)
    return apply_side_fields({
        validate = function(_, value)
            return Color.resolve(value)
        end,
    }, {
        default = default,
        set = opts and opts.set,
        required = opts and opts.required,
        tier = opts and opts.tier,
    }, 'always')
end

function Rule.opacity(default, opts)
    return apply_side_fields({
        validate = function(key, value, ctx, level)
            return GraphicsValidation.validate_opacity(key, value, ctx, level)
        end,
    }, {
        default = default,
        set = opts and opts.set,
        required = opts and opts.required,
        tier = opts and opts.tier,
    }, 'dev')
end

function Rule.instance(classes, msg, opts)
    local class_list = classes

    if not Types.is_table(classes) or classes.__name ~= nil or classes.super ~= nil then
        class_list = { classes }
    end

    if Types.is_table(msg) and opts == nil then
        opts = msg
        msg = nil
    end

    return apply_side_fields({
        validate = function(key, value, _, level)
            for index = 1, #class_list do
                if Types.is_instance(value, class_list[index]) then
                    return value
                end
            end

            if msg ~= nil then
                Assert.fail(msg, level or 1)
            end

            if #class_list == 1 then
                Assert.fail(key .. ' must be an instance of ' .. tostring(class_list[1]), level or 1)
            end

            local names = {}
            for index = 1, #class_list do
                names[index] = tostring(class_list[index])
            end
            Assert.fail(key .. ' must be an instance of one of: ' .. table.concat(names, ', '), level or 1)
        end,
    }, opts, 'dev')
end

function Rule.table(opts)
    return apply_side_fields({
        type = 'table',
    }, opts, 'dev')
end

function Rule.any(opts)
    return apply_side_fields({
        type = 'any',
    }, opts, 'always')
end

function Rule.string(opts)
    opts = opts or {}

    if opts.non_empty then
        return apply_side_fields({
            validate = function(key, value, _, level)
                Assert.string(key, value, level)
                if value == '' then
                    Assert.fail(key .. ' must not be an empty string', level or 1)
                end
                return value
            end,
        }, opts, 'dev')
    end

    return apply_side_fields({
        type = 'string',
    }, opts, 'dev')
end

function Rule.normalize(normalizer, opts)
    return apply_side_fields({
        validate = function(key, value, ctx, level, full_opts)
            return normalizer(value, key, ctx, level, full_opts)
        end,
    }, opts, 'always')
end

function Rule.custom(fn, opts)
    return apply_side_fields({
        validate = fn,
    }, opts, 'dev')
end

function Rule.gate(predicate, inner_rule)
    return apply_side_fields({
        validate = function(key, value, ctx, level, opts)
            predicate(key, value, ctx, opts)
            return validate_inner_rule(inner_rule, key, value, ctx, level, opts)
        end,
    }, {
        default = inner_rule.default,
        set = inner_rule.set,
        required = inner_rule.required,
        tier = inner_rule.tier or 'dev',
    }, 'dev')
end

function Rule.controlled_pair(value_key, callback_key, opts)
    return apply_side_fields({
        validate = function(_, value, ctx, level, full_opts)
            local current_opts = full_opts or {}
            local current_value = current_opts[value_key]
            local current_callback = current_opts[callback_key]

            if current_value == nil and ctx ~= nil then
                current_value = ctx[value_key]
            end

            if current_callback == nil and ctx ~= nil then
                current_callback = ctx[callback_key]
            end

            if current_value ~= nil and not Types.is_function(current_callback) then
                Assert.fail(
                    tostring(value_key) .. ' without ' .. tostring(callback_key) ..
                        ' when ' .. tostring(value_key) .. ' is intended to be mutable',
                    level or 1
                )
            end

            if current_value == nil and current_callback ~= nil then
                Assert.fail(
                    tostring(callback_key) .. ' without ' .. tostring(value_key) ..
                        ' when ' .. tostring(callback_key) .. ' implies a controlled value',
                    level or 1
                )
            end

            return value
        end,
    }, opts, 'dev')
end

return Rule
