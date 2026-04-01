local Stage = require('lib.ui.scene.stage')
local ok, err = pcall(function()
    Stage({ unsupportedProp = true })
end)
if ok then
    print("SUCCESS (FAIL)")
else
    print("FAILED AS EXPECTED: " .. tostring(err))
end
