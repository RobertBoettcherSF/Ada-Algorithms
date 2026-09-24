# Locality-Sensitive Hashing (LSH) in Ada 2023

---

## Project Overview

This repository contains a clean, robust, and mathematically precise implementation of **Locality-Sensitive Hashing (LSH)**, a fundamental algorithm for dimensionality reduction and approximate nearest neighbor searches. LSH operates on the principle that similar items in a high-dimensional space should collide in the same "buckets" with a high probability. The implementation covers the three primary hashing families identified in the literature corresponding to different distance metrics: **Hamming Distance**, **Jaccard Similarity**, and **Cosine Distance**.

---

## Features

- **Bit Sampling (Hamming Distance):** Packs specific sampled bits from a high-dimensional boolean vector into a lightweight 32-bit integer signature.
- **MinHash (Jaccard Similarity):** Creates permutation signatures for set intersections. Includes internal mixing functions and mathematical Jaccard approximation from resulting signatures.
- **Random Projection (Cosine Distance):** Hyperplane partitioning of real-valued vector spaces where signatures correlate smoothly with the angle between vectors.
- **Strict Typing and Edge-Case Safety:** Robustly handles dimension mismatches, out-of-bounds indices, and empty structures via Ada's native exceptions.
- **Zero Warnings:** Completely `-gnatwa` warning-free under GNAT.

---

## Building

**Prerequisites:** You need the GNAT compiler capable of handling Ada 2022/2023 standards.

Run the `make` utility to compile:

```bash
make
```

---

## Usage and Testing

Because LSH relies on hashing and comparisons, the usage of the library is directly demonstrated within the comprehensive `tests.adb` program, which acts as both the test suite and the main executable.

To build and run the test suite:

```bash
make test
```

**Expected Output:** The console will display a structured readout of 13 separate test categories containing exactly 39 assertions, all yielding `PASS`, ending with a `=== 39 passed, 0 failed ===` summary.

---

## Testing

Testing covers:

- Structural logic.
- Algorithmic edge-case stability (such as opposing vectors/exactly orthogonal vectors for cosine similarity).
- Parameter offset mismatch validations.
- Mathematical deterministic behavior for subset hashing relationships.
