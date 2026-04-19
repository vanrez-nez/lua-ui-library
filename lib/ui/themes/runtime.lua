local Theme = require('lib.ui.themes.theme')
local Resolver = require('lib.ui.themes.resolver')
local DefaultTokens = require('lib.ui.themes.default')

local Runtime = {}

function Runtime.resolve(style_scope, property_name, variant, context)
    context = context or {}
    context.style_scope = style_scope
    context.property = property_name
    context.variant = variant
    context.theme = context.theme or Theme.get_active()
    context.defaults = context.defaults or DefaultTokens

    return Resolver.resolve(context)
end

return Runtime
