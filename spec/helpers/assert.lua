local Assert = {}

function Assert.equal(actual, expected, message)
    assert(actual == expected, message or string.format("expected %s, got %s", tostring(expected), tostring(actual)))
end

function Assert.near(actual, expected, epsilon, message)
    epsilon = epsilon or 1e-6
    assert(math.abs(actual - expected) <= epsilon, message or string.format("expected %.6f, got %.6f", expected, actual))
end

function Assert.truthy(value, message)
    assert(value, message or "expected value to be truthy")
end

return Assert
