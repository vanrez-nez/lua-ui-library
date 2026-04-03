# Spec: Node Identity, Naming, Tagging, And Lookup Semantics

## Summary

The foundation family requires a complete and unambiguous contract for retained node
identity, human-readable naming, classification, and descendant lookup.

This spec defines three distinct fields with different contracts:

- `id` — structural addressing
- `name` — human-readable labeling
- `tag` — classification and bulk querying

All three fields are defined in this patch. Implementation may be staged, but the
semantic contract is fixed here in full to prevent conflation.

---

## The Three Concerns

Every retained UI system ends up solving three different questions:

| Concern            | Question it answers              | Field  |
|--------------------|----------------------------------|--------|
| Structural address | "Where is this node in the tree?"| `id`   |
| Human meaning      | "What is this thing?"            | `name` |
| Classification     | "What kind of thing is this?"    | `tag`  |

These concerns must not be merged. Each carries a different uniqueness contract, a
different mutation contract, and a different lookup shape. Conflating them forces
semantic compromise in all three roles.

---

## Definitions

### Retained Node

A retained node is any instance in the `Container` family that participates in the
retained scene tree. Subclasses such as `Row`, `Column`, and other layout primitives
are retained nodes.

### Attachment Root

The attachment root of a node is the highest ancestor in the retained tree that has
no parent. It is determined structurally, not by type or label.

Rules:

- A detached node with no parent is its own attachment root.
- Every attached node has exactly one attachment root.
- Attachment roots are not declared by the caller. They are resolved from tree
  structure at any point by walking up the parent chain.
- When a node is attached under a parent, its attachment root becomes the parent's
  attachment root.
- When a node is detached, it becomes its own attachment root again.

Known examples of attachment roots include `Stage` layer roots, scene roots, and
standalone detached subtrees. These are examples, not a closed enumeration.

### Internal Node

An internal node is a retained node created and managed by the framework itself, not
by the consumer. Internal nodes support layout, clipping, scrolling, and other
framework-level concerns.

Internal nodes are invisible to the public lookup API. They do not participate in
`id` uniqueness validation and are not returned by any public search method.

The implementation must maintain a clear distinction between consumer-owned nodes
and internal nodes. This distinction must be enforced at the tree level, not
inferred from field values.

---

## Field Contracts

### `id`

`id` is the structural addressing key.

```
id: string | nil
```

Properties:

- Machine-facing. Not displayed, not accessibility-facing.
- Unique within the attachment root boundary. See uniqueness rules below.
- Stable across reparenting. The value persists on the node; validity is
  re-evaluated at attach time.
- Not a display label. Not a category label.

Invalid values:

- `nil` — means no id is assigned. Valid state.
- Empty string `""` — rejected. Must fail deterministically.
- Non-string values — rejected. Must fail deterministically.

---

### `name`

`name` is the human-readable node label.

```
name: string | nil
```

Properties:

- Human-facing. Intended for display in inspector, debugger, and editor hierarchy
  panels.
- Unique among direct siblings. See uniqueness rules below.
- Mutable without structural consequence. Renaming does not affect `id` addressing,
  serialization keys, or any structural reference.
- Not a global lookup key. No subtree `findByName` is provided in this patch.
- Has no effect on layout, rendering, or runtime behavior.

Invalid values:

- `nil` — means no name is assigned. Valid state.
- Empty string `""` — rejected. Must fail deterministically.
- Non-string values — rejected. Must fail deterministically.

Editor-layer tooling may auto-disambiguate proposed names before they reach the
runtime. The runtime contract itself does not perform silent renaming. Collisions
at the runtime level fail deterministically.

---

### `tag`

`tag` is the classification field.

```
tag: string | nil
```

Properties:

- Non-unique. Multiple nodes at any depth may share the same tag.
- Intended for grouping, filtering, and bulk lookup.
- Not a singular address. Not a human-readable name.
- Has no effect on layout, rendering, or runtime behavior.

Existing internal use of `tag` for runtime and control-part labeling must be
resolved as part of this patch. Either:

