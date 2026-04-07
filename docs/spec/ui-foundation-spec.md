# UI Foundation Specification

> Version `0.1.0` — initial publication. Release history and change management policy: [UI Evolution Specification](./ui-evolution-spec.md).

## 3. Glossary

`Component`: A named UI construct with a defined purpose, contract, anatomy, state model, and composition rules.

`Primitive`: A low-level component intended to be composed by other components. A primitive owns structural or behavioral concerns rather than product-specific meaning.

`Runtime primitive`: A non-visual or app-level primitive that participates in lifecycle, scene ownership, or rendering orchestration.

`Consumer`: The application code using this library.

`Node`: A single retained object in the UI tree.

`Tree`: The parent-child structure used for transforms, visibility, event ancestry, focus ancestry, and z-order scoping.

`Root`: A node with no parent in the UI tree. `Stage` is the top runtime root.

`Attachment root`: The highest ancestor reachable from a node by following parent links until no parent remains. A detached node is its own attachment root.

`Internal node`: A retained node with `internal = true`. An internal node remains part of the retained tree for structure, layout, transform, rendering, clipping, focus ancestry, and event ancestry, but it does not participate as a public lookup or public addressing match.

`Slot`: A named child position or named subpart within a component contract.

`Variant`: A supported behavioral or presentational mode defined by the component contract.

`Controlled state`: A state value supplied by the consumer and treated as authoritative by the component. The component may request changes through callbacks but must not treat internal mutation as the source of truth.

`Render effect`: A visual operation applied during drawing, such as a shader, mask, opacity modulation, clipping, or isolated compositing.

`Isolation`: Rendering a subtree into an offscreen target before compositing it into its parent.

`Token`: A consumer-supplied theming value such as a color, spacing value, radius, timing value, texture reference, or shader reference.

`Skin asset`: A presentational asset used to draw a component, including textures, atlas regions, quads, shaders, and nine-slice definitions.

`Breakpoint`: A declarative conditional rule keyed to viewport, orientation, or environment constraints.

`Responsive rule`: A declarative rule that modifies measurement, placement, or variant resolution based on environment or parent space.

`Focusable`: A node eligible to receive logical focus.

`Focused`: The node currently owning logical keyboard or text-entry focus within a focus scope.

`Focus scope`: A bounded subtree within which focus traversal is resolved.

`Propagation`: Ordered delivery of an input event through a target path using capture, target, and bubble phases.

`Scroll container`: A node that owns clipping, scroll offsets, scroll state, and scroll input handling for descendant content.

`Safe area`: The unobstructed region reported by the environment and suitable for critical content placement.

`Anchored overlay`: A non-blocking overlay surface positioned relative to an owning anchor region while remaining constrained by viewport, safe-area, and clipping-fit rules.

`Preferred placement`: The consumer-requested initial side or alignment for an anchored overlay before fallback resolution is applied.

`Disabled`: A state in which a component accepts no input events, does not participate in focus traversal, and suppresses all activation behavior. A disabled component remains visible and retains its position in the tree unless additionally hidden.

`Activation`: The event signaling that a control's primary purpose has been fulfilled. The specific gesture or input sequence constituting activation is defined by the component contract.

`Hit test`: The process of determining whether a spatial point falls within a node's interactive bounds. A node passes a hit test when the point falls within its visible, clipped, and enabled interactive region.

`Local space`: The coordinate space relative to a node's own origin, before the node's local transform is applied.

`World space`: The coordinate space of the stage root, produced by composing all ancestor transforms along the path from root to node.

`Layout pass`: A tree traversal during which each dirty node resolves its measurement and child placement according to its layout contract.

## 3B. Shared Value Families

### 3B.1 SideQuad Input

`SideQuad input`: A public input family that resolves into the canonical shape
`{ top, right, bottom, left }`.

Accepted public forms in this revision:

- `number`
- `{ top = n, right = n, bottom = n, left = n }`
- `{ n, n }`
- `{ n, n, n, n }`

Normalization rules:

- `number` means all four sides equal
- keyed-table form fills missing members with `0`
- two-value sequence form means vertical, horizontal
- four-value sequence form means top, right, bottom, left

Invalid shapes fail deterministically.

`SideQuad input` defines only shape normalization and member expansion. The
owning property family remains authoritative for member domains such as
"non-negative only" or other narrower constraints.

Spacing-family constraints in this revision:

- `padding` and any flat `padding*` members must be finite and `>= 0`
- `margin` and any flat `margin*` members must be finite and may be positive,
  zero, or negative

### 3B.2 CornerQuad Input

`CornerQuad input`: A public input family that resolves into the canonical shape
`{ topLeft, topRight, bottomRight, bottomLeft }`.

Accepted public forms in this revision:

- `number`
- `{ topLeft = n, topRight = n, bottomRight = n, bottomLeft = n }`
- `{ n, n, n, n }`

Normalization rules:

- `number` means all four corners equal
- keyed-table form fills missing members with `0`
- four-value sequence form means topLeft, topRight, bottomRight, bottomLeft

Invalid shapes fail deterministically.

`CornerQuad input` defines only shape normalization and member expansion. The
owning property family remains authoritative for member domains such as
"non-negative only" or other narrower constraints.

### 3B.3 Aggregate And Flat Override Rule

When one property family exposes:

- one aggregate property using `SideQuad input` or `CornerQuad input`
- flat per-side or per-corner override props

the merge rule in this revision is:

- the aggregate property establishes the family fallback
- flat overrides win for their own member
- canonical resolved form is always expanded member-by-member

## 3A. Component Model

### 3A.1 Definition Of A Component

A component is a named, retained library artifact with a stable responsibility boundary, a documented public contract, and lifecycle participation in the `Stage`-rooted runtime model.

A library artifact qualifies as a component only when all of the following are true:

- it has a canonical name exported by the library and stabilized by this specification
- it can exist directly in the retained UI tree or it owns retained-tree orchestration as a runtime utility
- it has a documented purpose, anatomy, state model, and composition contract
- it participates in the library lifecycle model defined in Section 3A.6

The minimal first-class unit of composition is the named component. Named slots such as `content`, `label`, `panel`, or `surface` are contract surfaces, not separate components, unless they are defined elsewhere as their own named component.

The following artifacts are not components in this revision:

- value types and math helpers such as `Vec2`, `Matrix`, and `Rectangle`
- theme tokens, skin assets, breakpoint tables, callbacks, and scene params
- internal helper nodes used to implement a component but not stabilized as named public parts

### 3A.2 Classification Taxonomy

| Tier | Qualifies when | Disqualifies when | Canonical examples |
|------|----------------|-------------------|--------------------|
| Primitive | The component has its own direct contract and is not defined primarily as arrangement of other named components | The component exists solely to arrange children, or solely to orchestrate runtime/context behavior without a retained visual/tree contract | `Container`, `Drawable`, `Shape`, `ScrollableContainer`, `Text` |
| Composite | The component combines primitives or other composites into a higher-order semantic contract with named parts or slots | The component's contract is only generic layout, only runtime orchestration, or only an internal implementation detail of another component | `Button`, `Checkbox`, `Tabs`, `Modal`, `Alert` |
| Layout | The component exists solely to measure, align, or place descendants and has no semantic control meaning of its own | The component owns activation, selection, text entry, scroll state, or runtime scene orchestration as its primary contract | `Stack`, `Row`, `Column`, `Flow`, `SafeAreaContainer` |
| Utility | The component has no required visual output and primarily provides runtime, context, or orchestration behavior | The component's primary correctness depends on presenting semantic UI content or arranging ordinary descendants as its main job | `Stage`, `Scene`, `Composer` |

### 3A.3 Component Responsibility Boundary

`Boundary type` is normative:

- `fixed` means the consumer may configure or style the component but may not extend what the library treats as the component's correctness boundary
- `extensible through documented slots only` means consumer content may be supplied through named slots or descendants, but the owning component's responsibility remains fixed

| Component | Tier | Sole responsibility | Explicitly does not manage | Boundary type |
|-----------|------|---------------------|----------------------------|---------------|
| `Container` | Primitive | tree membership, transforms, visibility, bounds, event ancestry, focus ancestry | drawing, semantic meaning, control state, product-specific behavior | fixed |
| `Drawable` | Primitive | presentational surface, content box, alignment, render-effect participation | activation semantics, layout-family placement policy, business meaning | fixed |
| `Shape` | Primitive | geometric retained presentation, fill rendering, and silhouette-aware containment | `Drawable` box-model semantics, styling families, render-effect participation, child-layout semantics | fixed |
| `Stack` | Layout | layered child placement within one content box | sequential layout rules, overlay blocking, focus trapping | extensible through documented slots only |
| `Row` | Layout | horizontal sequencing, gap resolution, cross-axis alignment | scrolling, tabular data semantics, child activation behavior | extensible through documented slots only |
| `Column` | Layout | vertical sequencing, gap resolution, cross-axis alignment | scrolling, form semantics, child activation behavior | extensible through documented slots only |
| `Flow` | Layout | wrapped placement in reading order | strict grid semantics, selection logic, child activation behavior | extensible through documented slots only |
| `SafeAreaContainer` | Layout | safe-area-aware insetting of descendant content | reporting environment safe area, overlay blocking, viewport ownership | extensible through documented slots only |
| `ScrollableContainer` | Primitive | viewport clipping, scroll extent, scroll offsets, scroll input interpretation | descendant semantic layout, text editing, overlay focus policy | extensible through documented slots only |
| `Stage` | Utility | viewport root ownership, safe area exposure, root event dispatch entry, root focus scope | scene registry policy, app business state, control rendering semantics | fixed |
| `Scene` | Utility | screen-level subtree lifecycle boundary and active/inactive participation | scene registry ownership, navigation policy, sibling scene orchestration | extensible through documented slots only |
| `Composer` | Utility | scene registration, transition sequencing, scene activation, runtime routing | business navigation decisions, control-local behavior, application data ownership | fixed |

The concrete control boundaries that depend on this taxonomy are defined in [UI Controls Specification](./ui-controls-spec.md). Concrete first-class graphics-object contracts are defined in [UI Graphics Specification](./ui-graphics-spec.md). Motion integration contracts are defined in [UI Motion Specification](./ui-motion-spec.md).

### 3A.4 Identity Contract

The identity of a component is the combination of:

- its canonical name exactly as written in this specification
- its classification tier
- its documented responsibility boundary
- its required named anatomy and documented slots
- its lifecycle guarantees and rendering-model participation

Additional identity rules:

- This section defines component identity, not retained-node instance addressing. Per-node `id`, `name`, `tag`, and lookup behavior are defined by the `Container` contract in Section 6.1.1.
- No aliases are stabilized in this revision. A shortened or alternative name is not part of the contract unless it is explicitly added in a future revision.
- Internal helper structure is an implementation detail unless the part is named in the Anatomy section or stabilized in a theming contract.
- Changing a component's tier, required named parts, root ownership rules, or lifecycle observability is a breaking change.
- Re-implementing a component internally without changing its canonical name, boundary, anatomy, or lifecycle guarantees is non-breaking.

### 3A.5 Rendering Model Declaration

The library uses a retained rendering model.

Retained-mode consequences:

- component instances persist across frames until explicitly removed from the tree or runtime registry
- `Stage`-driven update and draw traversal operates on the retained tree rather than on a frame-by-frame re-description
- transform, layout, focus, and propagation ancestry are properties of persistent nodes

Immediate-mode components are not part of the public model in this revision.

Named exceptions:

- none in this revision

`Stage`, `Scene`, and `Composer` orchestrate retained subtrees but do not create a hybrid rendering model. They are runtime utilities operating on the same retained component graph.

Frame traversal model:

`Stage` drives two ordered, sequential passes per frame:

| Pass | Responsibility | Initiator |
|------|---------------|-----------|
| Update pass | resolve dirty geometry, layout, world transforms, and any queued state changes; the retained tree must be internally consistent before this pass completes | the host runtime initiates; `Stage` drives the traversal |
| Draw pass | traverse all visible retained nodes in tree order and issue draw commands; no state resolution occurs during this pass | the host runtime initiates; `Stage` drives the traversal |

The update pass must complete before the draw pass begins for the same frame. The host runtime is responsible for calling both entry points; the library defines what each traversal does and guarantees internal consistency within each pass.

### 3A.6 Lifecycle Model

Every component participates in the following lifecycle phases:

| Phase | Library guarantees | Consumer observability |
|------|--------------------|------------------------|
| Creation | The component has its canonical identity, defaults are resolved, required local fields and named parts exist, and the component has not yet been targeted for draw, focus, or input until attached to the retained runtime tree | Observable through construction and documented initialization APIs; `Scene` and `Composer` additionally expose explicit runtime lifecycle hooks |
| Update | Dirty state is resolved during retained update, layout, or draw preparation passes before behavior that depends on that state executes; parent ancestry, world state, and documented controlled-state rules are internally consistent for the duration of the pass | Observable through documented callbacks, event delivery, focus changes, scene activation changes, and visible output |
| Destruction | Once detached from the retained tree or removed from a runtime registry, the component stops participating in draw, input targeting, focus traversal, and ordinary retained updates; owned tree membership maintained by the library is severed | Observable through removal from the tree, loss of focus eligibility, scene leave/destroy behavior, and absence from further callbacks or traversal |

