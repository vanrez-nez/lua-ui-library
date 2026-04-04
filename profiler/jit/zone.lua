local stack = {}

local zone = setmetatable({}, {
    __call = function(_, name)
        if name == nil then
            local current = stack[#stack]
            stack[#stack] = nil
            return current
        end

        stack[#stack + 1] = tostring(name)
        return name
    end,
})

function zone:get()
    return stack[#stack]
end

function zone:flush()
    for index = #stack, 1, -1 do
        stack[index] = nil
    end
end

return zone
