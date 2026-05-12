# 02 - Lua External Types

## Goal

Expose selected handwritten Lua modules to TypeScript as typed externals. These
modules remain Lua sources of truth. TypeScript declarations describe their
public contracts so migrated TypeScript can call them safely.

## Permanent Lua Externals

These modules must not be ported during setup:

- `lib.ui.utils.reactive`
- `lib.ui.utils.dirty_props`
- `lib.ui.utils.memoize`
- `lib.ui.utils.schema`
- `lib.ui.utils.rule`

After the project refactor, their files live under `src/lua/lib/ui/utils`, but
their TypeScript declarations should keep the exact Lua require names used by
callers.

## Declaration Location

Use:

```text
src/types/lua-interop/
  optimized-utils.d.ts
```

The current anchor file `src/types/lua-ui-library.d.ts` may hold shared project
types such as atoms, but module declarations should live in `lua-interop`.

## Declaration Style

Use ambient module declarations and `export =` because each Lua file returns a
module table:

```ts
declare module "lib.ui.utils.rule" {
  const Rule: RuleModule;
  export = Rule;
}
```

TypeScript code should import these modules with CommonJS import-equals:

```ts
import Rule = require("lib.ui.utils.rule");
import Schema = require("lib.ui.utils.schema");
```

Function style rules:

- Use `this: void` for module table functions called with dot syntax.
- Use TypeScript interfaces for objects whose Lua methods are called with
  colon syntax.
- Use tuple-return annotations only when the Lua function returns multiple
  values.
- Avoid catch-all index signatures unless the Lua API is intentionally dynamic.

## Minimum Public Contracts

Declare only public, stable behavior.

For `Rule`:

- Factories: `string`, `number`, `boolean`, `table`, `func`, `enum`,
  `literal`, `instance`, `custom`, `optional`, `any_of`, `all_of`.
- Operations: `validate`, `resolve`.
- Descriptor types should include `kind`, `optional`, `has_default`, and
  `default`.
- Do not expose the internal validator table.

For `Schema`:

- Static functions: `create`, `extend`.
- Instance methods: `get_rules`, `get_rule`, `validate_rule`, `validate_all`,
  `set_defaults`.
- The schema instance should be treated as immutable from TypeScript.

For `DirtyProps`:

- Module functions: `create`, `init`.
- Instance methods: `sync_dirty_props`, `reset_dirty_props`, `mark_dirty`,
  `clear_dirty`, `is_dirty`, `any_dirty`, `all_dirty`, `group_dirty`,
  `group_any_dirty`, `group_all_dirty`, `get_dirty_props`,
  `get_dirty_groups`.
- Do not expose bit masks, hidden keys, or internal state tables.

For `Reactive`:

- Module functions: `create`, `define_property`, `remove_property`, `raw_get`,
  `raw_set`.
- Property definitions should support `val`, optional getter, and optional
  setter.
- Do not expose the shared metatable or hidden accessor key.

For `Memoize`:

- Production exports only.
- Declare arity-specific `memoize` overloads for 1, 2, and 3 arguments.
- Do not declare spec-local helpers such as `memoize_multi`.
- If `memoize_tick` or `tick` are still used by runtime code, verify the Lua
  module exports before declaring them.

## Acceptance Criteria

- A TypeScript type-smoke file can import all five externals.
- `npm run list:ts` includes `src/types/lua-interop/optimized-utils.d.ts`.
- `npm run build:ts` passes.
- Existing Lua specs for these modules remain the runtime source of behavior.
