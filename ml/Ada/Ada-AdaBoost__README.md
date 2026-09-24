# AdaBoost in Ada 2023

---

## Project Overview

This repository provides a complete, robust implementation of the standard **AdaBoost algorithm** (Discrete AdaBoost / AdaBoost.M1 for binary classification) utilizing Decision Stumps as the weak learners. Written strictly in Ada 2023, it natively exploits multidimensional arrays, rigorous range constraints, and strict data-type enforcement to eliminate traditional dynamic boundaries. The algorithm minimizes an exponential loss function over consecutive iterations, reweighting misclassified samples to sequentially construct a robust strong classifier out of computationally simple one-dimensional splits.

---

## Features

- **Discrete AdaBoost:** Fully compliant binary classifier training (Positive/Negative boundaries).
- **Decision Stumps:** Optimal deterministic threshold discovery operating across *N*-dimensions.
- **Dynamic Array Handling:** Type-checked multidimensional coordinate inputs, robustly managing variable sample scales.
- **Built-in Resilience:** Aborts safely upon hitting inseparable noise limits, and halts precisely when perfectly separable state is achieved to conserve CPU cycles.
- **Strict Typing:** All data (Scores, Features, Labels) bounded by specific sub-types, isolating potential numeric defects entirely at compile time.

---

## Usage

The `tests.adb` program doubles as both the primary test suite and usage example. It constructs data partitions natively and triggers `Train` and `Predict` directly.

Build and run:

```bash
make test
```

**Expected Output:**  
The build tool compiles the components with zero warnings using `-gnatwa`, leading sequentially into `Running tests...`. Output lines will display `PASS` strictly across 13 unique scenarios handling matrices, vectors, boundaries, and validation boundaries.

---

## Testing

The embedded unit testing schema tests edge boundaries deeply:

- **Functional Correctness:** Multi-step learning limits (reweighting XOR-style zones).
- **Edge Cases:** Infinite values (e.g., 1.0e15), exact duplicates, empty matrices, differing tuple lengths.
- **Error Handling:** Triggers and catches native Ada Exceptions (`Dimension_Mismatch_Error`, `Empty_Dataset_Error`).
- **Invariants Check:** Evaluates empty ensembles securely against runtime overflows.

All metrics are critical for verification and validation inside strict safety contexts.

---

## Building

**Prerequisites:** GNAT compiler system (GCC 13/14 or higher for native Ada 2022/2023 features).

**Compiler Flags:** Pre-configured via Makefile using `-gnat2022 -gnatwa` for optimal standard adherence without suppressions.
