# Hopfield Network in Ada 2023

---

## Project Overview

This project provides a robust, strictly typed Ada 2023 implementation of a **Hopfield Network**—a form of recurrent artificial neural network used as a content-addressable memory system. It implements both Discrete (bipolar) and Continuous network models, complete with synchronous and asynchronous update rules, Hebbian learning, and energy calculation functions based on the mathematical models detailed in the literature.

---

## Features

- **Discrete Hopfield Network:** Supports bipolar (-1, 1) node states.
- **Continuous Hopfield Network:** Supports continuous states integrated over time using an Euler method approximation with a sigmoid (tanh) activation function.
- **Update Rules:** Both Synchronous (all nodes updated at once) and Asynchronous (single node updated) routines are provided.
- **Hebbian Learning:** Procedures to train the weight matrix for both continuous and discrete patterns.
- **Energy Function:** Real-time calculation of the network energy to confirm state stability and convergence dynamics.
- **Design by Contract:** Heavy usage of Ada 2023 `Pre` and `Post` contracts to ensure matrix dimensions match, patterns are valid, and vectors remain strictly bipolar when required.

---

## Usage

To build and run the test suite (which acts as the usage demonstrator):

```bash
make test
```

**Expected Output:**  
You will see output detailing 13 distinct tests (across validation, mathematical accuracy, state evolution, and contract verification), each printing `PASS` for its assertions, culminating in:

```plaintext
===  39 passed,  0 failed ===
```

---

## Testing

The embedded test suite (`tests.adb`) provides complete verification and validation covering:

- **Functional Correctness:** Verifying standard Hebbian weight matrices matching hand-calculated expectations.
- **Invariant Checking:** Ensuring network energy is correctly computed for stable and unstable states.
- **Edge Cases:** Operating smoothly with minimal network sizes (1-node networks).
- **Error Handling &amp; Preconditions:** Purposefully passing mismatched arrays or non-bipolar integers to prove that `System.Assertions.Assert_Failure` catches invalid use before unsafe state occurs.

---

## Building

**Prerequisites:** A modern GNAT toolchain (e.g., GNAT FSF or GNAT Pro).

**Language Standard:** The Makefile configures the compiler for Ada 2023 by using the `-gnat2022` flag and enforces strict correctness checks with `-gnatwa`.
