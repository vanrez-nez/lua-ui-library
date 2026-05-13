# Future Migration Intake Template

Use this template only after the setup phase is accepted. Duplicate it into a
future migration note for one candidate at a time. Do not fill this setup folder
with a broad port schedule.

## Candidate

- Category:
- Module:
- Runtime require name:
- Current public surface:
- Existing LuaUnit coverage:

## Risk Check

- Why this is low risk:
- Runtime dependencies:
- Dependencies already covered by TypeScript declarations:
- Missing declarations required before porting:
- Protected handwritten externals used:

## Port Plan

- Author TypeScript under `src/ts`.
- Generate review output under `src/generated/tstl`.
- Compare generated Lua against the current reviewed Lua behavior.
- Promote nothing until the generated output has been reviewed and parity checks
  pass.

## Validation Gates

- `npm run list:ts`
- `npm run build:ts`
- `npm run check:boundaries`
- Relevant Lua smoke check:
- Relevant LuaUnit spec:
- `./lua_modules/bin/luacheck .`

## Promotion Decision

- Promotion target:
- Reviewer:
- Parity notes:
- Remaining risks:
