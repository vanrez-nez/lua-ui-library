local DemoAssets = {}

function DemoAssets.load_image(path)
    local function try_load(candidate)
        local ok, image_or_err = pcall(love.graphics.newImage, candidate)
        if ok then
            return image_or_err
        end
        return nil
    end

    local image = try_load(path)
    if image ~= nil then
        return image
    end

    if love == nil or love.filesystem == nil or love.filesystem.getSource == nil then
        error('could not resolve image path "' .. tostring(path) .. '"', 2)
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

    local source_dir = love.filesystem.getSource()
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

    for index = 1, #search_dirs do
        local base = search_dirs[index]
        local separator = base:sub(-1) == '/' and '' or '/'
        local full_path = base .. separator .. path
        local bytes = read_file_bytes(full_path)

        if bytes ~= nil then
            local file_data = love.filesystem.newFileData(bytes, path)
            local ok, resolved = pcall(love.graphics.newImage, file_data)
            if ok then
                return resolved
            end
        end
    end

    error('could not resolve image path "' .. tostring(path) .. '"', 2)
end

return DemoAssets
