# Aharonov-Jones-Landau Algorithm Simulation

## Project Overview
This project provides a robust Ada 2023 classical simulation of the quantum **Aharonov–Jones–Landau (AJL) algorithm**. The AJL algorithm evaluates the Jones polynomial of a knot or link by encoding it as a topological braid, translating the braid generators into Temperley-Lieb unitary matrix representations, and extracting the topological invariants by approximating the matrix trace using the quantum Hadamard test. This implementation simulates the quantum measurements required for bounded-error quantum polynomial-time (BQP) approximation and compares them against exact classical derivations.

## Features
* **Braid Group Representation:** Constructs valid unitary operator mappings for elements of the Braid Group $B_3$.
* **Algorithm Variants:**
  * `Classical_Exact`: Uses dense matrix multiplication to deterministically extract the trace (models exponential-time exact classical evaluation).
  * `Quantum_Simulated`: Uses a randomized Monte Carlo routine mimicking the quantum Hadamard measurement test to stochastically approximate the normalized trace.
* **Strong Typing Verification:** Subtyped constraints for valid braid generators and strict isolation between Real/Complex mathematics to ensure numerical stability.

## Usage
To build and run the provided test suite, simply use the `make` utility.

```bash
make test
```

**Expected Output:**

```text
Running tests...
TEST 1 — Complex Math Fundamentals
  PASS — 1.1 Addition Re
  PASS — 1.2 Addition Im
...
===  26 passed,  0 failed ===
```

## Testing
The test suite in `tests.adb` conducts rigorous validation covering:

* **Functional Correctness:** Verifying structural properties of complex multiplication, identity constraints, and non-abelian topological behaviors.
* **Invariant Bounds:** Checking stochastic quantum approximations converge reliably to the exact classical evaluations within $5\sigma$ confidence intervals at large sample sizes.
* **Edge Cases & Error Handling:** Confirming Ada's runtime correctly blocks out-of-bounds `0` generators, gracefully handles empty braids, and properly enforces domain invariants using Dynamic Predicates.

These categories guarantee that both standard execution paths and exceptional states conform strictly to both Ada language invariants and the algorithm's mathematical integrity.

## Building
**Prerequisites:**
* GNAT Ada Compiler (GCC suite)
* Ada version 2023 (or Ada 2022 compatibility via `-gnat2022`)

```bash
make all
```
