# Artificial Neural Network (Ada 2023)

---

## Project Overview

This repository contains a full Ada 2023 implementation of a classic **Artificial Neural Network (Multi-Layer Perceptron)**, deriving directly from structural logic described in the relevant computer science domain. It features a scalable sequence of dense, fully-connected layers, supports forward propagation (inference) and backpropagation learning via Stochastic Gradient Descent (SGD). Designed with strong Ada typing, robust contract-based programming (`Pre`/`Post` bounds checks), memory safety, and matrix indexing invariants.

---

## Features

- **Flexible Network Architecture:** Dynamically construct sequential N-Layer networks using bounded memory representations and Indefinite Vectors.
- **Inference Variant (Forward Pass):** Implements weighted-sum predictions using standardized tensor mathematics.
- **Training Variant (Backpropagation):** Stochastic Gradient Descent implemented mathematically without external algebraic modules.
- **Activation Function Variants:** Includes `Sigmoid`, `ReLU`, `Tanh`, and `Linear`, natively providing their derivatives for the backpropagation chain rule calculations.
- **Loss Evaluation:** Mean Squared Error computation.
- **Defensive Engineering:** Vector normalization guards against Ada's native unaligned array boundary traps; complete memory cleanup prevents leaks.

---

## Building

**Prerequisites:** A compliant Ada 2022/2023 compiler like GNAT.

```bash
make
```

---

## Usage &amp; Testing

A robust test suite acts as both the verification harness and the main API demonstration platform. The package contains no independent `main.adb`; execution runs entirely through the assertions.

```bash
make test
```

**Expected Output:**  
The software will produce terminal output verifying internal math parameters over 14 test sweeps (verifying components including Activation Functions, Matrix alignments, Unaligned index bounds, and Loss-reduction over SGD epochs). If any test fails, an explicit pragma `Assert` halting exception will trigger.

---

## Testing Philosophy

The integrated tests confirm 43 separate internal assertions spanning four distinct categories:

- **Functional Correctness:** Verifying exact gradient values across layer steps, ensuring SGD minimizes Loss effectively.
- **Edge Cases:** Protecting against network queries utilizing uninitialized variables or disjoint bounds sizes.
- **Error Handling:** Validating exact intercept behavior by purposefully violating mathematical shape rules across dot-product operations.
- **Invariants:** Maintaining state encapsulation to isolate network configurations during simultaneous memory adjustments.
