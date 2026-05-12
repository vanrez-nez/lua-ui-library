local Drawable = require('lib.ui.core.drawable')
local Text = require('lib.ui.controls.text')
local Button = require('lib.ui.controls.button')
local Vec2 = require('lib.ui.utils.vec2')

local Compat = {
  Vec2 = Vec2
}

local LAYOUT_KEYS = {
  id = true,
  name = true,
  tag = true,
  internal = true,
  visible = true,
  interactive = true,
  enabled = true,
  focusable = true,
  clipChildren = true,
  zIndex = true,
  x = true,
  y = true,
  width = true,
  height = true,
  minWidth = true,
  minHeight = true,
  maxWidth = true,
  maxHeight = true,
  scaleX = true,
  scaleY = true,
  rotation = true,
  skewX = true,
  skewY = true,
  backgroundColor = true,
  borderColor = true,
  borderWidth = true,
  cornerRadius = true,
  opacity = true
}

local function apply_layout(opts)
  opts = opts or {}
  local out = {}

  for key in pairs(LAYOUT_KEYS) do
    if opts[key] ~= nil then
      out[key] = opts[key]
    end
  end

  if opts.size ~= nil then
    out.width = opts.size.x
    out.height = opts.size.y
  end

  if opts.pos ~= nil then
    out.x = opts.pos.x
    out.y = opts.pos.y
  end

  if opts.anchor ~= nil then
    out.anchorX = opts.anchor.x
    out.anchorY = opts.anchor.y
  end

  if opts.pivot ~= nil then
    out.pivotX = opts.pivot.x
    out.pivotY = opts.pivot.y
  end

  return out
end

local function read_size_value(node, resolved_key, public_key, fallback)
  if node ~= nil and type(node[resolved_key]) == 'number' then
    return node[resolved_key]
  end

  if node ~= nil and type(node[public_key]) == 'number' then
    return node[public_key]
  end

  return fallback or 0
end

local function corner_radius(value)
  if type(value) == 'number' then
    return { value, value, value, value }
  end

  return value
end

function Compat.drawable(opts)
  return Drawable.new(apply_layout(opts))
end

function Compat.text(opts)
  opts = opts or {}
  local out = apply_layout(opts)
  out.text = opts.text or ''
  out.font = opts.font or opts.fontPath
  out.fontSize = opts.fontSize
  out.lineHeight = opts.lineHeight
  out.maxWidth = opts.maxWidth
  out.textAlign = opts.textAlign or opts.alignH
  out.textVariant = opts.textVariant
  out.color = opts.color
  out.wrap = opts.wrap == true or opts.maxWidth ~= nil
  return Text.new(out)
end

function Compat.button(opts)
  opts = opts or {}
  local out = apply_layout(opts)
  local label = opts.label or ''

  if opts.color ~= nil then
    out.backgroundColor = opts.color
  end

  if opts.borderColor ~= nil then
    out.borderColor = opts.borderColor
    out.borderWidth = out.borderWidth or 1
  end

  out.cornerRadius = corner_radius(out.cornerRadius or 10)
  out.onActivate = function(self, event)
    if opts.onClick ~= nil then
      opts.onClick(self, event)
    end
  end

  local label_node = Text.new({
    internal = true,
    text = label,
    fontSize = 16,
    maxWidth = out.width,
    textAlign = 'center',
    color = { 1, 1, 1, 1 },
    wrap = true,
    anchorX = 0.5,
    anchorY = 0.5,
    pivotX = 0.5,
    pivotY = 0.5
  })

  out.content = label_node

  local button = Button.new(out)
  button._compat_label_node = label_node

  function button:setLabel(value)
    self._compat_label_node:setText(value)
    return self
  end

  return button
end

function Compat.size(node)
  local fallback_width = 0
  local fallback_height = 0

  if love ~= nil and love.graphics ~= nil then
    fallback_width = love.graphics.getWidth()
    fallback_height = love.graphics.getHeight()
  end

  return read_size_value(node, '_resolved_width', 'width', fallback_width),
    read_size_value(node, '_resolved_height', 'height', fallback_height)
end

function Compat.set_pos(node, x, y)
  node.x = x
  node.y = y
  return node
end

return Compat
