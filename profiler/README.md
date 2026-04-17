# profiler

Runtime profiler for the Love2D UI library. Instruments Lua call stacks via `debug.sethook` to collect per-function and per-zone timing, call counts, and memory deltas. Output can be a human-readable text report or a [Speedscope](https://speedscope.app) JSON trace.

## Quick start

### Via environment variables (recommended)

```sh
PROFILE=1 love .
```

The report is written to `/tmp/profiler/profile-<timestamp>.txt` when profiling stops.

### Via code

```lua
local Profiler = require('profiler')

Profiler.start({ output = '/tmp/my-profile.txt' })
-- ... run your code ...
Profiler.stop()
```

## Environment variables

| Variable | Default | Description |
|---|---|---|
| `PROFILE` | — | Set to `1` to enable profiling |
| `PROFILE_FORMAT` | `text` | Output format: `text` or `speedscope` |
| `PROFILE_OUTPUT` | auto | Full output file path (overrides dir/prefix) |
| `PROFILE_OUTPUT_DIR` | `/tmp/profiler` | Directory for auto-named output files |
| `PROFILE_FEATURES` | `calls,time` | Comma-separated features to collect (see below) |
| `PROFILE_TARGETS` | all files | Comma-separated file path suffixes to filter |
| `PROFILE_INCLUDE_PROFILER` | — | Set to `1` to include profiler internals in results |

### Features

| Value | Description |
|---|---|
| `calls` | Count function calls |
| `time` | Measure total and self time |
| `memory` | Measure memory allocation/free |
| `zones` | Collect manual zone data |
| `all` | Enable all of the above |

Default when `PROFILE_FEATURES` is unset: `calls,time`.

```sh
PROFILE=1 PROFILE_FEATURES=all love .
```

### Targeting specific files

Restrict profiling to files whose paths end with the given suffix:

```sh
PROFILE=1 PROFILE_TARGETS=lib/ui/core/container.lua,lib/ui/scene love .
```

### Speedscope output

```sh
PROFILE=1 PROFILE_FORMAT=speedscope love .
```

Open the resulting `.speedscope.json` file at [speedscope.app](https://speedscope.app) for an interactive flame graph.

## API

### `Profiler.start(opts)` → `output_path`

Starts profiling. `opts` fields mirror the environment variables:

```lua
Profiler.start({
  format   = 'text',           -- 'text' | 'speedscope'
  output   = '/tmp/out.txt',   -- explicit output path
  output_dir = '/tmp/profiler',
  prefix   = 'profile',
  features = 'calls,time',     -- string or array
  targets  = {},               -- array of path suffixes
})
```

Returns the output path, or `nil` if profiling is disabled.

### `Profiler.stop()` → `output_path`

Stops profiling, writes the report, and returns the output path.

### `Profiler.toggle(opts)` → `output_path`

Starts profiling if inactive, stops it if active.

### `Profiler.start_from_env(opts)` → `output_path`

Like `start()`, but reads configuration from environment variables (same as the quick-start approach). `opts` provides fallback values.

### `Profiler.push_zone(name)` → `token`

Begins a named manual zone. Returns a token that must be passed to `pop_zone`.

```lua
local token = Profiler.push_zone('render')
-- ... code to measure ...
Profiler.pop_zone(token)
```

### `Profiler.pop_zone(token)`

Ends the zone opened by the matching `push_zone` call.

### `Profiler.measure(name, fn, ...)` → `...`

Wraps a function call in a zone. Propagates return values and errors transparently.

```lua
local result = Profiler.measure('expensive-op', my_fn, arg1, arg2)
```

### `Profiler.is_active()` → `boolean`

Returns `true` while profiling is running.

### `Profiler.is_available()` → `boolean`

Returns `true` if `debug.sethook` is available in the current runtime.

### `Profiler.status_text()` → `string`

Short human-readable status, suitable for a HUD or status bar.

## RuntimeProfiler

`profiler/runtime_profiler.lua` is a lightweight facade used internally by the UI library. It wraps tokens in a table so callers don't hold a direct reference to the profiler token, making it safe to pass around without coupling to profiler internals.

```lua
local RuntimeProfiler = require('profiler.runtime_profiler')

local token = RuntimeProfiler.push_zone('my-zone')
RuntimeProfiler.pop_zone(token)
```

## Module structure

```
profiler/
  init.lua           -- Public API and orchestration
  config.lua         -- Configuration parsing and defaults
  counters.lua       -- Per-function/file/zone stat aggregation
  reporter.lua       -- Output coordination and formatter dispatch
  runtime_profiler.lua -- Lightweight facade for UI library internals
  utils.lua          -- Stateless utilities (timer, memory, path)
  source_filter.lua  -- Decides which source files get profiled
  token.lua          -- Timing token lifecycle (open / close / propagate)
  trace.lua          -- Speedscope trace object (frames + events)
  formatters/
    text.lua         -- Human-readable text report
    speedscope.lua   -- Speedscope JSON trace format
```
