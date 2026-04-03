# Task 11: Remaining Styling Alignment

## Summary

- Finish the remaining styling-spec alignment work identified in the readiness pass.
- This task stays spec-driven and covers only the still-open blockers needed before `lib/ui` can be called ready.

## Depends On

- [10-readiness-pass.md](/Users/vanrez/Documents/game-dev/lua-ui-library/align/10-readiness-pass.md)

## Primary Files

- [docs/spec/ui-styling-spec.md](/Users/vanrez/Documents/game-dev/lua-ui-library/docs/spec/ui-styling-spec.md)
- [docs/spec/ui-controls-spec.md](/Users/vanrez/Documents/game-dev/lua-ui-library/docs/spec/ui-controls-spec.md)
- [docs/spec/ui-foundation-spec.md](/Users/vanrez/Documents/game-dev/lua-ui-library/docs/spec/ui-foundation-spec.md)
- [lib/ui/themes/default.lua](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/themes/default.lua)
- [lib/ui/themes/runtime.lua](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/themes/runtime.lua)
- [lib/ui/controls/checkbox.lua](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/controls/checkbox.lua)
- [lib/ui/controls/radio.lua](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/controls/radio.lua)
- [lib/ui/controls/switch.lua](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/controls/switch.lua)
- [lib/ui/controls/progress_bar.lua](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/controls/progress_bar.lua)
- [lib/ui/controls/tabs.lua](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/controls/tabs.lua)
- [lib/ui/controls/modal.lua](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/controls/modal.lua)
- [lib/ui/controls/text_area.lua](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/controls/text_area.lua)

## Work Items

- Re-check the specs before each concrete code change. Do not infer undocumented token bindings or part behavior from existing implementation alone.
- Resolve the default-token/runtime fallback mismatch so documented styling properties receive spec-aligned library defaults.
- Bring the remaining documented named parts onto real styling carriers where the controls spec exposes them as stable theming surface.
- Add or extend focused specs only for the parts and fallback paths that become newly supported in this pass.
- Re-run the readiness criteria from [10-readiness-pass.md](/Users/vanrez/Documents/game-dev/lua-ui-library/align/10-readiness-pass.md) after implementation.

## Current Blockers In Scope

- Runtime defaults still depend on unofficial token property names such as `fillColor`, `radius`, `borderWidth`, and `borderColor`.
- The following documented control parts still need verified styling-carrier coverage or explicit spec-backed closure:
  - `Checkbox.box`
  - `Checkbox.indicator`
  - `Radio.indicator`
  - `Switch.track`
  - `Switch.thumb`
  - `ProgressBar.track`
  - `ProgressBar.indicator`
  - `Tabs.list`
  - `Tabs.indicator`
  - `Modal.surface`
  - `TextArea.scroll region`

## Exit Criteria

- Library default fallback works through documented styling-property names.
- The remaining documented styleable parts in scope are either implemented as real styling carriers or explicitly ruled out by the specs after re-checking the contract.
- The focused styling specs pass and the readiness pass can be closed without known styling-spec mismatches.

## Status

- Completed.

## Outcome

- Documented styling-property defaults now resolve through the runtime fallback table.
- Added styling carriers for the remaining styling-spec-owned parts in scope:
  - `Checkbox.box`
  - `Checkbox.indicator`
  - `Radio.indicator`
  - `Switch.track`
  - `Switch.thumb`
  - `Slider.track`
  - `Slider.thumb`
  - `ProgressBar.track`
  - `ProgressBar.indicator`
  - `Select.trigger`
  - `Select.popup`
  - `Tabs.list`
  - `Tabs.indicator`
  - `Modal.surface`
  - `TextArea.scroll region`
- Re-ran focused styling verification successfully:
  - `lua -e "require('spec.control_part_styling_spec').run()"`
  - `lua -e "require('spec.styling_resolution_spec').run()"`
  - `lua -e "require('spec.styling_renderer_spec').run()"`
  - `lua -e "require('spec.theme_resolution_and_render_helpers_spec').run()"`
