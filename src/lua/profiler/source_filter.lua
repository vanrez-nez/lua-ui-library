local Utils = require('profiler.utils')

local SourceFilter = {}

local function is_profiler_source(source)
  source = Utils.normalize_path(source) or ''
  return source:find('/profiler/', 1, true) ~= nil or
    source:find('profiler/', 1, true) == 1
end

function SourceFilter.should_profile_source(source, config)
  if source == nil or source == '' then
    return false
  end

  source = Utils.normalize_path(source)
  if not config.include_profiler and is_profiler_source(source) then
    return false
  end

  if #config.targets == 0 then
    return true
  end

  for _, target in ipairs(config.targets) do
    if Utils.source_matches_target(source, target) then
      return true
    end
  end

  return false
end

return SourceFilter
