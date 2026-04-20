local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')
local Rule = require('lib.ui.utils.rule')

return {
    value = Rule.custom(function(_, value, _, level)
        if not Types.is_string(value) or value == '' then
            Assert.fail('Radio.value is required', level or 1)
        end
        return value
    end, { required = true }),
    disabled = Rule.boolean(false),
}
