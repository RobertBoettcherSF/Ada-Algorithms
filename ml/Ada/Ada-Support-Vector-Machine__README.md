# Support Vector Machine (SVM) in Ada 2023

---

## Project Overview

This project provides a robust, native Ada 2023 implementation of **Support Vector Machines (SVMs)**, representing the algorithms detailed in academic literature. The implementation covers both primal optimization methods (via sub-gradient descent/Pegasos) for fast linear separations, as well as a simplified Sequential Minimal Optimization (SMO) algorithm applied in the dual space for resolving non-linear classifications using the "Kernel Trick".

---

## Features

- **Linear Hard-Margin &amp; Soft-Margin SVM:** Resolved using the Pegasos algorithm with a customizable regularization parameter (`C`).
- **Non-linear Kernel SVM:** Built-in support for multiple kernel mapping functions (Linear, Polynomial, RBF) bypassing linear restrictions.
- **Dual Model Support Vectors Extraction:** Extracts and retains dynamic arrays of support vectors using discriminated records.
- **Zero Dependencies:** Relies exclusively on standard `Ada.Numerics` and core language features.
- **Contract/SPARK-like Preparedness:** Heavily annotated with Ada 2012/2022 `Pre` and `Post` contracts shielding the implementation from invalid bounds.

---

## Usage

The `tests.adb` file serves as the main executable, functioning as a comprehensive usage example of the `SVM` package.

To execute it:

```bash
make test
```

**Expected Output:**

```plaintext
Running tests...
TEST 1 — Vector Mathematics (Dot Product)
  PASS — 1.1 Dot product evaluates correctly
...
TEST 14 — Edge Cases (Single Element Set)
  PASS — 14.1 SMO properly rejects single-element datasets natively

===  41 passed,  0 failed ===
```

---

## Testing

The embedded test suite explicitly targets verification and validation of math integrity and bounds checking:

- **Functional Correctness:** Ensures accurate vector dot products, kernel operations, and confirms positive vs. negative categorization.
- **Edge Cases:** Evaluates data topologies like purely linear configurations (AND models) versus un-separable linear planes (XOR models that require the Radial Basis Function kernel constraint).
- **Error Handling:** Triggers and catches contract anomalies when supplying inconsistent dataset cardinalities (Dimension Mismatch) or degraded matrices.
- **Invariants:** Continuously validates bias, bounds, and dimensional mappings between parameters and instantiated models (`Post` checks).

---

## Building

**Prerequisites:**

- GNAT Ada Compiler (supporting `-gnat2022` / Ada 2023 standard)
- Make

Simply run:

```bash
make
```

This builds and stores artifacts in the respective `obj/` and `bin/` directories seamlessly.
