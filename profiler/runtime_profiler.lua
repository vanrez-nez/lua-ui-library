local JitProfiler = require('profiler.jit_profiler')
local TimingProfiler = require('profiler.timing_profiler')
local MemoryProfiler = require('profiler.memory_profiler')

local RuntimeProfiler = {}

function RuntimeProfiler.push_zone(name)
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
