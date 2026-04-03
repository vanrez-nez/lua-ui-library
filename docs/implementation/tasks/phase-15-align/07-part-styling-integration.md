# Task 7: Add Named Part Styling Resolution For Controls

## Summary

- The spec covers both styled roots and named presentational parts.
- The library has resolver pieces for parts and variants, but the actual styling paint path is still largely root-oriented.

## Depends On

- [01-resolution-contract.md](/Users/vanrez/Documents/game-dev/lua-ui-library/align/01-resolution-contract.md)
- [02-root-styling-resolution.md](/Users/vanrez/Documents/game-dev/lua-ui-library/align/02-root-styling-resolution.md)
- [03-token-normalization.md](/Users/vanrez/Documents/game-dev/lua-ui-library/align/03-token-normalization.md)
- [04-skin-value-coercion.md](/Users/vanrez/Documents/game-dev/lua-ui-library/align/04-skin-value-coercion.md)

## Primary Files

- [lib/ui/controls/button.lua](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/controls/button.lua)
- [lib/ui/controls/text_input.lua](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/controls/text_input.lua)
- [lib/ui/controls/text_area.lua](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/controls/text_area.lua)
- [lib/ui/controls/tabs.lua](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/controls/tabs.lua)
- [lib/ui/controls/modal.lua](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/controls/modal.lua)
- [lib/ui/controls/tooltip.lua](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/controls/tooltip.lua)
- [lib/ui/render/styling.lua](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/render/styling.lua)

## Work Items

- Identify controls with documented styleable parts that should use the styling system directly.
- Start with the controls already closest to the token model:
  - `Button.surface`
  - `Button.border` if kept separate
  - `TextInput.field`
  - `TextArea.field`
  - `Tabs.trigger`
  - `Tabs.panel`
  - `Modal.backdrop`
  - `Tooltip.surface`
- Route part styling through the same canonical resolution path used by roots.
- Avoid bespoke `fillColor`/`borderColor` ad hoc lookup code in control draw methods.

## Exit Criteria

- Named parts resolve direct overrides, skin values, variants, theme tokens, and defaults through one system.
- Visual variants such as hovered/pressed/focused/disabled map cleanly into part styling resolution.
