# K-Nearest Neighbors (Ada 2023)

---

## Project Overview

This repository contains a robust, type-safe Ada 2023 implementation of the **K-nearest neighbors (KNN)** algorithm. K-nearest neighbors is a non-parametric, supervised learning algorithm used for both classification and regression, functioning on the premise of predicting values by calculating the Euclidean distance between a given query point and points in a generalized multi-dimensional space. The solution includes the most prominent variants of the algorithm as standard standalone functions.

---

## Features

- **Classification (Majority Vote):** Assigns discrete categorical labels to new observations based on the mode of the neighboring points.
- **Regression (Uniform Average):** Estimates continuous variables by averaging the targets of the closest K neighbors.
- **Distance-Weighted Classification:** Implements inverse-distance weighting so closer neighbors influence the voting outcome more heavily than further ones.
- **Distance-Weighted Regression:** Uses an inverse-distance weighted average approach to draw continuous predictions closer to proximal training targets.
- **High Dimensionality Support:** Operates gracefully across *N*-dimensional spaces relying on strictly-typed unbounded Ada matrices.
- **Rigorous Error Constraints:** Employs Ada `Pre` conditions and explicitly raised named exceptions to manage dataset anomalies like dimension mismatches or out-of-bounds K values.

---

## Usage

Since this implementation avoids unnecessary wrappers, the primary usage is demonstrated entirely inside `tests.adb`. To execute the usage scenarios and confirm correct behavior, use the provided Makefile:

```bash
make test
```

**Expected Output:**

```plaintext
Running tests...
TEST 1 - Basic Classification (K=1)
  PASS - 1.1 Direct match picks class 0
  PASS - 1.2 Direct match picks class 1
...
TEST 13 - Row Count Mismatch Validation
  PASS - 13.1 Classify identifies differing lengths
  PASS - 13.2 Regression identifies differing lengths
  PASS - 13.3 Weighted Regression identifies differing lengths

===  39 passed,  0 failed ===
```

---

## Testing

The embedded standalone test suite `tests.adb` satisfies both verification and validation criteria using built-in assertions:

- **Functional Correctness:** Ensures mathematical constraints such as exact Euclidean distance checks, average calculation matching expected manual arithmetic, and correct nearest-point selection resolving deterministically across *N*-dimensions.
- **Edge Cases:** Validates functionality when constraints sit at bounds—like utilizing identically-placed items which traditionally triggers division-by-zero math panics (handled here strictly using epsilon constants).
- **Error Handling:** Uses isolated execution blocks to rigorously enforce exception raising on dataset flaws, assuring dimension counts correlate between matrices.
- **Invariants:** Proves the fundamental distance calculation is unaffected by scaling dimensions directly in the tests loop.

---

## Building

**Prerequisites:** A compliant Ada compilation toolchain (e.g., Alire/GNAT FSF 11+ or GNAT Pro).

**Language Level:** This package targets the ISO/IEC 8652:2023 (Ada 2022/2023) standard natively. The Makefile supplies the requisite flag (`-gnat2022`) to permit modern features like formal `Pre` and `Global` annotations alongside stringent warning checks (`-gnatwa`).