Lifecycle rules that apply across tiers:

- Ordinary primitives, layouts, and controls do not expose a generic lifecycle hook API in this revision. Their lifecycle is observed through construction, attachment, callbacks, and removal.
- `Scene` and `Composer` are the only components in this revision with explicit named runtime lifecycle hooks.
- Primitives guarantee only their own contract state at creation time. Composites additionally guarantee that their required named parts and slots exist as a coherent contract surface.
- Composite destruction includes destruction of library-owned internal parts. Consumer-supplied content passed through slots remains consumer-owned even though it leaves traversal with the owning composite.

Concrete terms:

- `fully initialized` means construction has completed successfully and, once attached, the component has completed at least one retained synchronization pass needed for its documented measurement, transform, and render ancestry
- `fully destroyed` means the component is no longer reachable from `Stage` or `Composer` traversal and cannot be drawn, focused, targeted, or updated through the library runtime

## 3B. Composition Grammar

### 3B.1 Relationship Types

| Relationship type | Direction | Cardinality | Initiator | Mechanism | Status in this revision |
|-------------------|-----------|-------------|-----------|-----------|-------------------------|
| Containment | unidirectional parent-to-child ownership | one-to-many | parent | retained-tree nesting | supported |
| Slotting | unidirectional root-to-slot-filler resolution | one-to-one or one-to-many per slot | slot owner declares, consumer fills | named slot, unnamed default slot, or documented prop-backed structural region | supported |
| Delegation | unidirectional delegating root-to-designated child region | one-to-one per delegated region | parent | required content subtree, required layer, or required surface subtree | supported |
| Structural registration | upward child-to-ancestor registration with downward resolution by the owner | many-to-one registration, one-to-many resolution | child or slot filler by placement and declared role | direct membership in a compound root or required slot container | supported |
| Context provision | broadcast ancestor-to-descendant availability | one-to-many | ancestor | implicit descendant lookup without containment or slot declaration | not a public composition mechanism in this revision |

Relationship definitions:

- `Containment` means the parent owns mounting, ordering, and ordinary traversal of the child.
- `Slotting` means a component exposes a named or unnamed structural region that a consumer may fill only according to that slot's contract.
- `Delegation` means a component gives a defined sub-region of its own contract entirely to a designated child subtree while retaining outer ownership of the whole component.
- `Structural registration` means a descendant becomes meaningful to a compound root by occupying a required role or slot recognized by that root.
- `Context provision` is intentionally excluded as a public structural relationship in this revision. Structural meaning must remain decidable from containment, slots, and registration.

### 3B.2 Composition Validity Rules

Composition validity is determined from the static structure of the retained tree and slot occupancy. Runtime state, event history, and visual output are not required to decide validity.

Every composition must be evaluated against these rules:

- A component is valid only when its immediate parent permits that component or tier in the occupied slot or child position.
- Reparenting always requires re-evaluation against the new immediate parent. Validity does not transfer automatically across different parents.
- A descendant that is valid inside an open child slot remains transitively valid only while every immediate parent-child relationship on the path remains valid and no ancestor compound rule narrows the allowed descendant set.
- Components with required slots or required child roles are incomplete and therefore invalid until those required regions are satisfied.
- Components with closed sub-part sets reject additional consumer-defined structural roles beyond the documented slots or child positions.
- The retained tree must be finite and acyclic.

Family-level validity matrix:

| Component or family | Allowed parents | Allowed children or fillers | Prohibited children or fillers | Required children or slots | Standalone validity |
|---------------------|-----------------|-----------------------------|-------------------------------|----------------------------|--------------------|
| `Container` | any component with an open descendant slot | any primitive, layout, or composite component | runtime utilities as descendants because they own runtime boundaries rather than ordinary subtree content | none | valid |
| `Drawable` | any component with an open descendant slot | any primitive, layout, or composite component | runtime utilities as descendants | none | valid |
| `Stack`, `Row`, `Column`, `Flow`, `SafeAreaContainer` | any component with an open descendant slot | any primitive, layout, or composite component | runtime utilities as descendants | none | valid |
| `ScrollableContainer` | any component with an open descendant slot | exactly one delegated `content` subtree; optional library-owned scrollbar decorations | multiple consumer content children at the root level; runtime utilities as content descendants | one `content` subtree | valid only when the `content` subtree exists |
| `Stage` | none | only the runtime-owned `base scene layer` and `overlay layer` | any consumer-defined direct child outside those two layers; any parent | `base scene layer`, `overlay layer` | valid |
| `Scene` | only the `base scene layer` owned by `Stage` through `Composer` management | any primitive, layout, or composite component in its content region | direct child scenes and runtime utility descendants | none | invalid when detached from `Composer` management |
| `Composer` | none | one owned `Stage` runtime root and registered `Scene` definitions | any parent; multiple owned stages | one owned `Stage` | valid |

### 3B.3 Foundation Compound Component Contract

Foundation-level compounds and delegated structures are:

| Root | Required sub-parts | Optional sub-parts | Independent meaning outside the root | Structural communication mechanism | Sub-part set |
|------|--------------------|--------------------|--------------------------------------|-----------------------------------|--------------|
| `ScrollableContainer` | `viewport`, `content` | `scrollbars` | no; these are roles within the scroll primitive | root-owned delegation to the `content` subtree and root-owned clipping region | closed |
| `Stage` | `base scene layer`, `overlay layer` | none | no; these are runtime-owned layers only | runtime-owned layer assignment and layer-priority target resolution | closed |
| `Scene` | `root` | `content` | `content` may contain independent components, but the role itself has meaning only within `Scene` | containment through the scene root owned by `Composer` and `Stage` | open only at the `content` region |

Control-level compounds such as `Button`, `Tabs`, `Modal`, and `Alert` are defined in [UI Controls Specification](./ui-controls-spec.md).

### 3B.4 Slot Model

Slot rules in this revision:

- A slot exists only when the component Anatomy or grammar tables name it explicitly, or when the component family is declared to have an unnamed default descendant slot.
- `Container`, `Drawable`, `Stack`, `Row`, `Column`, `Flow`, `SafeAreaContainer`, and `Scene` each expose an unnamed default descendant slot with ordered multiplicity.
- `Shape` is a retained node but does not expose a consumer-fillable descendant slot in this revision.
- `ScrollableContainer` exposes one required named `content` slot with single-fill multiplicity.
- `Stage` exposes two runtime-owned named slots: `base scene layer` and `overlay layer`. Consumers do not fill these slots directly.
- A slot may be filled either by direct retained-tree nesting or by a documented prop-backed structural region when the component contract names that prop as a structural surface.
- Slot ordering is stable insertion order unless the owning component defines a stronger ordering rule such as `zIndex` or trigger-panel mapping.
- Unfilled optional slots contribute no structure by default unless the component explicitly defines fallback content.
- No component in this revision defines consumer-extensible arbitrary named slots beyond the slots named in the specification.

### 3B.5 Structural Communication

The library permits only these categories of structural information to be exchanged:

- child presence, order, and multiplicity
- slot occupancy and slot emptiness
- delegated-region ownership such as `content`, `surface`, or layer assignment
- compound membership and role identity such as trigger-to-panel pairing
- stable structural identifiers used only to establish required structural correspondence

Structural communication rules:

- downward communication is allowed from a root to its direct slots or delegated regions
- upward communication is allowed only as structural registration to the nearest owning compound root
- peer components do not communicate structurally except through their nearest owning ancestor
- structural communication is implicit for ordinary containment and insertion order, and explicit for named slots, named roles, and identifier-based pairing
- structural communication does not skip across ownership boundaries unless the compound contract explicitly allows descendant registration across wrappers
- no public component in this revision uses context-style broadcast structural lookup

Composition depth: this revision defines no hard maximum nesting depth. Correctness is guaranteed for any finite acyclic composition that satisfies the validity rules in Section 3B.2. Performance cost scales with subtree depth across transform resolution, layout traversal, hit testing, clipping, and effect isolation. `Stage` establishes the root of composition semantics; scene activation and overlay mounting change runtime ownership and layer priority but do not create a second independent composition grammar.

## 3C. State Model

### 3C.1 State Category Taxonomy

Every authoritative piece of state in this library belongs to exactly one of these categories:

| Category | Definition | Library may be authoritative | Consumer may be authoritative | Ownership negotiable per instance |
|----------|------------|------------------------------|-------------------------------|-----------------------------------|
| Interaction state | transient state driven by input processing or focus arbitration, such as hover, press capture, drag progress, focus ownership, composition candidate presence, and inertial scrolling | yes | only when a component explicitly exposes that interaction state as a negotiated public value | yes, but only for documented public interaction values |
| UI state | non-domain UI condition that changes component mode or availability, such as open or closed, expanded or collapsed, active overlay presence, read-only editing mode, or resolved panel visibility | yes | yes | yes |
| Application state | domain-meaningful user data exposed through a component, such as text value, checked value, or selected item value | yes in uncontrolled mode | yes in controlled mode | yes |
| Composition state | state scoped to a named composition root and used to coordinate registered sub-parts, such as the active tab value within one `Tabs` root or the active scene within one `Composer` | yes | yes at the composition root boundary | yes |

### 3C.2 Ownership Model

Ownership definitions for this revision:

- `library-owned` means the library is the sole authoritative source and the consumer may only observe the state through documented outputs
- `consumer-owned` means the consumer is the sole authoritative source and the library only reads the value and proposes changes
- `negotiated` means ownership is chosen per state property at component instantiation and remains fixed for the lifetime of that component instance

Negotiated-state rules:

- controlled mode is signaled by supplying the authoritative value prop for that state property
- when the component contract defines a change callback for that property, the callback is the only stable mechanism for proposed changes
- uncontrolled mode is the default when the authoritative value prop is omitted
- ownership mode cannot transfer during the lifetime of one component instance

### 3C.3 Controlled Vs. Uncontrolled Model

Controlled mode:

- the consumer provides the authoritative value and receives proposed changes through the documented callback
- the library must never commit a controlled value internally as authoritative state
- while waiting for the consumer to apply a proposed change, the component must continue to reflect the last committed consumer value for that property
- the library may continue to update library-owned interaction state during that window, but it must not expose the proposed controlled value as committed state

Uncontrolled mode:

- the library is authoritative for that property
- the initial value is either the component-specific default defined by the component contract or an explicit initial value prop when such a prop exists
- no stable imperative getter, setter, or reset API for uncontrolled public state is standardized in this revision unless a component section explicitly says otherwise
- the consumer may observe uncontrolled state only through documented callbacks, accessibility outputs, composition effects, and visible behavior

Hybrid restriction:

- a component may mix controlled and uncontrolled ownership across different public state properties only when each property has an independent ownership signal
- one state property may not be partially controlled and partially uncontrolled at the same time

### 3C.4 State Flow Within Composition

State flow rules:

- downward flow is permitted for consumer-owned controlled values, library-owned runtime environment state, and composition-root-owned coordination state
- upward notification is permitted only through documented callbacks or root-owned registration mechanisms
- sibling coordination is permitted only through the nearest owning composition root or runtime root; siblings never share authoritative state peer-to-peer
- composition state is isolated to the nearest composition root that defines it and does not cross into a sibling composition root unless the consumer explicitly re-provides the value at that root

Sharing model:

- public consumer-owned state sharing is explicit: the consumer passes the same authoritative value into the components or root that need it
- root-scoped library coordination state is implicit for registered sub-parts within a documented compound root such as `Tabs`, `Modal`, `Alert`, `Scene`, or `Composer`

### 3C.5 Consistency Guarantees

This revision makes these binary commitments:

- `Single-update atomicity`: guaranteed. When one committed authoritative state change affects multiple derived values or related sub-parts, the library must resolve those consequences before the next draw, hit-test, focus traversal, or consumer-visible derived read.
- `Composition coherence`: guaranteed within one composition root. When a composition root commits a new composition state, all registered sub-parts in that root must observe the same committed value in the same update turn.
- `Re-entrancy`: guaranteed by serialization, not by inline recursion. If a consumer callback triggered by a state proposal requests another state change, the nested request must be queued after the current callback returns and processed in FIFO order. The library must not expose a partially applied tree between those requests.
- `Ordering`: guaranteed FIFO per component instance or composition root for queued state proposals generated within one runtime turn.

For controlled properties, the callback that proposes a change is not itself a committed state transition. Commitment occurs only when the authoritative consumer value changes.

### 3C.6 Derived State

The library computes these derived state classes:

