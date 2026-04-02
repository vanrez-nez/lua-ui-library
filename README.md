# Lua UI Library

Standalone LÖVE project for the extracted `lib/ui` package from `idle-game`.

## Run

From the project root:

```bash
love .
```

That opens the default scene showcase with three library-focused scenes:

- `home`
- `components`
- `transforms`

## Manual Demos

The original focused demos were copied over so component work can stay isolated:

```bash
love _test/phase1
love _test/ui
love _test/button
love _test/text
love _test/scene
```

## Focused Component Demos

The rebuilt demos under `demos/` are component-centered and follow the shared demo shell in `demos/common/`:

```bash
love demos/01-container
love demos/02-drawable
```

`01-container` covers retained tree, bounds, sizing, clamp, and visibility behavior.
`02-drawable` only covers the `Drawable` surface not already proven by `01-container`: alignments, padding, margin, opacity, skin, blend mode, mask, and motion inspection. Shader application is still deferred in the current runtime.

## Unit Tests

The non-graphics core has a lightweight Lua test suite:

```bash
lua scripts/run_unit_tests.lua
```

## Project Layout

- `lib/ui`: extracted library code
- `scenes`: default showcase scenes for day-to-day iteration
- `_test`: manual LÖVE demos copied from the source project
- `test`: intentionally empty staging area for rebuilt demos
- `spec`: headless unit tests for core math and layout behavior
- `assets`: demo font and image dependencies
