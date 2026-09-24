# Ada 2023 Rete Algorithm Implementation

This project provides a robust, strongly typed, memory-safe, and fully compilable implementation of the classic Rete Algorithm in Ada 2023. Rete is an efficient pattern matching algorithm for implementing production rule systems. It avoids iterating over all rules by organizing conditions into a network of nodes: Alpha Nodes for static filtering of Working Memory Elements (WMEs), and Beta Nodes for cross-referencing variable bindings between multiple conditions.

## Features
* **Static Configuration**: Build rule topologies safely by chaining Alpha and Beta Nodes.
* **Variant 1 — Incremental Right/Left Activation**: Native Rete insertion logic efficiently percolates single WME updates downwards without re-evaluating the entire working memory.
* **Variant 2 — Batched Processing**: An array-oriented insertion path for bulk Working Memory loading.
* **Variant 3 — State-Sweep Retraction**: An integrated robust variant of retraction that guarantees network consistency by sweeping affected tokens out of Beta memories, avoiding dangling pointers while maintaining deterministic behavior.
* **Bounded Memory Safety**: Relies entirely on statically bounded arrays and records—no unchecked deallocation or garbage collection overhead required.

## Building and Usage
This project requires GNAT with Ada 2022/2023 support (ISO/IEC 8652:2023).

To build and run tests:
1. Run `make test`

The test suite acts as the primary demonstration driver, explicitly exercising network topologies, valid insertions, cascading removals, exceptions, and overall rule matching consistency.

Expected Output:
```
Running tests...
TEST 1 — Symbol Handling
  PASS — 1.1 To_String equality
  PASS — 1.2 Symbol equality operator
  PASS — 1.3 Empty symbol consistency
...
===  39 passed,  0 failed ===
```

## Testing Framework
The suite runs 13 rigorous integration tests spanning functional validation and fault safety:
* **Correctness & Connectivity**: Verifies Alpha/Beta ID assignments, tree structures, and 0-Condition (Cross) Joins versus N-Condition Joins.
* **Propagation Integrity**: Exercises deep Left and Right token activations, proving the core Rete engine matching logic handles arbitrary fact insertion orders correctly.
* **Data Faulting**: Catches exceptions proactively via custom `Duplicate_ID` and `Fact_Not_Found` constraints.
* **State Consistency**: Validates that Variant 3 State-Sweep accurately tears down partial tokens from deeply nested Beta chains when a constituent WME is retracted.
