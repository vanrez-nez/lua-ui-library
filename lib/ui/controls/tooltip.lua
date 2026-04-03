local Container = require('lib.ui.core.container')
local Drawable = require('lib.ui.core.drawable')
local ControlUtils = require('lib.ui.controls.control_utils')
local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')

local Tooltip = Container:extends('Tooltip')

local PLACEMENTS = { top = true, bottom = true, left = true, right = true }
local ALIGNS = { start = true, center = true, ['end'] = true }
local TRIGGER_MODES = { hover = true, focus = true, ['hover-focus'] = true, manual = true }

local function effective_open(self)
    if rawget(self, '_open_controlled') then
        return rawget(self, 'open') == true
    end
    return rawget(self, '_open_uncontrolled') == true
end

local function request_open_change(self, next_value)
    next_value = next_value == true
    if not rawget(self, '_open_controlled') then
        rawset(self, '_open_uncontrolled', next_value)
    end
    ControlUtils.call_if_function(rawget(self, 'onOpenChange'), next_value)
end

local function detach_overlay_root(self)
    local stage = rawget(self, '_mounted_stage')
    if stage ~= nil then
        stage:_set_focus_contract_internal(rawget(self, '_overlay_root'), nil)
    end

    local overlay_root = rawget(self, '_overlay_root')
    if overlay_root.parent ~= nil then
        overlay_root.parent:removeChild(overlay_root)
    end

    rawset(self, '_mounted_stage', nil)
end

local function attach_overlay_root(self, stage)
    local overlay_root = rawget(self, '_overlay_root')
    if overlay_root.parent ~= stage.overlayLayer then
        stage.overlayLayer:addChild(overlay_root)
    end
    stage:_set_focus_contract_internal(overlay_root, { scope = true })
    rawset(self, '_mounted_stage', stage)
end

local function hovered(self)
    if love == nil or love.mouse == nil or not Types.is_function(love.mouse.getPosition) then
        return false
    end

    local x, y = love.mouse.getPosition()
    return rawget(self, 'trigger'):containsPoint(x, y)
end

local function focused(self)
    local focus_owner = ControlUtils.stage_focus_owner(self)
    local current = focus_owner
    local trigger = rawget(self, 'trigger')
    while current ~= nil do
        if current == trigger then
            return true
        end
        current = rawget(current, 'parent')
    end
    return false
end

local function desired_open(self)
    local mode = rawget(self, 'triggerMode')
    if mode == 'manual' then
        return effective_open(self)
    end
    if mode == 'hover' then
        return hovered(self)
    end
    if mode == 'focus' then
        return focused(self)
    end
    return hovered(self) or focused(self)
end

local function candidate_rect(trigger_bounds, width, height, placement, align, offset)
    local x = trigger_bounds.x
    local y = trigger_bounds.y

    if placement == 'top' then
        y = trigger_bounds.y - height - offset
        if align == 'center' then
            x = trigger_bounds.x + (trigger_bounds.width - width) * 0.5
        elseif align == 'end' then
            x = trigger_bounds.x + trigger_bounds.width - width
        end
    elseif placement == 'bottom' then
        y = trigger_bounds.y + trigger_bounds.height + offset
        if align == 'center' then
            x = trigger_bounds.x + (trigger_bounds.width - width) * 0.5
        elseif align == 'end' then
            x = trigger_bounds.x + trigger_bounds.width - width
        end
    elseif placement == 'left' then
        x = trigger_bounds.x - width - offset
        if align == 'center' then
            y = trigger_bounds.y + (trigger_bounds.height - height) * 0.5
        elseif align == 'end' then
            y = trigger_bounds.y + trigger_bounds.height - height
        end
    else
        x = trigger_bounds.x + trigger_bounds.width + offset
        if align == 'center' then
            y = trigger_bounds.y + (trigger_bounds.height - height) * 0.5
        elseif align == 'end' then
            y = trigger_bounds.y + trigger_bounds.height - height
        end
    end

    return {
        x = x,
        y = y,
        width = width,
        height = height,
    }
end

local function visible_area(rect, viewport)
    local x1 = math.max(rect.x, viewport.x)
    local y1 = math.max(rect.y, viewport.y)
    local x2 = math.min(rect.x + rect.width, viewport.x + viewport.width)
    local y2 = math.min(rect.y + rect.height, viewport.y + viewport.height)
    local width = math.max(0, x2 - x1)
    local height = math.max(0, y2 - y1)
    return width * height
end

local function resolve_placement(self, stage)
    local surface = rawget(self, 'surface')
    local bounds = rawget(self, 'trigger'):getWorldBounds()
    local viewport = rawget(self, 'safeAreaAware') and stage:getSafeAreaBounds() or stage:getViewport()
    local placements = {
        rawget(self, 'placement'),
        'top',
        'bottom',
        'left',
        'right',
    }

    local width = surface:getLocalBounds().width
    local height = surface:getLocalBounds().height
    local best = nil
    local best_area = -1

    for index = 1, #placements do
        local placement = placements[index]
        local rect = candidate_rect(bounds, width, height, placement, rawget(self, 'align'), rawget(self, 'offset'))
        local area = visible_area(rect, viewport)
        if area > best_area then
            best = {
                placement = placement,
                rect = rect,
            }
            best_area = area
        end
    end

    surface.x = best.rect.x
    surface.y = best.rect.y
    surface:markDirty()
    rawset(self, '_resolved_placement', best.placement)
