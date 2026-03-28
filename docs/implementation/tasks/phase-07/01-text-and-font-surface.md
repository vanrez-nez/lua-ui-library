# Task 01: Text And Font Surface

## Goal

Implement `Text` on the settled spec contract and keep all font-loading conveniences internal to the control implementation.

## Authority

- `docs/spec/ui-controls-spec.md §6.1 Text`
- `docs/spec/ui-controls-spec.md §8.1-§8.4`
- `docs/spec/ui-foundation-spec.md §3A-§3B`

## Settled Contract Points

- The public `Text` surface is exactly `text`, `font`, `fontSize`, `maxWidth`, `textAlign`, `textVariant`, `color`, and `wrap`.
- `textVariant` is a stable visual-selector surface for the `Text.content` part, but semantic role aliases such as `heading`, `body`, or `caption` remain internal unless a later spec names them.
- `Text` is non-interactive, owns no editing behavior, and may not contain child nodes.
- Empty text remains valid and renders nothing.
- Missing or invalid font references fail deterministically.

## Implementation Guardrails

- A font cache or asset-path helper may exist internally, but it is not public API.
- Do not promote `fontPath`, `alignX`, or any other draft-only convenience prop into the stable contract.
- Wrapping with `wrap = true` and no `maxWidth` must follow the spec rule of wrapping at the node's own measured width.
- Phase 07 visuals may be hardcoded, but they must still resolve through the stable `content` part and the documented text-style surface.

## Acceptance Checks

- Wrapped and unwrapped measurement both follow the spec-backed behavior.
- `textAlign` is the only public horizontal alignment prop.
- `textVariant` remains visible in the public task contract even if the current implementation uses provisional visuals.
- No child-management or imperative slot API is documented for `Text`.
