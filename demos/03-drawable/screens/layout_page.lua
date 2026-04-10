local UI = require('lib.ui')

local Column = UI.Column
local Drawable = UI.Drawable
local Flow = UI.Flow
local Row = UI.Row

local function build_header_section()
    local header = Row.new({
        id = 'layout-page-header',
        width = 'fill',
        height = 140,
        padding = { 20, 20, 20, 20 },
        gap = 20,
        justify = 'space-between',
        align = 'center',
    })

    local header_title = Drawable.new({
        id = 'layout-page-header-title',
        width = '30%',
        height = 50,
        padding = { 10, 15, 10, 15 },
        margin = 0,
        maxWidth = 100,
        backgroundColor = { 117, 184, 255, 51 },
        borderColor = { 117, 184, 255 },
        borderWidth = 1,
        borderStyle = 'rough',
    })
    local header_menu = Drawable.new({
        id = 'layout-page-header-menu',
        width = '40%',
        height = 50,
        maxWidth = 300,
        padding = { 10, 15, 10, 15 },
        margin = 0,
        backgroundColor = { 125, 235, 168, 51 },
        borderColor = { 125, 235, 168 },
        borderWidth = 1,
        borderStyle = 'rough',
    })

    header:addChild(header_title)
    header:addChild(header_menu)

    return header
end

local function build_content_section()
    local content = Flow.new({
        id = 'layout-page-content',
        width = 'fill',
        height = 'fill',
        padding = { 20, 20, 20, 20 },
        gap = 15,
        wrap = true,
        justify = 'start',
        direction = 'ltr',
    })

    local alpha = Drawable.new({
        id = 'layout-page-content-alpha',
        width = '20%',
        height = 50,
        minWidth = 200,
        padding = { 10, 15, 10, 15 },
        margin = 0,
        backgroundColor = { 117, 184, 255, 51 },
        borderColor = { 117, 184, 255 },
        borderWidth = 1,
        borderStyle = 'rough',
    })
    local beta = Drawable.new({
        id = 'layout-page-content-beta',
        width = '35%',
        height = 50,
        padding = { 10, 15, 10, 15 },
        margin = 0,
        backgroundColor = { 125, 235, 168, 51 },
        borderColor = { 125, 235, 168 },
        borderWidth = 1,
        borderStyle = 'rough',
    })
    local gamma = Drawable.new({
        id = 'layout-page-content-gamma',
        width = '25%',
        height = 50,
        minWidth = 150,
        padding = { 10, 15, 10, 15 },
        margin = 0,
        backgroundColor = { 255, 208, 117, 51 },
        borderColor = { 255, 208, 117 },
        borderWidth = 1,
        borderStyle = 'rough',
    })
    local delta = Drawable.new({
        id = 'layout-page-content-delta',
        width = '40%',
        height = 50,
        padding = { 10, 15, 10, 15 },
        margin = 0,
        backgroundColor = { 210, 165, 255, 51 },
        borderColor = { 210, 165, 255 },
        borderWidth = 1,
        borderStyle = 'rough',
    })
    local epsilon = Drawable.new({
        id = 'layout-page-content-epsilon',
        width = '30%',
        height = 50,
        minWidth = 200,
        padding = { 10, 15, 10, 15 },
        margin = 0,
        backgroundColor = { 117, 184, 255, 51 },
        borderColor = { 117, 184, 255 },
        borderWidth = 1,
        borderStyle = 'rough',
    })

    content:addChild(alpha)
    content:addChild(beta)
    content:addChild(gamma)
    content:addChild(delta)
    content:addChild(epsilon)

    return content
end

local function build_sidebar_section()
    local sidebar = Column.new({
        id = 'layout-page-sidebar',
        width = '40%',
        height = 'fill',
        padding = { 20, 20, 20, 20 },
        gap = 15,
        justify = 'start',
        align = 'stretch',
    })

    local sidebar_top = Drawable.new({
        id = 'layout-page-sidebar-top',
        width = 'fill',
        height = 50,
        padding = { 10, 15, 10, 15 },
        margin = 0,
        backgroundColor = { 117, 184, 255, 51 },
        borderColor = { 117, 184, 255 },
        borderWidth = 1,
        borderStyle = 'rough',
    })
    local sidebar_middle = Drawable.new({
        id = 'layout-page-sidebar-middle',
        width = 'fill',
        height = 75,
        padding = { 10, 15, 10, 15 },
        margin = 0,
        backgroundColor = { 125, 235, 168, 51 },
        borderColor = { 125, 235, 168 },
        borderWidth = 1,
        borderStyle = 'rough',
    })
    local sidebar_bottom = Drawable.new({
        id = 'layout-page-sidebar-bottom',
        width = 'fill',
        height = 50,
        padding = { 10, 15, 10, 15 },
        margin = 0,
        backgroundColor = { 255, 208, 117, 51 },
        borderColor = { 255, 208, 117 },
        borderWidth = 1,
        borderStyle = 'rough',
    })

    sidebar:addChild(sidebar_top)
    sidebar:addChild(sidebar_middle)
    sidebar:addChild(sidebar_bottom)

    return sidebar
end

local function build_footer_section()
    local footer = Row.new({
        id = 'layout-page-footer',
        width = 'fill',
        height = 100,
        padding = { 20, 20, 20, 20 },
        gap = 10,
        justify = 'space-between',
        align = 'center',
    })

    local footer_primary = Drawable.new({
        id = 'layout-page-footer-primary',
        width = '20%',
        height = 40,
        padding = { 10, 15, 10, 15 },
        margin = 0,
        backgroundColor = { 117, 184, 255, 51 },
        borderColor = { 117, 184, 255 },
        borderWidth = 1,
        borderStyle = 'rough',
    })
    local footer_secondary = Drawable.new({
        id = 'layout-page-footer-secondary',
        width = '25%',
        height = 40,
        padding = { 10, 15, 10, 15 },
        margin = 0,
        backgroundColor = { 125, 235, 168, 51 },
        borderColor = { 125, 235, 168 },
        borderWidth = 1,
        borderStyle = 'rough',
    })
    local footer_tertiary = Drawable.new({
        id = 'layout-page-footer-tertiary',
        width = '30%',
        height = 40,
        padding = { 10, 15, 10, 15 },
        margin = 0,
        backgroundColor = { 255, 208, 117, 51 },
        borderColor = { 255, 208, 117 },
        borderWidth = 1,
        borderStyle = 'rough',
    })

    footer:addChild(footer_primary)
    footer:addChild(footer_secondary)
    footer:addChild(footer_tertiary)

    return footer
end

return function(owner, helpers)
    local description = 'This screen combines layout components into a simple page. The header uses a Row with space-between, the content uses Flow, the sidebar uses Column, and the footer centers three items in a Row.'

    return helpers.screen_wrapper(
        owner,
        function(stage)
            local root = stage.baseSceneLayer
            local page = Column.new({
                id = 'layout-page-root',
                width = '50%',
                height = '70%',
                padding = { 20, 20, 20, 20 },
                gap = 20,
                justify = 'start',
                align = 'stretch',
            })
            local body_row = Row.new({
                id = 'layout-page-body',
                width = 'fill',
                height = 'fill',
                gap = 20,
                justify = 'start',
                align = 'stretch',
            })
            local header = build_header_section()
            local content = build_content_section()
            local sidebar = build_sidebar_section()
            local footer = build_footer_section()

            body_row:addChild(content)
            body_row:addChild(sidebar)

            page:addChild(header)
            page:addChild(body_row)
            page:addChild(footer)
            root:addChild(page)

            return {
                title = 'Layout: Page',
                description = description,
            }
        end
    )
end
