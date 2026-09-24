# LPBoost (Linear Programming Boosting) in Ada

---

## Project Overview

This project provides a totally complete, dependency-free implementation of the **LPBoost** (Linear Programming Boosting) algorithm in Ada 2023. LPBoost is a margin-maximizing ensemble learning algorithm that dynamically generates weak hypotheses and solves a linear program at each iteration to find the optimal global weights for both the ensemble elements and the dataset distribution. This repository includes a custom Primal Simplex algorithm tailored to exactly solve the dual soft-margin formulation required by LPBoost.

---

## Features

- **Totally Corrective Optimization:** A built-in Primal Simplex solver calculates optimal hypothesis weights (`Alphas`) and dataset distribution (`U`) concurrently without relying on external libraries.
- **Decision Stump Weak Learner:** Automatically evaluates feature thresholds efficiently (*O(N · M²)*) to identify optimal single-feature splits based on the dynamically updated weights.
- **Dynamic Regularization:** Allows arbitrary tuning of the `Nu` parameter ∈ (0.0, 1.0\] to define strict hard margins or regularized soft margins preventing overfitting.
- **Convergence Guarantees:** Halts intelligently if a weak hypothesis achieves no better than 50% weighted accuracy, bypassing cyclical or unbounded LP states.
- **Strong Typing &amp; Contracts:** Extensive use of Ada 2023 `Pre` and `Post` contracts, custom range types, and data bounds to prevent invariant violation at runtime.

---

## Usage

The system interacts primarily through the `LPBoost` package. Datasets are passed as standard matrices and labels as integers (`-1`, `1`). Below is an expected output of the test suite showcasing behavior over diverse datasets:

```bash
make test
```

**Expected Output:**

```plaintext
Running tests...
TEST 1 — Normal Separable 2D Dataset (Nu=0.5)
  PASS — 1.1 Model size is > 0
  PASS — 1.2 Predicts negative class correctly
  PASS — 1.3 Predicts positive class correctly
TEST 2 — Predict_Score Signs and Magnitudes
  PASS — 2.1 Negative example score < 0.0
...
===  39 passed,  0 failed ===
```

---

## Testing

The `tests.adb` test suite exercises 13 distinct behaviors:

- **Functional Correctness:** Validates that linearly separable points reach 100% margin alignment.
- **Non-Linear Composability (XOR):** Proves that combinations of decision stumps solve complex non-linear combinations through algorithmic boosting.
- **Regularization Integrity:** Adjusts `Nu` bounds strictly testing Hard Margin (1.0) and Soft Margin bounds (0.2) and ensuring stability.
- **Boundary &amp; Edge Conditions:** Evaluates performance explicitly in contradictions (same dataset points mapping to opposing classes), unary classes (all positives), and unidimensional datasets.
- **Contract Enforcement:** Captures and validates proper `System.Assertions.Assert_Failure` responses during illegal input configurations.

These tests ensure mathematically sound Linear Programming bounds and invariant enforcement across all execution paths.

---

## Building

**Prerequisites:** A GNAT Ada Compiler supporting the 2022/2023 standard (`gnatmake`).

Build and test automatically using the provided Makefile:

```bash
make test
```

To clean all build artifacts:

```bash
make clean
```
