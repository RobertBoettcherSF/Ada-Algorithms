# Q-Learning (Ada 2023 Implementation)

---

## Project Overview

This project provides a robust, strongly-typed generic Ada 2023 implementation of the **Q-Learning algorithm**, as described in the tabular model-free reinforcement learning literature. It facilitates intelligent decision-making by allowing an agent to iteratively approximate an optimal action-value function representing the expected future rewards across a discrete state-action space. The implementation encompasses both standard Q-learning updates and Double Q-learning updates to prevent overestimation bias.

---

## Features

- **Standard Q-Learning Update:** Implements the classic tabular Bellman equation update for calculating *Q(s, a)*.
- **Double Q-Learning:** Provides decoupled action selection and evaluation utilizing dual independent Q-Tables to significantly reduce overestimation errors intrinsic to noisy environments.
- **Epsilon-Greedy Strategy:** Incorporates a built-in helper function to seamlessly balance between environmental exploration and exploitation based on provided random distributions.
- **Strongly Typed Generics:** The package is abstracted over user-defined arbitrary discrete domains for `State_Type` and `Action_Type`, heavily enforcing Ada's strict compile-time safety and semantic correctness.
- **Contract-Based Validation:** Employs Ada 2022/2023 `Pre` and `Global` aspects natively ensuring the absolute purity of the underlying logic boundaries.

---

## Usage

The system does not utilize a standalone `main.adb` application. Instead, behavior and usage are showcased securely within the executable test suite.

To build and run the execution examples via the test framework, simply run:

```sh
make test
```

**Expected Output:**

```plaintext
Running tests...
Starting Q-Learning Test Suite...
TEST 1 - Max_Q_Value Basic
  PASS - 1.1 Empty table returns 0.0
  PASS - 1.2 Finds highest positive value
  PASS - 1.3 Correctly considers unmodified 0.0 as max over negatives
...
===  42 passed,  0 failed ===
```

---

## Testing

The embedded test suite (`tests.adb`) doubles as validation architecture and API documentation, ensuring correct functionality across the following categories:

- **Functional Correctness:** Validates that all mathematical Q-value updates strictly align with expected manual Bellman derivations for multiple alpha/gamma bounds.
- **Edge Cases:** Validates proper functionality and exact tie-breaking when processing identical values, uninitialized structures, and purely negative reward streams.
- **Double-Q Evaluation Matrix:** Explicitly verifies proper action selection mapping, avoiding cross-contamination of isolated evaluation states to confirm correct suppression of the Q-overestimation bias.
- **Exploration Bounds Verification:** Thoroughly exercises Epsilon-Greedy distribution parameters to verify strict exploitation/exploration cutoffs.

---

## Building

**Prerequisites:** A functional installation of the GNAT Ada toolchain (`gnatmake`).

**Ada Version Requirement:** Project compiles targeting standard Ada 2022/2023 (`-gnat2022` flag) and explicitly maintains a zero-warning profile (`-gnatwa` flag).
