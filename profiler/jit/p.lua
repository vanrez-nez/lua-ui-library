local profile = require('jit.profile')

local has_zone, zone = pcall(require, 'profiler.jit.zone')

local M = {}

local state = {
    active = false,
    options = nil,
    sink = nil,
    config = nil,
    counts = nil,
    samples = 0,
}

local function is_digit(char)
    return char ~= nil and char >= '0' and char <= '9'
end

local function parse_number(spec, index)
    local start_index = index
    local first = spec:sub(index, index)

    if first == '-' then
        index = index + 1
    end

    while is_digit(spec:sub(index, index)) do
        index = index + 1
    end

    local value = tonumber(spec:sub(start_index, index - 1))
    return value, index
end

local function parse_options(options)
    local config = {
        format = 'f',
        depth = 1,
        interval = 10,
        min_percent = 3,
        preserve_path = false,
        show_vmstate = false,
        show_zone = false,
        raw_counts = false,
    }

    local index = 1
    while index <= #options do
        local char = options:sub(index, index)

        if char == 'f' or char == 'F' or char == 'l' then
            config.format = char
            index = index + 1
        elseif char == 'p' then
            config.preserve_path = true
            index = index + 1
        elseif char == 'v' then
            config.show_vmstate = true
            index = index + 1
        elseif char == 'z' then
            config.show_zone = true
            index = index + 1
        elseif char == 'r' then
            config.raw_counts = true
            index = index + 1
        elseif char == 'm' or char == 'i' then
            local value, next_index = parse_number(options, index + 1)
            if char == 'm' and value ~= nil then
                config.min_percent = value
            elseif char == 'i' and value ~= nil then
                config.interval = value
            end
            index = next_index
        elseif char == 's' then
            config.depth = math.max(config.depth, 2)
            index = index + 1
        elseif char == '-' or is_digit(char) then
            local value, next_index = parse_number(options, index)
            if value ~= nil then
                config.depth = value
            end
            index = next_index
        else
            index = index + 1
        end
    end

    return config
end

local function build_profile_mode(config)
    local format = config.format
    if format ~= 'l' then
        format = 'f'
    end

    return string.format('%si%d', format, config.interval)
end

local function current_zone_name()
    if not has_zone or not state.config.show_zone then
        return nil
    end

    if type(zone.get) ~= 'function' then
        return nil
    end

    return zone:get() or '<no-zone>'
end

local function current_stack(thread)
    local depth = state.config.depth or 1
    local format = state.config.format or 'f'

    if state.config.preserve_path then
        format = 'p' .. format
    end

    if math.abs(depth) > 1 then
        if depth < 0 then
            format = format .. 'Z -> '
        else
            format = format .. 'Z <- '
        end
    end

    local stack = profile.dumpstack(thread, format, depth)
    if stack == nil or stack == '' then
        return '<unknown>'
    end

    return stack
end

local function sample_key(thread, vmstate)
    local parts = {}

    local zone_name = current_zone_name()
    if zone_name ~= nil then
        parts[#parts + 1] = zone_name
    end

    if state.config.show_vmstate then
        parts[#parts + 1] = vmstate or '?'
    end

    parts[#parts + 1] = current_stack(thread)

    return table.concat(parts, ' | ')
end

local function write_report(sink)
    local rows = {}
    local total = state.samples

    for key, count in pairs(state.counts) do
        local percent = total > 0 and (count * 100 / total) or 0
        if percent >= state.config.min_percent then
            rows[#rows + 1] = {
                key = key,
                count = count,
                percent = percent,
            }
        end
    end

    table.sort(rows, function(left, right)
        if left.count == right.count then
            return left.key < right.key
        end

        return left.count > right.count
    end)

    sink:write(string.format('jit.p compatibility report\n'))
    sink:write(string.format('options: %s\n', state.options or ''))
    sink:write(string.format('samples: %d\n', total))
    sink:write('\n')

    for _, row in ipairs(rows) do
        if state.config.raw_counts then
            sink:write(string.format('%8d  %6.2f%%  %s\n', row.count, row.percent, row.key))
        else
            sink:write(string.format('%6.2f%%  %8d  %s\n', row.percent, row.count, row.key))
        end
    end
end

local function open_sink(output)
    if output == nil then
        return io.stdout, false
    end

    if type(output) == 'string' then
        local handle, err = io.open(output, 'w')
        if handle == nil then
            error(err or ('unable to open profiler output: ' .. output), 3)
        end
        return handle, true
    end

    if type(output) == 'table' or type(output) == 'userdata' then
        if type(output.write) == 'function' then
            return output, false
        end
    end

    error('unsupported profiler output sink', 3)
end

local function on_sample(thread, samples, vmstate)
    local key = sample_key(thread, vmstate)
    state.counts[key] = (state.counts[key] or 0) + samples
    state.samples = state.samples + samples
end

function M.start(options, output)
    if state.active then
        return output
    end

    options = options or 'f'

    local sink, should_close = open_sink(output)

    state.active = true
    state.options = options
    state.config = parse_options(options)
    state.counts = {}
    state.samples = 0
    state.sink = {
        handle = sink,
        should_close = should_close,
    }

    profile.start(build_profile_mode(state.config), on_sample)

    return output
end

function M.stop()
    if not state.active then
        return
    end

    profile.stop()
    write_report(state.sink.handle)

    if state.sink.should_close then
        state.sink.handle:close()
    end

    state.active = false
    state.options = nil
    state.config = nil
    state.counts = nil
    state.samples = 0
    state.sink = nil
end

return M
