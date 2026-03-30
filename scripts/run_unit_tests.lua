package.path = './?.lua;./?/init.lua;' .. package.path

local function find_spec_files()
    local pipe = io.popen("find spec -type f -name '*_spec.lua' | sort")

    if not pipe then
        error('failed to enumerate spec files', 0)
    end

    local files = {}

    for line in pipe:lines() do
        files[#files + 1] = line
    end

    pipe:close()

    if #files == 0 then
        error('no spec files found under spec/', 0)
    end

    return files
end

local function path_to_module(path)
    return path:gsub('%.lua$', ''):gsub('/', '.')
end

local function run_spec(path)
    local spec = require(path_to_module(path))

    if type(spec) == 'table' and type(spec.run) == 'function' then
        spec.run()
    end
end

local failures = 0

for _, spec_path in ipairs(find_spec_files()) do
    io.write('Running ', spec_path, '\n')

    local ok, err = xpcall(function()
        run_spec(spec_path)
    end, debug.traceback)

    if ok then
        io.write('PASS ', spec_path, '\n')
    else
        failures = failures + 1
        io.write('FAIL ', spec_path, '\n')
        io.write(err, '\n')
    end
end

if failures > 0 then
    os.exit(1)
end

io.write('All unit tests passed.\n')
