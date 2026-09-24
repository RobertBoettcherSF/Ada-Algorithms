# Zero-Attribute Rule (ZeroR) in Ada 2023

---

## Project Overview

This repository provides a robust, strongly-typed implementation of the **Zero-Attribute Rule (ZeroR)**, the simplest classification and regression method used in Machine Learning and Association Rule Learning. ZeroR simply relies on the target (class) variable and ignores all predictors. This implementation provides variants for both standard and robust regression (Mean and Median targets) and categorical classification (Mode/majority class) for datasets.

---

## Features

- **Numeric Mean Prediction:** Standard ZeroR variant for continuous regression targets.
- **Numeric Median Prediction:** Robust ZeroR variant for continuous targets, resilient to outliers.
- **Nominal Mode Prediction:** Standard ZeroR classification variant to find the most frequent class (with deterministic tie-breaking logic towards the smaller ID).
- **Safe &amp; Dynamic Wrappers:** Subprograms (`Safe_Predict_*`) that evaluate bounds dynamically and raise proper domain-specific exceptions, avoiding fatal bounds errors.
- **Strong Typing:** `Numeric_Value` and `Nominal_Value` discrete types enforce domain correctness and avoid raw integer/float pollution.

---

## Usage

The package acts as a library. For testing and demonstration, `tests.adb` acts as both the main executable and usage guide.

To execute and verify all capabilities:

```bash
make test
```

**Expected Output:**

```plaintext
Running tests...
TEST 1 — Numeric Mean (Basic Arrays)
  PASS — 1.1 Calculate mean of (1.0, 3.0) -> 2.0
  PASS — 1.2 Calculate mean of (-1.0, 1.0) -> 0.0
...
===  42 passed,  0 failed ===
```

---

## Testing

The embedded test suite (`tests.adb`) achieves high coverage by addressing:

- **Functional Correctness:** Verifying exact statistical operations (Mean, Median, Mode).
- **Edge Cases:** Single elements, odd/even length sorting distributions, and highly uniform arrays.
- **Error Handling:** Validating the behavior of safe wrappers against empty datasets, ensuring robust system exception paths.
- **Invariants:** Cross-validating that structural properties of arrays maintain mathematical equivalency across different variants.

Testing allows consumers to build trust in the component for upstream Machine Learning data processing pipelines.

---

## Building

**Prerequisites:**

- A modern GNAT toolchain supporting Ada 2022/2023 (`gnatmake`).
- Standard GNU Make tool.

Built adhering to ISO/IEC 8652:2023 strictly. All files compile clean under `-gnatwa`.
