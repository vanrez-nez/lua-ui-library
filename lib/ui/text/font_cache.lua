local Assert = require('lib.ui.utils.assert')

local FontCache = {}

local cache = {}

local function assert_love_graphics(level)
    if love == nil or love.graphics == nil then
        Assert.fail('font operations require love.graphics runtime', level or 2)
    end
end

local function make_key(path, size)
    return tostring(path or '__default__') .. ':' .. tostring(size)
end

local function load_font(path, size)
    assert_love_graphics(3)

    if path == nil then
        return love.graphics.newFont(size)
    end

    local function try_load(candidate)
        local ok, font_or_err = pcall(love.graphics.newFont, candidate, size)
        if ok then
            return true, font_or_err
        end
        return false, font_or_err
    end

    local function read_file_bytes(file_path)
        local handle = io.open(file_path, 'rb')
        if handle == nil then
            return nil
        end
        local bytes = handle:read('*a')
        handle:close()
        return bytes
    end

    local candidates = { path }

    if path:sub(1, 1) ~= '/' then
        local rel = path
        for _ = 1, 6 do
            rel = '../' .. rel
            candidates[#candidates + 1] = rel
        end

        if love ~= nil and love.filesystem ~= nil and love.filesystem.getSource ~= nil then
            local source_dir = love.filesystem.getSource()
            if source_dir ~= nil and source_dir ~= '' then
                local sep = source_dir:sub(-1) == '/' and '' or '/'
                candidates[#candidates + 1] = source_dir .. sep .. path
            end
        end
    end

    local last_err = nil
    for i = 1, #candidates do
        local ok, font_or_err = try_load(candidates[i])
        if ok then
            return font_or_err
        end
        last_err = font_or_err
    end

    -- Fallback for subfolder test harnesses where LÖVE filesystem cannot
    -- directly resolve parent-relative paths. Read bytes from host FS and load
    -- as FileData.
    if love ~= nil and love.filesystem ~= nil and love.filesystem.getSource ~= nil then
        local source_dir = love.filesystem.getSource()
        if source_dir ~= nil and source_dir ~= '' then
            local search_dirs = { source_dir }
            local current = source_dir
            for _ = 1, 6 do
                local parent = current:match('^(.+)/[^/]+$')
                if parent == nil then
                    break
                end
                search_dirs[#search_dirs + 1] = parent
                current = parent
            end

            for i = 1, #search_dirs do
                local base = search_dirs[i]
                local sep = base:sub(-1) == '/' and '' or '/'
                local full = base .. sep .. path
                local bytes = read_file_bytes(full)
                if bytes ~= nil then
                    local file_data = love.filesystem.newFileData(bytes, path)
                    local ok, font_or_err = pcall(love.graphics.newFont, file_data, size)
                    if ok then
                        return font_or_err
                    end
                    last_err = font_or_err
                end
            end
        end
    end

    Assert.fail('failed to load font "' .. tostring(path) .. '": ' .. tostring(last_err), 3)
end

function FontCache.get(path, size)
    if path ~= nil then
        Assert.string('path', path, 2)
    end
    Assert.number('size', size, 2)

    local key = make_key(path, size)
    local font = cache[key]
    if font ~= nil then
        return font
    end

    font = load_font(path, size)
    cache[key] = font
    return font
end

function FontCache.get_default(size)
    return FontCache.get(nil, size)
end

function FontCache.clear()
    cache = {}
end

return FontCache
