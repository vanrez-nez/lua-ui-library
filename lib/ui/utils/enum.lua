-- utils/enum.lua
--
-- Declaration-time enum builder.
-- Enums are plain tables with both an ordered array part (1..N) and a
-- named hash part (MEMBER_NAME -> atom). Members reference atoms from
-- a Constants module; the enum wrapper does not own the values.

local M = {}

--- Build an enum from an ordered sequence of single-pair entries.
-- Each entry is a table with exactly one key/value pair: the member name
-- maps to its atom. Order of varargs is preserved in the array part.
--
-- @usage
--   local Justify = enum(
--       { START  = Constants.ALIGN_START },
--       { CENTER = Constants.ALIGN_CENTER },
--       { END    = Constants.ALIGN_END }
--   )
--   Justify.START  -- "start"
--   Justify[1]     -- "start"
--   #Justify       -- 3
function M.enum(...)
    local args = { ... }
    local t = {}

    for i = 1, #args do
        local entry = args[i]
        assert(type(entry) == "table",
            "enum entry #" .. i .. " must be a table")

        local k, v = next(entry)
        assert(k ~= nil,
            "enum entry #" .. i .. " is empty")
        assert(next(entry, k) == nil,
            "enum entry #" .. i .. " must have exactly one member")
        assert(type(k) == "string",
            "enum member name must be a string (got " .. type(k) .. ")")
        assert(v ~= nil,
            "enum member '" .. k .. "' has nil value")
        assert(t[k] == nil,
            "duplicate enum member: '" .. k .. "'")

        t[i] = v
        t[k] = v
    end

    return t
end

--- Check if a value is a member of the enum.
-- O(n) linear scan; fine for typical small enums (<20 members).
function M.enum_has(e, v)
    for i = 1, #e do
        if e[i] == v then return true end
    end
    return false
end

--- Return the ordered values as an ipairs-iterable array.
-- The enum itself satisfies this; the function exists for readability.
function M.enum_values(e)
    return e
end

return M