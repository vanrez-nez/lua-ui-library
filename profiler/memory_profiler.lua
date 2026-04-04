local MemoryProfiler = {}

local state = {
    active = false,
    output = nil,
    last_output = nil,
    started_at = nil,
    started_heap_kb = nil,
    ended_heap_kb = nil,
    stats = nil,
    stack = nil,
}

local function now_seconds()
    if love ~= nil and love.timer ~= nil and love.timer.getTime ~= nil then
        return love.timer.getTime()
    end

    return os.clock()
end

local function heap_kb()
    return collectgarbage('count')
end

local function make_timestamp()
    return os.date('%Y%m%d-%H%M%S')
end

local function ensure_zone_stats(name)
    local stats = state.stats[name]
    if stats ~= nil then
        return stats
    end

    stats = {
        net_kb = 0,
        self_net_kb = 0,
        alloc_kb = 0,
        self_alloc_kb = 0,
        free_kb = 0,
        self_free_kb = 0,
        max_growth_kb = 0,
        max_self_growth_kb = 0,
        calls = 0,
    }
    state.stats[name] = stats

    return stats
end

local function sorted_rows()
    local rows = {}

    for name, stats in pairs(state.stats or {}) do
        rows[#rows + 1] = {
            name = name,
            net_kb = stats.net_kb,
            self_net_kb = stats.self_net_kb,
            alloc_kb = stats.alloc_kb,
            self_alloc_kb = stats.self_alloc_kb,
            free_kb = stats.free_kb,
            self_free_kb = stats.self_free_kb,
            max_growth_kb = stats.max_growth_kb,
            max_self_growth_kb = stats.max_self_growth_kb,
            calls = stats.calls,
        }
    end

    table.sort(rows, function(left, right)
        if left.self_alloc_kb == right.self_alloc_kb then
            return left.name < right.name
        end

        return left.self_alloc_kb > right.self_alloc_kb
    end)

    return rows
end

local function write_report(output, elapsed_seconds)
    local handle, should_close

    if type(output) == 'string' then
        local err
        handle, err = io.open(output, 'w')
        if handle == nil then
            error(err or ('unable to open memory profile output: ' .. output), 2)
        end
        should_close = true
    else
        handle = output or io.stdout
        should_close = false
    end

    local rows = sorted_rows()
    local frame_stats = state.stats['Stage.draw']
    local frames = frame_stats and frame_stats.calls or 0

    handle:write('memory profile report\n')
    handle:write(string.format('seconds: %.6f\n', elapsed_seconds))
    handle:write(string.format('frames: %d\n', frames))
    handle:write(string.format('heap_start_kb: %.3f\n', state.started_heap_kb or 0))
    handle:write(string.format('heap_end_kb: %.3f\n', state.ended_heap_kb or 0))
    handle:write(string.format('heap_net_kb: %+0.3f\n', (state.ended_heap_kb or 0) - (state.started_heap_kb or 0)))
    handle:write('note: net columns are signed; negative values mean the zone freed more Lua heap than it retained.\n')
    handle:write('\n')
    handle:write(string.format(
        '%14s  %12s  %14s  %12s  %14s  %12s  %18s  %7s  %s\n',
        'self_alloc_kb',
        'alloc_kb',
        'self_net_kb',
        'net_kb',
        'self_free_kb',
        'free_kb',
        'max_self_growth_kb',
        'calls',
        'zone'
    ))

    for _, row in ipairs(rows) do
        handle:write(string.format(
            '%14.3f  %12.3f  %+14.3f  %+12.3f  %14.3f  %12.3f  %18.3f  %7d  %s\n',
            row.self_alloc_kb,
            row.alloc_kb,
            row.self_net_kb,
            row.net_kb,
            row.self_free_kb,
            row.free_kb,
            row.max_self_growth_kb,
            row.calls,
            row.name
        ))
    end

    if should_close then
        handle:close()
    end
end

function MemoryProfiler.is_available()
    return true
end

function MemoryProfiler.is_active()
    return state.active
end

function MemoryProfiler.get_output()
    return state.output
end

function MemoryProfiler.get_last_output()
    return state.last_output
end

function MemoryProfiler.default_output(prefix)
    prefix = prefix or 'memory-profile'
    return string.format('tmp/%s-%s.txt', prefix, make_timestamp())
end

function MemoryProfiler.start(opts)
    opts = opts or {}

    if state.active then
        return state.output
    end

    state.active = true
    state.output = opts.output or MemoryProfiler.default_output(opts.prefix)
    state.last_output = state.output
    state.started_at = now_seconds()
    state.started_heap_kb = heap_kb()
    state.ended_heap_kb = nil
    state.stats = {}
    state.stack = {}

    print(string.format('[memory] started output=%s', state.output))

    return state.output
end

function MemoryProfiler.stop()
    if not state.active then
        return state.last_output
    end

    local output = state.output
    local elapsed_seconds = now_seconds() - (state.started_at or now_seconds())

    while state.stack ~= nil and #state.stack > 0 do
        MemoryProfiler.pop_zone(state.stack[#state.stack])
    end

    state.ended_heap_kb = heap_kb()
    write_report(output, elapsed_seconds)

    state.active = false
    state.output = nil
    state.started_at = nil
    state.started_heap_kb = nil
    state.ended_heap_kb = nil
    state.stats = nil
    state.stack = nil

    print(string.format('[memory] stopped output=%s', output or 'nil'))

    return output
end

function MemoryProfiler.toggle(opts)
    if state.active then
        return MemoryProfiler.stop()
    end

    return MemoryProfiler.start(opts)
end

function MemoryProfiler.push_zone(name)
    if not state.active or name == nil then
        return false
    end

    local token = {
        name = tostring(name),
        started_heap_kb = heap_kb(),
        child_delta_kb = 0,
    }

    local stack = state.stack
    stack[#stack + 1] = token

    return token
end

function MemoryProfiler.pop_zone(token)
    if not state.active or not token then
        return nil
    end

    local stack = state.stack
    if stack == nil or #stack == 0 then
        return nil
    end

    local top = stack[#stack]
    stack[#stack] = nil

    if top ~= token then
        token = top
    end

    local delta_kb = heap_kb() - token.started_heap_kb
    local self_delta_kb = delta_kb - token.child_delta_kb

    local stats = ensure_zone_stats(token.name)
    stats.net_kb = stats.net_kb + delta_kb
    stats.self_net_kb = stats.self_net_kb + self_delta_kb
    stats.calls = stats.calls + 1

    local alloc_kb = math.max(0, delta_kb)
    local self_alloc_kb = math.max(0, self_delta_kb)
    local free_kb = math.max(0, -delta_kb)
    local self_free_kb = math.max(0, -self_delta_kb)

    stats.alloc_kb = stats.alloc_kb + alloc_kb
    stats.self_alloc_kb = stats.self_alloc_kb + self_alloc_kb
    stats.free_kb = stats.free_kb + free_kb
    stats.self_free_kb = stats.self_free_kb + self_free_kb

    if alloc_kb > stats.max_growth_kb then
        stats.max_growth_kb = alloc_kb
    end

    if self_alloc_kb > stats.max_self_growth_kb then
        stats.max_self_growth_kb = self_alloc_kb
    end

    local parent = stack[#stack]
    if parent ~= nil then
        parent.child_delta_kb = parent.child_delta_kb + delta_kb
    end

    return delta_kb
end

function MemoryProfiler.status_text()
    if state.active then
        return string.format('memory on -> %s', state.output or '?')
    end

    if state.last_output ~= nil then
        return string.format('memory off -> last %s', state.last_output)
    end

    return 'memory off'
end

return MemoryProfiler
