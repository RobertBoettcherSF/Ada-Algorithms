# One-Attribute Rule (OneR) Algorithm in Ada 2023

---

## Project Overview

This repository provides a complete, robust, type-safe implementation of the **One-Attribute Rule** (OneR) classification algorithm. OneR is a machine learning approach that discovers the single most predictive feature inside a dataset to make simple but statistically surprisingly effective human-readable decision rules. It categorizes instances by constructing internal frequency tables of each attribute against the target class and selecting the single attribute that dictates the minimum error rate.

---

## Features

- **Strong Type Definitions:** Employs precise subtypes (`Attribute_Index`, `Attribute_Value`, `Class_Label`) enforcing boundaries at compile time to eliminate silent logic flaws.
- **Basic &amp; Robust Model Variants:**
  - **Basic Model:** Operates on strict statistical constraints. Raises mathematical exceptions when analyzing out-of-bounds/unseen variable states.
  - **Robust Model:** Adapts dynamically, tracking the macroscopic majority class globally. Safely proxies undefined states dynamically without crashing.
- **Algorithmic Determinism:** Utilizes structured `Ada.Containers.Ordered_Maps` ensuring mathematical resolution is identical and deterministic on every compiler architecture even during edge-case attribute tiebreaker events.
- **Zero-Warning Codebase:** Carefully validated to compile without extraneous metadata drops or unutilized variable checks using GNAT's aggressive `-gnatwa` flag.

---

## Usage

The library is heavily integrated into a comprehensive unit suite mimicking production deployment strategies. To observe predictions natively in the terminal, utilize the predefined make target:

```bash
make test
```

**Expected Output:**

```plaintext
Running tests...
TEST 1 - Basic Model Perfect Predictor
  PASS - 1.1 Best attribute chosen correctly
  PASS - 1.2 Optimal total error evaluates to 0
  ...
TEST 13 - Independent Cross-Overriding
  PASS - 13.1 Selects independent subset majority globally
  ...
===  42 passed,  0 failed ===
```

---

## Testing

The standalone runner `tests.adb` guarantees high internal test confidence using multiple validation paths:

- **Functional Integrity:** Verifies the rule engines isolate and optimize minimum prediction error natively against dense grids (e.g., simulating uniform logic sets traversing thousands of loops).
- **Tie Breaking:** Evaluates subset resolution priority dynamically, enforcing identical outputs for parallel attribute weights or frequency ties.
- **Boundary Hardening:** Intentionally injects invalid arrays and out-of-domain variables validating that pre-conditions trap illegal reads, guaranteeing hardware isolation.

---

## Building

**Requirements:** Any GCC/GNAT toolchain supporting ISO/IEC 8652:2023 (`-gnat2022`).

Build artifacts manually via `make all` or clear intermediate caches with `make clean`.
