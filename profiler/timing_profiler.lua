local TimingProfiler = {}

local state = {
    active = false,
    output = nil,
    last_output = nil,
    started_at = nil,
    stats = nil,
    stack = nil,
}

local function now_seconds()
    if love ~= nil and love.timer ~= nil and love.timer.getTime ~= nil then
        return love.timer.getTime()
    end

    return os.clock()
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
        total = 0,
        self_total = 0,
        calls = 0,
        max = 0,
        self_max = 0,
    }
    state.stats[name] = stats

    return stats
end

local function sorted_rows()
    local rows = {}

    for name, stats in pairs(state.stats or {}) do
        rows[#rows + 1] = {
            name = name,
            total = stats.total,
            self_total = stats.self_total,
            calls = stats.calls,
            max = stats.max,
            self_max = stats.self_max,
        }
    end

    table.sort(rows, function(left, right)
        if left.total == right.total then
            return left.name < right.name
        end

        return left.total > right.total
    end)

    return rows
end

local function write_report(output, elapsed_seconds)
    local handle, should_close

    if type(output) == 'string' then
        local err
        handle, err = io.open(output, 'w')
        if handle == nil then
            error(err or ('unable to open timing profile output: ' .. output), 2)
        end
        should_close = true
    else
        handle = output or io.stdout
        should_close = false
    end

    local rows = sorted_rows()
    local frame_stats = state.stats['Stage.draw']
    local frames = frame_stats and frame_stats.calls or 0

    handle:write('timing profile report\n')
    handle:write(string.format('seconds: %.6f\n', elapsed_seconds))
    handle:write(string.format('frames: %d\n', frames))
    handle:write('\n')
    handle:write('total_ms  self_ms  avg_ms  self_avg_ms  max_ms  calls  zone\n')

    for _, row in ipairs(rows) do
        local total_ms = row.total * 1000
        local self_ms = row.self_total * 1000
        local avg_ms = row.calls > 0 and (total_ms / row.calls) or 0
        local self_avg_ms = row.calls > 0 and (self_ms / row.calls) or 0
        local max_ms = row.max * 1000

        handle:write(string.format(
            '%8.3f  %7.3f  %6.3f  %11.3f  %6.3f  %5d  %s\n',
            total_ms,
            self_ms,
            avg_ms,
            self_avg_ms,
            max_ms,
            row.calls,
            row.name
        ))
    end

    if should_close then
        handle:close()
    end
end

function TimingProfiler.is_available()
    return true
end

function TimingProfiler.is_active()
    return state.active
end

function TimingProfiler.get_output()
    return state.output
end

function TimingProfiler.get_last_output()
    return state.last_output
end

function TimingProfiler.default_output(prefix)
    prefix = prefix or 'timing-profile'
    return string.format('tmp/%s-%s.txt', prefix, make_timestamp())
end

function TimingProfiler.start(opts)
    opts = opts or {}

    if state.active then
        return state.output
    end

    state.active = true
    state.output = opts.output or TimingProfiler.default_output(opts.prefix)
    state.last_output = state.output
    state.started_at = now_seconds()
    state.stats = {}
    state.stack = {}

    print(string.format('[timing] started output=%s', state.output))

    return state.output
end

function TimingProfiler.stop()
    if not state.active then
        return state.last_output
    end

    local output = state.output
    local elapsed_seconds = now_seconds() - (state.started_at or now_seconds())

    while state.stack ~= nil and #state.stack > 0 do
        TimingProfiler.pop_zone(state.stack[#state.stack])
    end

    write_report(output, elapsed_seconds)

    state.active = false
    state.output = nil
    state.started_at = nil
    state.stats = nil
    state.stack = nil

    print(string.format('[timing] stopped output=%s', output or 'nil'))

    return output
end

function TimingProfiler.toggle(opts)
    if state.active then
        return TimingProfiler.stop()
    end

    return TimingProfiler.start(opts)
end

function TimingProfiler.push_zone(name)
    if not state.active or name == nil then
        return false
    end

    local token = {
        name = tostring(name),
        started_at = now_seconds(),
        child_time = 0,
    }

    local stack = state.stack
    stack[#stack + 1] = token

    return token
end

function TimingProfiler.pop_zone(token)
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

    local elapsed = now_seconds() - token.started_at
    local self_time = elapsed - token.child_time
    if self_time < 0 then
        self_time = 0
    end

    local stats = ensure_zone_stats(token.name)
    stats.total = stats.total + elapsed
    stats.self_total = stats.self_total + self_time
    stats.calls = stats.calls + 1

    if elapsed > stats.max then
        stats.max = elapsed
    end

    if self_time > stats.self_max then
        stats.self_max = self_time
    end

    local parent = stack[#stack]
    if parent ~= nil then
        parent.child_time = parent.child_time + elapsed
    end

    return elapsed
end

function TimingProfiler.status_text()
    if state.active then
        return string.format('timing on -> %s', state.output or '?')
    end

    if state.last_output ~= nil then
        return string.format('timing off -> last %s', state.last_output)
    end

    return 'timing off'
end

return TimingProfiler
