local Bootstrap = {}

function Bootstrap.init()
    package.path = '../../?.lua;../../?/init.lua;' .. package.path

    if love == nil or love.filesystem == nil or love.filesystem.getSource == nil then
        return
    end

    local source = love.filesystem.getSource()
    if source == nil or source == '' then
        return
    end

    local root = source:match('^(.*)/[^/]+/[^/]+$')
    if root == nil then
        return
    end

    package.path = root .. '/?.lua;' .. root .. '/?/init.lua;' .. package.path
end

return Bootstrap
