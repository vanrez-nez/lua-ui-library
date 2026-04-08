local Container = require('lib.ui.core.container')
local UI = require('lib.ui')

local function assert_equal(actual, expected, message)
    if actual ~= expected then
        error(message .. ': expected ' .. tostring(expected) ..
            ', got ' .. tostring(actual), 2)
    end
end

local function assert_true(value, message)
    if not value then
        error(message, 2)
    end
end

local function assert_error(fn, needle, message)
    local ok, err = pcall(fn)

    if ok then
        error(message .. ': expected an error', 2)
    end

    local text = tostring(err)

    if needle and not text:find(needle, 1, true) then
        error(message .. ': expected error containing "' .. needle ..
            '", got "' .. text .. '"', 2)
    end
end

local function assert_children(parent, expected, message)
    local actual = parent:getChildren()

    assert_equal(#actual, #expected, message .. ' child count')

    for index = 1, #expected do
        assert_equal(actual[index], expected[index], message .. ' child ' .. index)
    end
end

local function run_public_surface_tests()
    local breakpoints = {
        compact = {
            width = '100%',
        },
    }

    local node = Container.new({
        tag = 'root',
        visible = false,
        interactive = true,
        enabled = false,
        focusable = true,
        clipChildren = true,
        zIndex = 7,
        anchorX = 0.25,
        anchorY = 0.75,
        pivotX = 0.5,
        pivotY = 1,
        x = 12,
        y = 18,
        width = '75%',
        height = 'fill',
        minWidth = 40,
        minHeight = 30,
        maxWidth = 400,
        maxHeight = 300,
        scaleX = 2,
        scaleY = 0.5,
        rotation = 0.25,
        skewX = 0.1,
        skewY = -0.2,
        breakpoints = breakpoints,
    })

    assert_equal(UI.Container, Container,
        'lib.ui should expose the Container module')
    assert_equal(node.tag, 'root', 'Container should preserve tag')
    assert_equal(node.visible, false, 'Container should preserve visible')
    assert_equal(node.interactive, true, 'Container should preserve interactive')
    assert_equal(node.enabled, false, 'Container should preserve enabled')
    assert_equal(node.focusable, true, 'Container should preserve focusable')
    assert_equal(node.clipChildren, true, 'Container should preserve clipChildren')
    assert_equal(node.zIndex, 7, 'Container should preserve zIndex')
    assert_equal(node.anchorX, 0.25, 'Container should preserve anchorX')
    assert_equal(node.anchorY, 0.75, 'Container should preserve anchorY')
    assert_equal(node.pivotX, 0.5, 'Container should preserve pivotX')
    assert_equal(node.pivotY, 1, 'Container should preserve pivotY')
    assert_equal(node.x, 12, 'Container should preserve x')
    assert_equal(node.y, 18, 'Container should preserve y')
    assert_equal(node.width, '75%', 'Container should preserve percentage width')
    assert_equal(node.height, 'fill', 'Container should preserve fill height')
    assert_equal(node.minWidth, 40, 'Container should preserve minWidth')
    assert_equal(node.minHeight, 30, 'Container should preserve minHeight')
    assert_equal(node.maxWidth, 400, 'Container should preserve maxWidth')
    assert_equal(node.maxHeight, 300, 'Container should preserve maxHeight')
    assert_equal(node.scaleX, 2, 'Container should preserve scaleX')
    assert_equal(node.scaleY, 0.5, 'Container should preserve scaleY')
    assert_equal(node.rotation, 0.25, 'Container should preserve rotation')
    assert_equal(node.skewX, 0.1, 'Container should preserve skewX')
    assert_equal(node.skewY, -0.2, 'Container should preserve skewY')
    assert_equal(node.breakpoints, breakpoints,
        'Container should preserve breakpoints by reference')

    assert_error(function()
        Container.new({ width = 'content' })
    end, 'intrinsic measurement rule',
    'Container width=content should fail deterministically')

    assert_error(function()
        Container.new({ height = 'content' })
    end, 'intrinsic measurement rule',
    'Container height=content should fail deterministically')

    assert_error(function()
        Container.new({ focusScope = true })
    end, 'focusScope',
    'Container should reject unsupported focusScope props')

    assert_error(function()
        Container.new({ trapFocus = true })
    end, 'trapFocus',
    'Container should reject unsupported trapFocus props')
end

local function run_default_anchor_and_pivot_tests()
    local node = Container.new({
        tag = 'defaults',
    })

    assert_equal(node.anchorX, 0,
        'Container should default anchorX to origin-based parent attachment')
    assert_equal(node.anchorY, 0,
        'Container should default anchorY to origin-based parent attachment')
    assert_equal(node.pivotX, 0.5,
        'Container should default pivotX to centered local transforms')
    assert_equal(node.pivotY, 0.5,
        'Container should default pivotY to centered local transforms')
end

local function run_tree_management_tests()
    local parent_a = Container.new({ tag = 'parent-a' })
    local parent_b = Container.new({ tag = 'parent-b' })
    local child_a = Container.new({ tag = 'child-a' })
    local child_b = Container.new({ tag = 'child-b' })
    local leaf = Container.new({ tag = 'leaf' })

    parent_a:addChild(child_a)
    parent_a:addChild(child_b)
    child_a:addChild(leaf)

    assert_children(parent_a, { child_a, child_b },
        'Container should preserve insertion order')
    assert_equal(child_a.parent, parent_a,
        'Container should set parent references on addChild')
    assert_equal(leaf.parent, child_a,
        'Container should preserve deeper parent references')

    local snapshot = parent_a:getChildren()
    snapshot[1] = child_b
    snapshot[2] = nil

    assert_children(parent_a, { child_a, child_b },
        'Container:getChildren should return a defensive copy')

    parent_a:addChild(child_a)

    assert_children(parent_a, { child_a, child_b },
        'Re-adding an existing child to the same parent should not duplicate it')

    parent_b:addChild(child_a)

    assert_children(parent_a, { child_b },
        'Reparenting should detach the child from the prior parent')
    assert_children(parent_b, { child_a },
        'Reparenting should attach the child to the new parent once')
    assert_equal(child_a.parent, parent_b,
        'Reparenting should update the child parent reference')
end

local function run_cycle_and_destroy_tests()
    local root = Container.new({ tag = 'root' })
    local branch = Container.new({ tag = 'branch' })
    local leaf = Container.new({ tag = 'leaf' })

    root:addChild(branch)
    branch:addChild(leaf)

    assert_error(function()
        leaf:addChild(root)
    end, 'cyclic parenting',
    'Cyclic parenting should fail deterministically')

    assert_children(root, { branch },
        'Failed cycle creation should preserve the prior valid tree')
    assert_children(branch, { leaf },
        'Failed cycle creation should not mutate descendants')

    branch:destroy()

    assert_children(root, {},
        'Destroy should detach the subtree from its parent')
    assert_equal(branch.parent, nil,
        'Destroy should clear the destroyed node parent reference')
    assert_equal(leaf.parent, nil,
        'Destroy should clear descendant parent references')
    assert_children(branch, {},
        'Destroy should clear descendant ownership from the destroyed node')

    assert_error(function()
        root:addChild(branch)
    end, 'destroyed',
    'Destroyed nodes must not re-enter the retained tree')
end

local function run_fill_contract_tests()
    local stage = UI.Stage.new({
        width = 320,
        height = 180,
    })
    local parent = Container.new({
        width = 200,
        height = 120,
    })
    local invalid = Container.new({
        width = 'fill',
        height = 40,
    })

    stage.baseSceneLayer:addChild(parent)
    parent:addChild(invalid)

    assert_error(function()
        stage:update()
    end, 'does not define fill resolution for width',
        'Plain Container children should fail deterministically when using unsupported fill')

    stage:destroy()
end

local function run()
    run_public_surface_tests()
    run_default_anchor_and_pivot_tests()
    run_tree_management_tests()
    run_cycle_and_destroy_tests()
    run_fill_contract_tests()
end

return {
    run = run,
}
