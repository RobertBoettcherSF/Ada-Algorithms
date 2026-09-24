# Cluster Analysis in Ada

---

## Project Overview

This repository provides a strongly typed, zero-warning Ada implementation of unsupervised **Cluster Analysis** utilizing N-dimensional capabilities. It explicitly covers standard partitioning logic, supporting generic initialization over an abstract configurable multidimensional coordinate space.

---

## Features

- **K-Means Clustering:** Employs standard Lloyd's Algorithm paired with Euclidean distances, converging at the statistical mean of spatial groupings.
- **K-Medians Clustering:** A variant clustering method relying on Manhattan (L1) geometry distances and replacing typical averages with exact median calculations for robustness against extreme outliers.
- **Dynamic Dimensionality:** Entire logic encapsulated in a generic package parametrically defined by `Dimensions` (e.g., can generate fully capable robust 2D, 3D, and N-dimensional implementations statically at compile-time).
- **Metrics Utilities:** Bundled calculation procedures for cluster evaluation (inertia measurements based on intra-cluster variance summing).

---

## Usage

Simply invoke Make to run the exhaustive integrated test-suite, which doubles as API usage documentation natively. No external libraries are needed.

```bash
make test
```

**Expected Output:**

```plaintext
Running tests...
TEST 1 — Euclidean Distance 2D
  PASS — 1.1 Dist(0,0 to 3,4) = 5
  PASS — 1.2 Dist(P,P) = 0
  ...
===  39 passed,  0 failed ===
```

---

## Testing

This repository opts for runtime executable verification relying on Ada's **Design-by-Contract** (`Pre`, `Post`). Included are rigorous sanity tests mapped functionally:

- **Functional Correctness:** Verifying convergence across both K-Means and K-Medians algorithms under varying K limits.
- **Math Equivalencies:** Proving absolute metrics for Manhattan geometry vs standard Cartesian geometry over multidimensional spans.
- **Edge Cases &amp; Error Handling:** Explicit bounds assertion (testing execution stops gracefully without infinite looping when max iteration hits) along with constraint boundary defense verified by throwing `Assertion_Error` gracefully upon contract break.

---

## Building

**Prerequisites:** GNAT toolchain (e.g., via Alire or system package managers).

Requires `-gnat2022` flag, which natively conforms to ISO/IEC 8652:2023 Ada standards, allowing latest iteration mechanics and structural bounds enforcement.
