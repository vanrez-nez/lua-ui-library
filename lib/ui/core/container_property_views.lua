local Proxy = require('lib.ui.utils.proxy')

local ContainerPropertyViews = {}

local DECLARED_PROPS = '_declared_props'

local function has_declared_prop(instance, key)
    local declared_props = rawget(instance, DECLARED_PROPS)
    return declared_props ~= nil and declared_props[key] ~= nil
end

local function install_view(instance, field_name, reader)
    rawset(instance, field_name, setmetatable({}, {
        __index = function(_, key)
            return reader(instance, key)
        end,
        __newindex = function(_, key, value)
            if has_declared_prop(instance, key) then
                Proxy.raw_set(instance, key, value)
            else
                rawset(instance, key, value)
            end
        end,
    }))
end

function ContainerPropertyViews.install(instance, readers)
    install_view(instance, '_public_values', readers.public)
    install_view(instance, '_effective_values', readers.effective)
end

function ContainerPropertyViews.write_extra(instance, key, value)
    local public_values = rawget(instance, '_public_values')
    local effective_values = rawget(instance, '_effective_values')

    if public_values ~= nil then
        public_values[key] = value
    end

    if effective_values ~= nil then
        effective_values[key] = value
    end
end

return ContainerPropertyViews
