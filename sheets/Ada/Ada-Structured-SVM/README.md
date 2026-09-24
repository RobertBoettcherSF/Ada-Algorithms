# Structured Support Vector Machine (SSVM) in Ada

---

## Project Overview

This package implements the **Structured Support Vector Machine (Structured SVM)** algorithm, derived from the mathematical formulations featured on the [Structured SVM Wikipedia article](https://en.wikipedia.org/wiki/Structured_SVM). Structured SVMs generalize traditional classification boundaries to accommodate arbitrarily structured output spaces—such as sequential chains, grammatical trees, and spatial graphs.

---

## Features

- **Highly Generic Design:** Accepts any arbitrary type mappings for `Input_Type` and `Output_Type` alongside standard structural constraints, decoupling mathematical optimization from the underlying problem logic.
- **Margin-Rescaling Formulation Variant:** Adjusts constraints by enforcing that margin violations map directly proportionally to absolute distance metrics.
- **Slack-Rescaling Formulation Variant:** Adjusts constraints by rescaling slacks, which handles scenarios where varying loss metrics dictate disproportionate error scaling.
- **Stochastic Subgradient Optimization:** Replaces unwieldy external Quadratic Programming environments with cyclical subgradient projection (Pegasos).
- **Strict Typing &amp; Contracts:** Provides zero-warning compilability under GNAT, rigorous Ada 2022 compatibility, and defensive parameter verification to safely identify configuration faults.

---

## Usage

Because arbitrary inference strategies often face intractably huge dimension spaces natively, the user dictates search logic via callback routines: `Argmax_Margin_Rescaling` and `Argmax_Slack_Rescaling`. A self-contained utilization test proving how to wire up linear multiclass classification instances lives in `tests.adb`.

Build and trigger executions using the top-level `Makefile`:

```bash
make test
```

**Expected Output:**

```plaintext
Running tests...
TEST 1 — Vector Math Functions
  PASS — 1.1 Vector Addition
...
===  39 passed,  0 failed ===
```

---

## Testing

The `tests.adb` executable serves concurrently as the regression testing suite and canonical documentation for how client spaces integrate mathematically with callbacks.

- **Functional Correctness:** Ensures accurate vector mathematics, sparse feature representations, and stable determinism.
- **Overfitting Capability:** Proves empirical minimizers flawlessly separate trivially non-overlapping coordinate data under intense regularizations.
- **Optimization Progress:** Tests cyclic subgradient decay logic.
- **Edge Cases &amp; Error Handling:** Validates strict enforcement against improperly matched vectors, mismatched sets, invalid hyper-parameters, and missing data boundaries.

---

## Building

**Prerequisites:** GNAT Ada compiler suite.

**Standard:** Ada 2023 (formally triggered as Ada 2022 or `-gnat2022` inside active GNAT environments).
