local ContainerPropertyViews = {}

local function install_view(instance, field_name, reader)
    rawset(instance, field_name, setmetatable({}, {
        __index = function(_, key)
            return reader(instance, key)
        end,
        __newindex = function(_, key, value)
            rawset(instance, key, value)
        end,
    }))
end

function ContainerPropertyViews.install(instance, readers)
    install_view(instance, '_public_values', readers.public)
    install_view(instance, '_effective_values', readers.effective)
end

function ContainerPropertyViews.write_extra(instance, key, value)
    local public_values = instance._public_values
    local effective_values = instance._effective_values

    if public_values ~= nil then
        public_values[key] = value
    end

    if effective_values ~= nil then
        effective_values[key] = value
    end
end

return ContainerPropertyViews
