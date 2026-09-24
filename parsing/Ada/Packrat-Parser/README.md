# Ada 2023 Packrat Parser Implementation

---

## Project Overview

This repository provides a comprehensive Ada 2023 implementation of a Packrat Parser for Parsing Expression Grammars (PEGs). Packrat parsing employs a memoization technique over a standard recursive descent model to guarantee linear time parsing. The project fulfills all typical algorithm variants explored in academic literature, showcasing the performance/capability tradeoffs between naive parsing, standard memoization, and complex left-recursion handling implementations.

---

## Features

- **Parse\_Naive**: Standard top-down recursive descent algorithm. Exponential worst-case execution time, but structurally simple. It includes dynamic cycle detection to fail gracefully instead of causing stack overflows.
- **Parse\_Packrat**: The canonical linear-time Packrat parser. Achieves O(1) repeated sub-rule lookups via a dynamically sizing memoization table.
- **Parse\_Packrat\_Left\_Rec**: An advanced memoization variant supporting direct left-recursion. Implements a bounded seed-growth evaluation technique (similar to Warth et al.) ensuring that left-recursive PEG rules like `Expr -> Expr '+' | 'n'` do not trap the parser, matching natively in linear time.
- **Strong Type Definitions**: Implements clean subtype and variant boundaries without relying on primitive scalars for internal business logic.
- **Complete PEG Combinator Set**: Supports standard operations — `Literal`, `Any`, `Choice`, `Sequence`, `Zero_Or_More` (Greedy), and `Not_Predicate`.

---

## Building

**Prerequisites:**  
You need a recent GNAT toolchain (e.g., Alire or GNAT CE) supporting Ada 2022/2023 constructs, such as flexible array aggregates (`[...]`).

Execute the automated build using Make:

```bash
make
```

---

## Testing

The implementation includes a rigorous standalone test suite encompassing 13 detailed scenarios (39+ specific assertions).

Categories explicitly validated:

- **Functional Correctness**: Operator compliance across variants.
- **Edge Cases**: Empty input structures, partial consumptions, greedy iteration endpoints.
- **Error Handling**: Defending against structurally malformed grammars.
- **Invariants**: Cross-variant output comparisons verifying deterministic output uniformity for non-left-recursive contexts, and cycle-trap resistance during aggressive recursion tests.

To run the suite:

```bash
make test
```

**Expected Output:**  
You should see 39 assertions pass across 13 test suites successfully with **0 failed**. No execution errors or warnings will be triggered.