| Derived value | Source of truth | Synchronous with authoritative state | Stable API status |
|---------------|-----------------|--------------------------------------|-------------------|
| effective enabled / disabled participation | local enabled flags plus ancestor constraints | yes | stable when referenced by a component contract |
| effective focus eligibility and active focus owner | focusable flags, focus scopes, and current focus root | yes | stable |
| effective visibility for hit testing and rendering eligibility | local visibility plus ancestor clipping and visibility | yes | stable for behavior, internal storage is implementation detail |
| hover ownership and pointer-entry/exit bookkeeping | current pointer-derived hit target plus gesture ownership constraints | yes | internal unless a later component contract explicitly exposes it |
| resolved content box, layout dirtiness, world transform dirtiness, scroll range, and similar runtime caches | authoritative geometry, layout inputs, and content extents | yes at stable pass boundaries | implementation detail unless a component contract names the value explicitly |
| effective committed value for negotiated properties | authoritative controlled or uncontrolled property value | yes | stable |
| root-scoped coordination results such as active scene, active tab mapping, active panel visibility, or modal focus scope ownership | composition-root authoritative state plus registration data | yes | stable when named by the root contract |

Any transient `focused` render flag, draw-context hint, or equivalent rendering helper derived from focus ownership is internal unless a later component contract explicitly exposes it.

Trace note: added hover ownership to derived-state taxonomy so Phase 4 can use it for control plumbing without promoting hover or pointer-enter/leave notifications to stable public API.

Trace note: clarified that derived focused rendering state may exist, but it is not a durable public node property in this revision.

## 3D. Interaction Model

### 3D.1 Input Abstraction Model

The library recognizes input as logical intents rather than as device-specific events.

| Logical input | Definition | Physical mappings handled by the runtime and library |
|---------------|------------|----------------------------------------------------|
| `Activate` | primary confirmation intent targeted at the current hit target or focused component | mouse click, touch tap, confirm key, keyboard activation keys, programmatic activation request |
| `Navigate` | intent to move focus or roving selection within a structured set | directional keys, tab traversal commands, d-pad commands |
| `Dismiss` | intent to cancel, close, or leave the current bounded interaction scope without committing further action | escape key, back command, backdrop tap when allowed |
| `Scroll` | intent to move a viewport or overflow region | wheel delta, scroll gesture, keyboard scroll command, programmatic scroll request |
| `Drag` | continuous pointing intent that owns gesture progress over time | pointer drag, touch drag |
| `TextInput` | committed character or text insertion intent | key text entry, paste, IME commit, platform text insertion |
| `TextCompose` | provisional composition-candidate editing intent before committed text exists | IME candidate update, composition update from the platform |
| `Submit` | intent to finalize current text entry or confirmation flow without introducing new content | enter or confirm command in text-entry context, explicit submit action |

Mapping rules:

- the runtime may deliver platform-specific callbacks, but the library is responsible for translating supported callbacks into these logical input types before they reach components
- text composition and committed text may already arrive normalized by the platform; the library still treats them as `TextCompose` and `TextInput` logical inputs respectively
- once a logical input is consumed by a component during dispatch, the corresponding physical callback must not produce an additional second logical dispatch within the same runtime turn
- one pointer press-release gesture may use press, move, and release callbacks internally for recognition, but it must not emit more than one public `Activate` dispatch unless a component contract explicitly defines distinct press and release semantics

Trace note: clarified pointer-gesture activation deduplication because Phase 4 planning exposed a real risk of double-dispatch from naïve press-plus-release translation.

Input delivery rules:

- `Stage` is the single delivery point for all raw platform input; no component in the retained tree may receive raw input directly from the host runtime
- all translation from raw platform events to logical intents occurs inside the library, at or before `Stage` dispatch, before any component listener is invoked
- components participate in input only through the propagation system defined in Section 7.1; components must not read raw platform input state directly
- the host runtime is responsible for delivering raw input to `Stage`; the library is responsible for everything that follows delivery

### 3D.2 Event Contract

Sections 7.1 and 7.2 define propagation and focus mechanics. This section defines the named public interaction events emitted through that mechanism.

Common payload fields for all public interaction events:

- `type: string`
- `timestamp: number`
- `target`
- `currentTarget`
- `path: array`
- `defaultPrevented: boolean`
- `propagationStopped: boolean`

Additional payload fields are present by event family:

- spatial events also include `pointerType`, `x`, `y`, `localX`, and `localY`
- navigation events also include `direction` and `navigationMode`
- scroll events also include `deltaX`, `deltaY`, and `axis`
- drag events also include `dragPhase`, `originX`, `originY`, `deltaX`, and `deltaY`
- text events also include `text`; composition events additionally include `rangeStart` and `rangeEnd`
- focus events also include `previousTarget` and `nextTarget`

Named public events:

| Event name | Trigger | Cancellable | Timing | Propagation |
|------------|---------|-------------|--------|-------------|
| `ui.activate` | an `Activate` logical input reaches a component that defines activation semantics | yes; cancellation prevents the component default action and any mediated state proposal tied to that activation | before default action | capture, target, bubble |
| `ui.navigate` | a `Navigate` logical input reaches a component or focus scope that handles traversal | yes; cancellation prevents the resulting focus or roving navigation move | before focus movement is committed | capture, target, bubble |
| `ui.dismiss` | a `Dismiss` logical input reaches a dismissable component or active dismiss scope | yes; cancellation prevents the dismissal proposal | before dismissal proposal | capture, target, bubble |
| `ui.scroll` | a `Scroll` logical input reaches a scrollable target or focused scroll container | yes; cancellation prevents the scroll offset update | before uncontrolled offset update | capture, target, bubble |
| `ui.drag` | a drag-capable component receives a `Drag` logical input phase change | yes for `start`, `move`, and `end`; cancellation prevents the associated drag progression or release proposal for that phase | once per drag phase transition | capture, target, bubble |
| `ui.text.input` | committed `TextInput` reaches an active text-entry target | yes; cancellation prevents insertion or value proposal for that committed text | before value proposal | capture, target, bubble |
| `ui.text.compose` | provisional `TextCompose` reaches an active text-entry target | yes; cancellation prevents composition-candidate update | before composition state update | capture, target, bubble |
| `ui.submit` | `Submit` reaches a component that defines submission semantics | yes; cancellation prevents submit default action or submit proposal | before submit default action | capture, target, bubble |
| `ui.focus.change` | logical focus ownership changes between committed targets | no | after focus change is committed | target only on the new focus owner plus observation from the active focus scope |

Event ordering guarantees:

1. logical input dispatch begins
2. capture listeners fire
3. target listeners fire
4. bubble listeners fire
5. if `defaultPrevented = false`, the component default action and uncontrolled proposal resolution execute
6. if focus ownership changed, `ui.focus.change` fires after the change commits

Event deduplication and synthetic events:

- the library does not deduplicate rapid identical logical inputs by default
- repeated physical callbacks produce repeated logical events unless a component-specific contract says otherwise
- the library may emit synthetic `ui.focus.change` when focus changes due to component opening, closing, restoration, or explicit consumer focus request
- programmatic state changes do not emit synthetic `ui.activate`, `ui.dismiss`, `ui.navigate`, `ui.scroll`, or `ui.submit` unless a component contract explicitly says they do

### 3D.3 Input-To-State-Proposal Mapping

| Logical input | State categories it may propose to change | Proposal rule | Proposal mode |
|---------------|-------------------------------------------|---------------|---------------|
| `Activate` | interaction, UI, application, or composition state depending on the target component | component default action resolves a target-specific proposed change such as activate, toggle, open, close, or select | mediated in controlled mode; direct in uncontrolled mode |
| `Navigate` | interaction or composition state | moves focus, roving focus, or structured active-item position; does not itself commit unrelated application state | direct for library-owned focus, mediated or direct for component-specific composition state |
| `Dismiss` | UI or composition state | proposes closing, cancelling, or leaving the active bounded scope | mediated in controlled mode; direct in uncontrolled mode |
| `Scroll` | interaction or UI state | updates scroll offsets and related inertial progress within the active scroll owner | direct for uncontrolled scroll containers |
| `Drag` | interaction, UI, or application state | updates gesture progress during move phases and may propose a final committed value at drag end | direct for library-owned gesture progress; mediated or direct for the final committed property |
| `TextInput` | application state and selection-related UI state | proposes insertion or replacement of committed text and resulting selection collapse | mediated in controlled mode; direct in uncontrolled mode |
| `TextCompose` | interaction state | updates composition-candidate presence and range only | direct for library-owned composition state |
| `Submit` | UI or application state only when the target component defines submit semantics | proposes blur, submit callback behavior, or no state change depending on the component contract | component-specific; may be mediated or may have no state proposal |

If a logical input has no state implication for a target component, that component may still emit the corresponding event but must take no default action after listener delivery.

### 3D.4 Focus Model

Focus ownership:

- the library owns logical focus targeting, traversal, focus trapping, and focus restoration within the component tree
- the consumer owns explicit requests to move focus and any application policy that decides which request to issue
- native operating-system focus outside the library tree is outside the library scope except where text-entry activation requires platform cooperation

The requirement for explicit focus request support is behavioral, not a commitment to one public imperative method name on `Stage` or on ordinary nodes. Any helper API used to submit such a request remains internal unless a later revision documents it.

Trace note: added the explicit-request boundary because Phase 5 planning exposed pressure to stabilize `requestFocus(...)` as public API even though imperative handles are not generally standardized in this revision.

Focus movement rules:

- `Navigate` with sequential traversal commands moves focus linearly within the active focus scope
- `Navigate` with directional traversal commands moves focus only in component families that explicitly support directional navigation
- `Activate` may move focus only when the target component contract declares pointer-focus coupling
- `Dismiss` may move focus indirectly by closing a focus-trapping scope and restoring the prior focus target

Focus observation:

- focus is observable through `ui.focus.change`
- this revision defines one logical focus concept; keyboard focus is not separated into a second public focus type

### 3D.5 Interaction Propagation

Sections 7.1 and 7.2 remain normative for path resolution and focus traversal. The default propagation direction per logical input is:

- `Activate`, `Dismiss`, `Scroll`, `Drag`, `TextInput`, `TextCompose`, and `Submit`: inward target resolution followed by capture, target, and bubble delivery
- `Navigate`: inward target resolution to the active focus owner or active focus scope followed by capture, target, and bubble delivery

Primary-recipient rules:

- spatial logical inputs target the deepest eligible hit-test result after overlay precedence is applied
- non-spatial keyboard-derived logical inputs target the current logical focus owner, or the active focus scope when no focused leaf exists and the scope defines a root handler
- text-entry logical inputs target the active text-entry owner, not merely the currently hovered node

Consumption rules:

- `stopPropagation()` prevents further ancestor delivery after the current listener returns
- `stopImmediatePropagation()` prevents later listeners on the same target and all further propagation
- `preventDefault()` preserves listener delivery but suppresses the default action and any direct uncontrolled proposal tied to that event

Overriding propagation order is not stable public API in this revision. Consumers may observe, cancel, or stop propagation only through the documented event object contract.

## 3E. Behavioral Completeness

### 3E.1 Empty And Null State Contract

Foundation-level empty-state rules:

- `Container`, `Drawable`, `Stack`, `Row`, `Column`, `Flow`, and `Scene` render nothing when they have zero eligible children; this is a valid empty state, not an error state.
- `Shape` remains valid when detached or when sized to a degenerate area, but a zero-area shape may draw nothing and may expose no hittable silhouette.
- `ScrollableContainer` with an empty content subtree remains valid, resolves zero content extent, and does not enter a scrolling state.
- runtime roots such as `Stage` and `Composer` remain valid when no active scene content is present; they render no scene content and continue to maintain runtime ownership invariants.
- the library does not inject default empty-state placeholder content for foundation components in this revision.
- transitioning into or out of an empty structural state does not emit a dedicated empty-state event in this revision.
- foundation components define no public asynchronous content-loading contract; any consumer-composed async behavior is consumer-owned unless a future component specification defines otherwise.

### 3E.2 Overflow And Constraint Behavior

Foundation overflow model by family:

| Family | Default overflow behavior | Functional minimum contract | Dynamic constraint change behavior |
|--------|---------------------------|-----------------------------|------------------------------------|
| `Container` and `Drawable` | overflow unless clipping is explicitly enabled; zero-area content boxes clamp to zero rather than producing invalid geometry | remains valid at zero size but may render nothing useful | re-resolve transforms, bounds, and content boxes on the next retained pass |
| Layout primitives | place, wrap, or overflow according to the [UI Layout Specification](./ui-layout-spec.md) | remain structurally valid even when content cannot fully fit; clipping occurs only when enabled | re-measure and re-place children on the next layout pass |
| `ScrollableContainer` | scroll within the enabled axis set; no implicit clipping escape beyond the viewport | remains functional when the viewport is smaller than content so long as scrolling on at least one axis remains enabled | recalculate content extent, clamp offsets, and continue from the clamped position |
| Runtime roots | resize and reflow subordinate content | remain valid at any finite viewport size even when descendant content becomes unusable | propagate resize and mark descendants dirty |

The library exposes no generic overflow event or overflow flag in this revision unless a component contract names one explicitly.

### 3E.3 Concurrent And Rapid Input Behavior

Library-wide rapid-input policy:

- the library does not apply global throttle or debounce behavior to logical inputs in this revision
- repeated logical inputs are processed in arrival order
- library-owned interaction progress such as focus changes, drag progress, and scroll offsets must remain internally consistent after each processed input
- when multiple input sources target different recipients simultaneously, arbitration resolves per active recipient rules from the Interaction Model; there is no cross-tree multi-recipient merge step
- when multiple input sources target the same active interaction owner, the owner that currently holds gesture or text-entry ownership keeps priority until it releases that ownership or is destroyed

### 3E.4 Transition Interruption

Transition interruption rules for foundation/runtime components:

- an interruption occurs when a new navigation request, dismiss request, resize, destruction, or other authoritative state change prevents a multi-step transition from completing along its currently scheduled path
- intermediate runtime transition state may be observable only through the documented transition state machine or visible output; no separate interruption event is standardized in this revision
- `Composer` interruptions resolve by cancelling the active visual transition, committing to the last authoritative runtime state defined by the `Composer` contract, and then processing the new request
- layout, transform, and render-dirty passes are not treated as interruptible animations; they simply recompute from the latest authoritative inputs on the next pass

### 3E.5 Destruction During Activity

Foundation destruction guarantees:

| Activity type | Library guarantee on destruction | Consumer responsibility |
|---------------|----------------------------------|-------------------------|
| pending state proposal | abandon any uncommitted uncontrolled proposal owned by the destroyed component; no further callback is emitted from the destroyed instance after removal | ignore stale consumer-owned proposals that were never committed |
| in-progress transition or animation | cancel the in-progress runtime transition work owned by the destroyed subtree and remove it from further traversal | clean up any consumer-owned transition bookkeeping outside the component tree |
| active interaction | release gesture ownership, text-entry ownership, and focus participation held by the destroyed component; ancestor focus and routing must remain coherent | clean up application-side effects that were waiting on completion of that interaction |
| pending async operation | no foundation component in this revision owns a public async load operation; any consumer-owned async work is outside the library responsibility boundary | cancel or ignore consumer-owned async work |

## 3F. Contract Stability

### 3F.1 Stability Tier Taxonomy

The stability tiers in this section are binding promises.

No additional tier such as `preview`, `beta`, or `legacy` exists in this revision. A documented API surface is `Stable` unless it is explicitly marked `Experimental`, `Deprecated`, or `Internal`.

| Tier | Promise |
|------|---------|
| `Stable` | the library will not make a breaking change to this surface without using the defined breaking-version boundary and following the deprecation protocol in Section 3F.5 |
| `Experimental` | the surface may change or be removed in any release, including patch releases; consumers must opt in explicitly; no deprecation notice is guaranteed |
| `Deprecated` | the surface remains supported and behaviorally equivalent until its declared removal version; a replacement or explicit `no direct replacement` statement must be declared at deprecation time |
| `Internal` | the surface is not public API, consumer usage is unsupported, and no compatibility promise is made |

### 3F.2 API Surface Classification

The stability taxonomy applies to the full documented API surface of this library.

| API surface element | Tier in this revision | Current tier since | Deprecation/removal rule |
|---------------------|-----------------------|--------------------|--------------------------|
| canonical component names defined by this specification | `Stable` | `0.1.0` | none in this revision |
| documented component classification, identity, lifecycle, composition, state, interaction, behavioral, and visual contracts | `Stable` | `0.1.0` | none in this revision |
| documented properties, parameters, public state names, accepted value types, and documented default values | `Stable` | `0.1.0` | none in this revision |
| documented callback names, event names, and documented payload schemas | `Stable` | `0.1.0` | none in this revision |
| documented slot names, required structural pairings, validity rules, and composition prohibitions | `Stable` | `0.1.0` | none in this revision |
| documented named visual parts, documented token naming schema, documented token keys, and documented part-property bindings | `Stable` | `0.1.0` | none in this revision |
| documented extension points such as part skin override and custom renderer slots where the component contract names them | `Stable` | `0.1.0` | none in this revision |
| imperative handles or ref-style control interfaces | no public surface standardized | n/a | this revision declares no stable imperative-handle API |
| any surface explicitly marked `Experimental` by a future revision | `Experimental` | first labeled version | may change or be removed in any release |
| any surface explicitly marked `Deprecated` by a future revision | `Deprecated` | deprecation version | removal version and replacement must be declared at deprecation time |
| undocumented helper nodes, private caches, batching behavior, incidental traversal order, undocumented exports, and undocumented native-bridge choices | `Internal` | always | may change without notice |

The controls specification in [UI Controls Specification](./ui-controls-spec.md) assigns these same stability tiers to each concrete control family and its documented public surfaces.

Breaking change definition, versioning semantics, deprecation protocol, experimental gate, and stability scope are governed by [UI Evolution Specification](./ui-evolution-spec.md).

## 3G. Failure Semantics

### 3G.1 Failure Response Taxonomy

The library recognizes exactly these failure response modes:

| Mode | Definition |
|------|------------|
| `Hard failure` | the library raises an unrecoverable error for the current operation before committing invalid authoritative state for the affected target |
| `Soft failure with signal` | the library detects invalid or deprecated usage, emits a diagnostic signal, and continues with a defined compatibility or rejection behavior |
| `Silent fallback` | the library detects the condition and applies a documented fallback without emitting a diagnostic signal |
| `Passthrough` | the library does not intercept the condition; resulting behavior is determined by the host runtime, renderer, or platform primitive |
| `Undefined` | the behavior is intentionally unspecified; no stability or compatibility guarantee is made |

In this specification, `fail deterministically` means the condition is assigned one exact failure mode by this section or by a component-specific failure table. Unless a more specific rule says otherwise, deterministic failure for invalid configuration is a `Hard failure`.

### 3G.2 Invalid Usage Classification

| Category | Class of invalid usage | Detectable point | Default failure mode | Notes |
|----------|------------------------|------------------|----------------------|-------|
| A | structural invalidity such as missing required slots, cyclic parenting, or structurally incomplete compounds | when the owning tree relation or slot mapping is first knowable, typically at mount, registration, or the next retained pass after mutation | `Hard failure` | author-time tooling may detect earlier, but runtime detection is authoritative |
| B | type or value invalidity such as out-of-range numeric values, missing required asset references, or unsupported enum values | immediately on assignment when knowable, otherwise on the first pass that requires the value | `Hard failure` unless a component contract explicitly defines a fallback | documented fallback cases override this default |
| C | state contract violation such as switching a negotiated public value from controlled to uncontrolled after first commit, omitting a required change callback for a mutable controlled value, or providing an incomplete controlled pair | when state ownership is reconciled for the affected component | `Hard failure` | the library does not guess a new ownership mode |
| D | lifecycle violation such as invalid root/runtime operations, navigation to unknown runtime targets, or future imperative use outside a valid lifecycle phase | immediately when the operation is attempted | `Hard failure` | this revision exposes no stable imperative lifecycle surface for ordinary components |
| E | composition boundary violation such as mounting a component outside its required parent or runtime layer | when the parent/layer requirement is first knowable | `Hard failure` | boundary violations are distinct from merely optional empty states |
| F | out-of-scope usage such as relying on internal structures, mutating undocumented internals, or using explicitly unsupported extension patterns | generally not required to be detected | `Undefined` or `Passthrough` | the library disclaims responsibility for these cases |

### 3G.3 Diagnostic Signal Contract

Soft-failure diagnostics use the following contract:

- `Signal type`: warning-level diagnostic for deprecated or recoverable invalid usage; hard failures use thrown errors rather than this warning channel.
- `Signal timing`: emit at the point of detection, before the compatibility shim or rejection behavior is committed when that ordering is knowable.
- `Signal content`: include the failure category, affected component or API surface when known, and a concise reason. Exact message text is implementation detail and not stable API.
- `Signal environment`: warnings for soft failures and deprecated APIs are emitted in all supported runtime environments in this revision.
- `Signal suppression`: this revision defines no stable API for suppressing, redirecting, or subscribing to diagnostics. The transport may be implementation-specific, but the presence of the warning is contract surface when a rule selects `Soft failure with signal`.

### 3G.4 Fallback Behavior Contract

The library does not provide a generic best-effort recovery path for invalid configuration. If a fallback exists, it must be explicitly declared.

| Failure class | Mode | Fallback behavior | Contract status |
|---------------|------|-------------------|-----------------|
| documented missing optional visual input where the component contract defines a default token or fallback render input | `Silent fallback` | use the documented default token or fallback render input and continue rendering | stable degraded-but-valid output |
| documented omission of an optional slot or optional region | `Silent fallback` | render no content for that optional region and continue | stable valid output |
| deprecated API usage | `Soft failure with signal` | execute the deprecated behavior or a compatibility shim with equivalent documented observable behavior until removal | stable until removal |
| documented component-specific truncation, clamping, or rejection fallback | the mode named by the component section | apply exactly the fallback named by that section and no stronger recovery behavior | stable for that specific condition |
| all other detected invalid usage | `Hard failure` | no fallback is provided | fail-stop for the current invalid operation |

### 3G.5 Deprecated API Runtime Behavior

When a deprecated API is exercised at runtime:

- the library must execute the deprecated behavior or a compatibility shim that is externally equivalent to the deprecated behavior
- the library must emit a warning diagnostic under the signal contract in Section 3G.3
- the deprecated behavior remains guaranteed until the declared removal version
- no deprecated API may be removed before its declared removal version

### 3G.6 Undefined Behavior Declaration

The following classes of usage are intentionally undefined in this revision:

- mutating undocumented internal fields, caches, helper nodes, or runtime bookkeeping objects
- relying on undocumented wrapper hierarchy, undocumented traversal order, or undocumented diagnostic message text
- calling or importing internal-only symbols that are not declared as public API by this specification
- using the library through host-platform or renderer integrations that the specification does not claim to support

These classes are intentionally undefined rather than accidentally unspecified.

Future revisions may define some of them, but this revision makes no stability commitment about them and they may change without version increment.

### 3G.7 Graceful Degradation Contract

When the library encounters a failure condition, it guarantees the following minimum floor:

- a detected invalid operation must not partially commit invalid authoritative state; either the prior valid state is preserved or the documented fallback is fully applied
- a soft failure or silent fallback must remain isolated to the affected component, subtree, or runtime operation; unrelated committed siblings and roots remain valid
- when a fallback is defined, the resulting subtree must remain traversable for layout, input routing, and rendering according to the degraded contract
- except where a component section explicitly defines truncation, clamping, or omission as a fallback, the library must not silently discard committed consumer-owned content or state
- if the consumer catches a hard failure, the library must leave the previously committed unaffected tree in its last valid state

## 4. Scope And Domain

This document governs the abstract and non-concrete parts of the UI library: retained structure, composition grammar, state model, interaction model, behavioral completeness, contract stability, failure semantics, rendering behavior, state ownership, event propagation, focus management, responsive layout, runtime orchestration, render effects, and theming.

This document does not define the concrete control contracts in detail. Those are defined in [UI Controls Specification](./ui-controls-spec.md).

This revision owns the following families:

- Foundational primitives: `Container`, `Drawable`, `Shape`
- Layout primitives: `Stack`, `Row`, `Column`, `Flow`, `SafeAreaContainer`
- Scroll primitive: `ScrollableContainer`
- Runtime primitives: `Stage`, `Scene`, `Composer`
- Cross-cutting contracts: event propagation, focus, state model, render effects, responsive rules, theming

The library owns rendering behavior, transform composition, event routing, focus semantics, clipping, shader inheritance, negotiated state resolution, and the stable theming interface.

The consumer owns business meaning, application state orchestration, scene registration, token values, skin assets, copy, gameplay integration, and unsupported custom rendering behavior outside the defined extension surfaces.

## 5. Design Principles

1. Every UI object must exist as a retained node in a tree rooted at `Stage`.
2. Every interactive component must participate in true event propagation with capture and bubble phases.
3. Every focusable component must support keyboard focus semantics even in mobile-first environments.
4. Presentation must remain separable from behavior.
5. The library must reuse native platform primitives when they satisfy the contract without loss of composability, consistency, or performance.
6. The library must only wrap or re-implement a native primitive when the wrapper provides normalization, expandability, specification compliance, or measurable performance benefit.
7. Unsupported prop combinations must fail deterministically.
8. Effects and shaders must compose through defined inheritance and isolation rules.
9. Layout and scrolling must be invalidation-driven.
10. Z-order must be explicit and local to siblings.
11. Stateful primitives and controls that expose mutable public state must declare ownership as consumer-owned or negotiated; when negotiated, the controlled and uncontrolled contracts must both be explicit.
12. All input must enter the retained tree through `Stage`'s dispatch entry point and reach components only through the propagation system. No component may read raw platform input state directly.

