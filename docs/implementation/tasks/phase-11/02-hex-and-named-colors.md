# Task 02: Hex And Named Color Parsing

## Goal

Extend `Color.resolve` to handle hex color strings in all four accepted formats and the nine named color strings defined by the spec.

## Spec Anchors

- `docs/spec/ui-styling-spec.md §5.4` — accepted hex forms: `#RGB`, `#RGBA`, `#RRGGBB`, `#RRGGBBAA`
- `docs/spec/ui-styling-spec.md §5.3` — named color catalog: `transparent`, `black`, `white`, `red`, `green`, `blue`, `yellow`, `cyan`, `magenta`
- `docs/spec/ui-styling-spec.md §13` — hard-failure: unsupported named color, invalid hex color syntax

## Scope

- Route string inputs in `Color.resolve` to hex or named handler based on prefix
- Implement hex parser for `#RGB`, `#RGBA`, `#RRGGBB`, `#RRGGBBAA`
- Implement named color lookup table
- Hard-fail on unrecognized strings

## Concrete Module Targets

- Extend `lib/ui/render/color.lua`

## Implementation Guidance

**Named colors:**

Store as a module-level constant table keyed by name. Values are plain `{ r, g, b, a }` tables in `[0, 1]`:

```
transparent → {0, 0, 0, 0}
black       → {0, 0, 0, 1}
white       → {1, 1, 1, 1}
red         → {1, 0, 0, 1}
green       → {0, 0.502, 0, 1}   -- #008000, web green
blue        → {0, 0, 1, 1}
yellow      → {1, 1, 0, 1}
cyan        → {0, 1, 1, 1}
magenta     → {1, 0, 1, 1}
```

Return a shallow copy of the table, not the constant itself, so callers cannot mutate the catalog.

**Hex parsing:**

- Input starts with `#`: route to hex handler
- Strip `#`, check length: 3, 4, 6, or 8 chars only. Any other length is a hard failure.
- 3-char shorthand (`RGB`): expand each nibble by doubling — `"F"` → `"FF"`, `"0"` → `"00"`
- 4-char shorthand (`RGBA`): expand same way
- Parse each byte as `tonumber(twoChars, 16)`. If `tonumber` returns nil, the character is invalid — hard failure.
- Divide each channel by `255` to normalize to `[0, 1]`
- Alpha defaults to `1.0` (i.e., `255/255`) when absent (3- and 6-char forms)

**String routing:**

```
if input:sub(1, 1) == "#" then
    return parse_hex(input)
elseif NAMED_COLORS[input] then
    return shallow_copy(NAMED_COLORS[input])
else
    error("color: unsupported color string '" .. input .. "'", 2)
end
```

## Required Behavior

- `"#F00"` → `{1, 0, 0, 1}`
- `"#FF0000"` → `{1, 0, 0, 1}`
- `"#FF000080"` → `{1, 0, 0, 0.502}` (approximately)
- `"#F00F"` → `{1, 0, 0, 1}`
- `"#GG0000"` → hard failure (invalid hex character)
- `"#FF00"` → hard failure (length 4 after strip = valid 4-char RGBA... wait: `"#FF00"` stripped is `"FF00"` which is 4 chars = valid RGBA shorthand `F`, `F`, `0`, `0` → `{1, 1, 0, 0}`)
- `"#FFFFF"` → hard failure (5 chars after strip)
- `"red"` → `{1, 0, 0, 1}`
- `"transparent"` → `{0, 0, 0, 0}`
- `"purple"` → hard failure (not in catalog)
- `""` → hard failure
- Named color result must be a copy — mutating the returned table must not affect subsequent calls

## Non-Goals

- No HSL string handling in this task.
- No case-insensitive hex matching beyond what Lua's `tonumber(x, 16)` handles naturally.

## Acceptance Checks

- All required behavior cases pass.
- Named color lookup returns independent copies.
- Hex parser correctly handles all four length variants.
- Invalid hex characters and unsupported string formats produce hard failures with readable messages.
