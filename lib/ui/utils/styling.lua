-- Proxy removed

local Styling = {}

-- Optimized check to determine if a property requires full resolution logic.
-- Returns true if the property has active responsive overrides or requires
-- internal Quad family merging (aggregate expansion).
function Styling.requires_resolution(node, key, family)
    -- 1. If we have active responsive overrides, we MUST always resolve.
    -- We check the raw field to avoid triggering Proxy/Class __index recursion.
    local overrides = rawget(node, '_resolved_responsive_overrides')
    if overrides ~= nil and next(overrides) ~= nil then
        return true
    end

    -- 2. If we have NO active overrides, we only need complex resolution if
    -- there is an aggregate vs member conflict in a Quad family.
    if family then
        -- If we are reading a member (e.g., paddingTop) but the aggregate (padding)
        -- is set, we must resolve to expand the aggregate into the member.
        if key ~= family.aggregate and rawget(node, family.aggregate) ~= nil then
            return true
        end

        -- In all other cases without overrides (member set, aggregate set, or neither set),
        -- the Effective value is identical to the Local value (rawget).
        return false
    end

    -- 3. Non-quad properties with no overrides never require resolution.
    return false
end

return Styling