## 6. Component Specifications

### 6.1 Foundation Family

#### 6.1.1 Container

**Purpose and contract**

`Container` is the foundational retained node. It owns tree membership, transforms, visibility, event ancestry, focus ancestry, sibling-local z-order, and spatial bounds. `Container` does not own presentation by itself.

`Container` must:

- participate in parent-child composition
- resolve local and world transforms
- expose hit-testable bounds
- participate in event propagation when interactive
- participate in focus ancestry
- support responsive rule resolution
- support explicit sibling-local `zIndex`

**Anatomy**

- `root`: the `Container` instance itself. Required.
- `children`: ordered child nodes. Optional.

All retained child membership in this tree model is `Container`-family membership.
In other words, the searchable retained subtree consists only of `Container`
instances and their subclasses. Non-`Container` values are not valid retained
children and are outside the lookup contract.

**Props and API surface**

- `id: string | nil`
- `name: string | nil`
- `tag: string | nil`
- `internal: boolean`
- `visible: boolean`
- `interactive: boolean`
- `enabled: boolean`
- `focusable: boolean`
- `clipChildren: boolean`
- `zIndex: number`
- `anchorX`, `anchorY: number`
- `pivotX`, `pivotY: number`
- `x`, `y: number`
- `width`, `height: number | "content" | "fill" | percentage`
- `minWidth`, `minHeight`, `maxWidth`, `maxHeight: number | nil`
- `scaleX`, `scaleY: number`
- `rotation: number`
- `skewX`, `skewY: number`
- `breakpoints: table | nil`
- `findById(id, depth?) -> Container | nil`
- `findByTag(tag, depth?) -> Container[]`

Trace note: clarified that the accepted `width` and `height` surface is stable at first publication. Implementation phases may stage resolution-path completion, but they must not narrow the accepted prop domain.

**Identity, naming, tagging, and lookup**

`Container` owns the retained-node addressing and classification contract for the foundation tree.

The lookup contract applies only to retained nodes in the `Container` family.
Because retained child membership is `Container`-family-only, every match
returned by `findById` or `findByTag` is a `Container` instance or subclass.

Field roles:

| Field | Purpose | Uniqueness boundary | Public lookup role |
|-------|---------|---------------------|--------------------|
| `id` | structural address | unique within one attachment root | singular lookup through `findById` |
| `name` | human-readable label | unique among direct siblings | no subtree name lookup in this revision |
| `tag` | classification label | none | bulk lookup through `findByTag` |

Field rules:

- `id`, `name`, and `tag` accept only `string | nil`.
- `nil` means the field is unset and is valid for all three fields.
- Empty-string and non-string assignments are invalid configuration and must fail deterministically.
- `internal` is a boolean structural lookup-boundary property. Its default value is `false`.
- `id` is machine-facing structural address only. It is not a display label or classification label.
- `name` is a human-facing label for inspectors, debuggers, and editor hierarchy views. It has no effect on rendering, layout, or runtime behavior.
- `tag` is the consumer-facing classification field. It is not a singular address and it has no uniqueness requirement.
- A node with `internal = true` remains in the retained tree but is excluded from public lookup matching and public uniqueness participation as defined below.
- Internal nodes may still carry `id`, `name`, or `tag` as local metadata, but those values are outside the public lookup and public uniqueness contract.
- Public `tag` remains consumer-facing classification. Internal nodes do not appear as `findByTag` matches even when they carry a tag.

Write-time validation:

- assigning or changing a non-`nil` `id` on an attached non-internal node must validate uniqueness against the node's current attachment root before the change commits
- attaching a non-internal node with a non-`nil` `id` must validate uniqueness against the target attachment root before the attach commits
- assigning or changing a non-`nil` `name` on an attached non-internal node must validate uniqueness against the node's direct non-internal siblings before the change commits
- attaching a non-internal node with a non-`nil` `name` must validate uniqueness against the target parent's direct non-internal children before the attach commits
- `tag` has no uniqueness validation
- when an incoming subtree is attached, all non-`nil` `id` values on non-internal nodes in that subtree must be validated against the target attachment root before any node in that subtree is attached
- changing `internal` on an attached node must update public lookup participation and public uniqueness participation atomically

Reparenting rules:

- `id`, `name`, `tag`, and `internal` persist on the node across reparenting
- `id` must be revalidated against the new attachment root during reparenting for non-internal nodes
- `name` must be revalidated against the new direct non-internal siblings during reparenting for non-internal nodes
- if reparenting or subtree attachment fails any public `id` or public `name` validation, the operation must fail deterministically without partially committing tree changes

Lookup rules:

| Method | Return | Default depth | Match set |
|--------|--------|---------------|-----------|
| `findById(id, depth?)` | `Container | nil` | `-1` | first matching public retained node in the receiver subtree |
| `findByTag(tag, depth?)` | `Container[]` | `1` | all matching public retained nodes in the receiver subtree |

Depth semantics for both methods:

| Value | Meaning |
|-------|---------|
| `0` | receiver only |
| `1` | direct children only |
| `2` | children and grandchildren |
| `-1` or `math.huge` | full descendant subtree |

Lookup behavior:

- `findById` returns the matching node when found and `nil` when no matching node exists in the receiver subtree
- `findByTag` returns a table in depth-first pre-order using sibling insertion order and returns an empty table when no matches exist
- `findById` and `findByTag` must fail deterministically when their search key is `nil`, empty, or not a string
- `depth = 0` is valid for both methods and limits evaluation to the receiver itself
- negative depth values other than `-1` are invalid configuration and must fail deterministically
- fractional depth values are invalid configuration and must fail deterministically
- no `findByName` or other subtree name-search API is standardized in this revision
- nodes with `internal = true` are excluded from `id` uniqueness validation, `name` uniqueness validation, and all public lookup matches
- lookup traversal continues through internal nodes, so non-internal descendants under internal wrappers remain discoverable within the receiver subtree

**State model**

STATE clean

  ENTRY:
    1. Local measurement and transform caches are current.
    2. World transform and bounds are current.

  TRANSITIONS:
    ON geometry mutation:
      1. Mark local measurement or transform state invalid.
      2. Mark descendant world state invalid where required.
      → dirty

    ON tree mutation:
      1. Update parent-child references.
      2. Mark ordering and world state invalid.
      → dirty

    ON breakpoint resolution change:
      1. Re-resolve responsive inputs.
      2. Mark measurement and transform state invalid.
      → dirty

STATE dirty

  ENTRY:
    1. Cached geometry or transform values are stale.

  TRANSITIONS:
    ON next layout or draw pass:
      1. Resolve responsive inputs.
      2. Resolve measurement.
      3. Resolve local transform.
      4. Resolve world transform from parent state.
      5. Resolve bounds.
      → clean

ERRORS:
  - `width = "content"` on a node with no intrinsic measurement rule → invalid configuration and deterministic failure.
  - Cyclic parenting attempt → invalid configuration and deterministic failure.

**Accessibility contract**

`Container` does not carry semantic accessibility meaning. It provides structural tree membership that allows descendant focusable nodes to resolve their focus ancestry correctly. `Container` does not require consumer-supplied accessibility attributes. A `Container` that is interactive and enabled must expose its interactive and enabled state so that assistive systems can determine whether the node participates in focus traversal.

**Composition rules**

A `Container` may contain any number of child nodes, including other `Containers`, `Drawable`-derived components, and `Shape`-derived components. A `Container` must not be placed inside a node that explicitly prohibits children.

Sibling draw order must resolve by:

1. ascending `zIndex`
2. stable insertion order among equal `zIndex` values

Hit testing must resolve in reverse draw order among eligible siblings.

A `Container` that is not interactive does not participate as a hit-test target but still participates as a propagation ancestor for its descendants. Event propagation continues through non-interactive containers in both the capture and bubble phases.

Direct target eligibility is determined from effective participation after applying visibility, ancestor clipping, and enabled-state constraints, not from raw local flags alone.

Attachment-root addressing is structural. Calling `findById` from a non-root node searches only that node's subtree even when another node with the same `id` exists elsewhere under the same attachment root.

Trace note: added an explicit effective-targeting sentence because Phase 1 planning exposed ambiguity between structural traversal and direct target eligibility.

**Behavioral edge cases**

- A `Container` with no children must remain valid and render nothing.
- A `Container` marked `visible = false` must not participate in hit testing, event propagation targeting, or rendering. It must retain its position in the tree and continue to contribute its transform to any descendants that may be independently made visible.
- A `Container` with `clipChildren = true` must clip both rendering and hit testing to its own bounds.
- A `Container` with `clipChildren = true` whose resolved clip bounds are degenerate produces an empty effective clip region.
- A `Container` with `width = "fill"` as a direct child of `Stage` resolves against the full viewport width.
- A `Container` with `enabled = false` must not receive activated events and must suppress focus acquisition for itself and its descendants.
- A detached `Container` is its own attachment root until attached under a parent.
- A subtree attach that would introduce any duplicate public `id` within one attachment root must fail atomically with no partial attachment.
- A rename or reparent that would introduce a duplicate sibling `name` must fail without moving the node or partially committing the mutation.

Trace note: clarified that `visible = false` changes rendering and direct-target participation, but does not detach the node from retained-tree geometry, transform, or descendant-state resolution while it remains attached.

Trace note: added the degenerate-clip case explicitly so implementation plans do not diverge between "no-op clip" and "empty clip region" behavior.

#### 6.1.2 Drawable

**Purpose and contract**

`Drawable` is the first render-capable primitive. It extends `Container` with presentation, content box calculation, and render-effect participation. `Drawable` owns no control-specific behavior by itself.

`Drawable` must:

- define a content box inside its padding
- participate in the theming and skinning contract
- participate in inherited render effects
- provide isolation hooks when required by the render pipeline

**Anatomy**

- `root`: the drawable node. Required.
- `content box`: the inner rectangle after padding. Required.
- `skin`: the presentational surface resolved from tokens and skin assets. Optional.
- `effects`: local render effects applied before descendant composition. Optional.

**Props and API surface**

- `padding`
- `paddingTop`, `paddingRight`, `paddingBottom`, `paddingLeft`
- `margin`
- `marginTop`, `marginRight`, `marginBottom`, `marginLeft`
- `alignX: "start" | "center" | "end" | "stretch"`
- `alignY: "start" | "center" | "end" | "stretch"`
- `skin`
- `shader`
- `opacity: number`
- `blendMode`
- `mask`

`padding` uses `SideQuad input`.

`margin` uses `SideQuad input`.

`paddingTop`, `paddingRight`, `paddingBottom`, `paddingLeft` are flat overrides
for the corresponding `padding` members.

`marginTop`, `marginRight`, `marginBottom`, `marginLeft` are flat overrides for
the corresponding `margin` members.

The authoritative behavioral semantics for `Drawable.padding`,
`Drawable.padding*`, `Drawable.margin`, `Drawable.margin*`, `Drawable.alignX`,
and `Drawable.alignY` are defined in
[UI Layout Specification](./ui-layout-spec.md).

**State model**

STATE render_clean

  ENTRY:
    1. Skin, padding, content alignment, and effect chain are resolved.

  TRANSITIONS:
    ON token change:
      1. Re-resolve presentational inputs.
      → render_dirty

    ON local effect change:
      1. Re-resolve effect chain.
      2. Re-evaluate isolation requirement.
      → render_dirty

STATE render_dirty

  ENTRY:
    1. Presentation or effect data is stale.

  TRANSITIONS:
    ON next draw preparation:
      1. Resolve inherited effect chain.
      2. Resolve local skin assets.
      3. Resolve whether inline drawing is valid.
      4. Resolve whether isolation is required.
      → render_clean

**Accessibility contract**

`Drawable` inherits the accessibility contract of `Container`. It provides the presentational surface through which visual accessibility cues such as focus indicators may be rendered. `Drawable` does not impose additional accessibility requirements beyond those defined by components that extend it.

**Composition rules**

`Drawable` may contain child nodes. Descendants render within the `Drawable`'s content box unless explicitly positioned outside it through transform or anchor. An effect chain applied to a `Drawable` propagates to its descendants according to the rules in Section 7.4. A `Drawable` that requires isolation draws itself and its descendants into an offscreen target before compositing into the parent context. Nested `Drawable` instances each resolve their own effect chain relative to their parent's resolved chain.

**Behavioral edge cases**

- A `Drawable` with no skin must render nothing for its background and must not fail.
- A `Drawable` with `opacity = 0` remains in the tree and retains hit-test participation unless additionally marked non-interactive.
- A `Drawable` with a missing or invalid shader must fail deterministically.
- A `Drawable` with a mask that references a missing asset must fail deterministically.

#### 6.1.3 Shape

**Purpose and contract**

`Shape` is a render-capable geometric primitive. It extends `Container` with a
fill-rendered silhouette and silhouette-aware point containment. `Shape` is
parallel to `Drawable`, not a subtype of it.

