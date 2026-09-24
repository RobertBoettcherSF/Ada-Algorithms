# Ada SARSA (State–Action–Reward–State–Action)

---

## Project Overview

This project provides a robust, strongly-typed Ada 2023 implementation of the **SARSA Reinforcement Learning algorithm**. The implementation encompasses the foundational on-policy Temporal Difference (TD) control mechanisms used to learn a Markov Decision Process policy. It strictly leverages standard Ada constructs with comprehensive contracts (preconditions and postconditions) to ensure state and action safety during Q-Table interactions.

---

## Features

- **Standard SARSA:** Implements the base on-policy TD update rule taking into account exact subsequent actions.
- **Expected SARSA:** Integrates expected value computation under an *ε*-greedy policy to reduce the variance in updates.
- **SARSA(λ):** Incorporates accumulating eligibility traces to distribute rewards effectively across recently visited state-action pairs.
- **Helper Subprograms:** Includes TD error derivation, strictly bounds-checked trace management, and randomized *ε*-greedy policy selection.
- **Strong Typing:** Domain-specific constraint types (`Rate`, `Reward_Value`, `Trace_Value`) enforcing validity directly through the Ada compiler.

---

## Usage

Run `make test` to automatically build the project and execute the comprehensive test suite demonstrating the API usage.

**Expected Output:**

```text
Running tests...
TEST 1 — Initialize Q Table
  PASS — 1.1 Q-table row bounds match
  PASS — 1.2 Q-table col bounds match
...
===  42 passed,  0 failed ===
```

---

## Testing

The embedded test suite (`tests.adb`) doubles as a working example of package initialization and execution. It contains 14 tests with 42 assertions spanning the following categories:

- **Functional Correctness:** Validates that matrix values match exact mathematical derivations for target values.
- **Edge Cases:** Explores limit conditions such as strictly greedy (*ε*=0) vs strictly randomized (*ε*=1) paths.
- **Error Handling &amp; Invariants:** Demonstrates protective boundary violation traps resulting in explicitly named runtime exceptions. Verification enforces that incorrect array topologies gracefully fail.

---

## Building

**Prerequisites:**

- GNAT toolchain (e.g., Alire, or `gnatmake` provided natively).
- Compliance configured for Ada 2022/2023 via `-gnat2022`.

Execute `make` or `make all` to compile the tests binary. Object and executable outputs are cleanly deposited into dynamically generated `obj/` and `bin/` directories, respectively.
