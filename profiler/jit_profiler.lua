local JitProfiler = {
    DEFAULT_OPTIONS = 'z2fi2m1',
}

local has_jit = pcall(require, 'jit')
local has_profiler, profiler = pcall(require, 'profiler.jit.p')
local has_zone, zone = pcall(require, 'profiler.jit.zone')

local state = {
    active = false,
    options = nil,
    output = nil,
    last_output = nil,
}

local function make_timestamp()
    return os.date('%Y%m%d-%H%M%S')
end

local function flush_zones()
    if not has_zone then
        return
    end

    pcall(function()
        zone:flush()
    end)
end

function JitProfiler.is_available()
    return has_jit and has_profiler
end

function JitProfiler.supports_zones()
    return JitProfiler.is_available() and has_zone
end

function JitProfiler.is_active()
    return state.active
end

function JitProfiler.get_output()
    return state.output
end

function JitProfiler.get_last_output()
    return state.last_output
end

function JitProfiler.default_output(prefix)
    prefix = prefix or 'jit-profile'
    return string.format('tmp/%s-%s.txt', prefix, make_timestamp())
end

function JitProfiler.start(opts)
    opts = opts or {}

    if not JitProfiler.is_available() then
        return nil, 'jit.p is unavailable in this runtime'
    end

    if state.active then
        return state.output
    end

    local options = opts.options or JitProfiler.DEFAULT_OPTIONS
    local output = opts.output or JitProfiler.default_output(opts.prefix)

    flush_zones()

    local ok, err = pcall(function()
        profiler.start(options, output)
    end)

    if not ok then
        return nil, err
    end

    state.active = true
    state.options = options
    state.output = output
    state.last_output = output

    print(string.format('[jit.p] started options=%s output=%s', options, output))

    return output
end

function JitProfiler.stop()
    if not state.active then
        return state.last_output
    end

    local output = state.output
    local ok, err = pcall(function()
        profiler.stop()
    end)

    flush_zones()

    state.active = false
    state.options = nil
    state.output = nil

    if not ok then
        return nil, err
    end

    print(string.format('[jit.p] stopped output=%s', output or 'nil'))

    return output
end

function JitProfiler.toggle(opts)
    if state.active then
        return JitProfiler.stop()
    end

    return JitProfiler.start(opts)
end

function JitProfiler.push_zone(name)
    if not state.active or not has_zone or name == nil then
        return false
    end

    zone(name)
    return true
end

function JitProfiler.pop_zone(token)
    if not token or not has_zone then
        return nil
    end

    return zone()
end

function JitProfiler.status_text()
    if not JitProfiler.is_available() then
        return 'jit.p unavailable'
    end

    if state.active then
        return string.format('jit.p on -> %s', state.output or '?')
    end

    if state.last_output ~= nil then
        return string.format('jit.p off -> last %s', state.last_output)
    end

    return 'jit.p off'
end

return JitProfiler
