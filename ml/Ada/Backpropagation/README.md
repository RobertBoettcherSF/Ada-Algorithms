# Backpropagation in Ada 2023

---

## Project Overview

This repository contains a purely standard, zero-dependency implementation of the **Backpropagation algorithm** in Ada 2023. Backpropagation calculates gradients using the chain rule, enabling feedforward neural networks to learn by minimizing loss. This implementation cleanly abstracts a 3-layer architecture, utilizing explicit strict bounds and parameterizable activation functions to demonstrate the core variants of network training safely and efficiently.

---

## Features

- **Strictly Typed Matrices/Vectors:** Uses custom floating-point types (`Real`) instead of generic primitives.
- **Multiple Optimization Variants:**
  - Standard Stochastic Gradient Descent (SGD).
  - Mini-batch / Batch Gradient Descent via gradient accumulation (`Accumulate_Gradients`).
  - SGD with Momentum.
- **Configurable Activations:** Native implementations and derivatives for `Sigmoid`, `ReLU`, `Tanh`, and `Linear`.
- **Preconditions and Constraints:** Uses contract-based programming (`with Pre => ...`) alongside manual exception handling (`Dimension_Error`) for fail-fast tensor mismatch debugging.

---

## Usage

No external mathematical dependencies or specific matrix libraries are required. Simply compile the standalone project.

```bash
# Build and run the test suite
make test
```

**Expected Output:**

```plaintext
Running tests...
TEST 1 -- Network Creation
  PASS -- 1.1 Correct Input size
  PASS -- 1.2 Correct Hidden size
  PASS -- 1.3 Correct Output size
  PASS -- 1.4 Activation function set properly
...
TEST 13 -- XOR Integration Test
  PASS -- 13.1 XOR(0,0) near 0
  PASS -- 13.2 XOR(0,1) near 1
  PASS -- 13.3 XOR(1,1) near 0

===  39 passed,  0 failed ===
```

---

## Testing

The `tests.adb` program serves double duty as both the unit test suite and the main usage example. It tests:

- **Contract Adherence &amp; Exception Handling:** Enforces valid tensor bounds for all array math logic.
- **Gradient Accuracy:** Validates correct error scaling and matrix-vector operations.
- **Mathematical Convergence:** Integrates operations end-to-end to train an XOR network.
- **State Integrity:** Verifies state clearing, gradient accumulations, and velocity math in Momentum.

---

## Building

**Prerequisites:** GNAT compiler.

**Standards:** Ada 2022/2023 conformant (`-gnat2022`).

Designed to compile completely warning-free under extreme checking (`-gnatwa`).


## SPARK / GNATprove (Level 2)

`SPARK_Mode => On` on the package. RNG init, elementary activations, and
exception-raising tensor ops are `SPARK_Mode => Off`. `Zero_Gradients` stays On.

```bash
make prove
```

**Bar:** Level 2 on SPARK-On parts; all analyzed checks proved. `make test` green.
