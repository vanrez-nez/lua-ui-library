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
