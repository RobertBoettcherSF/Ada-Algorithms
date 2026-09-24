# Ada 2023 Boosting Framework

---

## Project Overview

This repository provides an industrial-grade, strongly-typed Ada 2023 (ISO/IEC 8652:2023) implementation of the **Boosting meta-algorithm**. Boosting systematically creates a strong predictive model by combining an ensemble of sequentially trained weak learners. This implementation encapsulates both discrete classification (AdaBoost.M1) and continuous regression (Least-Squares Gradient Boosting), utilizing single-level decision trees (stumps) as the foundational weak learner logic.

---

## Features

- **AdaBoost.M1 Variant:** Binary classification implementation. Dynamically updates point weights sequentially emphasizing frequently misclassified samples, capping *α* iteratively for robust convergence.
- **Gradient Boosting Variant:** Optimized for Least-Squares (MSE) regression. Integrates a flexible learning rate multiplier and effectively fits sequential models on pseudo-residuals.
- **Zero Warnings Codebase:** Entirely compliant with rigorous GNAT verification flags (`-gnatwa` / `-gnat2022`).
- **Robust Contract Validation:** Ada 2023 constructs, such as `Global => null`, `Pre`, and `Post`, ensure subprograms remain pure and rigorously check incoming arrays bounding to prevent silent math exceptions.
- **Early Stopping:** Efficiently halts AdaBoost iterations upon reaching perfect classification or degrading below random prediction thresholds (error ≥ 0.5).

---

## Building

To compile the test suite successfully, you will need a GNAT toolchain compliant with the Ada 2022/2023 specification. Ensure GNU `make` is also installed on your system.

```bash
make all
```

---

## Testing

The `tests.adb` test suite utilizes zero external dependencies and serves as both API documentation and invariant validation. It runs 13 unique test profiles (at minimum 3 assertions each).

```bash
make test
```

**Categories covered in testing:**

- **Functional Correctness:** Training trajectories for linearly separable bounds and regression gradient bounding limits.
- **Edge Cases:** Passing 0-iteration demands, early-stopping behavior checks, and constant-variance sets preventing mathematical division bounds.
- **Error Handling:** Validates expected behaviors enforcing dimensionality symmetries (X vs Y) and precise Boolean-equivalent labels (+1.0 / -1.0 arrays for AdaBoost classification logic).

---

## Usage

Calling algorithms directly returns strongly typed discriminant records `AdaBoost_Model` and `Gradient_Boosting_Model`.

```ada
--  Initialize and train a binary AdaBoost classifier (max 50 stumps)
Model : AdaBoost_Model := Train_AdaBoost (Feature_Matrix, Label_Vector, 50);

--  Predict utilizing unseen feature vectors (Returns exactly 1.0 or -1.0)
Prediction : Real := Predict_AdaBoost (Model, Data_Vector);
```
