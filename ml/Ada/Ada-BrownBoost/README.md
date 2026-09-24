# BrownBoost

---

## Project Overview

**BrownBoost** is an adaptive ensemble boosting algorithm introduced by Yoav Freund that is specifically designed to be robust to noisy datasets. Unlike algorithms like AdaBoost that endlessly focus on repeatedly misclassified examples (effectively memorizing noise), BrownBoost inherently "gives up" on points that refuse to align with the rest of the dataset. It operates by numerically optimizing a non-convex error function parameterized by a time variable *c* that equates to expected data noise variance. This Ada 2023 implementation uses decision stumps as the weak learners and rigorously solves the differential constraint equations via numerical processes to assemble an accurate final model.

---

## Features

- **Strictly Typed Architecture:** Designed specifically around strong domains (`Value_Type`, `Class_Label`, etc.) to prevent semantic mismatches.
- **Robust Solver Variants:**
  - `Bisection_Solver`: Derives steps utilizing iterative bisection (similar to JBoost's technique).
  - `Newton_Solver`: Evaluates constraint differentials and applies iterative 2D Newton-Raphson approximation (as featured in Freund's original theory).
- **Built-in Weak Learners:** Evaluates and combines multidimensional decision stumps natively without requiring external ML scaffolding.
- **Memory Constrained:** Exposes pre-allocated ensemble sizes configurable upon invocation to safely operate within constrained devices.
- **Contract Driven:** Heavy use of Ada preconditions ensuring data dimension matching, variance legality, and robust numeric boundaries.

---

## Usage

The package operates directly over multi-dimensional feature matrices. The tests program (`tests.adb`) doubles as the implementation sample illustrating exactly how datasets are constructed, initialized, generated, and verified.

To execute the test and use cases:

```bash
make test
```

**Expected Output:** Directly indicates clean compilations followed by 42 successfully passing assertions across all numerical routines and edge cases.

---

## Testing

The `tests.adb` program is fully self-contained without dependencies on `main.adb`. 14 structural test domains cover 42 discrete runtime assertions, including:

- **Numerical Edge Cases:** Identifies handling of zero-variance models and large-scale *C* constants.
- **Constraint Handling:** Evaluates algorithm resistance against incorrect sizes/ranges by deliberately triggering exception logic.
- **Noisy Tolerances:** Injects incorrectly labeled parameters explicitly validating the potential-function's ability to "discard" the outlier without polluting the final matrix output.
- **Solver Integrity:** Enforces tests equally validating outputs against both Bisection and Newton internal variants to prove their mathematical continuity.

---

## Building

**Prerequisites:**

- GNAT Compilation Suite (supporting Ada 2022/2023 constructs and capabilities).
- Standard Make environment.

The implementation enforces the `gnat2022` standard utilizing strict checking variables (`-gnatwa -gnata`). All builds compile seamlessly into `.o` binaries mapped tightly within memory via the enclosed `Brown_Boost.gpr` configurations. No warnings are emitted during artifact generation.