- Those internal uses are formally classified as valid consumer-facing classification
  tags and documented as such, or
- Those internal uses are migrated to a separate private field that is not part of
  the public contract.

The public `tag` field must be cleanly consumer-facing before this patch ships.
This is a Patch 1 precondition, not a later follow-up.

---

## Uniqueness Contracts

### `id` Uniqueness

`id` must be unique within the attachment root boundary.

This means:

- No two nodes under the same attachment root may share the same `id`.
- Two nodes under different attachment roots may share the same `id` because they
  occupy different address spaces.

Write-time enforcement:

- When a node with a non-nil `id` is attached to a parent, validate uniqueness
  against the target attachment root before completing the attach operation.
- When a node's `id` is changed while it is already attached, validate uniqueness
  against the current attachment root before accepting the new value.
- Fail deterministically on collision.

Subtree attach:

- When a subtree is attached, all `id` values across the entire incoming subtree
  must be validated against the target attachment root before any node is attached.
- The operation is atomic: if any single collision is found, the entire attach
  fails. No partial attachment occurs.

### `name` Uniqueness

`name` must be unique among direct siblings.

Write-time enforcement:

- When a node with a non-nil `name` is attached to a parent, validate uniqueness
  against the current direct children of the target parent before completing the
  attach operation.
- When a node's `name` is changed while it is already attached, validate uniqueness
  against the current direct siblings before accepting the new value.
- Fail deterministically on collision. The node remains at its current position
  in the tree. The mutation is rejected entirely.

`name` is not globally unique and is not enforced beyond direct siblings.

### `tag` Uniqueness

`tag` has no uniqueness constraint. No validation is performed.

---

## Reparenting Contract

All three fields persist on a node across reparenting.

| Field  | Persists | Revalidated at attach | Failure behavior                        |
|--------|----------|-----------------------|-----------------------------------------|
| `id`   | yes      | yes, against new attachment root | fail atomically, node stays at origin |
| `name` | yes      | yes, against new parent's children | fail, node stays at origin           |
| `tag`  | yes      | no                    | n/a                                     |

On reparenting failure, the tree state must be unchanged. The node must remain at
its original position. No partial state is allowed.

---

## Lookup API

### `findById`

```
node:findById(id, depth?) -> retained node | nil
```

Searches the subtree rooted at the receiver for a node with the given `id`.

Depth semantics:

| Value              | Behavior                                        |
|--------------------|-------------------------------------------------|
| `0`                | Checks only the receiver itself                 |
| `1`                | Searches direct children only                   |
| `2`                | Searches children and grandchildren             |
| `-1` or `math.huge`| Searches the full descendant subtree            |

Default: `-1` (full subtree).

The default is unbounded because the primary consumers of `findById` are tooling,
test harnesses, and serialization layers that start from a root boundary and need
full addressing. Callers who need bounded local lookup must pass an explicit depth.

Behavior:

- Returns the matching node instance, preserving its concrete runtime subtype.
- Returns `nil` when no match is found.
- Returns `nil` when depth = 0 and the receiver's `id` does not match. Does not
  error.
- Fails with a deterministic error when `id` is nil, empty string, or non-string.

Scope note:

- `findById` searches within the receiver's subtree only.
- If a node with the given `id` exists in the same attachment root but outside the
  receiver's subtree, the result is `nil`.
- This is expected behavior. `nil` from `findById` means either the node does not
  exist or it is outside the caller's subtree. The caller cannot distinguish these
  two cases from the return value alone.
- For full-tree addressing, callers should invoke `findById` from the attachment
  root. Attachment-root-level lookup is the canonical addressing entry point.

Internal nodes are excluded from all results.

---

### `findByTag`

```
node:findByTag(tag, depth?) -> retained node[]
```

Searches the subtree rooted at the receiver for all nodes with the given `tag`.

Depth semantics: same values as `findById`.

Default: `1` (direct children only).

The default is shallow because tag queries are bulk queries. An accidental
full-subtree tag scan has a much higher performance cost than an accidental
full-subtree id lookup. Callers who need deeper classification queries must opt
in explicitly.

