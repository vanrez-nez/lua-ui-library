# Lens 08 — Failure Semantics

> **Core question:** What does the library do when it is used incorrectly or receives conditions it cannot handle?

---

## Purpose

The Failure Semantics lens defines the **library's behavior in response to misuse, invalid input, and out-of-scope conditions**. It is exclusively concerned with failure — not with edge cases during correct usage (that is Behavioral Completeness) and not with API evolution (that is Contract Stability).

This lens answers a question most specs never ask: *what is the contract when the contract is violated?*

---

## Strict Scope

This lens owns:

- Invalid usage detection: whether the library detects misuse and at what point
- The failure response taxonomy: the complete set of ways the library responds to failures
- Failure response assignment: which failure mode applies to which class of invalid usage
- Consumer-observable failure signals: what the library communicates to the consumer when it detects misuse
- Usage of deprecated APIs: how the library behaves at runtime when a deprecated interface is exercised
- Graceful degradation contract: what the library guarantees it will preserve when it cannot fulfill its full contract

This lens does **not** own:

- Edge cases that occur during correct usage (empty content, overflow, rapid input) → **Behavioral Completeness**
- API removal schedule or deprecation windows → **Contract Stability**
- What valid API surface exists → any other lens
- How the library evolves over time → **Contract Stability**

---

## Required Spec Sections

### 8.1 Failure Response Taxonomy

Define every mode in which the library responds to a failure condition. The taxonomy must be exhaustive — every failure the library can detect must produce a response from exactly one of these modes.

| Mode | Definition |
|------|-----------|
| **Hard failure** | The library throws an unrecoverable error. Execution stops. The consumer must handle the exception. |
| **Soft failure with signal** | The library detects invalid usage, emits a diagnostic (warning, log, dev-mode assertion), and continues with defined fallback behavior. |
| **Silent fallback** | The library detects invalid usage and substitutes a defined fallback behavior without emitting any signal. |
| **Passthrough** | The library does not detect or intercept the condition; the behavior is determined by the underlying platform or runtime. |
| **Undefined** | The library makes no claim about behavior for this condition. Explicitly documented as undefined. |

The spec must declare which failure mode applies to which class of invalid input, not leave it to discovery.

### 8.2 Invalid Usage Classification

Define the categories of invalid usage the library recognizes.

**Category A — Structural invalidity**: The consumer creates a composition that violates the Composition Grammar.
- Example: placing a sub-part component outside its required parent
- The spec must declare: is this detectable at author time, at initialization time, or only at runtime?

**Category B — Type or value invalidity**: The consumer passes a value of the wrong type or an out-of-range value to a component property.
- Example: passing a negative value to a property that requires a positive integer
- The spec must declare: which properties are validated, what the validation rules are, and what the failure mode is per-property or per-category

**Category C — State contract violation**: The consumer violates the State Model — for example, switching a component from controlled to uncontrolled mode after initialization.
- The spec must declare each documented state contract violation and its failure mode

**Category D — Lifecycle violation**: The consumer interacts with a component outside of its valid lifecycle phase — for example, calling an imperative method on a component that has been destroyed.
- The spec must declare what the library does for each class of lifecycle violation

**Category E — Composition boundary violation**: The consumer uses the library in a way that violates declared composition rules — for example, rendering a component outside of any valid parent when one is required.
- The spec must declare whether this is detectable and what the failure response is

**Category F — Out-of-scope usage**: The consumer uses the library for a purpose explicitly declared out of scope in the Contract Stability lens.
- The spec must declare the library's policy: does it attempt to detect out-of-scope usage, or does it make no guarantee and disclaim all responsibility?

### 8.3 Diagnostic Signal Contract

For failure modes that emit a diagnostic signal (Soft Failure with Signal), define the signal contract:

- **Signal type**: warning, error-level log, dev-mode assertion, or other — each must be defined
- **Signal timing**: when in the lifecycle does the signal fire? (initialization, first render, on interaction, immediately on invalid input)
- **Signal content contract**: what information does the signal contain? Is the message text stable API or implementation detail?
- **Signal environment**: does the library emit signals in all environments, or only in development/debug modes? If conditional, define the condition precisely
- **Signal suppression**: can the consumer suppress or redirect signals? If so, through what mechanism, and is that mechanism stable API?

### 8.4 Fallback Behavior Contract

For every failure mode that includes a fallback (Soft Failure with Signal, Silent Fallback), the fallback behavior itself is part of the contract.

For each class of invalid usage with a defined fallback, the spec must declare:

- What the fallback behavior is (specifically, not "best effort")
- Whether the fallback behavior is stable API or subject to change
- Whether the fallback produces valid output that the consumer can rely on, or whether it is minimal/degraded output intended only to prevent a crash

The fallback is not a courtesy. It is a sub-contract. If the library commits to a fallback, consumers will depend on it.

### 8.5 Deprecated API Runtime Behavior

When a consumer calls a deprecated API at runtime:

- Does the library execute the deprecated behavior, a compatibility shim, or nothing?
- Does it emit a diagnostic signal? (cross-reference §8.3 for signal contract)
- Is the deprecated behavior guaranteed to be identical to its pre-deprecation behavior until removal?
- Are there any conditions under which a deprecated API may be removed before its declared removal version?

### 8.6 Undefined Behavior Declaration

Some inputs or usage patterns are not worth specifying — the cost of defining them is not worth the value. The library must explicitly declare these as undefined rather than leaving them as undocumented.

For each class of usage declared as undefined behavior:

- State the class of usage precisely
- Confirm that it is intentionally undefined (not accidentally unspecified)
- Declare whether future versions may define this behavior (making it no longer undefined)
- Confirm that the library makes no stability commitment about undefined behavior — it may change without version increment

This declaration protects the library from consumers who rely on incidental behavior of undefined cases.

### 8.7 Graceful Degradation Contract

Define what the library guarantees it will preserve when operating in a failure state.

The degradation contract is a minimum floor: regardless of what fails, the library commits to not violating these guarantees.

Example categories for the degradation contract:

- **No silent data loss**: if the library cannot render output correctly, it will not silently discard consumer-provided content
- **No uncaught exceptions in production mode**: hard failures are caught and converted to soft failures with signals in non-development environments
- **Composition partial validity**: if one component in a composition fails, the library defines whether the failure is isolated or propagates

The degradation contract must be specific and testable. Aspirational statements ("we try not to crash") are not part of this lens.

---

## What a Weak Failure Semantics Lens Looks Like

A spec has a weak Failure Semantics section if:

- Invalid usage is described only by "don't do this" without specifying what actually happens if the consumer does it anyway
- The failure response is described uniformly ("the library will warn you") without distinguishing hard failure from soft failure from undefined behavior
- Fallback behavior is described as "best effort" without committing to a specific fallback
- Deprecated API runtime behavior is undocumented, so consumers cannot determine whether calling deprecated code produces a warning, an error, or silent failure
- Undefined behavior is not explicitly declared — it is simply absent from the spec, making consumers unable to distinguish "undefined" from "not yet documented"

---

## Boundary Assertions

| Question | Belongs Here | Belongs Elsewhere |
|----------|-------------|-------------------|
| What happens if I place a `Tab` outside a `TabGroup`? | ✓ | |
| Is placing `Tab` outside `TabGroup` a valid composition? | | Composition Grammar |
| What happens if I pass a string where a number is expected? | ✓ | |
| What is the valid type for that property? | | per-component spec sections |
| What happens when I call a method on a destroyed component? | ✓ | |
| What happens during an ongoing interaction when the component is destroyed? | | Behavioral Completeness |
| What happens if I call a deprecated method? | ✓ | |
| When will that deprecated method be removed? | | Contract Stability |