end

function Tooltip:constructor(opts)
    opts = opts or {}
    Assert.table('opts', opts, 2)

    local base_opts = ControlUtils.base_opts(opts, {
        interactive = false,
        focusable = false,
    })
    Container.constructor(self, base_opts)

    rawset(self, '_ui_tooltip_control', true)
    rawset(self, 'open', opts.open)
    rawset(self, 'onOpenChange', opts.onOpenChange)
    rawset(self, 'placement', opts.placement or 'top')
    rawset(self, 'align', opts.align or 'center')
    rawset(self, 'offset', opts.offset or 8)
    rawset(self, 'triggerMode', opts.triggerMode or 'hover-focus')
    rawset(self, 'safeAreaAware', opts.safeAreaAware ~= false)
    rawset(self, '_open_controlled', opts.open ~= nil)
    rawset(self, '_open_uncontrolled', opts.open == true)
    rawset(self, '_mounted_stage', nil)
    rawset(self, '_last_open_state', effective_open(self))
    rawset(self, '_resolved_placement', rawget(self, 'placement'))

    ControlUtils.assert_controlled_pair('open', opts.open, 'onOpenChange', opts.onOpenChange, 2)

    if not PLACEMENTS[self.placement] then
        Assert.fail('Tooltip.placement is invalid', 2)
    end
    if not ALIGNS[self.align] then
        Assert.fail('Tooltip.align is invalid', 2)
    end
    if not TRIGGER_MODES[self.triggerMode] then
        Assert.fail('Tooltip.triggerMode is invalid', 2)
    end
    if self.offset < 0 then
        Assert.fail('Tooltip.offset must be >= 0', 2)
    end

    local trigger = Container.new({
        tag = (self.tag and (self.tag .. '.trigger')) or 'tooltip.trigger',
        internal = true,
        width = 180,
        height = 42,
        interactive = true,
        focusable = true,
    })
    local overlay_root = Container.new({
        tag = (self.tag and (self.tag .. '.overlay')) or 'tooltip.overlay',
        internal = true,
        width = 'fill',
        height = 'fill',
        interactive = false,
        focusable = false,
    })
    Container._allow_fill_from_parent(overlay_root, { width = true, height = true })
    local surface = Drawable.new({
        tag = (self.tag and (self.tag .. '.surface')) or 'tooltip.surface',
        internal = true,
        width = 220,
        height = 80,
        interactive = false,
        focusable = false,
    })
    rawset(surface, '_styling_context', {
        component = 'tooltip',
        part = 'surface',
    })
    local content = Container.new({
        tag = (self.tag and (self.tag .. '.content')) or 'tooltip.content',
        internal = true,
        width = 'fill',
        height = 'fill',
        interactive = false,
        focusable = false,
    })
    Container._allow_fill_from_parent(content, { width = true, height = true })
    Container._allow_child_fill(content, { width = true, height = true })

    overlay_root:addChild(surface)
    surface:addChild(content)
    Container.addChild(self, trigger)

    rawset(self, 'root', self)
    rawset(self, 'trigger', trigger)
    rawset(self, 'surface', surface)
    rawset(self, 'content', content)
    rawset(self, '_overlay_root', overlay_root)

    if opts.trigger ~= nil then
        trigger:addChild(opts.trigger)
    end
    if opts.content ~= nil then
        content:addChild(opts.content)
    end

    overlay_root:_add_event_listener('ui.dismiss', function(event)
        request_open_change(self, false)
        event:stopPropagation()
    end)
end

function Tooltip.new(opts)
    return Tooltip(opts)
end

function Tooltip:update(dt)
    Container.update(self, dt)

    if rawget(self, 'triggerMode') ~= 'manual' and rawget(self, '_open_controlled') == false then
        request_open_change(self, desired_open(self))
    end

    local wants_open = effective_open(self)
    local stage = ControlUtils.find_stage(self)
    local was_open = rawget(self, '_last_open_state')

    if wants_open and stage ~= nil then
        attach_overlay_root(self, stage)
        resolve_placement(self, stage)
        if not was_open then
            self:_raise_motion('open', {
                defaultTarget = 'surface',
                resolvedPlacement = rawget(self, '_resolved_placement'),
            })
        else
            self:_raise_motion('placement', {
                defaultTarget = 'surface',
                resolvedPlacement = rawget(self, '_resolved_placement'),
            })
        end
    else
        if rawget(self, '_mounted_stage') ~= nil then
            detach_overlay_root(self)
        end
        if was_open and not wants_open then
            self:_raise_motion('close', { defaultTarget = 'surface' })
        end
    end

    rawset(self, '_last_open_state', wants_open)
    return self
end

function Tooltip:destroy()
    if rawget(self, '_destroyed') then
        return
    end
    detach_overlay_root(self)
    if not rawget(rawget(self, '_overlay_root'), '_destroyed') then
        rawget(self, '_overlay_root'):destroy()
    end
    Container.destroy(self)
end

return Tooltip
