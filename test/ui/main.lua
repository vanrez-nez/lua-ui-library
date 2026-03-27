-- test/ui/main.lua - Visual test demo for Vec2 + Container
-- Run with: love test/ui (from project root)

package.path = "?.lua;?/init.lua;" .. package.path

local UI        = require("lib.ui")
local Vec2      = UI.Vec2
local Container = UI.Container

-- ── Globals ──────────────────────────────────────────────

local screens = {}
local currentScreen = 1
local currentRoot   = nil

-- ── Helpers ──────────────────────────────────────────────

local function drawContainerDebug(c, color, label)
    c:pushTransform()
    local w, h = c.size.x, c.size.y
    love.graphics.setColor(color[1], color[2], color[3], 0.25)
    love.graphics.rectangle("fill", 0, 0, w, h)
    love.graphics.setColor(color[1], color[2], color[3], 0.9)
    love.graphics.rectangle("line", 0, 0, w, h)
    if label then
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(label, 4, 4)
    end
    c:popTransform()
end

local function drawTree(node, colors, labels, depth)
    depth = depth or 0
    local ci = (depth % #colors) + 1
    drawContainerDebug(node, colors[ci], labels and labels[node] or node.tag)
    for _, child in ipairs(node.children) do
        drawTree(child, colors, labels, depth + 1)
    end
end

local function makeRoot()
    local w, h = love.graphics.getDimensions()
    return Container.new({ anchor = Vec2(0,0), pivot = Vec2(0,0), size = Vec2(w, h) })
end

local function rebuildCurrent()
    local w, h = love.graphics.getDimensions()
    local scr = screens[currentScreen]
    currentRoot = scr.build(w, h)
    currentRoot:updateTransform()
end

-- ── Screen 1: Anchors (9-point) ─────────────────────────

screens[1] = {
    name = "Anchors (9-point)",
    build = function(w, h)
        local root = makeRoot()
        local sz = 60
        local anchors = {
            { "TL", 0,0 }, { "TC", 0.5,0 }, { "TR", 1,0 },
            { "ML", 0,0.5 }, { "MC", 0.5,0.5 }, { "MR", 1,0.5 },
            { "BL", 0,1 }, { "BC", 0.5,1 }, { "BR", 1,1 },
        }
        for _, a in ipairs(anchors) do
            root:addChild(Container.new({
                tag    = a[1],
                anchor = Vec2(a[2], a[3]),
                pivot  = Vec2(a[2], a[3]),
                size   = Vec2(sz, sz),
            }))
        end
        return root
    end,
    draw = function()
        local colors = {
            {0.9,0.3,0.3}, {0.3,0.9,0.3}, {0.3,0.3,0.9},
            {0.9,0.9,0.3}, {0.9,0.3,0.9}, {0.3,0.9,0.9},
            {1,0.6,0.2}, {0.6,1,0.2}, {0.2,0.6,1},
        }
        for i, child in ipairs(currentRoot.children) do
            drawContainerDebug(child, colors[i], child.tag)
        end
    end,
}

-- ── Screen 2: Pivot variations ──────────────────────────

screens[2] = {
    name = "Pivot variations",
    build = function(w, h)
        local root = makeRoot()
        local sz = 100
        local pivots = {
            { "TL(0,0)",   0,   0 },
            { "TR(1,0)",   1,   0 },
            { "Center",    0.5, 0.5 },
            { "BL(0,1)",   0,   1 },
            { "BR(1,1)",   1,   1 },
        }
        for _, p in ipairs(pivots) do
            root:addChild(Container.new({
                tag    = p[1],
                anchor = Vec2(0.5, 0.5),
                pivot  = Vec2(p[2], p[3]),
                size   = Vec2(sz, sz),
            }))
        end
        return root
    end,
    draw = function()
        -- Draw crosshair at center
        local cx = love.graphics.getWidth() / 2
        local cy = love.graphics.getHeight() / 2
        love.graphics.setColor(1, 1, 1, 0.3)
        love.graphics.line(cx - 20, cy, cx + 20, cy)
        love.graphics.line(cx, cy - 20, cx, cy + 20)

        local colors = {
            {0.9,0.2,0.2}, {0.2,0.9,0.2}, {0.2,0.2,0.9},
            {0.9,0.9,0.2}, {0.9,0.2,0.9},
        }
        for i, child in ipairs(currentRoot.children) do
            drawContainerDebug(child, colors[i], child.tag)
        end
    end,
}

-- ── Screen 3: Scale ─────────────────────────────────────

screens[3] = {
    name = "Scale (multiplier)",
    build = function(w, h)
        local root = makeRoot()
        local sz = 80
        local spacing = 200
        local startX = -2 * spacing

        local variants = {
            { "1x",   1,   1   },
            { "2x",   2,   2   },
            { "0.5x", 0.5, 0.5 },
            { "Wide", 3,   1   },
            { "Tall", 1,   2.5 },
        }
        for i, v in ipairs(variants) do
            root:addChild(Container.new({
                tag    = v[1],
                anchor = Vec2(0.5, 0.5),
                pivot  = Vec2(0.5, 0.5),
                pos    = Vec2(startX + (i - 1) * spacing, 0),
                size   = Vec2(sz, sz),
                scale  = Vec2(v[2], v[3]),
            }))
        end

        return root
    end,
    draw = function()
        local colors = {
            {0.8,0.3,0.3}, {0.3,0.8,0.3}, {0.3,0.3,0.8},
            {0.8,0.8,0.3}, {0.8,0.3,0.8},
        }
        for i, child in ipairs(currentRoot.children) do
            drawContainerDebug(child, colors[i], child.tag)
        end
    end,
}

-- ── Screen 4: Rotation & Scale (animated) ─────────────

local screen4 = { time = 0 }

screens[4] = {
    name = "Rotation & Scale (animated)",
    build = function(w, h)
        screen4.time = 0
        local root = makeRoot()

        local L1 = Container.new({
            tag    = "L1",
            anchor = Vec2(0.5, 0.5),
            pivot  = Vec2(0.5, 0.5),
            size   = Vec2(w * 0.55, h * 0.55),
        })
        root:addChild(L1)

        local L2 = Container.new({
            tag    = "L2",
            anchor = Vec2(0.3, 0.35),
            pivot  = Vec2(0.8, 0.2),
            size   = Vec2(w * 0.28, h * 0.28),
        })
        L1:addChild(L2)

        local L3 = Container.new({
            tag    = "L3",
            anchor = Vec2(0.7, 0.65),
            pivot  = Vec2(0.2, 0.8),
            size   = Vec2(w * 0.14, h * 0.14),
        })
        L2:addChild(L3)

        local orbiter = Container.new({
            tag    = "Orb",
            anchor = Vec2(0.95, 0.05),
            pivot  = Vec2(0.5, 1.0),
            size   = Vec2(50, 50),
        })
        L1:addChild(orbiter)

        return root
    end,
    update = function(dt)
        screen4.time = screen4.time + dt
        local t = screen4.time

        local nodes = {}
        local function collect(node)
            for _, c in ipairs(node.children) do
                nodes[#nodes + 1] = c
                collect(c)
            end
        end
        collect(currentRoot)

        -- Each node: { rotSpeed, scaleFreq, scaleAmp }
        local anim = {
            L1  = { 0.3,  0.8, 0.15 },
            L2  = { -0.5, 1.2, 0.10 },
            L3  = { 0.8,  1.6, 0.12 },
            Orb = { 1.2,  2.0, 0.20 },
        }

        for _, node in ipairs(nodes) do
            local a = anim[node.tag]
            if a then
                node:setRotation(t * a[1])
                local s = 1.0 + a[3] * math.sin(t * a[2])
                node:setScale(s, s)
            end
        end

        currentRoot:updateTransform()
    end,
    draw = function()
        local colors = {
            {0.9,0.4,0.2}, {0.2,0.7,0.9}, {0.9,0.9,0.2}, {0.8,0.3,0.8},
        }

        -- Collect all nodes for drawing
        local all = {}
        local function collect(node, depth)
            for _, c in ipairs(node.children) do
                all[#all + 1] = { node = c, depth = depth }
                collect(c, depth + 1)
            end
        end
        collect(currentRoot, 0)

        for _, entry in ipairs(all) do
            local c = entry.node
            local ci = (entry.depth % #colors) + 1
            local deg = math.deg(c.rotation) % 360
            local s = c.scale.x
            local label = string.format("%s %.0f° x%.2f", c.tag, deg, s)
            drawContainerDebug(c, colors[ci], label)

            -- Draw anchor dot
            if c.parent then
                local awx, awy = c.parent.worldTransform:apply(
                    c.anchor.x * c.parent.size.x,
                    c.anchor.y * c.parent.size.y
                )
                love.graphics.setColor(1, 1, 1)
                love.graphics.circle("fill", awx, awy, 4)
                love.graphics.setColor(1, 1, 1, 0.4)
                love.graphics.circle("line", awx, awy, 7)
            end
        end
    end,
}

-- ── Screen 5: Target sync ───────────────────────────────

local screen5_targets = {}

screens[5] = {
    name = "Target sync",
    build = function(w, h)
        local root = makeRoot()
        screen5_targets = {}

        local targetNames = { "BtnA", "BtnB", "BtnC" }
        for i, name in ipairs(targetNames) do
            local t = { x = 0, y = 0, w = 0, h = 0 }
            screen5_targets[i] = { name = name, target = t }

            root:addChild(Container.new({
                tag    = name,
                anchor = Vec2(0.5, 0),
                pivot  = Vec2(0.5, 0),
                pos    = Vec2(0, 60 + (i - 1) * 80),
                size   = Vec2(200, 60),
                target = t,
            }))
        end

        -- Also test manual applyTo
        local manual = { x = 0, y = 0, w = 0, h = 0 }
        screen5_targets[4] = { name = "Manual", target = manual }
        local manualNode = Container.new({
            tag    = "Manual",
            anchor = Vec2(0.5, 1),
            pivot  = Vec2(0.5, 1),
            pos    = Vec2(0, -30),
            size   = Vec2(160, 50),
        })
        root:addChild(manualNode)

        return root
    end,
    draw = function()
        -- Manually sync the last node
        local manualNode = currentRoot:getChildByTag("Manual")
        if manualNode then
            manualNode:applyTo(screen5_targets[4].target)
        end

        local colors = {
            {0.3,0.7,0.9}, {0.9,0.5,0.3}, {0.3,0.9,0.5}, {0.7,0.3,0.9},
        }
        for i, child in ipairs(currentRoot.children) do
            drawContainerDebug(child, colors[i], child.tag)
        end

        -- Display synced values
        love.graphics.setColor(1, 1, 1)
        local y = 10
        for i, info in ipairs(screen5_targets) do
            local t = info.target
            love.graphics.print(
                string.format("%s -> x=%.0f y=%.0f w=%.0f h=%.0f",
                    info.name, t.x, t.y, t.w, t.h),
                10, y
            )
            y = y + 18
        end
    end,
}

-- ── Screen 6: Dirty propagation ─────────────────────────

local screen6_nodes = {}

screens[6] = {
    name = "Dirty propagation",
    build = function(w, h)
        local root = makeRoot()
        screen6_nodes = {}

        --[[
            Tree structure (7 nodes):
                A
               / \
              B   C
             /|    \
            D  E    F
                     \
                      G
        ]]
        local A = Container.new({ tag = "A", anchor = Vec2(0.5, 0.1), pivot = Vec2(0.5, 0), size = Vec2(400, 60) })
        local B = Container.new({ tag = "B", anchor = Vec2(0.25, 1), pivot = Vec2(0.5, 0), pos = Vec2(0, 20), size = Vec2(160, 50) })
        local C = Container.new({ tag = "C", anchor = Vec2(0.75, 1), pivot = Vec2(0.5, 0), pos = Vec2(0, 20), size = Vec2(160, 50) })
        local D = Container.new({ tag = "D", anchor = Vec2(0.25, 1), pivot = Vec2(0.5, 0), pos = Vec2(0, 15), size = Vec2(60, 40) })
        local E = Container.new({ tag = "E", anchor = Vec2(0.75, 1), pivot = Vec2(0.5, 0), pos = Vec2(0, 15), size = Vec2(60, 40) })
        local F = Container.new({ tag = "F", anchor = Vec2(0.5, 1),  pivot = Vec2(0.5, 0), pos = Vec2(0, 15), size = Vec2(80, 40) })
        local G = Container.new({ tag = "G", anchor = Vec2(0.5, 1),  pivot = Vec2(0.5, 0), pos = Vec2(0, 15), size = Vec2(50, 35) })

        root:addChild(A)
        A:addChild(B)
        A:addChild(C)
        B:addChild(D)
        B:addChild(E)
        C:addChild(F)
        F:addChild(G)

        screen6_nodes = { A, B, C, D, E, F, G }
        return root
    end,
    draw = function()
        for _, node in ipairs(screen6_nodes) do
            local color
            if node._dirty then
                color = {0.9, 0.2, 0.2}
            else
                color = {0.2, 0.8, 0.2}
            end
            drawContainerDebug(node, color, node.tag .. (node._dirty and " [dirty]" or " [clean]"))
        end

        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Space = setPos on A (marks dirty)    Enter = updateTransform (clears dirty)", 10, love.graphics.getHeight() - 30)
    end,
    keypressed = function(key)
        if key == "space" and #screen6_nodes > 0 then
            screen6_nodes[1]:setPos(screen6_nodes[1].pos.x, screen6_nodes[1].pos.y)
        elseif key == "return" then
            currentRoot:updateTransform()
        end
    end,
}

-- ── Screen 7: Coordinate helpers ────────────────────────

screens[7] = {
    name = "Coordinate helpers",
    build = function(w, h)
        local root = makeRoot()

        local boxes = {
            { "BoxA", 0.25, 0.4, 180, 120 },
            { "BoxB", 0.65, 0.5, 200, 150 },
            { "BoxC", 0.5,  0.8, 140, 80 },
        }
        for _, b in ipairs(boxes) do
            root:addChild(Container.new({
                tag    = b[1],
                anchor = Vec2(b[2], b[3]),
                pivot  = Vec2(0.5, 0.5),
                size   = Vec2(b[4], b[5]),
            }))
        end

        return root
    end,
    draw = function()
        local mx, my = love.mouse.getPosition()

        local colors = {
            {0.4,0.6,0.9}, {0.9,0.6,0.4}, {0.6,0.9,0.4},
        }
        for i, child in ipairs(currentRoot.children) do
            local hover = child:containsPoint(mx, my)
            local c = colors[i]
            if hover then
                c = {1, 1, 1}
            end
            drawContainerDebug(child, c, child.tag)

            if hover then
                local lx, ly = child:worldToLocal(mx, my)
                local wx2, wy2 = child:localToWorld(lx, ly)
                love.graphics.setColor(1, 1, 0)
                love.graphics.print(
                    string.format("local: (%.0f, %.0f)  world: (%.0f, %.0f)", lx, ly, wx2, wy2),
                    child._worldPos.x + 4, child._worldPos.y + child._worldSize.y + 4
                )
            end
        end

        -- Mouse crosshair
        love.graphics.setColor(1, 1, 1, 0.4)
        love.graphics.line(mx - 10, my, mx + 10, my)
        love.graphics.line(mx, my - 10, mx, my + 10)

        love.graphics.setColor(1, 1, 1)
        love.graphics.print(string.format("Mouse: (%d, %d) - hover a box to see coords", mx, my), 10, 10)
    end,
}

-- ── Screen 8: findByTag ─────────────────────────────────

local screen8_found = { direct = nil, recursive = nil }

screens[8] = {
    name = "findByTag",
    build = function(w, h)
        local root = makeRoot()
        screen8_found = { direct = nil, recursive = nil }

        local parent = Container.new({
            tag     = "Parent",
            anchor  = Vec2(0.5, 0.3),
            pivot   = Vec2(0.5, 0.5),
            size    = Vec2(w * 0.7, h * 0.4),
        })
        root:addChild(parent)

        local childA = Container.new({
            tag    = "ChildA",
            anchor = Vec2(0.25, 0.5),
            pivot  = Vec2(0.5, 0.5),
            size   = Vec2(100, 60),
        })
        parent:addChild(childA)

        local childB = Container.new({
            tag    = "ChildB",
            anchor = Vec2(0.75, 0.5),
            pivot  = Vec2(0.5, 0.5),
            size   = Vec2(100, 60),
        })
        parent:addChild(childB)

        local deep = Container.new({
            tag    = "DeepNode",
            anchor = Vec2(0.5, 0.5),
            pivot  = Vec2(0.5, 0.5),
            size   = Vec2(50, 30),
        })
        childA:addChild(deep)

        -- Test getChildByTag (direct only)
        screen8_found.direct = parent:getChildByTag("ChildA")

        -- Test findByTag (recursive)
        screen8_found.recursive = parent:findByTag("DeepNode")

        -- getChildByTag won't find deep nodes
        screen8_found.directDeep = parent:getChildByTag("DeepNode")

        return root
    end,
    draw = function()
        local colors = {
            {0.4,0.4,0.4}, {0.6,0.8,0.3}, {0.3,0.6,0.8}, {0.8,0.3,0.6},
        }
        drawTree(currentRoot, colors)

        -- Highlight found nodes
        if screen8_found.direct then
            local x, y, w, h = screen8_found.direct:getRect()
            love.graphics.setColor(0, 1, 0, 0.5)
            love.graphics.setLineWidth(3)
            love.graphics.rectangle("line", x - 2, y - 2, w + 4, h + 4)
            love.graphics.setLineWidth(1)
        end

        if screen8_found.recursive then
            local x, y, w, h = screen8_found.recursive:getRect()
            love.graphics.setColor(1, 1, 0, 0.5)
            love.graphics.setLineWidth(3)
            love.graphics.rectangle("line", x - 2, y - 2, w + 4, h + 4)
            love.graphics.setLineWidth(1)
        end

        -- Info text
        love.graphics.setColor(1, 1, 1)
        local by = love.graphics.getHeight() - 80
        love.graphics.print("getChildByTag('ChildA') => " .. tostring(screen8_found.direct and screen8_found.direct.tag or "nil") .. "  (green border)", 10, by)
        love.graphics.print("findByTag('DeepNode')   => " .. tostring(screen8_found.recursive and screen8_found.recursive.tag or "nil") .. "  (yellow border)", 10, by + 18)
        love.graphics.print("getChildByTag('DeepNode') => " .. tostring(screen8_found.directDeep and screen8_found.directDeep.tag or "nil") .. "  (not found - direct children only)", 10, by + 36)
    end,
}

-- ── Screen 9: Vec2 operations ──────────────────────────

local screen9 = { lerpT = 0 }

screens[9] = {
    name = "Vec2 operations",
    build = function(w, h)
        screen9.lerpT = 0
        return makeRoot()
    end,
    draw = function()
        local x, y = 30, 40
        local lineH = 22

        love.graphics.setColor(1, 1, 1)

        -- Operators
        local a = Vec2(10, 20)
        local b = Vec2(3, 4)

        love.graphics.print("a = " .. tostring(a), x, y); y = y + lineH
        love.graphics.print("b = " .. tostring(b), x, y); y = y + lineH
        y = y + 5
        love.graphics.print("a + b = " .. tostring(a + b), x, y); y = y + lineH
        love.graphics.print("a - b = " .. tostring(a - b), x, y); y = y + lineH
        love.graphics.print("a * b = " .. tostring(a * b), x, y); y = y + lineH
        love.graphics.print("a * 3 = " .. tostring(a * 3), x, y); y = y + lineH
        love.graphics.print("2 * b = " .. tostring(2 * b), x, y); y = y + lineH
        love.graphics.print("-a    = " .. tostring(-a), x, y); y = y + lineH
        love.graphics.print("a == Vec2(10,20) => " .. tostring(a == Vec2(10, 20)), x, y); y = y + lineH
        love.graphics.print("a == b => " .. tostring(a == b), x, y); y = y + lineH

        y = y + 10
        love.graphics.print("clone: a:clone() = " .. tostring(a:clone()), x, y); y = y + lineH

        -- unpack
        local ux, uy = a:unpack()
        love.graphics.print(string.format("unpack: a:unpack() => %s, %s", ux, uy), x, y); y = y + lineH

        -- length
        love.graphics.print(string.format("length: b:length() = %.4f", b:length()), x, y); y = y + lineH

        -- Constants
        y = y + 10
        love.graphics.print("Vec2.ZERO = " .. tostring(Vec2.ZERO), x, y); y = y + lineH
        love.graphics.print("Vec2.ONE  = " .. tostring(Vec2.ONE), x, y); y = y + lineH
        love.graphics.print("Vec2.HALF = " .. tostring(Vec2.HALF), x, y); y = y + lineH

        -- Lerp visualization
        y = y + 20
        love.graphics.print("Lerp animation:", x, y); y = y + lineH + 5

        local startP = Vec2(x, y + 20)
        local endP   = Vec2(x + 300, y + 20)
        local lerpP  = startP:lerp(endP, screen9.lerpT)

        -- Draw line
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.line(startP.x, startP.y, endP.x, endP.y)

        -- Draw endpoints
        love.graphics.setColor(0.3, 0.8, 0.3)
        love.graphics.circle("fill", startP.x, startP.y, 6)
        love.graphics.circle("fill", endP.x, endP.y, 6)

        -- Draw lerp dot
        love.graphics.setColor(1, 0.3, 0.3)
        love.graphics.circle("fill", lerpP.x, lerpP.y, 8)

        love.graphics.setColor(1, 1, 1)
        love.graphics.print(string.format("t = %.2f", screen9.lerpT), lerpP.x - 15, lerpP.y + 15)

        -- Length arrow
        y = y + 70
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Length visualization:", x, y); y = y + lineH + 5

        local origin = Vec2(x, y + 20)
        local dir = Vec2(b.x * 20, b.y * 20)
        local tip = origin + dir

        love.graphics.setColor(0.3, 0.6, 1)
        love.graphics.setLineWidth(2)
        love.graphics.line(origin.x, origin.y, tip.x, tip.y)
        love.graphics.circle("fill", tip.x, tip.y, 4)
        love.graphics.setLineWidth(1)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(string.format("|b| = %.4f", b:length()), tip.x + 10, tip.y - 8)
    end,
    update = function(dt)
        screen9.lerpT = screen9.lerpT + dt * 0.4
        if screen9.lerpT > 1 then screen9.lerpT = 0 end
    end,
}

-- ── LOVE callbacks ──────────────────────────────────────

function love.load()
    love.graphics.setBackgroundColor(0.12, 0.12, 0.14)
    rebuildCurrent()
end

function love.update(dt)
    local scr = screens[currentScreen]
    if scr.update then scr.update(dt) end
end

function love.draw()
    -- Draw current screen
    local scr = screens[currentScreen]
    scr.draw()

    -- HUD
    love.graphics.setColor(0.15, 0.15, 0.18, 0.85)
    love.graphics.rectangle("fill", 0, love.graphics.getHeight() - 24, love.graphics.getWidth(), 24)
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print(
        string.format("[%d/%d] %s  |  Left/Right = navigate", currentScreen, #screens, scr.name),
        8, love.graphics.getHeight() - 20
    )
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif key == "right" then
        currentScreen = currentScreen % #screens + 1
        rebuildCurrent()
    elseif key == "left" then
        currentScreen = (currentScreen - 2) % #screens + 1
        rebuildCurrent()
    else
        local scr = screens[currentScreen]
        if scr.keypressed then scr.keypressed(key) end
    end
end

function love.resize(w, h)
    rebuildCurrent()
end
