local Config = {}

local DEFAULT_OUTPUT_DIR = '/tmp/profiler'
local DEFAULT_FORMAT = 'text'

local function truthy(value)
  if value == nil then
    return false
  end

  value = tostring(value):lower()
  return value == '1' or value == 'true' or value == 'yes' or value == 'on'
end

local function split_csv(value)
  local result = {}

  if value == nil or value == '' then
    return result
  end

  for item in tostring(value):gmatch('[^,]+') do
    item = item:match('^%s*(.-)%s*$')
    if item ~= '' then
      result[#result + 1] = item
    end
  end

  return result
end

local function parse_nonnegative_number(value)
  if value == nil or value == '' then
    return nil
  end

  value = tonumber(value)
  if value == nil then
    return nil
  end

  if value < 0 then
    return 0
  end

  return value
end

local function parse_frame_count(value)
  value = parse_nonnegative_number(value)
  if value == nil then
    return nil
  end

  return math.floor(value)
end

local function feature_map(features)
  if type(features) == 'table' and
    features.calls ~= nil and
    features.time ~= nil and
    features.memory ~= nil and
    features.zones ~= nil
  then
    return {
      calls = features.calls == true,
      time = features.time == true,
      memory = features.memory == true,
      zones = features.zones == true
    }
  end

  local map = {
    calls = false,
    time = false,
    memory = false,
    zones = false
  }

  for _, feature in ipairs(features or {}) do
    feature = tostring(feature):lower()
    if feature == 'all' then
      map.calls = true
      map.time = true
      map.memory = true
      map.zones = true
    elseif map[feature] ~= nil then
      map[feature] = true
    end
  end

  if #features == 0 then
    map.calls = true
    map.time = true
  end

  return map
end

local function copy_array(values)
  local result = {}

  for index = 1, #(values or {}) do
    result[index] = values[index]
  end

  return result
end

function Config.default_output_dir()
  return DEFAULT_OUTPUT_DIR
end

function Config.make_timestamp()
  return os.date('%Y%m%d-%H%M%S')
end

function Config.default_output(opts)
  opts = opts or {}

  local output_dir = opts.output_dir or DEFAULT_OUTPUT_DIR
  local prefix = opts.prefix or 'profile'
  local format = opts.format or DEFAULT_FORMAT
  local extension = 'txt'

  if format == 'speedscope' then
    extension = 'speedscope.json'
  end

  return string.format('%s/%s-%s.%s', output_dir, prefix, Config.make_timestamp(), extension)
end

function Config.from_env(opts)
  opts = opts or {}

  local features = split_csv(os.getenv('PROFILE_FEATURES'))
  local format = os.getenv('PROFILE_FORMAT')
  local output = os.getenv('PROFILE_OUTPUT')
  local output_dir = os.getenv('PROFILE_OUTPUT_DIR')
  local targets = split_csv(os.getenv('PROFILE_TARGETS'))
  local delay_seconds = parse_nonnegative_number(os.getenv('PROFILE_DELAY'))
  local profile_frames = parse_frame_count(os.getenv('PROFILE_FRAMES'))

  if format == '' then
    format = nil
  end
  if output == '' then
    output = nil
  end
  if output_dir == '' then
    output_dir = nil
  end

  return Config.normalize({
    enabled = truthy(os.getenv('PROFILE')) or opts.enabled == true,
    output = output or opts.output,
    output_dir = output_dir or opts.output_dir,
    prefix = opts.prefix,
    format = format or opts.format,
    features = #features > 0 and features or opts.features,
    targets = #targets > 0 and targets or opts.targets,
    delay_seconds = delay_seconds or opts.delay_seconds or opts.delay,
    profile_frames = profile_frames or opts.profile_frames or opts.frames,
    include_profiler = truthy(os.getenv('PROFILE_INCLUDE_PROFILER')) or opts.include_profiler
  })
end

function Config.normalize(opts)
  opts = opts or {}

  local features = opts.features
  if type(features) == 'string' then
    features = split_csv(features)
  elseif type(features) == 'table' and
    features.calls ~= nil and
    features.time ~= nil and
    features.memory ~= nil and
    features.zones ~= nil
  then
    features = features
  else
    features = copy_array(features)
  end

  local targets = opts.targets
  if type(targets) == 'string' then
    targets = split_csv(targets)
  else
    targets = copy_array(targets)
  end

  local output_dir = opts.output_dir or DEFAULT_OUTPUT_DIR
  local format = tostring(opts.format or DEFAULT_FORMAT):lower()
  if format ~= 'text' and format ~= 'speedscope' then
    format = DEFAULT_FORMAT
  end

  local delay_seconds = parse_nonnegative_number(opts.delay_seconds or opts.delay)
  local profile_frames = parse_frame_count(opts.profile_frames or opts.frames)

  return {
    enabled = opts.enabled ~= false,
    output = opts.output,
    output_dir = output_dir,
    prefix = opts.prefix or 'profile',
    format = format,
    features = feature_map(features),
    targets = targets,
    delay_seconds = delay_seconds or 0,
    profile_frames = profile_frames,
    include_profiler = opts.include_profiler == true
  }
end

return Config
