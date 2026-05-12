local Profiler = require('profiler')

local RuntimeProfiler = {}

function RuntimeProfiler.is_active()
    return Profiler.is_active()
end

function RuntimeProfiler.push_zone(name)
    if name == nil or not RuntimeProfiler.is_active() then
        return nil
    end

    return {
        profile = Profiler.push_zone(name),
    }
end

function RuntimeProfiler.pop_zone(token)
    if token == nil then
        return nil
    end

    Profiler.pop_zone(token.profile)
    return nil
end

return RuntimeProfiler
