local JitProfiler = require('profiler.jit_profiler')
local TimingProfiler = require('profiler.timing_profiler')
local MemoryProfiler = require('profiler.memory_profiler')

local DemoProfiling = {}
DemoProfiling.__index = DemoProfiling

local function parse_positive_number(value)
    local number = tonumber(value)
    if number == nil or number <= 0 then
        return nil
    end

    return number
end

local function parse_screen_index()
    local value = tonumber(
        os.getenv('UI_PROFILE_SCREEN') or
        os.getenv('UI_TIME_PROFILE_SCREEN') or
        os.getenv('UI_JIT_PROFILE_SCREEN')
    )
    if value == nil then
        return nil
    end

    value = math.floor(value)
    if value < 1 then
        return nil
    end

    return value
end

function DemoProfiling.new(opts)
    opts = opts or {}

    local self = setmetatable({}, DemoProfiling)
    self.jit_prefix = opts.jit_prefix or 'jit-profile'
    self.timing_prefix = opts.timing_prefix or 'timing-profile'
    self.memory_prefix = opts.memory_prefix or 'memory-profile'
    self.auto_stop_time = nil

    return self
end

function DemoProfiling:build_jit_output_path()
    local explicit = os.getenv('UI_JIT_PROFILE_OUTPUT')
    if explicit ~= nil and explicit ~= '' then
        return explicit
    end

    return JitProfiler.default_output(self.jit_prefix)
end

function DemoProfiling:build_timing_output_path()
    local explicit = os.getenv('UI_TIME_PROFILE_OUTPUT')
    if explicit ~= nil and explicit ~= '' then
        return explicit
    end

    return TimingProfiler.default_output(self.timing_prefix)
end

function DemoProfiling:build_memory_output_path()
    local explicit = os.getenv('UI_MEMORY_PROFILE_OUTPUT')
    if explicit ~= nil and explicit ~= '' then
        return explicit
    end

    return MemoryProfiler.default_output(self.memory_prefix)
end

function DemoProfiling:start_jit()
    local output, err = JitProfiler.start({
        options = os.getenv('UI_JIT_PROFILE_OPTIONS') or JitProfiler.DEFAULT_OPTIONS,
        output = self:build_jit_output_path(),
    })

    if output == nil then
        print(string.format('[jit.p] failed to start: %s', tostring(err)))
        return false
    end

    return true
end

function DemoProfiling:stop_jit()
    if not JitProfiler.is_active() then
        return JitProfiler.get_last_output()
    end

    local output, err = JitProfiler.stop()
    if output == nil then
        print(string.format('[jit.p] failed to stop: %s', tostring(err)))
        return nil
    end

    return output
end

function DemoProfiling:start_timing()
    local output, err = TimingProfiler.start({
        output = self:build_timing_output_path(),
    })

    if output == nil then
        print(string.format('[timing] failed to start: %s', tostring(err)))
        return false
    end

    return true
end

function DemoProfiling:stop_timing()
    if not TimingProfiler.is_active() then
        return TimingProfiler.get_last_output()
    end

    local output, err = TimingProfiler.stop()
    if output == nil then
        print(string.format('[timing] failed to stop: %s', tostring(err)))
        return nil
    end

    return output
end

function DemoProfiling:start_memory()
    local output, err = MemoryProfiler.start({
        output = self:build_memory_output_path(),
    })

    if output == nil then
        print(string.format('[memory] failed to start: %s', tostring(err)))
        return false
    end

    return true
end

function DemoProfiling:stop_memory()
    if not MemoryProfiler.is_active() then
        return MemoryProfiler.get_last_output()
    end

    local output, err = MemoryProfiler.stop()
    if output == nil then
        print(string.format('[memory] failed to stop: %s', tostring(err)))
        return nil
    end

    return output
end

function DemoProfiling:toggle_jit()
    if JitProfiler.is_active() then
        return self:stop_jit()
    end

    return self:start_jit()
end

function DemoProfiling:toggle_timing()
    if TimingProfiler.is_active() then
        return self:stop_timing()
    end

    return self:start_timing()
end

function DemoProfiling:toggle_memory()
    if MemoryProfiler.is_active() then
        return self:stop_memory()
    end

    return self:start_memory()
end

function DemoProfiling:maybe_start_auto(demo_base)
    local should_start_jit = os.getenv('UI_JIT_PROFILE') == '1'
    local should_start_timing = os.getenv('UI_TIME_PROFILE') == '1'
    local should_start_memory = os.getenv('UI_MEMORY_PROFILE') == '1'

    if not should_start_jit and not should_start_timing and not should_start_memory then
        return true
    end

    local screen_index = parse_screen_index()
    if screen_index ~= nil and demo_base ~= nil and demo_base.screens[screen_index] == nil then
        return false
    end

    if screen_index ~= nil and demo_base ~= nil and demo_base.screens[screen_index] ~= nil then
        demo_base:_activate_screen(screen_index)
    end

    local started = false

    if should_start_jit and self:start_jit() then
        started = true
    end

    if should_start_timing and self:start_timing() then
        started = true
    end

    if should_start_memory and self:start_memory() then
        started = true
    end

    if not started then
        return true
    end

    local seconds = parse_positive_number(os.getenv('UI_JIT_PROFILE_SECONDS')) or 5
    local timing_seconds = parse_positive_number(os.getenv('UI_TIME_PROFILE_SECONDS'))
    if timing_seconds ~= nil then
        seconds = timing_seconds
    end
    local memory_seconds = parse_positive_number(os.getenv('UI_MEMORY_PROFILE_SECONDS'))
    if memory_seconds ~= nil then
        seconds = memory_seconds
    end

    self.auto_stop_time = love.timer.getTime() + seconds
    return true
end

function DemoProfiling:update()
    if self.auto_stop_time == nil then
        return false
    end

    if love.timer.getTime() < self.auto_stop_time then
        return false
    end

    self.auto_stop_time = nil
    self:stop_jit()
    self:stop_timing()
    self:stop_memory()
    love.event.quit()
    return true
end

function DemoProfiling:draw_status(g, colors)
    local any_active_or_recorded =
        JitProfiler.is_active() or JitProfiler.get_last_output() ~= nil or
        TimingProfiler.is_active() or TimingProfiler.get_last_output() ~= nil or
        MemoryProfiler.is_active() or MemoryProfiler.get_last_output() ~= nil

    if not any_active_or_recorded then
        return
    end

    local bottom = g.getHeight()
    g.setColor(colors.roles.text_muted)
    g.print(JitProfiler.status_text(), 16, bottom - 94)
    g.print(TimingProfiler.status_text(), 16, bottom - 78)
    g.print(MemoryProfiler.status_text(), 16, bottom - 62)
end

function DemoProfiling:handle_keypressed(key)
    if key == 'p' then
        self:toggle_jit()
        return true
    end

    if key == 't' then
        self:toggle_timing()
        return true
    end

    if key == 'y' then
        self:toggle_memory()
        return true
    end

    return false
end

function DemoProfiling:shutdown()
    self.auto_stop_time = nil
    self:stop_jit()
    self:stop_timing()
    self:stop_memory()
end

return DemoProfiling