`Shape` must:

- render a geometric silhouette in its own local bounds
- participate in retained-tree targeting through the same `containsPoint`
  vocabulary used by other interactive nodes
- evaluate containment in inverse-transformed local space
- remain narrow enough that its public surface is geometry and fill only in
  this revision

`Shape` must not:

- inherit the `Drawable` content-box, spacing, internal alignment, styling, or
  render-effect contract
- expose stroke, border, shadow, skin, shader, mask, blend-mode, or
  shape-aware clipping semantics in this revision
- permit consumer child composition in this revision

**Anatomy**

- `root`: the shape node. Required.
- `silhouette`: the local-space geometric region used for fill rendering and
  point containment. Required.

**Props and API surface**

- `fillColor`
- `fillOpacity: number`
- `containsPoint(x, y) -> boolean`
- `_contains_local_point(local_x, local_y) -> boolean`

Approved concrete classes in this revision:

- `RectShape`
- `CircleShape`
- `TriangleShape`
- `DiamondShape`

Default values:

- `fillOpacity = 1`

Public surface exclusions in this revision:

- no `padding`, `padding*`, `margin`, `margin*`, `alignX`, or `alignY`
- no `skin`, `shader`, `opacity`, `blendMode`, or `mask`
- no `background*`, `border*`, `cornerRadius*`, or `shadow*`
- no `strokeColor`, `strokeOpacity`, or `strokeWidth`

**State model**

STATE shape_clean

  ENTRY:
    1. Fill inputs and local geometry are current.
    2. The shape's containment silhouette is current for the resolved bounds.

  TRANSITIONS:
    ON bounds, transform, or fill-input change:
      1. Mark local geometry or draw inputs stale as required.
      2. Reuse the ordinary `Container` dirty path for transform and bounds.
      → shape_dirty

STATE shape_dirty

  ENTRY:
    1. Fill or local-geometry data is stale.

  TRANSITIONS:
    ON next draw preparation or containment evaluation:
      1. Resolve local geometry from the current bounds.
      2. Resolve effective fill inputs.
      → shape_clean

**Containment contract**

`Shape` uses the existing public containment method name:

- `containsPoint(x, y)`

`containsPoint(x, y)` accepts a world-space point. `Shape` must inverse-transform
that point into the node's local space before evaluating the silhouette.

The stable rule in this revision is:

- inverse-transform first
- local geometry test second

`Shape` exposes the protected hook:

- `_contains_local_point(local_x, local_y)`

The base `Shape` behavior is rectangular containment against the node's local
bounds. `RectShape` inherits that rectangular fallback unchanged.

Concrete local-space geometry rules:

- `RectShape` uses the full local bounds rectangle.
- `CircleShape` uses the ellipse inscribed in the local bounds rectangle. When
  `width == height`, the silhouette is a true circle; otherwise it is an
  ellipse by explicit contract.
- `TriangleShape` uses an upright isosceles triangle inscribed in local bounds
  with vertices at top-center, bottom-right, and bottom-left.
- `DiamondShape` uses the four edge midpoints of local bounds: top-center,
  right-center, bottom-center, and left-center.

Rotation, scale, skew, and pivot-driven transforms affect hit testing only
through the inverse-transform step. The spec does not define world-space
polygon hit testing as a separate path.

**Accessibility contract**

`Shape` inherits the accessibility contract of `Container`. It may participate
in direct target resolution when interactive and enabled, but it does not add a
separate accessibility naming contract in this revision.

**Composition rules**

`Shape` derives from `Container` for retained-tree membership, transforms,
visibility, event ancestry, focus ancestry, clipping ancestry, and sibling
z-order. Its layout footprint remains rectangular and matches its resolved
local bounds, regardless of the visible silhouette.

Even though `Shape` derives from `Container`, `Shape` is leaf-only in this
revision. Attempting to attach consumer child nodes to a `Shape` is invalid
configuration and must fail deterministically.

When `clipChildren = true` is inherited from `Container`, descendant clipping
remains rectangular and bounds-based. It does not follow the visible triangle,
diamond, or ellipse silhouette.

**Behavioral edge cases**

- A `Shape` with a zero-area bounds box remains valid but may render no visible
  pixels and may expose no hittable silhouette.
- A `Shape` with `fillOpacity = 0` remains in the tree and retains hit-test
  participation unless additionally marked non-interactive.
- A `Shape` with non-rect geometry still occupies its full rectangular layout
  footprint; transparent corners do not reduce layout size.
- A `Shape` with `clipChildren = true` clips descendants to rectangular bounds,
  not to the visible silhouette; authors must not rely on `Shape` as a
  silhouette clip in this revision.
- The drawn silhouette and the hit silhouette must match for each concrete
  shape class in the same resolved local geometry.

### 6.2 Layout Family

Layout behavior is defined in [UI Layout Specification](./ui-layout-spec.md).

This revision standardizes these layout-family components:

- `Stack`
- `Row`
- `Column`
- `Flow`
- `SafeAreaContainer`

That document is authoritative for:

- layout-family common props
- layout-family common state model
- child measurement and placement rules
- `gap`, `padding`, and child `margin` behavior under layout parents
- negative-margin overlap behavior in layouts
- `SafeAreaContainer` safe-area-aware placement behavior

### 6.3 Scroll Primitive

#### 6.3.1 ScrollableContainer

**Purpose and contract**

`ScrollableContainer` is a structural primitive that clips descendant content and exposes scroll state. It is not a layout family peer of `Row` or `Column`, though it may host layout containers as descendants.

`ScrollableContainer` must:

- own a viewport rectangle
- own content extent measurement
- own scroll offsets
- clip descendant drawing and hit testing to the viewport
- capture and interpret scroll input
- support touch, wheel, keyboard, and programmatic scrolling
- support configurable direct drag and configurable momentum behavior

**Anatomy**

- `root`: the scroll node. Required.
- `viewport`: the visible region. Required.
- `content`: the scrollable child subtree. Required.
- `scrollbars`: optional visual indicators and drag handles.

Trace note: the required `content` subtree is part of the public structure, but this revision does not standardize one consumer-facing attachment method surface such as `addContent(...)` or `getContentContainer()`.

**Props and API surface**

- `scrollXEnabled: boolean`
- `scrollYEnabled: boolean`
- `momentum: boolean`
- `momentumDecay: number`
- `overscroll: boolean`
- `scrollStep: number`
- `showScrollbars: boolean`

Trace note: these props standardize scroll behavior categories, not one exact inertial curve, damping formula, stop threshold, overscroll spring model, or scrollbar geometry policy. Those mechanics remain internal unless later documented.

**State model**

STATE idle

  ENTRY:
    1. Scroll offset is stable.
    2. No active gesture owns the container.

  TRANSITIONS:
    ON pointer drag start within viewport:
      1. Capture scroll gesture.
      2. Record initial pointer position and current offset.
      → dragging

    ON wheel input:
      1. Adjust scroll offset by configured step.
      2. Clamp or overscroll according to policy.
      → idle

    ON keyboard scroll command while focused:
      1. Adjust scroll offset by configured step or page amount.
      2. Clamp or overscroll according to policy.
      → idle

Trace note: `keyboard scroll command` is a behavioral contract, not a commitment to one key-mapping table or to `Navigate` as the public scroll entry point. Implementations may translate host keys internally so long as the resulting behavior follows the `Scroll` contract.

STATE dragging

  ENTRY:
    1. Active pointer owns the scroll gesture.

  TRANSITIONS:
    ON pointer move:
      1. Update offset from pointer delta.
      2. Update velocity estimate when momentum is enabled.
      → dragging

    ON pointer release with momentum disabled:
      1. Clamp final offset.
      → idle

    ON pointer release with momentum enabled:
      1. Seed inertial velocity from the recorded velocity estimate.
      → inertial

STATE inertial

  ENTRY:
    1. Offset advances each frame from the retained velocity.

  TRANSITIONS:
    ON frame update:
      1. Integrate velocity into offset.
      2. Apply configured decay to velocity.
      3. Clamp or resolve overscroll return.
      4. When velocity falls to the stop threshold, transition to idle.
      → idle

**Accessibility contract**

When focused, `ScrollableContainer` must respond to keyboard scroll commands as defined in the state model. Scrollbar parts, when present, must be non-focusable decorations. The consumer is responsible for configuring any semantic region labels for the scrollable content area.

**Composition rules**

`ScrollableContainer` must contain exactly one content child subtree. Additional children outside the content slot are unsupported. `ScrollableContainer` may be nested; each nested instance manages its own offset, gesture capture, and clipping independently. A nested scroll container must not propagate scroll events to its ancestor when the inner container still has remaining scroll range in the requested direction.

Trace note: clarified that the content subtree is structurally required while the consumer-facing mechanics used to populate it remain unspecified at the foundation level. This keeps the component reusable by controls such as `TextArea` without freezing helper method names as public API.

**Behavioral edge cases**

- When content extent is less than or equal to the viewport size along a given axis, scrolling on that axis must be suppressed regardless of `scrollXEnabled` or `scrollYEnabled`.
- When `overscroll = false`, scroll offset must be clamped to the valid range at all times.
- When `momentum = false`, releasing a drag immediately clamps the offset without entering the inertial state.
- An empty content subtree results in zero content extent. The container must remain valid and not enter any scroll state.
- When both `scrollXEnabled = false` and `scrollYEnabled = false`, the container must not respond to any scroll input.

### 6.4 Runtime Family

#### 6.4.1 Stage

**Purpose and contract**

`Stage` is the runtime root for the UI tree. It owns viewport bounds, safe area bounds, root-level event dispatch entry, and root-level environment synchronization.

`Stage` must:

- reflect current viewport dimensions at all times
- expose full viewport bounds as a queryable rectangle
- expose safe area bounds as a queryable rectangle
- provide an update traversal entry point that drives one update pass over the retained tree
- provide a draw traversal entry point that drives one draw pass over the retained tree
- provide the root input delivery entry point; translate all delivered raw input into logical intents before dispatching; no component beneath `Stage` may receive raw input directly
- provide the root focus scope
- propagate viewport resize to the full tree

**Anatomy**

- `root`: the stage node. Required.
- `base scene layer`: the layer hosting the active scene. Required.
- `overlay layer`: the layer above the base scene, used for modal and overlay rendering. Required.

**Props and API surface**

- `width: number`
- `height: number`
- `safeAreaInsets: { top, bottom, left, right }`

`safeAreaInsets` uses `SideQuad input`.

Trace note: `safeAreaInsets` and safe-area bounds are both part of the Stage environment surface. Exposing only raw insets without a queryable bounds view is insufficient for full Stage compliance.

**State model**

STATE synchronized

  ENTRY:
    1. Viewport dimensions match the environment-reported window size.
    2. Safe area insets reflect the current environment-reported values.

  TRANSITIONS:
    ON viewport resize:
      1. Update width and height to new dimensions.
      2. Update safe area insets if they changed.
      3. Mark the full tree dirty for layout resolution.
      → synchronized

    ON update traversal entry invoked:
      1. Traverse the retained tree in tree order.
      2. Resolve dirty geometry, layout, and world transforms for each dirty node.
      3. Process any queued state changes.
      4. The tree is internally consistent when this traversal completes.
      → synchronized

    ON draw traversal entry invoked:
      1. Traverse visible retained nodes in tree order.
      2. Issue draw commands for each visible node.
      3. No state resolution occurs during this traversal.
      → synchronized

    ON raw input delivered:
      1. Translate the raw input to the corresponding logical intent.
      2. Resolve the target path from Stage to the deepest eligible hit-test result.
      3. Dispatch the logical event through the propagation system.
      → synchronized

Trace note: all raw host input enters through this Stage-owned boundary. Implementation phases may stage downstream mechanics, but they must not create a second raw-input intake path beneath Stage.

ERRORS:
  - Attempting to assign a parent to `Stage` → invalid configuration and deterministic failure.
  - Creating more than one `Stage` instance → invalid configuration and deterministic failure.

**Accessibility contract**

`Stage` is the root of the application's accessible component tree. It does not carry a semantic role itself. It provides the root focus scope for all traversal. The consumer is responsible for any application-level accessibility metadata outside the component tree.

**Composition rules**

`Stage` contains exactly two logical layers: the base scene layer and the overlay layer. The overlay layer always renders above the base scene layer. Event resolution must check the overlay layer before the base scene layer. `Stage` must have no parent. Exactly one `Stage` must exist per application runtime.

**Behavioral edge cases**

- `Stage` must remain valid when no active scene is present. It renders nothing in this state.
- When the overlay layer is empty, event resolution falls through to the base scene layer without additional cost.

#### 6.4.2 Scene

**Purpose and contract**

`Scene` is a runtime primitive representing a screen-level subtree with lifecycle hooks. It provides the boundary at which the consumer controls creation, activation, deactivation, and destruction of a screen's content tree.

`Scene` must:

- own a full-screen or stage-sized subtree by default
- expose creation, enter, leave, and destruction lifecycle hooks
- integrate with `Composer`
- receive active-scene logical input routed through the `Stage`/`Composer` runtime boundary and dispatch it into its subtree

Trace note: clarified that `Scene` participates in routed logical input only after `Stage` owns raw input intake. This avoids implying a second raw-input boundary or a scene-local input entry point.

**Anatomy**

- `root`: the scene subtree root. Required.
- `content`: consumer-provided child subtree. Optional.

**Props and API surface**

- `params: table | nil`

Trace note: `Scene` public lifecycle surface is limited to creation, enter-before, enter-after, leave-before, leave-after, and destruction. No additional public in-transition `"running"` phase is standardized in this revision.

**State model**

STATE inactive

  ENTRY:
    1. The scene subtree exists but is not the active scene.
    2. The scene receives no input events.

  TRANSITIONS:
    ON activation by `Composer`:
      1. Fire the enter-before lifecycle hook.
      2. Become the current active scene.
      3. Fire the enter-after lifecycle hook.
      → active

STATE active

  ENTRY:
    1. The scene is the current active scene.
    2. Input events are forwarded to this scene's subtree.

  TRANSITIONS:
    ON deactivation by `Composer`:
      1. Fire the leave-before lifecycle hook.
      2. Yield active scene status.
      3. Fire the leave-after lifecycle hook.
      → inactive

**Accessibility contract**

`Scene` is a structural runtime container. It does not impose accessibility requirements beyond those of its content. When a scene becomes active, its focusable descendants become eligible for traversal within the base scene focus scope.

**Composition rules**

`Scene` must be registered with and managed by `Composer`. A `Scene` must not manage other scenes directly. `Scene` may contain any layout or control components as descendants. Consumer lifecycle hooks must not invoke `Composer` navigation during the enter or leave phases of the same transition.

Trace note: activation and deactivation are owned by `Composer`. Scene-local visibility helpers may exist internally, but they are not a parallel public activation contract.

**Behavioral edge cases**

- A `Scene` with no content must remain valid and render nothing.
- If a consumer-supplied lifecycle hook produces an error, `Composer` must handle it deterministically rather than leaving the tree in an indeterminate activation state.

#### 6.4.3 Composer

**Purpose and contract**

`Composer` owns scene registration, scene caching, scene transition sequencing, and scene activation.

`Composer` must:

- register scenes by stable name
- activate one scene at a time in the base scene layer
- expose and manage the active overlay layer above the base scene layer
- support transitions
- support deterministic scene lifecycle sequencing
- forward root input into the active runtime subtree

**Anatomy**

- `root`: the composer runtime. Required.
- `stage`: the owned `Stage` node. Required.
- `scene registry`: the named scene store. Required.
- `transition state`: active transition context. Optional, present only during transitioning.

**Props and API surface**

- `defaultTransition`
- `defaultTransitionDuration`

Trace note: these properties stabilize transition configuration concepts only. Built-in transition catalogs, helper modules, callback signatures, and canvas-composition mechanics remain internal unless separately documented.

**State model**

STATE stable

  ENTRY:
    1. Exactly one scene is active in the base scene layer.
    2. No transition is running.

  TRANSITIONS:
    ON gotoScene(target):
      1. Resolve or create the target scene.
      2. Fire the current scene leave-before hook if a current scene exists.
      3. Fire the target scene enter-before hook.
      4. If transition is disabled, commit immediately.
      5. If transition is enabled, initialize transition state.
      → transitioning or stable

STATE transitioning

  ENTRY:
    1. Outgoing and incoming scenes are both known.
    2. Transition clock is initialized.

  TRANSITIONS:
    ON frame update before completion:
      1. Advance transition clock.
      2. Update transition progress.
      3. Draw outgoing and incoming scenes through transition composition.
      → transitioning

    ON transition completion:
      1. Fire the outgoing scene leave-after hook.
      2. Remove the outgoing scene from the active layer.
      3. Fire the incoming scene enter-after hook.
      4. Set the incoming scene as current.
      5. Clear transition state.
      → stable

    ON new navigation request during transition:
      1. Cancel the active visual transition.
      2. Commit the current incoming scene as the stable current scene.
      3. Clear transition state.
      4. Process the new navigation request from the resulting stable state.
      → transitioning or stable

ERRORS:
  - Unknown scene name → deterministic failure.

**Accessibility contract**

`Composer` does not carry semantic accessibility meaning. When a scene transition completes, the incoming scene's focusable descendants become available for traversal. `Composer` must not leave focus in an indeterminate state after any transition.

**Composition rules**

`Composer` owns one `Stage` and must not share stage ownership with other `Composer` instances. Scene activation is exclusively managed through the defined navigation interface. Consumer code must not directly manipulate the scene tree during an active transition.

Trace note: overlay-layer ownership is part of the runtime contract, but this revision does not standardize a separate public overlay-scene API beyond the documented `Composer` responsibilities.

Trace note: overlay mounting, stacking registries, helper methods such as `showOverlay(...)` or `hideOverlay(...)`, and any overlay z-order allocation policy remain internal unless a later revision documents them explicitly.

**Behavioral edge cases**

- When `gotoScene` is called with the currently active scene name, `Composer` must treat it as a full navigation request with complete lifecycle hook execution, not as a no-op.
- When `gotoScene` is called before any scene has been activated, no outgoing scene exists and no leave hooks fire.
- A transition interrupted by a second navigation request must complete the leave lifecycle for the outgoing scene and the enter lifecycle for the final incoming scene. No intermediate scene should execute enter or leave hooks.

## 7. Composition And Interaction Patterns

### 7.1 Event Propagation

`Stage` is the dispatch root for all input. Raw input delivered to `Stage` is translated to a logical intent and dispatched as an event through the propagation system described in this section. No event enters the propagation tree except through `Stage`.

The library must implement three ordered propagation phases:

1. capture
2. target
3. bubble

Each dispatched input event must resolve a target path from `Stage` to the deepest eligible target.

Backdrop-based blocking for overlays must work through normal propagation semantics.

The active overlay layer must be considered before ordinary scene content during target resolution.

This revision standardizes propagation phases, event names, and payload contracts, but it does not standardize one listener-registration method surface. Implementations may provide listener helpers, yet undocumented method names, storage models, and registration helpers remain internal.

Trace note: added the listener-surface boundary so Phase 4 implementations can route events without turning provisional helper methods into stable API.

#### 7.1.1 Event object contract

Every dispatched event must expose at least:

- `type`
- `phase`
- `target`
- `currentTarget`
- `path`
- `timestamp`
- `defaultPrevented`
- `propagationStopped`
- `immediatePropagationStopped`
- `pointerType` when the source is pointer-derived
- `x`, `y` in stage space when the source is spatial
- `localX`, `localY` relative to the `currentTarget` when the source is spatial

The event object must provide:

- `stopPropagation()`
- `stopImmediatePropagation()`
- `preventDefault()`

#### 7.1.2 Target resolution rules

Target resolution must occur in this order:

1. active overlay layer, from highest eligible sibling-local z-order to lowest
2. active base scene layer, from highest eligible sibling-local z-order to lowest
3. within any sibling set, reverse draw order among hit-test-eligible descendants

For spatial events, hit-test eligibility is determined from effective participation, not raw local flags alone. Eligibility must account for effective visibility, enabled participation, ancestor clipping, and the current layer precedence rules before a node may become the resolved target.

If a spatial event resolves no eligible target in either active layer, no propagation path is built and no propagation occurs for that event.

Trace note: added explicit effective-targeting and no-target behavior because Phase 4 planning showed that local-flag-only hit testing leaves clipping and visibility semantics underdefined at dispatch time.

#### 7.1.3 Default actions

For a component with a defined default action:

1. capture listeners fire
2. target listeners fire
3. bubble listeners fire
4. if `defaultPrevented = false`, the component default action executes

#### 7.1.4 Anchored overlay placement

When a component contract defines an anchored overlay surface, placement must resolve in two ordered stages:

1. attempt the consumer-declared preferred placement
2. apply fallback placement resolution when the preferred placement would place required overlay content outside the effective visible region

The effective visible region for anchored-overlay placement is the intersection of:

- the current viewport bounds
- the current safe area when the owning component contract enables safe-area-aware placement
- any ancestor clipping region that the anchored overlay is documented to respect

Fallback placement resolution must:

- preserve visual association with the owning anchor region
- choose a placement that maximizes visible overlay area within the effective visible region
- prefer same-axis alternatives before cross-axis alternatives when multiple fallback candidates are equally valid
- allow the final resolved placement to differ from the preferred placement without treating that difference as an error

If no placement allows the overlay to fit fully, the implementation must choose the placement that yields the greatest visible area and the least clipping within the effective visible region.

This section standardizes placement behavior, not one generic public positioning object schema. Concrete props such as `placement`, `align`, `offset`, or fallback-candidate lists remain the responsibility of the owning component contract.

Trace note: anchored overlay placement is standardized here so controls such as `Tooltip` and other anchor-bound popup surfaces can share one fallback-fitting rule without freezing a generic overlay manager or geometry helper API.

### 7.2 Focus

The library must maintain a logical focus model independent of pointer hover.

Focus traversal must support:

- explicit focus request
- next and previous traversal
- directional traversal where the component family defines it
- focus restoration when modals close

#### 7.2.1 Focus scopes

`Stage` defines the root focus scope.

A component or runtime primitive may define a nested focus scope when it needs bounded traversal, including:

- `Modal`
- `Alert`

Exactly one node may own logical focus within the active focus scope chain at a time.

This revision standardizes the existence and behavior of nested focus scopes, but it does not standardize one generic `Container` property or marker schema for declaring them. Scope participation is public only when a component or runtime contract names it explicitly.

Trace note: added the scope-marker boundary so Phase 5 implementation can support nested scopes without freezing `focusScope` as a generic foundation prop.

#### 7.2.2 Focus acquisition rules

Focus may be acquired by:

- explicit consumer request
- pointer activation when the component contract allows pointer-focus coupling
- sequential traversal commands
- directional traversal commands
- modal or alert opening rules

#### 7.2.3 Sequential traversal rules

Within a focus scope, the default sequential order must resolve by:

1. tree order among focusable descendants
2. sibling-local `zIndex` only when the component family explicitly binds focus order to visual order

If no component family overrides the rule, traversal must use depth-first pre-order tree order over focusable descendants.

#### 7.2.4 Directional traversal rules

Directional traversal is optional per component family, but when supported it must:

- evaluate candidate focusable nodes within the active focus scope
- prefer candidates in the requested direction
- break ties through nearest-distance stable ordering

#### 7.2.5 Focus and overlays

When an overlay with `trapFocus = true` becomes active:

1. record the previously focused node
2. move focus into the overlay according to overlay-specific rules
3. restrict traversal to the overlay scope

This overlay trapping rule defines behavior, not a generic trap contract for arbitrary foundation nodes. A general-purpose `Container` trap property is not standardized by this section.

Trace note: clarified that focus trapping is currently standardized through overlay behavior, preventing Phase 5 from generalizing `trapFocus` into a generic foundation prop by implication.

#### 7.2.6 Pointer and focus coupling

Pointer activation does not automatically imply focus for every component.

The component contract must define whether pointer activation:

- focuses before default action
- focuses after default action
- does not change focus

This revision standardizes pointer-focus coupling as component behavior, not as one generic foundation property schema. If an implementation uses metadata to encode the coupling policy, that metadata remains internal unless a component contract documents it.

Trace note: added the coupling-surface boundary so Phase 5 implementation can support pointer-driven focus changes without freezing `pointerFocusCoupling` as a generic `Container` prop.

### 7.3 Responsive Rules

Responsive behavior must be declarative.

`responsive` and inherited `breakpoints` are two public entry points into the same pre-measure responsive resolution step. `breakpoints` is the breakpoint-oriented shorthand inherited from `Container`; `responsive` is the layout-family-facing responsive surface. This revision standardizes responsive timing and dependency categories, but not one serialized rule schema shared by every implementation.

A node must not rely on implementation-specific breakpoint object shapes as stable public API. If a node supplies both `responsive` and `breakpoints`, the configuration is invalid and must fail deterministically rather than depend on undocumented precedence.

Trace note: added the relationship between `responsive` and `breakpoints` because Phase 3 planning exposed a real spec gap. The goal is to preserve both published entry points while preventing ambiguous dual-source configuration.

Responsive rules may depend on:

- viewport width
- viewport height
- orientation
- safe area
- parent dimensions

Responsive rules must resolve before measurement and layout for the affected subtree.

Percentage-based size resolution uses the effective parent content region for the relevant axis. When the parent region is itself derived from safe-area bounds or another delegated content box, percentages resolve against that effective region rather than against raw viewport size.

Trace note: clarified percentage resolution against the effective parent region so Phase 09 can complete responsive behavior for `SafeAreaContainer` and other delegated content regions without introducing a viewport-only exception.

This revision supports:

