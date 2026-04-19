local SideQuad = require('lib.ui.core.side_quad')
local CornerQuad = require('lib.ui.core.corner_quad')
local Insets = require('lib.ui.core.insets')
local Styling = require('lib.ui.utils.styling')

local Quads = {}

-- Scratch tables for layer resolution (avoid per-call allocations)
local side_scratch_layer_1 = {}
local side_scratch_layer_2 = {}
local corner_scratch_layer_1 = {}
local corner_scratch_layer_2 = {}

-- Quad family definitions: kind, aggregate key, member keys, and factory functions
Quads.FAMILIES = {
    padding = {
        kind = 'side',
        aggregate = 'padding',
        members = {
            top = 'paddingTop',
            right = 'paddingRight',
            bottom = 'paddingBottom',
            left = 'paddingLeft',
        },
        factory = function(top, right, bottom, left)
            return Insets.new(top, right, bottom, left)
        end,
    },
    margin = {
        kind = 'side',
        aggregate = 'margin',
        members = {
            top = 'marginTop',
            right = 'marginRight',
            bottom = 'marginBottom',
            left = 'marginLeft',
        },
        factory = function(top, right, bottom, left)
            return Insets.new(top, right, bottom, left)
        end,
    },
    safeAreaInsets = {
        kind = 'side',
        aggregate = 'safeAreaInsets',
        members = {}, -- Only resolves through aggregate key on the source table
        factory = function(top, right, bottom, left)
            return Insets.new(top, right, bottom, left)
        end,
    },
    borderWidth = {
        kind = 'side',
        aggregate = 'borderWidth',
        members = {
            top = 'borderWidthTop',
            right = 'borderWidthRight',
            bottom = 'borderWidthBottom',
            left = 'borderWidthLeft',
        },
        factory = false, -- borderWidth layers do not use Insets factories
    },
    cornerRadius = {
        kind = 'corner',
        aggregate = 'cornerRadius',
        members = {
            topLeft = 'cornerRadiusTopLeft',
            topRight = 'cornerRadiusTopRight',
            bottomRight = 'cornerRadiusBottomRight',
            bottomLeft = 'cornerRadiusBottomLeft',
        },
        factory = false, -- cornerRadius layers do not use Insets factories
    },
}

-- Maps property keys to their family names
Quads.KEY_TO_FAMILY = {
    padding = 'padding',
    paddingTop = 'padding',
    paddingRight = 'padding',
    paddingBottom = 'padding',
    paddingLeft = 'padding',
    margin = 'margin',
    marginTop = 'margin',
    marginRight = 'margin',
    marginBottom = 'margin',
    marginLeft = 'margin',
    safeAreaInsets = 'safeAreaInsets',
    borderWidth = 'borderWidth',
    borderWidthTop = 'borderWidth',
    borderWidthRight = 'borderWidth',
    borderWidthBottom = 'borderWidth',
    borderWidthLeft = 'borderWidth',
    cornerRadius = 'cornerRadius',
    cornerRadiusTopLeft = 'cornerRadius',
    cornerRadiusTopRight = 'cornerRadius',
    cornerRadiusBottomRight = 'cornerRadius',
    cornerRadiusBottomLeft = 'cornerRadius',
}

-- Maps property keys to their accessor names within resolved quad objects
Quads.MEMBER_ACCESSOR = {
    paddingTop = 'top', paddingRight = 'right', paddingBottom = 'bottom', paddingLeft = 'left',
    marginTop = 'top', marginRight = 'right', marginBottom = 'bottom', marginLeft = 'left',
    borderWidthTop = 'top', borderWidthRight = 'right', borderWidthBottom = 'bottom', borderWidthLeft = 'left',
    cornerRadiusTopLeft = 'topLeft', cornerRadiusTopRight = 'topRight',
    cornerRadiusBottomRight = 'bottomRight', cornerRadiusBottomLeft = 'bottomLeft',
}

-- Fills a side quad layer from a source table
-- Returns the target table for chaining
local function fill_side_quad_layer(target, source, family)
    if source == nil then
        target.aggregate = nil
        target.top = nil
        target.right = nil
        target.bottom = nil
        target.left = nil
    else
        target.aggregate = source[family.aggregate]
        target.top = source[family.members.top]
        target.right = source[family.members.right]
        target.bottom = source[family.members.bottom]
        target.left = source[family.members.left]
    end
    return target
end

-- Fills a corner quad layer from a source table
-- Returns the target table for chaining
local function fill_corner_quad_layer(target, source, family)
    if source == nil then
        target.aggregate = nil
        target.topLeft = nil
        target.topRight = nil
        target.bottomRight = nil
        target.bottomLeft = nil
    else
        target.aggregate = source[family.aggregate]
        target.topLeft = source[family.members.topLeft]
        target.topRight = source[family.members.topRight]
        target.bottomRight = source[family.members.bottomRight]
        target.bottomLeft = source[family.members.bottomLeft]
    end
    return target
end

-- Resolves a quad property value by merging responsive overrides with base values
-- Returns the resolved quad object or a specific member value
local function resolve_quad_value(self, family_name, requested_key)
    local family = Quads.FAMILIES[family_name]

    if not Styling.requires_resolution(self, requested_key, family) then
        return nil
    end

    local overrides = self._resolved_responsive_overrides

    if family.kind == 'corner' then
        local resolved = CornerQuad.resolve_layers({
            fill_corner_quad_layer(corner_scratch_layer_1, overrides, family),
            fill_corner_quad_layer(corner_scratch_layer_2, self._pdata, family),
        }, {
            label = family.aggregate,
        }, 3)

        if resolved == nil then
            return nil
        end

        if requested_key == family.aggregate then
            return resolved
        end

        local accessor = Quads.MEMBER_ACCESSOR[requested_key]
        if accessor then
            return resolved[accessor]
        end

        return nil
    end

    local resolved = SideQuad.resolve_layers({
        fill_side_quad_layer(side_scratch_layer_1, overrides, family),
        fill_side_quad_layer(side_scratch_layer_2, self._pdata, family),
    }, {
        label = family.aggregate,
        factory = family.factory,
    }, 3)

    if resolved == nil then
        return nil
    end

    if requested_key == family.aggregate then
        return resolved
    end

    local accessor = Quads.MEMBER_ACCESSOR[requested_key]
    if accessor then
        return resolved[accessor]
    end

    return nil
end

-- Returns the effective value of a property, accounting for responsive overrides
-- For quad properties, delegates to resolve_quad_value
-- For other properties, checks _resolved_responsive_overrides first, then falls back to raw value
function Quads.get_effective_value(self, key)
    local family_name = Quads.KEY_TO_FAMILY[key]
    if family_name ~= nil then
        local family = Quads.FAMILIES[family_name]
        if Styling.requires_resolution(self, key, family) then
            return resolve_quad_value(self, family_name, key)
        end
        return rawget(self, key)
    end

    local overrides = self._resolved_responsive_overrides
    if not Styling.requires_resolution(self, key) then
        return rawget(self, key)
    end

    if overrides ~= nil and overrides[key] ~= nil then
        return overrides[key]
    end

    return rawget(self, key)
end

-- Internal helper for fill_side_quad_layer (exposed for container.lua)
Quads._fill_side_quad_layer = fill_side_quad_layer

-- Internal helper for fill_corner_quad_layer (exposed for container.lua)
Quads._fill_corner_quad_layer = fill_corner_quad_layer

return Quads
