package.path = "./?.lua;./?/init.lua;" .. package.path

local specs = {
    "spec.vec2_spec",
    "spec.matrix_spec",
    "spec.rectangle_spec",
    "spec.drawable_spec",
    "spec.container_spec",
}

local total = 0
local failed = 0

for _, specName in ipairs(specs) do
    local cases = require(specName)
    for _, case in ipairs(cases) do
        total = total + 1
        local ok, err = pcall(case.run)
        if ok then
            io.write("PASS ", specName, " :: ", case.name, "\n")
        else
            failed = failed + 1
            io.write("FAIL ", specName, " :: ", case.name, "\n")
            io.write("  ", tostring(err), "\n")
        end
    end
end

io.write(string.format("\n%d tests, %d failures\n", total, failed))

if failed > 0 then
    os.exit(1)
end
