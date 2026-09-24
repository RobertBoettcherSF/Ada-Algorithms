# Supervised Learning in Ada 2023

---

## Project Overview

This repository provides a strongly-typed, verifiable Ada 2023 implementation of fundamental **Supervised Learning** algorithms based on the principles outlined in the [Wikipedia article on Supervised Learning](https://en.wikipedia.org/wiki/Supervised_learning). It demonstrates multiple algorithmic variants, specifically targeting distance-based classification (K-Nearest Neighbors), statistical regression (Simple Linear Regression), and dynamic iterative classification (Perceptron).

---

## Features

- **Simple Linear Regression:** Computes line of best fit for real-valued targets via least-squares variance calculation. Protects against zero-variance inputs.
- **K-Nearest Neighbors (KNN):** Multi-dimensional classifier using Euclidean distance and stable majority voting. Allows querying dynamically via different `K` values.
- **Perceptron:** Binary linear classifier that dynamically adjusts internal weights over iterative epochs using a definable learning rate.
- **Strong Typing:** Leverages custom numeric and integer domain types (e.g., `Real`, `Class_Label`, `K_Value`) rejecting arbitrary primitive substitution.
- **Ada Contracts &amp; Validation:** Extensive bounds checking, dimension validation, and named exception propagation.

---

## Building

To build and run this project, you will need the GNAT Ada compiler suite capable of handling Ada 2022/2023 (ISO/IEC 8652:2023) standards.

```bash
make test
```

---

## Usage

The primary execution target is the test suite itself, which acts as the usage example for invoking the module logic:

```bash
./bin/tests
```

**Output:**

```plaintext
--- Starting Supervised Learning Tests ---
TEST 1 — Linear Regression Positive Trend
  PASS — 1.1 Slope is approx 2.0
  PASS — 1.2 Intercept is approx 1.0
  PASS — 1.3 Predict 5.0 is 11.0
...
===  39 passed,  0 failed ===
```

---

## Testing

The `tests.adb` program executes 13 rigorous test scenarios categorized by:

- **Functional Correctness:** Assuring exact math, logic gates (AND/OR), and predictions.
- **Edge Cases:** Testing single points, exact tie-breakers in voting, flat regression lines, and boundaries.
- **Error Handling:** Intentionally violating preconditions to ensure proper structural exception raises (e.g., mismatched multi-dimensional array bounds, zero variance calculations, incompatible hyper-parameters).
