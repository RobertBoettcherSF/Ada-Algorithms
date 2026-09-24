# Petrick's Method — Ada Implementation

---

## Project Overview

This project provides a robust, strongly-typed Ada 2023 implementation of [Petrick's method](https://en.wikipedia.org/wiki/Petrick%27s_method), an algorithmic technique for determining all minimum sum-of-products solutions from a prime implicant chart. The method works by expanding a Boolean Product-of-Sums (representing required chart coverage) into a simplified Sum-of-Products using Boolean algebra axioms (Idempotence and Absorption). This package safely applies the expansion using 64-bit integer bitmasks, ensuring high performance, memory safety, and complete absence of dynamic resizing issues during logical reductions.

---

## Features

- **Core Expansion (`Multiply_And_Simplify`):** Completely transforms and minimizes clauses to find every possible non-dominated combination of prime implicants that satisfy the Boolean chart.
- **Minimum Terms Selection (`Minimum_Terms`):** A variant that processes the generalized result to yield only the solutions requiring the fewest possible prime implicants.
- **Weighted Minimum Selection (`Minimum_Cost_Terms`):** A variant accepting a dynamically-sized `Cost_Map`, allowing users to prioritize specific subsets (e.g., those producing the fewest total literals) regardless of simple cardinality.
- **Safety Contexts:** Bounds checked to 64 prime implicants, cleanly rejecting empty configurations and gracefully trapping mapping errors.

---

## Usage

The `tests.adb` acts simultaneously as the comprehensive test suite and usage example showing how clauses are instantiated and multiplied.

To execute and view results:

```bash
make test
```

**Expected Output:**  
You will see exactly 13 logical test groupings execute sequentially across 39 checks. All checks will read `PASS`, terminating with a summary of `39 passed, 0 failed`.

---

## Testing

The embedded test suite uses functional assertion techniques validating:

- **Functional Correctness:** Distributive expansion, Wikipedia baseline proofs, Idempotence deduplication.
- **Edge Cases:** Subset &amp; Superset Absorption verifications, minimum term constraints bypassing cardinality for cost.
- **Error Handling:** Triggering and trapping `Empty_Chart_Error`, `Empty_Clause_Error`, and unmapped variables raising `Missing_Cost_Error`.

---

## Building

**Prerequisites:** GNAT Toolchain (GCC-based Ada Compiler).

**Standards:** Exploits specific syntactic simplifications built into Ada 2022/2023 (ISO/IEC 8652:2023), including initialized array aggregates. The provided Makefile injects the necessary compiler flags (`-gnatwa -gnat2022`) automatically.
