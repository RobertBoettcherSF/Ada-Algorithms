# Ada LogitBoost

---

## Project Overview

This project provides a robust, strongly-typed Ada 2023 implementation of the **LogitBoost** machine learning algorithm, developed by Jerome Friedman, Trevor Hastie, and Robert Tibshirani. LogitBoost casts the AdaBoost method as a statistical framework minimizing a logistic loss function, creating resilient ensembles. The implementation builds a functional gradient descent model based on 1-level decision trees (stumps) to form highly interpretable and performant binary classifiers.

---

## Features

- **Binary LogitBoost Implementation:** Calculates weighted likelihoods and dynamically adapts internal working response variables *zᵢ* and weights *wᵢ*.
- **Decision Stump Weak Learners:** Employs an exact minimum-weighted-error greedy search across multidimensional feature matrices.
- **Strict Numerical Stability:** Bounding logic ensures convergence and mathematically sane weights, preventing exploding gradients when encountering saturated probabilities (*p → 0* or *p → 1*).
- **Ada 2023 Strong Typing:** Defines clean domain models using continuous `Real` numeric domains, mapping strictly against 2D `Feature_Matrix` structures and deterministic enumerative classification labels.
- **Contract-Driven Development:** Incorporates exact state assertions across subprogram interfaces (`Pre`, `Post`).

---

## Usage

No `main` target is needed to try out the package; a rich standalone demonstration and verification suite is built natively.

```bash
make test
```

**Expected Output:**

```plaintext
Running tests...
TEST 1 - Calculate_Working_Data Basic Logic (P=0.5)
  PASS - 1.1 Z for Y=1, P=0.5 is 2.0
  PASS - 1.2 W for P=0.5 is 0.25
  PASS - 1.3 Z for Y=0, P=0.5 is -2.0
...
TEST 13 - Train Handles Constant Labels Robustly
  PASS - 13.1 Predicts class 1 uniformly for x=1.0
  PASS - 13.2 Predicts class 1 uniformly for x=2.0
  PASS - 13.3 Predicts class 1 uniformly for x=3.0

===  44 passed,  0 failed ===
```

---

## Testing

The test suite (`tests.adb`) operates as both regression harness and usage example. Verified categories include:

- **Mathematical Precision:** Working targets (*z*, *w*) bound properly preventing NaN leaks and preserving the Log-Odds objective structure.
- **Component Integrity:** Evaluating the internal Stump logic guarantees appropriate feature index selection upon multiple vectors and strict adherence to minimization.
- **Behavioral Invariants:** Stress testing the trainer under 0 iterations, multi-dimensional boundaries, single classes, and empty data states to prove contract safety.
- **Range Fidelity:** Assuring raw continuous Log-Odds estimations map explicitly within standard 0.0 - 1.0 *P(y=1|x)* mappings without arithmetic bounds overflow under high ensemble weight.

---

## Building

**Prerequisites:** A functional GNAT Ada compiler targeting Ada 2022/2023 capabilities (`gnatmake`).

The project is fully conformant to standard ISO/IEC 8652:2023 Ada semantics. Compilation operates under maximum warnings `-gnatwa` without producing artifact spam, ensuring deep structural type safety.

```bash
make all
```
