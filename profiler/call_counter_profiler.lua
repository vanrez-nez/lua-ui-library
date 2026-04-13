local CallCounterProfiler = {}

local state = {
    active = false,
    targets = {},
    order = {},
    pending = {},
    pending_order = {},
    last_outputs = {},
    quit_installed = false,
    previous_quit = nil,
    run_installed = false,
    capture_delay = nil,
    capture_at = nil,
    capture_started = false,
    capture_finished = false,
    stack = {},
}

local function make_timestamp()
    return os.date('%Y%m%d-%H%M%S')
end

local function normalize_path(path)
    if path == nil then
        return nil
    end

    path = tostring(path):gsub('\\', '/')
    if path:sub(1, 1) == '@' then
        path = path:sub(2)
    end

    while path:sub(1, 2) == './' do
        path = path:sub(3)
    end

    return path
end

local function source_matches_target(source, target)
    source = normalize_path(source)
    target = normalize_path(target)

    if source == nil or target == nil or target == '' then
        return false
    end

    return source == target or source:sub(-#target) == target
end

local function line_label(line)
    return line:match('^%s*local%s+function%s+([%w_]+)%s*%(') or
        line:match('^%s*function%s+([%w_%.:]+)%s*%(') or
        line:match('^%s*([%w_%.:]+)%s*=%s*function%s*%(')
end

local function has_anonymous_function_expression(line)
    local index = 1

    while true do
        local start_index, end_index = line:find('function%s*%(', index)
        if start_index == nil then
            return false
        end

        local previous = start_index > 1 and line:sub(start_index - 1, start_index - 1) or ''
        if not previous:match('[%w_]') then
            return true
        end

        index = end_index + 1
    end
end

local function load_definitions(path)
    local definitions = {}
    local handle = io.open(path, 'r')

    if handle == nil then
        return definitions
    end

    local line_number = 0
    for line in handle:lines() do
        line_number = line_number + 1

        local label = line_label(line)
        if label == nil and has_anonymous_function_expression(line) then
            label = '<anonymous>'
        end

        if label ~= nil then
            definitions[line_number] = label
        end
    end

    handle:close()
    return definitions
end

local function function_label(profile, info)
    local defined_name = profile.definitions and
        profile.definitions[info.linedefined] or nil
    if defined_name ~= nil then
        return defined_name
    end

    if info.name ~= nil and info.name ~= '' then
        return info.name
    end

    return '<anonymous>'
end

local function now_seconds()
    return love.timer.getTime()
end

local function row_for_call(profile, info)
    local line = info.linedefined or 0
    local row = profile.counts[line]
    if row == nil then
        row = {
            line = line,
            label = function_label(profile, info),
            calls = 0,
            total_time = 0,
            self_time = 0,
        }
        profile.counts[line] = row
    end

    return row
end

local function count_call(profile, info)
    local row = row_for_call(profile, info)

    row.calls = row.calls + 1
    profile.total_calls = profile.total_calls + 1
    return row
end

local function push_frame(profile, info, row)
    state.stack[#state.stack + 1] = {
        profile = profile,
        source = normalize_path(info.source),
        line = info.linedefined or 0,
        row = row,
        start_time = now_seconds(),
        child_time = 0,
    }
end

local function pop_frame(info)
    local source = normalize_path(info.source)
    local line = info.linedefined or 0

    for index = #state.stack, 1, -1 do
        local frame = state.stack[index]
        if frame.source == source and frame.line == line then
            local elapsed = now_seconds() - frame.start_time
            local self_time = elapsed - frame.child_time
            if self_time < 0 then
                self_time = 0
            end

            frame.row.total_time = frame.row.total_time + elapsed
            frame.row.self_time = frame.row.self_time + self_time
            frame.profile.total_time = frame.profile.total_time + elapsed

            table.remove(state.stack, index)

            local parent = state.stack[#state.stack]
            if parent ~= nil then
                parent.child_time = parent.child_time + elapsed
            end
            return
        end
    end
end

local function on_call_event(event)
    if not state.active then
        return
    end

    local info = debug.getinfo(2, 'nS')
    if info == nil or info.what == 'C' then
        return
    end

    if event == 'call' or event == 'tail call' then
        for _, name in ipairs(state.order) do
            local profile = state.targets[name]
            if profile ~= nil and source_matches_target(info.source, profile.target) then
                local row = count_call(profile, info)
                push_frame(profile, info, row)
            end
        end
        return
    end

    if event == 'return' or event == 'tail return' then
        for _, name in ipairs(state.order) do
            local profile = state.targets[name]
            if profile ~= nil and source_matches_target(info.source, profile.target) then
                pop_frame(info)
                return
            end
        end
    end
end

local function sorted_rows(profile)
    local rows = {}
    local seen = {}

    for line, label in pairs(profile.definitions or {}) do
        local counted = profile.counts and profile.counts[line] or nil
        rows[#rows + 1] = {
            line = line,
            label = counted and counted.label or label,
            calls = counted and counted.calls or 0,
            total_time = counted and counted.total_time or 0,
            self_time = counted and counted.self_time or 0,
        }
        seen[line] = true
    end

    for line, row in pairs(profile.counts or {}) do
        if not seen[line] then
            rows[#rows + 1] = row
        end
    end

    table.sort(rows, function(left, right)
        if left.calls == right.calls then
            return left.line < right.line
        end

        return left.calls > right.calls
    end)

    return rows
end

local function write_report(profile)
    local handle, should_close
    local output = profile.output

    if type(output) == 'string' then
        local err
        handle, err = io.open(output, 'w')
        if handle == nil then
            error(err or ('unable to open call count profile output: ' .. output), 2)
        end
        should_close = true
    else
        handle = output or io.stdout
        should_close = false
    end

    handle:write('call count profile report\n')
    handle:write(string.format('name: %s\n', profile.name or ''))
    handle:write(string.format('target: %s\n', profile.target or ''))
    handle:write(string.format('total_calls: %d\n', profile.total_calls or 0))
    handle:write(string.format('total_time_ms: %.6f\n', (profile.total_time or 0) * 1000))
    handle:write('\n')
    handle:write('calls  total_ms  self_ms  avg_us  line  function\n')

    for _, row in ipairs(sorted_rows(profile)) do
        local total_ms = (row.total_time or 0) * 1000
        local self_ms = (row.self_time or 0) * 1000
        local avg_us = 0
        if row.calls > 0 then
            avg_us = (row.total_time or 0) * 1000000 / row.calls
        end

        handle:write(string.format(
            '%7d  %11.6f  %10.6f  %8.3f  %4d  %s\n',
            row.calls,
            total_ms,
            self_ms,
            avg_us,
            row.line,
            row.label
        ))
    end

    if should_close then
        handle:close()
    end
end

local function truthy(value)
    if value == nil then
        return false
    end

    value = tostring(value):lower()
    return value == '1' or value == 'true' or value == 'yes' or value == 'on'
end

local function parse_positive_number(value)
    local number = tonumber(value)
    if number == nil or number <= 0 then
        return nil
    end

    return number
end

local function install_hook()
    if not state.active then
        debug.sethook(on_call_event, 'cr')
        state.active = true
    end
end

local function remove_hook_if_idle()
    if #state.order == 0 then
        debug.sethook()
        state.active = false
    end
end

local function remove_ordered_name(name)
    for index = #state.order, 1, -1 do
        if state.order[index] == name then
            table.remove(state.order, index)
            return
        end
    end
end

local function queue_pending(opts)
    local name = opts.name or 'default'

    if state.pending[name] == nil then
        state.pending_order[#state.pending_order + 1] = name
    end

    state.pending[name] = {
        name = name,
        target = opts.target,
        output = opts.output,
        prefix = opts.prefix,
    }
end

local function start_pending()
    local names = {}
    local pending_profiles = state.pending

    for _, name in ipairs(state.pending_order) do
        names[#names + 1] = name
    end

    state.pending = {}
    state.pending_order = {}

    for _, name in ipairs(names) do
        local pending = pending_profiles[name]
        if pending ~= nil then
            CallCounterProfiler.start(pending)
        end
    end
end

function CallCounterProfiler.is_available()
    return debug ~= nil and type(debug.sethook) == 'function'
end

function CallCounterProfiler.is_active(name)
    if name ~= nil then
        return state.targets[name] ~= nil
    end

    return state.active
end

function CallCounterProfiler.get_output(name)
    name = name or 'default'

    local profile = state.targets[name]
    return profile and profile.output or nil
end

function CallCounterProfiler.get_outputs()
    local outputs = {}

    for _, name in ipairs(state.order) do
        local profile = state.targets[name]
        if profile ~= nil then
            outputs[name] = profile.output
        end
    end

    return outputs
end

function CallCounterProfiler.get_last_output(name)
    if name ~= nil then
        return state.last_outputs[name]
    end

    return state.last_outputs.default
end

function CallCounterProfiler.get_last_outputs()
    local outputs = {}

    for name, output in pairs(state.last_outputs) do
        outputs[name] = output
    end

    return outputs
end

function CallCounterProfiler.default_output(prefix)
    prefix = prefix or 'call-count-profile'
    return string.format('tmp/%s-%s.txt', prefix, make_timestamp())
end

function CallCounterProfiler.install_love_quit_stop()
    if state.quit_installed or type(love) ~= 'table' then
        return
    end

    state.quit_installed = true
    state.previous_quit = love.quit

    love.quit = function(...)
        local previous_quit = state.previous_quit
        if previous_quit ~= nil then
            local result = previous_quit(...)
            if result then
                return result
            end
        end

        CallCounterProfiler.stop()
        return nil
    end
end

function CallCounterProfiler.install_single_frame_run(delay_seconds)
    if state.run_installed or type(love) ~= 'table' then
        return
    end

    state.run_installed = true
    state.capture_delay = delay_seconds or 0

    love.run = function()
        if love.load then
            love.load(love.arg.parseGameArguments(arg), arg)
        end

        if love.timer then
            love.timer.step()
            state.capture_at = love.timer.getTime() + state.capture_delay
        else
            state.capture_at = 0
        end

        local dt = 0

        return function()
            if love.event then
                love.event.pump()
                for name, a, b, c, d, e, f in love.event.poll() do
                    if name == 'quit' then
                        if not love.quit or not love.quit() then
                            return a or 0
                        end
                    end

                    if love.handlers[name] then
                        love.handlers[name](a, b, c, d, e, f)
                    end
                end
            end

            if love.timer then
                dt = love.timer.step()
            end

            local now = love.timer and love.timer.getTime() or 0
            if not state.capture_started and now >= (state.capture_at or 0) then
                state.capture_started = true
                start_pending()
            end

            if love.update then
                love.update(dt)
            end

            if love.graphics and love.graphics.isActive() then
                love.graphics.origin()
                love.graphics.clear(love.graphics.getBackgroundColor())

                if love.draw then
                    love.draw()
                end

                love.graphics.present()
            end

            if state.capture_started and not state.capture_finished then
                state.capture_finished = true
                CallCounterProfiler.stop()
                if love.event then
                    love.event.quit()
                end
            end

            if love.timer then
                love.timer.sleep(0.001)
            end
        end
    end
end

function CallCounterProfiler.start(opts)
    opts = opts or {}

    if not CallCounterProfiler.is_available() then
        return nil, 'debug.sethook is unavailable in this runtime'
    end

    local target = normalize_path(opts.target)
    if target == nil or target == '' then
        return nil, 'target is required'
    end

    local name = opts.name or 'default'
    local existing = state.targets[name]
    if existing ~= nil then
        return existing.output
    end

    local output = opts.output or CallCounterProfiler.default_output(opts.prefix)
    state.targets[name] = {
        name = name,
        output = output,
        target = target,
        definitions = load_definitions(target),
        counts = {},
        total_calls = 0,
        total_time = 0,
    }
    state.order[#state.order + 1] = name
    state.last_outputs[name] = output
    if name == 'default' then
        state.last_outputs.default = output
    end

    install_hook()
    CallCounterProfiler.install_love_quit_stop()

    print(string.format('[call-count] started name=%s target=%s output=%s', name, target, output))
    return output
end

function CallCounterProfiler.start_from_env(opts)
    opts = opts or {}

    if not truthy(os.getenv(opts.enabled_env)) then
        return nil
    end

    local start_opts = {
        name = opts.name,
        target = opts.target,
        output = opts.output_env and os.getenv(opts.output_env) or nil,
        prefix = opts.prefix,
    }
    local delay = parse_positive_number(
        os.getenv('UI_CALL_PROFILE_FRAME_AFTER_SECONDS') or
        os.getenv('UI_CALL_PROFILE_SINGLE_FRAME_AFTER_SECONDS')
    )

    if delay ~= nil then
        start_opts.output = start_opts.output or
            CallCounterProfiler.default_output(start_opts.prefix)
        queue_pending(start_opts)
        CallCounterProfiler.install_love_quit_stop()
        CallCounterProfiler.install_single_frame_run(delay)
        return start_opts.output
    end

    return CallCounterProfiler.start(start_opts)
end

function CallCounterProfiler.stop(name)
    if name ~= nil then
        local profile = state.targets[name]
        if profile == nil then
            return state.last_outputs[name]
        end

        local output = profile.output
        write_report(profile)
        state.targets[name] = nil
        state.last_outputs[name] = output
        remove_ordered_name(name)
        remove_hook_if_idle()

        print(string.format('[call-count] stopped name=%s output=%s', name, output or 'nil'))
        return output
    end

    local outputs = {}
    local names = {}

    for _, target_name in ipairs(state.order) do
        names[#names + 1] = target_name
    end

    for _, target_name in ipairs(names) do
        outputs[target_name] = CallCounterProfiler.stop(target_name)
    end

    return outputs.default or outputs
end

function CallCounterProfiler.toggle(opts)
    opts = opts or {}
    local name = opts.name or 'default'

    if state.targets[name] ~= nil then
        return CallCounterProfiler.stop(name)
    end

    return CallCounterProfiler.start(opts)
end

function CallCounterProfiler.status_text()
    if not CallCounterProfiler.is_available() then
        return 'call-count unavailable'
    end

    if state.active then
        return string.format('call-count on -> %d targets', #state.order)
    end

    local last_output = state.last_outputs.default
    if last_output ~= nil then
        return string.format('call-count off -> last %s', last_output)
    end

    return 'call-count off'
end

return CallCounterProfiler
