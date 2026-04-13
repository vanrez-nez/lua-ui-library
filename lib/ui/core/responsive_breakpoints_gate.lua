local Assert = require('lib.ui.utils.assert')

local ResponsiveBreakpointsGate = {}

function ResponsiveBreakpointsGate.with_peer(peer_key, opts)
    opts = opts or {}

    return function(_, value, ctx, full_opts)
        if value == nil then
            return
        end

        local public_values = ctx._public_values
        local has_peer = (full_opts and full_opts[peer_key] ~= nil) or
            (public_values and public_values[peer_key] ~= nil)

        if not has_peer then
            return
        end

        if opts.require_declared_peer then
            local allowed_public_keys = ctx._declared_props

            if not (allowed_public_keys and allowed_public_keys[peer_key]) then
                return
            end
        end

        Assert.fail('responsive and breakpoints cannot both be supplied on the same node', 3)
    end
end

return ResponsiveBreakpointsGate
