# ALOPEX Optimization Algorithm in Ada 2023

---

## Project Overview

This project provides an expert, production-grade implementation of the **ALOPEX** (Algorithms of Pattern Extraction) optimization algorithm in **Ada 2023** (ISO/IEC 8652:2023). ALOPEX is a correlation-based stochastic optimization and machine learning method originally proposed by E. Harth and E. Tzanakou in 1974. Unlike gradient descent methods that easily become trapped in local extrema, ALOPEX leverages cross-correlation of parameter changes and response function differences combined with a stochastic Gaussian perturbation process (temperature) to effectively navigate complex cost landscapes and locate global minima or maxima.

---

## Features

- **Strong Typing:** Domain-specific types (`Weight_Type`, `Cost_Type`, `Learning_Rate_Type`, `Temperature_Type`, `Weight_Vector`) prevent unit and domain errors.
- **Contract-Based Programming:** Public subprograms are annotated with `Pre` and `Post` contracts ensuring correctness and safety at boundaries.
- **Multiple Algorithm Variants:**
  - `Optimize`: General-purpose optimization supporting both minimization and maximization via the sign of the learning rate.
  - `Minimize`: Specialized minimization variant with enforced negative feedback dynamics.
  - `Maximize`: Specialized maximization variant with enforced positive feedback dynamics.
  - `Optimize_Adaptive`: Advanced variant incorporating simulated annealing temperature cooling schedules over iterations.
- **Robust Math &amp; Helpers:** Gaussian random number generation via the Box-Muller transform using standard Ada numerics, alongside Euclidean norm vector calculations.
- **Comprehensive Error Handling:** Custom named exceptions (`Invalid_Parameter_Error`, `Empty_Vector_Error`, `Convergence_Error`) and safe exception propagation wrapping.
- **Zero Warnings:** Fully compliant with GNAT compiler strict warning flags (`-gnatwa -gnat2022`).

---

## Usage

The project builds a standalone test suite executable (`tests.adb`) that demonstrates the API across diverse objective functions and edge cases.

To build and run tests:

```bash
make test
```

To clean build artifacts:

```bash
make clean
```

**Expected Output:**  
When running `make test`, the test suite executes 13 comprehensive test categories verifying over 40 distinct assertions, reporting `PASS` status for each check and concluding with a summary:

```plaintext
=== STARTING ALOPEX ALGORITHM TEST SUITE ===
TEST 1 — Quadratic Minimization (Optimize)
  PASS — 1.1 Iterations run within bound
  ...
=== 39 passed, 0 failed ===
```

---

## Testing

The test suite (`tests.adb`) exercises all public subprograms across multiple categories:

- **Functional Correctness:** Verifying minimization and maximization convergence on quadratic and multi-dimensional sphere objectives.
- **Variants Validation:** Testing specialized `Minimize`, `Maximize`, and `Optimize_Adaptive` procedures.
- **Edge Cases:** Single-element vectors, boundary iteration counts (e.g., 1 iteration), and high/low temperature stochastic behavior.
- **Error Handling &amp; Invariants:** Validating expected exceptions (`Empty_Vector_Error`, `Invalid_Parameter_Error`, objective failures) and ensuring cost monotonicity and invariant preservation.

---

## Building

**Prerequisites:**

- GNAT Compiler supporting Ada 2023 (e.g., GNAT 13 or newer with `-gnat2022` support).
- GNU Make.

**Project Structure:**

- `alopex.ads`: Package specification (types, exceptions, public subprograms with contracts).
- `alopex.adb`: Package body (core ALOPEX algorithm, Box-Muller Gaussian generator, variants).
- `alopex.gpr`: GNAT project file configured for building `tests.adb`.
- `Makefile`: Build automation (`all`, `test`, `clean`).
- `tests.adb`: Standalone test suite and API demonstration executable.
- `README.md`: Project documentation.
