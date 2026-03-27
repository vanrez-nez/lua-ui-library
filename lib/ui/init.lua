return {
    -- Core
    Vec2      = require("lib.ui.core.vec2"),
    Matrix    = require("lib.ui.core.matrix"),
    Rectangle = require("lib.ui.core.rectangle"),
    Container = require("lib.ui.core.container"),
    Drawable  = require("lib.ui.core.drawable"),

    -- Components
    Text      = require("lib.ui.components.text"),
    Button    = require("lib.ui.components.button"),

    -- Theme
    theme       = require("lib.ui.themes"),

    -- Scene management
    Scene       = require("lib.ui.scene.scene"),
    Stage       = require("lib.ui.scene.stage"),
    Composer    = require("lib.ui.scene.composer"),
    transitions = require("lib.ui.scene.transitions"),
}
