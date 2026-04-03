# Task 02A: Container Identity And Lookup

## Goal

Implement the retained-node identity, naming, tagging, and descendant-lookup contract on `Container` in a way that matches the settled spec and keeps performance choices internal.

## Spec Anchors

- `docs/spec/ui-foundation-spec.md Glossary: Attachment root, Internal node`
- `docs/spec/ui-foundation-spec.md §3A.4 Identity Contract`
- `docs/spec/ui-foundation-spec.md §6.1.1 Container`
- `docs/spec/ui-foundation-spec.md §3G.2 Invalid Usage Classification`
- `docs/spec/ui-foundation-spec.md §3G.7 Graceful Degradation Contract`

## Scope

- Extend `lib/ui/core/container_schema.lua` and `lib/ui/core/container.lua`
- Add public `id`, `name`, and existing public `tag` validation behavior
- Add attachment-root tracking and public/internal node boundary support
- Add `findById(id, depth?)`
- Add `findByTag(tag, depth?)`
- Add attach, detach, destroy, and reparent bookkeeping needed to preserve the contract

## Required Public Surface

- `id: string | nil`
- `name: string | nil`
- `tag: string | nil`
- `findById(id, depth?) -> Container | nil`
- `findByTag(tag, depth?) -> Container[]`

## Required Behavior

- `id` is unique within one attachment root.
- `name` is unique among direct public siblings.
- `tag` is non-unique and remains consumer-facing classification only.
- Empty-string and non-string assignments for `id`, `name`, and `tag` fail deterministically.
- Reparenting preserves `id`, `name`, and `tag`, but revalidates `id` against the destination attachment root and `name` against the destination siblings.
- A failed reparent or subtree attach must leave the tree unchanged.
- Internal framework nodes are excluded from public uniqueness validation and from all public lookup results.
- `findById` searches only within the receiver subtree even when the same attachment root contains the target elsewhere.
- `findByTag` returns matches in depth-first pre-order using sibling insertion order.
- No `findByName` or selector/query language is introduced.

## Implementation Direction

- Store `_attachment_root` on every node and update it across attach, detach, destroy, and subtree moves.
- Maintain one internal `_id_index` table per attachment root.
- Use the `id` index for the common unbounded `findById` path, then verify that the indexed node is inside the receiver subtree before returning it.
- Use bounded tree walks for explicit bounded-depth `findById` and for all `findByTag` calls in this phase.
- Do not add a tag index in this task. Tag indexing remains a deferred implementation optimization.
- Keep ordering/index structures internal. They are not part of the public contract.

## Performance Guidance

- Optimize `findById` first; it is the singular-addressing path and the best index candidate.
- Treat `findByTag` as a bounded or full subtree walk for now. The spec already keeps tag indexing out of the required surface.
- Favor a simple preflight-then-commit attach flow for the first compliant implementation. Correctness and atomicity matter more than collapsing validation and registration into one pass.
- Attachment-root caching should make common index access a field read plus a table lookup rather than a parent-chain walk.

## Internal Boundary Requirements

- The implementation must have an explicit internal-node marker or equivalent tree-level mechanism.
- Framework-created helper nodes must migrate off public `tag` as an internal bookkeeping channel.
- Public lookup and uniqueness checks must operate on public retained nodes only.

## Non-Goals

- No public scoped name lookup.
- No path-based lookup API.
- No tag index or traversal-order maintenance structure.
- No public exposure of index tables or attachment-root helpers.

## Acceptance Checks

- Duplicate public `id` under one attachment root fails deterministically.
- The same public `id` under two different attachment roots is valid.
- Duplicate public sibling `name` fails deterministically.
- A subtree attach with any `id` conflict fails atomically with no partial attachment.
- `findById` returns `nil` when the indexed node exists in the same attachment root but outside the receiver subtree.
- `findByTag` excludes internal helper nodes and preserves depth-first pre-order for public nodes.
