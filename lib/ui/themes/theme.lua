local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')
local Object = require('lib.cls')

local Theme = Object:extends('Theme')

local active_theme = nil

local function copy_tokens(tokens)
    local copy = {}

    for key, value in pairs(tokens or {}) do
        copy[key] = value
    end

    return copy
end

function Theme:constructor(opts)
    opts = opts or {}
    Assert.table('opts', opts, 2)

    local tokens = opts.tokens or {}
    Assert.table('tokens', tokens, 2)

    self.tokens = copy_tokens(tokens)
end

function Theme.new(opts)
    return Theme(opts)
end

function Theme.is_theme()
    return true
end

function Theme:set(key, value)
    Assert.string('key', key, 2)
    self.tokens[key] = value
    return self
end

function Theme:get(key)
    Assert.string('key', key, 2)
    return self.tokens[key]
end

function Theme:merge(tokens)
    Assert.table('tokens', tokens, 2)

    for key, value in pairs(tokens) do
        self.tokens[key] = value
    end

    return self
end

function Theme.set_active(theme)
    if theme ~= nil and (not Types.is_table(theme) or theme.tokens == nil) then
        Assert.fail('active theme must be a Theme or nil', 2)
    end

    active_theme = theme
    return active_theme
end

function Theme.get_active()
    return active_theme
end

return Theme
