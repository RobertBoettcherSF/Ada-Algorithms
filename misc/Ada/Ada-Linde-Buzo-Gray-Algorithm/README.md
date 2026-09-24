# Linde-Buzo-Gray (LBG) Algorithm in Ada 2023

---

## Project Overview

This repository provides a strict, statically-typed Ada 2023 implementation of the **Linde–Buzo–Gray (LBG) algorithm** for vector quantization. First conceptualized in 1980, the LBG algorithm constructs an optimal scalar or vector quantizer codebook based on a training dataset. It operates by successively splitting codebook vectors and locally optimizing them through the Lloyd-Max clustering algorithm. This codebase implements the full specification with both standard generation (splitting) and distinct centroid optimization.

---

## Features

- **Full Generic Dimensionality:** Codebook structures adapt strictly to a user-provided vector dimension type parameter at compile-time.
- **Variant 1 — Lloyd's Optimization (K-Means):** Optimizes an existing initial centroid array using distance clustering and fractional improvement evaluation.
- **Variant 2 — Complete LBG Codebook Generation:** Grows a codebook from size 1 iteratively splitting vectors by a provided factor `Epsilon` up to an arbitrary positive `Target_Size`.
- **Non-Power-of-2 Scaling:** Handles exact arbitrary codebook target sizes beyond typical powers of 2.
- **Contract-Driven Robustness:** Strict `Pre` and `Post` aspect conditions guarantee that dimensions, array sizing bounds, and logic limits enforce stability (e.g., tracking dataset exhaustion).

---

## Usage

Execute the built test binary to see the algorithm in motion. The tests simultaneously act as usage examples of instantiating the packages and interacting with datasets.

To build and run:

```bash
make test
```

**Expected Output:**

```plaintext
Running tests...
TEST 1 -- Squared_Distance Correctness
  PASS -- 1.1 Distance to Origin
  PASS -- 1.2 Distance to Self is zero
  PASS -- 1.3 Symmetry
TEST 2 -- Average_Distortion Perfect Match
  PASS -- 2.1 Exact match codebook
  PASS -- 2.2 Single exact point
  PASS -- 2.3 Duplicated training data
...
===  39 passed,  0 failed ===
```

---

## Testing

The standalone test suite (`tests.adb`) actively verifies properties and edge cases:

- **Functional Correctness:** Ensures accurate multi-dimensional vector distortion calculation and logical centroid balancing.
- **Edge Cases:** Examines empty logical cells during iteration, handles target sizes not forming a pure power of 2, and tests zero threshold Epsilon.
- **Error Handling / Preconditions:** Enforces runtime safety against mathematically invalid inputs (like requesting a codebook target larger than available data arrays).
- **Invariants:** Employs Ada assertions via GNAT compilation flags to evaluate runtime boundary strictness recursively.

---

## Building

**Prerequisites:** GNAT Toolchain (GCC-based Ada Compiler).

This project relies upon Ada 2022/2023 constructs, such as formal pre-contracts and extended array attribute utilization. The provided Makefile applies the required compilation flag `-gnat2022` and strictly enables warnings and assertions with `-gnatwa -gnata`.
