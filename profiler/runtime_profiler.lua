local JitProfiler = require('profiler.jit_profiler')
local TimingProfiler = require('profiler.timing_profiler')
local MemoryProfiler = require('profiler.memory_profiler')

local RuntimeProfiler = {}

function RuntimeProfiler.is_active()
    return JitProfiler.is_active() or
        TimingProfiler.is_active() or
        MemoryProfiler.is_active()
end

function RuntimeProfiler.push_zone(name)
    if name == nil or not RuntimeProfiler.is_active() then
        return nil
    end

    return {
        jit = JitProfiler.push_zone(name),
        timing = TimingProfiler.push_zone(name),
        memory = MemoryProfiler.push_zone(name),
    }
end

function RuntimeProfiler.pop_zone(token)
    if token == nil then
        return nil
    end

    MemoryProfiler.pop_zone(token.memory)
    TimingProfiler.pop_zone(token.timing)
    JitProfiler.pop_zone(token.jit)
    return nil
end

return RuntimeProfiler
