local screen_modules = {
    require('demos.03-drawable.screens.alignments'),
    require('demos.03-drawable.screens.spacing'),
    require('demos.03-drawable.screens.layout_stack'),
    require('demos.03-drawable.screens.layout_row'),
    require('demos.03-drawable.screens.layout_column'),
    require('demos.03-drawable.screens.layout_flow'),
    require('demos.03-drawable.screens.layout_page'),
    require('demos.03-drawable.screens.opacity'),
    require('demos.03-drawable.screens.skin'),
    require('demos.03-drawable.screens.blendmode'),
    require('demos.03-drawable.screens.render_effects'),
    require('demos.03-drawable.screens.motion'),
    require('demos.03-drawable.screens.borders'),
}

screen_modules.helpers = require('demos.common.drawable_screen_helpers')

return screen_modules
