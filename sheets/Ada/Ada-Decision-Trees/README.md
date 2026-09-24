# Decision Tree Learning in Ada 2023

---

## Project Overview

This repository provides a strongly-typed, memory-safe Ada implementation of **Decision Tree Learning**. Decision trees are supervised learning models used for predictive modeling, deriving split routes based on feature impurities. This implementation covers both prominent feature split variants referenced mathematically in algorithmic literature: the **ID3-style Information Gain** mechanism leveraging Entropy, and the **CART-style** mechanism leveraging Gini Impurity.

---

## Features

- **Strictly Typed Architecture:** Features, labels, and matrices use strictly defined domain indices guaranteeing safe access limits.
- **Variant 1 (ID3 Style):** Entropy-based partitioning to maximize Information Gain across potential feature thresholds.
- **Variant 2 (CART Style):** Partitioning explicitly evaluating Gini Impurity to construct continuous splitting mechanics.
- **Hyperparameter Tuning:** Supports bounded tree depth (`Max_Depth`) and minimal dataset lengths prior to forcing a categorical leaf (`Min_Samples_Split`).
- **Memory Integrity:** Clean structural initialization and automated de-allocation protocols leveraging `Ada.Unchecked_Deallocation` with guaranteed recursive destruction of nodes avoiding memory leakage.

---

## Usage

No `main.adb` is required for production inclusion. The unit file `tests.adb` is provided to demonstrate robust usage mapping directly through standard data instantiation and prediction flows.

To execute the test suite which builds and prints verification output:

```bash
make test
```

**Expected Output:**  
Sequential breakdown of test evaluations labeled 1-15 checking functionality like max depth bounds, impurity metric verification, split selection, memory behaviors, and structured exceptions for invalid datasets. Output concludes with:

```plaintext
=== 45 passed,  0 failed ===
```

---

## Testing

Comprehensive testing encompasses categorical operations crucial to standard machine learning routines. Tested scenarios include:

- **Functional Correctness:** Ensures accurate non-linear classification mappings, multi-feature selection, tie-breaker strategies, and verification that pure data resolves directly to leaves.
- **Boundary Validation:** Validates `Max_Depth` truncations, edge cases like single-item datasets, and `Min_Samples_Split` forcing mechanisms.
- **Error Handling Architecture:** Directly asserts correct exception propagation for empty sets, dimension array mismatches, out-of-bound predictions, and handling logic blocks over de-allocated pointers.

---

## Building

**Prerequisites:** GNAT compiler (compatible with `-gnat2022` flag aligning with ISO/IEC 8652:2023 Ada specifications) and standard make tooling.

To simply compile without running tests:

```bash
make all
```

To clean environment artifacts:

```bash
make clean
```
