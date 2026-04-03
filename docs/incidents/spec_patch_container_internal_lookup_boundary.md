# Spec Patch: `Container.internal` As The Lookup Boundary

## Summary

The current spec already uses the term `Internal node` to exclude framework-owned
helper nodes from public lookup and uniqueness participation.

The intent is correct, but the mechanism is too implementation-shaped. What the
spec actually needs is a direct structural property on `Container` so the
boundary is explicit in the public node contract rather than implied through
implementation conventions.

This patch keeps the existing glossary term and turns it into an explicit
property:

- `internal: boolean`

This means the node remains in the retained tree, but does not participate in the
public lookup and addressing contract.

---

## Problem

The current wording creates two avoidable problems:

1. It centers the rule on origin rather than contract.
   What matters is not only who created the node. What matters is whether that
   node participates in public addressing and public search.

2. It leaves the boundary under-specified.
   The spec says internal nodes are excluded, but it does not define the
   node-level contract that makes that exclusion explicit and compositional.

The spec should express this directly:

- some retained nodes are public search participants
- some retained nodes are marked `internal`

That distinction should live on the node contract itself.

---

## Proposed Contract

### New `Container` Prop

Add to the `Container` props surface:

```text
- `internal: boolean`
```

Default:

```text
false
```

Meaning:

- When `internal = false`, the node participates normally in public lookup and
  addressing behavior.
- When `internal = true`, the node remains part of the retained tree for layout,
  transform, rendering, clipping, focus ancestry, and event ancestry, but is
  excluded from public search participation as defined below.

`internal` is a structural lookup-boundary property. It is not a visual property
and it does not mean render isolation.

---

## Terminology Alignment

This patch intentionally keeps the existing glossary term:

- `Internal node`

and makes it concrete:

- an internal node is any retained node with `internal = true`

This keeps the spec vocabulary aligned instead of introducing a second term for
the same concept.

---

## Behavioral Rules

### Lookup Visibility

For any node where `internal = true`:

- the node itself must not be returned by `findById`
- the node itself must not be returned by `findByTag`
- the node's `id` must not participate in attachment-root uniqueness validation
- the node's `name` must not participate in sibling uniqueness validation

### Traversal Through Internal Nodes

An internal node is excluded from matching and tracking. It does not remove the
node's descendants from the searchable tree.

Therefore:

- public search methods must traverse through internal nodes
- non-internal descendants under an internal ancestor remain searchable
- an internal node acts like a transparent wrapper for traversal, but not for
  matching

This is the key semantic rule.

The intended model is:

- internal node: not matchable
- internal node's public descendants: still reachable

---

## Field Contract Implications

### `id`

Patch the `id` contract to say:

- `id` on an internal node is permitted as local metadata but is outside the
  public addressing contract
- `id` uniqueness is enforced only across non-internal nodes within the
  attachment root
- `findById` never returns an internal node even if its `id` matches

### `name`

Patch the `name` contract to say:

- sibling uniqueness is enforced only among non-internal siblings
- internal nodes do not reserve public sibling names

### `tag`

Patch the `tag` contract to say:

- internal nodes may carry tags for local implementation grouping or diagnostics
- `findByTag` never returns internal nodes
- traversal must continue through internal nodes to reachable non-internal
  descendants

This lets the framework keep local structure labels without polluting the public
lookup contract.

---

## API Semantics Patch

### `findById`

Replace the current exclusion wording with:

```text
Nodes with `internal = true` are never returned as matches.
Traversal continues through internal nodes so that non-internal descendants remain
discoverable within the receiver subtree.
```

### `findByTag`

Replace the current exclusion wording with:

```text
Nodes with `internal = true` are excluded from matches but do not terminate
traversal. Non-internal descendants under internal ancestors remain part of the
search space.
```

---

## Composition And Tree-Model Implications

`internal` must not alter ordinary retained-tree behavior outside lookup and
identity participation.

An internal node still:

- has a parent
- has children
- participates in transforms
- participates in clipping
- participates in rendering
- participates in focus ancestry
- participates in event ancestry
- may still be required by a component's internal or named-part structure

`internal` changes search visibility, not structural existence.

---

## Reparenting And Mutation Implications

When `internal` changes on an attached node:

- the attachment root must recompute or update its public `id` tracking
- sibling `name` validation participation must be re-evaluated
- lookup-visible membership must update atomically

When a subtree containing internal nodes is attached:

- only non-internal nodes participate in `id` collision checks
- only the moved node itself, if non-internal, participates in sibling `name`
  collision checks at the destination parent
- search traversal after attach must still be able to reach non-internal
  descendants under internal wrappers

---

## Why This Is Better

This model is cleaner because it defines the public contract in terms of the
observable behavior:

- does the node participate in public addressing?
- does the node participate in public search?

It also keeps the vocabulary aligned with the existing glossary instead of
inventing a second name for the same boundary.

And it supports the common composite-control case directly:

- wrapper nodes can be hidden from search
- meaningful descendants can still be found through them

That is usually what consumers actually expect.

---

## Required Spec Edits

If accepted, patch these areas in `docs/spec/ui-foundation-spec.md`:

1. Glossary
   redefine `Internal node` as a retained node with `internal = true`

2. `Container` props surface
   add `internal: boolean`

3. `Container` identity and lookup section
   replace the current "internal nodes are excluded" wording with explicit
   `internal = true` rules, including traversal-through behavior

4. `id`, `name`, and `tag` participation rules
   clarify that uniqueness and search matching apply to non-internal nodes only

5. Failure semantics
   clarify that changing `internal` on an attached node must update lookup-visible
   membership atomically

---

## Implementation Implications

If this spec patch is accepted, implementation should move from a private marker
convention to a direct property-based rule.

That implies:

1. the exclusion mechanism should be expressed through `internal = true`
2. lookup and uniqueness indexes must ignore internal nodes as matches, but still
   traverse through internal wrappers
3. helper nodes inside composites should generally be `internal = true`
4. the implementation must not prune internal subtrees entirely from lookup, or
   public descendants under those wrappers will become unreachable
5. any index-based fast path for `findById` must still handle the case where an
   indexed non-internal node sits under one or more internal ancestors

The search-space rule is:

- skip internal nodes as results
- do not skip their descendants

That should be treated as the non-negotiable behavioral core of this patch.
