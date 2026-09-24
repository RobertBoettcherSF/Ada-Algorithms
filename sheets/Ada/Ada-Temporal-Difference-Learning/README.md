# Temporal Difference (TD) Learning in Ada 2023

---

## Project Overview

This repository provides a complete, strongly-typed implementation of **Temporal Difference (TD) Learning** algorithms in Ada 2023 (ISO/IEC 8652:2023). Temporal difference learning is a fundamental reinforcement learning technique combining ideas from Monte Carlo methods and dynamic programming. It allows an agent to learn directly from raw experience without a model of the environment's dynamics, bootstrapping predictions by using subsequent predictions.

---

## Features

- **Tabular TD(0):** State-value function prediction for policy evaluation.
- **Q-Learning (Off-Policy):** Learns the optimal action-value function independently of the agent's actions.
- **SARSA (On-Policy):** Learns the action-value function relative to the policy currently being followed by the agent.
- **Expected SARSA:** Generalizes Q-learning and SARSA by using the probability distribution of actions (policy) to compute the expected value of the next state.
- **Strong Typing:** Leverages Ada subtypes and domains (`State_Index`, `Action_Index`, `Rate`, `Value_Type`) for rigid compile-time validation.
- **Contract-Based Programming:** Uses Ada 2012/2023 `Pre`, `Post`, and `Global` aspects to assert inputs structurally.

---

## Usage

To use the implementations, call the variants defined in `Temporal_Difference_Learning`.  
Run the integrated test suite to see working examples:

```bash
make test
```

**Expected Output:**  
You should see a sequence of tests asserting algorithmic behavior, with 39 passing assertions total, concluding with:

```plaintext
...
===  39 passed,  0 failed ===
```

---

## Testing

The suite in `tests.adb` acts as both the verification framework and an executable usage example. Categories tested:

- **Functional Correctness:** Verifies algorithmic equations (Target and Error calculations) apply properly across TD(0), Q-Learning, and SARSA variants.
- **Edge Cases:** Verifies zero-values for Alpha (learning rate) and Gamma (myopic discount factor) gracefully halt value propagation without crashing.
- **Error Handling:** Checks that bounds mismatches and absent state/action references raise explicit exceptions (`Invalid_State_Error`, `Invalid_Action_Error`, `Policy_Mismatch_Error`).
- **Invariants:** Validates policies strictly sum to 1.0 (probabilities) and checks tabular persistence against uncorrupted states.

---

## Building

**Prerequisites:** A modern GNAT toolchain supporting Ada 2022/2023 (`-gnat2022`).

To compile everything with extensive warnings turned on, simply invoke:

```bash
make
```
