# UI Styling Alignment

Goal: bring `lib/ui` into full alignment with `docs/spec/ui-styling-spec.md` and make the styling system ready for real use across `Drawable` roots and named control parts.

## Principles

- Align the runtime behavior first, not just the data model.
- Use the spec-owned styling vocabulary consistently: `background*`, `border*`, `cornerRadius*`, `shadow*`.
- Keep resolution deterministic: direct property -> skin -> theme/token -> library default.
- Add tests for each contract that was previously only implemented in isolation.

## Task Order

1. [01-resolution-contract.md](/Users/vanrez/Documents/game-dev/lua-ui-library/align/01-resolution-contract.md)
2. [02-root-styling-resolution.md](/Users/vanrez/Documents/game-dev/lua-ui-library/align/02-root-styling-resolution.md)
3. [03-token-normalization.md](/Users/vanrez/Documents/game-dev/lua-ui-library/align/03-token-normalization.md)
4. [04-skin-value-coercion.md](/Users/vanrez/Documents/game-dev/lua-ui-library/align/04-skin-value-coercion.md)
5. [05-background-image-rendering.md](/Users/vanrez/Documents/game-dev/lua-ui-library/align/05-background-image-rendering.md)
6. [06-inner-geometry.md](/Users/vanrez/Documents/game-dev/lua-ui-library/align/06-inner-geometry.md)
7. [07-part-styling-integration.md](/Users/vanrez/Documents/game-dev/lua-ui-library/align/07-part-styling-integration.md)
8. [08-failure-semantics.md](/Users/vanrez/Documents/game-dev/lua-ui-library/align/08-failure-semantics.md)
9. [09-tests.md](/Users/vanrez/Documents/game-dev/lua-ui-library/align/09-tests.md)
10. [10-readiness-pass.md](/Users/vanrez/Documents/game-dev/lua-ui-library/align/10-readiness-pass.md)

## Ticket Format

Each task file uses the same structure:

- `Summary`: what the task is fixing.
- `Depends On`: prerequisites from this alignment set.
- `Primary Files`: the likely code and spec touchpoints.
- `Work Items`: concrete implementation steps.
- `Exit Criteria`: the bar for considering the task complete.

## Merge Slices

1. Resolution foundation
   Includes Tasks 1-4.

2. Renderer correctness
   Includes Tasks 5-6.

3. Control-part integration
   Includes Task 7.

4. Verification and cleanup
   Includes Tasks 8-10.