- fluid percentages
- min and max clamps
- declarative breakpoints

### 7.4 Render Effects And Shaders

Effects inherit from parent to child by default.

The effective effect chain must be resolved in tree order.

The renderer may draw inline when the full chain can be applied without violating the contract.

The renderer must isolate a subtree when required by:

- shader composition rules
- masking rules
- clipping rules that cannot be expressed inline
- opacity or blend behavior that requires offscreen composition

## 8. Visual Contract And Theming Contract

The theming contract is the stable interface between the library and the consumer's design system.

### 8.1 Visual Ownership Model

The library sits in the middle of the opinionated-to-headless axis, leaning opinionated for render-capable controls and leaning headless for structural and runtime primitives.

Tier-specific position:

| Tier or family | Position on the axis | Rationale |
|----------------|----------------------|-----------|
| Runtime utilities | near headless | `Stage`, `Scene`, and `Composer` own runtime structure and orchestration, not branded appearance |
| Structural and layout primitives | mostly headless | `Container`, layout primitives, and scroll ownership define composition and measurement; any appearance is optional and secondary |
| Render-capable primitives | shared middle | `Drawable` defines a stable render-skin mechanism and part model, while `Shape` defines a narrow fill-and-silhouette primitive outside the skinning system |
| Concrete controls | shared middle leaning opinionated | controls expose stable visual parts and default skins so behavior remains legible and cross-component consistency is preserved, but consumers may replace most decorative appearance through the defined override surface |

This position is not uniform across all components.

The library must remain in this range because:

- moving further toward fully headless would remove the stable part and token contract that allows controls to share one skinning system
- moving further toward fully opinionated would make design-system integration depend on undocumented internal rendering rather than on explicit public skin surfaces
- accessibility-significant visual affordances such as focus indicators, selection regions, and modal backdrop separation require a minimum stable visual structure even when appearance is customized

### 8.2 Visual Property Taxonomy

| Category | Ownership | Default source | Override mechanism | Stable API status |
|----------|-----------|----------------|--------------------|-------------------|
| Required named visual parts and part presence | library-owned | specification-defined component anatomy | none; only documented component revision can change this | stable and structural |
| Part-to-role mapping such as `backdrop`, `surface`, `trigger`, `panel`, `caret` | library-owned | specification-defined component contract | none | stable and structural |
| Color, typography, texture, atlas, quad, nine-slice, border, radius, opacity, blend, and shader inputs for named parts | shared overridable | token-resolved with library fallbacks when available | token substitution, part skin override, instance-level visual prop override where documented; border, radius, shadow, and color-backed visual property definitions are owned by [UI Styling Specification](./ui-styling-spec.md) | stable when the part and property are documented |
| Stateful skin variants for documented states | shared overridable | base skin plus variant-specific token or part-skin mapping | variant selection through stateful skin resolution and explicit variant overrides where documented | stable when the state and part are documented |
| Brand identity choices, custom art direction, and consumer-provided renderer behavior inside a documented extension slot | consumer-owned | none required from the library | consumer-provided tokens, assets, or custom renderer slot | stable only through the documented extension slot boundary |
| Internal draw-call decomposition, helper layers, batching strategy, and cache layout | library-owned implementation detail | implementation-defined | not overridable | not public API |

### 8.3 Customization Mechanism

This revision standardizes these visual customization mechanisms:

| Mechanism | Scope | Description | Stable API status |
|-----------|-------|-------------|-------------------|
| Token substitution | library-wide | the consumer provides token values for documented token keys used by component parts | stable |
| Part skin override | component-wide or instance-level | the consumer supplies an explicit skin description for a named component part | stable |
| Instance-level visual prop override | instance-level | the consumer passes a documented visual prop directly on a component instance; the styling property contract for these visual props is defined in [UI Styling Specification](./ui-styling-spec.md) | stable only for documented props |
| Variant selection | component-wide or instance-level depending on the component contract | the component resolves a named or state-derived skin variant for its parts | stable when the variant contract is documented |
| Custom renderer extension slot | part-level | the consumer replaces the render implementation of a documented part while leaving structure and behavior intact | stable only where a documented part exposes this slot |

Precedence order, from highest to lowest:

1. explicit instance-level visual prop override
2. explicit part skin override for the targeted part
3. active stateful or named variant mapping for the targeted part
4. active theme token override
5. library default token or library fallback skin input

The custom renderer extension slot replaces the ordinary render mode for its target part after part resolution but before node-level inherited effects, opacity, masking, and blend behavior are applied.

### 8.4 Token Model

This revision standardizes:

- scalar tokens: spacing, radii, border widths, timing values
- color tokens
- font tokens
- texture references
- atlas references
- quad references
- nine-slice definitions
- shader references
- stateful variants per component state

The visual property definitions for styling-relevant scalar tokens (radii, border widths) and color tokens are defined in [UI Styling Specification](./ui-styling-spec.md). This document standardizes the token model and resolution order; it does not redefine the meaning of those visual properties.

Token naming convention:

- global roles use `global.<token-class>.<role>`
- component-bound roles use `<component>.<part>.<property>`
- variant-specific roles append `.<variant>` to the component-bound token key

The naming schema is stable API. Individual token names become stable only when the component-part-property binding is documented by the library.

Token resolution order:

1. variant-specific instance override, if present
2. base instance override, if present
3. variant-specific part skin override, if present
4. base part skin override, if present
5. active theme token override
6. library default token

Required versus optional tokens:

- a token is required only when the component contract references it and the library defines no default fallback
- a token is optional when the component contract defines a library fallback token or fallback render input

Token-to-component binding is explicit. A component part resolves tokens only through documented part-property bindings; there is no implicit CSS-like selector or descendant-based token matching in this revision.

Library default tokens and fallback skin inputs need to cover only documented part-property bindings and documented fallback render inputs. Extra convenience aliases, authoring shorthands, or undocumented coverage tables may exist internally, but they are not public contract surface.

Trace note: clarified the boundary of library default token coverage so Phase 8 can ship broad internal fallback tables without implying that every convenience alias or undocumented binding is stable API.

### 8.5 Structure Vs. Appearance Boundary

Criteria:

- structure is anything required to preserve component identity, named part topology, composition validity, accessibility-significant region separation, or behaviorally significant hit/focus regions
- appearance is any render treatment that can change without changing the component's identity, structure, or validity

Per-family boundary:

| Family | Structural surface | Appearance surface | Internal visual structure status |
|--------|--------------------|--------------------|----------------------------------|
| Runtime utilities | layer ownership, root boundaries, overlay separation | none by default | internal helper nodes are implementation detail |
| Layout and structural primitives | child placement model, clip ownership, viewport ownership, content-box semantics | optional background, border, effect, and scrollbar decoration skins | internal helper layers are implementation detail |
| Render-capable primitives | named renderable part surfaces, content-box contract for `Drawable`, and silhouette contract for `Shape` | skin mode, tokens, textures, fonts, colors, border treatment, shader choice, and `Shape` fill inputs | internal draw order within a part is implementation detail unless a named part contract says otherwise |
| Concrete controls | required named parts, control-region separation, indicator/panel/surface roles, stable part names | all documented part skins, typography, decorative assets, and visual variants | internal wrapper hierarchy is implementation detail; consumers must not depend on undocumented helper parts |

### 8.6 Visual Inheritance Within Composition

Visual propagation rules:

- the inherited render-effect chain defined in Section 7.4 propagates from parent to child in tree order
- node-level opacity, blend mode, masking, and shader behavior propagate only through the inherited effect chain and may trigger isolation according to Section 8.14
- token values do not cascade by ordinary parent-child containment; components resolve visual inputs from the active theme and their own explicit overrides
- component part skins, border radii, textures, fonts, and state variants are isolated per component instance unless a component contract explicitly delegates appearance of a named slot to consumer content
- consumer content placed into a slot keeps its own visual resolution rules; the slot owner does not automatically recolor, re-font, or re-skin arbitrary descendants unless the component contract explicitly defines that part as a presentational surface owned by the root
- overlay subtrees inherit only from their own overlay ancestors and the active theme; they do not inherit visual effects from obscured base-scene ancestors

The consumer may interrupt visual propagation only through documented local effect overrides or by causing subtree isolation under the rules in Section 8.14. No general-purpose style reset node is standardized in this revision.

### 8.7 Token Classes

This revision standardizes these token classes:

- `color`
- `spacing`
- `radius`
- `border`
- `font`
- `timing`
- `texture`
- `atlas`
- `quad`
- `nineSlice`
- `shader`
- `opacity`
- `blendMode`

This list is exhaustive for this revision. Additional public token classes are not implied by focus-indicator styling, text-role aliases, renderer helpers, or other implementation conveniences unless a later revision documents them explicitly.

Trace note: added an explicit exhaustiveness statement because Phase 8 planning exposed pressure to invent new token families without amending the stable token-class contract.

### 8.8 Part-Level Skin Contract

Each skinnable component part may resolve one of these render modes:

- solid fill
- stroked shape
- texture draw
- quad draw
- nine-slice draw
- text draw
- shader-modified draw
- fully custom consumer renderer through a defined extension slot

The visual property contract for color-backed, gradient-backed, and image-backed fills, border rendering, corner radius, and shadow is defined in [UI Styling Specification](./ui-styling-spec.md).

### 8.9 Render Skin Resolution

The library must treat presentation as a resolved render skin rather than as ad hoc draw behavior embedded in each control.

A render skin may be composed from:

- scalar tokens
- color tokens
- textures
- atlas regions
- quads
- nine-slice definitions
- shaders
- opacity and blend settings
- state-dependent part visibility

Styling-family opacity properties (`backgroundOpacity`, `borderOpacity`, `shadowOpacity`) are defined in [UI Styling Specification](./ui-styling-spec.md). Node-level opacity and blend mode remain owned by this document.

Each render-capable component must expose named presentational parts that can be skinned independently.

### 8.10 Graphics Asset Interoperability Contract

This section defines the foundation-level interoperability contract for texture-backed rendering inputs. It does not own the concrete first-class graphics objects themselves; those are defined in [UI Graphics Specification](./ui-graphics-spec.md).

A texture-backed visual surface may reference:

- a full texture-backed image source
- an atlas-backed region reference
- a precomputed quad or region reference
- a nine-slice definition over either a full source or a region-backed source

The foundation contract in this section standardizes how these asset classes participate in rendering, token resolution, and failure semantics. It does not standardize one host-framework object model or one loading pipeline.

### 8.11 Nine-Slice Contract

The nine-slice rendering procedure is defined in [UI Graphics Specification](./ui-graphics-spec.md). This document references nine-slice as a recognized skin asset type and token input category. It does not redefine the nine-slice cell division model, stretch rules, inset contract, or corner scale-down behavior.

### 8.12 Stateful Variant Resolution

A component resolves its active skin variant by evaluating its current state flags in a defined priority order. Each component that exposes state-driven presentation must document the priority order of its states in its specification.

When multiple states are simultaneously active, the highest-priority state determines which variant skin is selected.

When no state-specific variant is defined for the currently active state, the component must fall back to the base variant skin.

When no base variant skin is defined, the component must apply any available default token values. If a required token is absent and no default exists, the component must fail deterministically.

### 8.13 Shader Contract

A shader applied at the node level executes over the node's rendered output, after the node draws and before its descendants draw, unless the composition requires isolation.

A shader applied at the part level executes only for that part's draw operation and does not affect sibling parts or descendants.

Shaders in the inherited effect chain compose in tree order. A node whose shader cannot compose inline with its ancestor chain must trigger isolation for its subtree.

A component must fail deterministically if a shader is invalid or if the shader requires rendering capabilities unavailable in the current context.

### 8.14 Isolation Rules

Isolation requires drawing a subtree to an offscreen target and compositing the result into the parent using the subtree root's opacity and blend mode.

Isolation is required when:

- a node applies opacity or a blend mode that would produce incorrect results if applied individually to each descendant during inline drawing
- a node applies a shader that requires the fully composited subtree as its input
- a node applies a mask whose correct appearance depends on the composited result of the entire subtree rather than the masked sum of individual draw calls

Isolation carries a performance cost and must not be applied speculatively when inline drawing satisfies the contract.

### 8.15 Performance Rules

The implementation should:

- prefer native image, quad, font, text object, canvas, shader, and batch draw primitives where contract-compliant
- avoid per-frame recomputation of skin geometry when inputs are unchanged
- cache part-level quads, nine-slice geometry, text measurement, and resolved render descriptions when safe

Batch draw primitives are an implementation optimization and are not part of the public component contract.

### 8.16 Missing Or Invalid Skin Inputs

If a token is absent, the component may fall back to a stable default token. If no default token exists, the component must fail deterministically.

If a skin asset or shader is invalid, the component must fail deterministically.

## 9. Deferred Items

- `Grid`
  Reason: omitted from this revision to keep the first layout standard narrow and invalidation-friendly. Grid semantics require a two-axis measurement model that is not yet standardized here.
