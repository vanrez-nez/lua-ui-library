local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')
local Rule = require('lib.ui.utils.rule')
local Proxy = require('lib.ui.utils.proxy')

local Responsive = {}

local MATCHER_KEYS = {
    minWidth = true,
    maxWidth = true,
    minHeight = true,
    maxHeight = true,
    orientation = true,
    viewport = true,
    parent = true,
    safeArea = true,
    safeAreaInsets = true,
}

local function copy_keys_sorted(source)
    local keys = {}

    for key in pairs(source) do
        keys[#keys + 1] = key
    end

    table.sort(keys, function(left, right)
        return tostring(left) < tostring(right)
    end)

    return keys
end

local function shallow_equals(left, right)
    if left == right then
        return true
    end

    if not Types.is_table(left) or not Types.is_table(right) then
        return false
    end

    for key, value in pairs(left) do
        if right[key] ~= value then
            return false
        end
    end

    for key, value in pairs(right) do
        if left[key] ~= value then
            return false
        end
    end

    return true
end

local function copy_table(source)
    local copy = {}

    for key, value in pairs(source) do
        copy[key] = value
    end

    return copy
end

local function normalize_dimension_target(name, value, level)
    if value == nil then
        return nil
    end

    Assert.table(name, value, level or 1)

    return {
        minWidth = value.minWidth,
        maxWidth = value.maxWidth,
        minHeight = value.minHeight,
        maxHeight = value.maxHeight,
    }
end

local function matches_dimension_target(target, constraints)
    if constraints == nil then
        return true
    end

    if constraints.minWidth ~= nil and target.width < constraints.minWidth then
        return false
    end

    if constraints.maxWidth ~= nil and target.width > constraints.maxWidth then
        return false
    end

    if constraints.minHeight ~= nil and target.height < constraints.minHeight then
        return false
    end

    if constraints.maxHeight ~= nil and target.height > constraints.maxHeight then
        return false
    end

    return true
end

local function normalize_inset_constraints(value, level)
    if value == nil then
        return nil
    end

    Assert.table('safeAreaInsets', value, level or 1)

    return {
        minTop = value.minTop,
        maxTop = value.maxTop,
        minRight = value.minRight,
        maxRight = value.maxRight,
        minBottom = value.minBottom,
        maxBottom = value.maxBottom,
        minLeft = value.minLeft,
        maxLeft = value.maxLeft,
    }
end

local function matches_inset_constraints(insets, constraints)
    if constraints == nil then
        return true
    end

    if constraints.minTop ~= nil and insets.top < constraints.minTop then
        return false
    end

    if constraints.maxTop ~= nil and insets.top > constraints.maxTop then
        return false
    end

    if constraints.minRight ~= nil and insets.right < constraints.minRight then
        return false
    end

    if constraints.maxRight ~= nil and insets.right > constraints.maxRight then
        return false
    end

    if constraints.minBottom ~= nil and insets.bottom < constraints.minBottom then
        return false
    end

    if constraints.maxBottom ~= nil and insets.bottom > constraints.maxBottom then
        return false
    end

    if constraints.minLeft ~= nil and insets.left < constraints.minLeft then
        return false
    end

    if constraints.maxLeft ~= nil and insets.left > constraints.maxLeft then
        return false
    end

    return true
end

local function normalize_matcher(rule, level)
    if Types.is_function(rule.when) then
        return {
            kind = 'function',
            callback = rule.when,
        }
    end

    local constraints = rule.when

    if constraints == nil then
        constraints = {}

        for key, value in pairs(rule) do
            if MATCHER_KEYS[key] then
                constraints[key] = value
            end
        end
    end

    if not Types.is_table(constraints) then
        Assert.fail('responsive rule "when" must be a table or function', level or 1)
    end

    return {
        kind = 'constraints',
        constraints = {
            minWidth = constraints.minWidth,
            maxWidth = constraints.maxWidth,
            minHeight = constraints.minHeight,
            maxHeight = constraints.maxHeight,
            orientation = constraints.orientation,
            viewport = normalize_dimension_target('viewport', constraints.viewport,
                level),
            parent = normalize_dimension_target('parent', constraints.parent, level),
            safeArea = normalize_dimension_target('safeArea', constraints.safeArea,
                level),
            safeAreaInsets = normalize_inset_constraints(
                constraints.safeAreaInsets,
                level
            ),
        },
    }
end

local function normalize_rule(id, rule, level)
    Assert.table('responsive rule', rule, level or 1)

    local overrides = rule.props or rule.overrides

    if overrides == nil then
        Assert.fail(
            'responsive rule "' .. tostring(id) ..
                '" must define a props or overrides table',
            level or 1
        )
    end

    Assert.table('responsive overrides', overrides, level or 1)

    return {
        id = tostring(id),
        matcher = normalize_matcher(rule, level),
        overrides = overrides,
    }
end

local function normalize_rule_list(source, level)
    local rules = source.rules or source
    local normalized = {}

    if rules.when ~= nil or rules.props ~= nil or rules.overrides ~= nil then
        normalized[1] = normalize_rule(1, rules, level)
        return normalized
    end

    local count = #rules

    if count > 0 then
        for index = 1, count do
            normalized[index] = normalize_rule(index, rules[index], level)
        end

        return normalized
    end

    local keys = copy_keys_sorted(rules)

    for index = 1, #keys do
        local key = keys[index]
        normalized[index] = normalize_rule(key, rules[key], level)
    end

    return normalized
end

local function normalize_source(node, source_kind, source)
    local cached_source = rawget(node, '_responsive_source_cache')
    local cached_kind = rawget(node, '_responsive_source_cache_kind')

    if cached_source == source and cached_kind == source_kind then
        return rawget(node, '_responsive_normalized_source')
    end

    local normalized

    if Types.is_function(source) then
        normalized = {
            kind = 'function',
            callback = source,
        }
    else
        Assert.table(source_kind, source, 3)

        normalized = {
            kind = 'rules',
            rules = normalize_rule_list(source, 3),
        }
    end

    rawset(node, '_responsive_source_cache', source)
    rawset(node, '_responsive_source_cache_kind', source_kind)
    rawset(node, '_responsive_normalized_source', normalized)
    rawset(node, '_responsive_resolved_cache', {})

    return normalized
end

local function get_source(node)
    local responsive = Proxy.raw_get(node, 'responsive')
    local breakpoints = Proxy.raw_get(node, 'breakpoints')

    if responsive ~= nil and breakpoints ~= nil then
        Assert.fail(
            'responsive and breakpoints cannot both be supplied on the same node',
            3
        )
    end

    if responsive ~= nil then
        return 'responsive', responsive
    end

    if breakpoints ~= nil then
        return 'breakpoints', breakpoints
    end

    return nil, nil
end

local function matches_rule(matcher, context, node)
    if matcher.kind == 'function' then
        return not not matcher.callback(context, node)
    end

    local constraints = matcher.constraints

    if constraints.orientation ~= nil and
        context.orientation ~= constraints.orientation then
        return false
    end

    if constraints.minWidth ~= nil and
        context.viewport.width < constraints.minWidth then
        return false
    end

    if constraints.maxWidth ~= nil and
        context.viewport.width > constraints.maxWidth then
        return false
    end

    if constraints.minHeight ~= nil and
        context.viewport.height < constraints.minHeight then
        return false
    end

    if constraints.maxHeight ~= nil and
        context.viewport.height > constraints.maxHeight then
        return false
    end

    if not matches_dimension_target(context.viewport, constraints.viewport) then
        return false
    end

    if not matches_dimension_target(context.parent, constraints.parent) then
        return false
    end

    if not matches_dimension_target(context.safeArea, constraints.safeArea) then
        return false
    end

    if not matches_inset_constraints(
        context.safeArea.insets,
        constraints.safeAreaInsets
    ) then
        return false
    end

    return true
end

local function cache_resolved_overrides(node, token, overrides)
    local cache = rawget(node, '_responsive_resolved_cache')

    if cache == nil then
        cache = {}
        rawset(node, '_responsive_resolved_cache', cache)
    end

    local existing = cache[token]

    if existing ~= nil and shallow_equals(existing, overrides) then
        return existing
    end

    local copy = copy_table(overrides)
    cache[token] = copy
    return copy
end

function Responsive.resolve(node, context)
    local source_kind, source = get_source(node)

    if source == nil then
        return nil, nil
    end

    local normalized = normalize_source(node, source_kind, source)

    if normalized.kind == 'function' then
        local overrides, token = normalized.callback(context, node)

        if overrides == nil then
            return nil, nil
        end

        Assert.table('responsive overrides', overrides, 3)

        if token == nil then
            token = overrides
        end

        return token, cache_resolved_overrides(node, token, overrides)
    end

    local token_parts = {}
    local merged_overrides = nil

    for index = 1, #normalized.rules do
        local rule = normalized.rules[index]

        if matches_rule(rule.matcher, context, node) then
            if merged_overrides == nil then
                merged_overrides = {}
            end

            for key, value in pairs(rule.overrides) do
                merged_overrides[key] = value
            end

            token_parts[#token_parts + 1] = rule.id
        end
    end

    if merged_overrides == nil then
        return nil, nil
    end

    local token = source_kind .. ':' .. table.concat(token_parts, '|')
    return token, cache_resolved_overrides(node, token, merged_overrides)
end

function Responsive.schema_rule(kind, opts)
    return Rule.custom(function(_, value, _, level)
        if not Types.is_table(value) and not Types.is_function(value) then
            Assert.fail(kind .. '.responsive must be a table or a function', level or 1)
        end

        return value
    end, opts)
end

return Responsive