This asymmetry with `findById` is intentional. The default for each method matches
the dominant use case and cost profile of that method.

Behavior:

- Returns all matching node instances in depth-first pre-order traversal.
- Returns an empty table when no matches are found. Never returns `nil`.
- `depth = 0` is a degenerate self-check: returns a table containing the receiver
  if its tag matches, otherwise an empty table. This is a valid but uncommon case.
- Fails with a deterministic error when `tag` is nil, empty string, or non-string.
- Never returns a singular node. The return type is always a table.

Traversal contract: depth-first pre-order. Parent nodes appear before their
children. Among siblings, left-to-right insertion order is used. This matches the
natural composition order of the retained tree and is stable and predictable for
tooling and debugging.

Internal nodes are excluded from all results.

---

## Return Type Contract

Both `findById` and `findByTag` return retained node instances.

The return type preserves the concrete runtime subtype of the matched node. Lookup
does not erase, wrap, or narrow the type of the result. A `Button` found by `id`
is still a `Button`.

In typed surface terms:

- `findById` returns `TNode | nil`
- `findByTag` returns `TNode[]`

where `TNode` means a concrete retained node instance in the `Container` family.

Callers in dynamically typed environments should validate the concrete type of the
result if subtype-specific methods are needed.

---

## API Summary

| Method                        | Returns              | Default depth | Unique result |
|-------------------------------|----------------------|---------------|---------------|
| `node:findById(id, depth?)`   | `retained node\|nil` | `-1`          | yes           |
| `node:findByTag(tag, depth?)` | `retained node[]`    | `1`           | no            |

Depth values for both methods:

| Value   | Meaning                         |
|---------|---------------------------------|
| `0`     | Receiver only                   |
| `1`     | Direct children                 |
| `2`     | Children and grandchildren      |
| `-1`    | Full subtree (unbounded)        |

Negative values other than `-1` are rejected. Fractional values are rejected.
Values greater than `-1` and less than `1` are rejected.

---

## Name Lookup

No `findByName` or equivalent is provided in this patch.

`name` is sibling-unique, not globally unique. A subtree name search without an
explicit scope would be ambiguous across the tree.

If a future consumer requires name-based lookup, the appropriate API shapes are:

- Direct child lookup scoped to a known parent
- Path-based lookup using slash-delimited name segments

These are deferred until a concrete consumer requires them.

---

## Non-Goals For This Patch

Do not add:

- `findByName` or any broad name-based search
- Path-based lookup syntax
- Selector or query language
- Implicit fallback from `name` or `tag` to identity lookup
- Tag indexing or accelerators (deferred to Patch 3)

---

## Implementation Staging

The full semantic contract is defined above. Implementation may be delivered in
stages. The spec is not staged; only the implementation is.

### Patch 1 — Required

Must ship together:

- `id` field and uniqueness enforcement
- `name` field and sibling uniqueness enforcement
- `tag` clarification and internal usage resolution
- `findById` implementation
- `findByTag` implementation
- Reparenting validation for all three fields
- Subtree attach collision check for `id`
- Internal node boundary enforcement

### Patch 2 — Conditional

Ship if a concrete name-lookup consumer appears:

- Scoped `name` lookup
- Path-based lookup

### Patch 3 — Conditional

Ship if runtime query performance requires it:

- Tag indexing at attachment root boundary
- Root-level query accelerators

---

## Foundation Spec Changes

### `Container` Props

Add:

```
id:   string | nil   -- structural addressing key, unique within attachment root
name: string | nil   -- human-readable label, unique among direct siblings
tag:  string | nil   -- classification label, non-unique
```

### `Container` API

Add:

```
findById(id, depth?)  -> retained node | nil
findByTag(tag, depth?) -> retained node[]
```

### Clarifications

- `tag` is consumer-facing classification. It is not a structural address.
- Internal framework nodes use a separate private labeling mechanism and do not
  participate in the public `tag`, `id`, or `name` contracts.
- `id` is the only field that participates in cross-boundary structural addressing.
  `name` and `tag` must not be used as substitutes for `id`.