# Operations Research Simplex Algorithm (Ada 2023)

## Project Overview
This repository implements a fundamental Operations Research algorithm: the Simplex Method for Linear Programming. Operations Research relies heavily on mathematical optimization to allocate scarce resources effectively, and the Simplex algorithm serves as the primary computational engine for solving linear objective scenarios. The package natively solves both Standard Form Maximization and Minimization problem variants by leveraging primal and dual transformations directly over a tableau formulation.

## Features
* **Standard Form Maximization (`Maximize`)**: Solves standard linear constraints ($A \mathbf{x} \le \mathbf{b}$, $\mathbf{x} \ge \mathbf{0}$) using a standard tableau with slack variables.
* **Standard Form Minimization (`Minimize`)**: Automates problem transformation into the mathematical Dual ($A^T \mathbf{y} \ge \mathbf{c}$, $\mathbf{y} \ge \mathbf{0}$) and extracts optimal primal values directly from the dual slack variables.
* **Bounded Exception Handling**: Explicitly traps constraints that fall outside standard formulation, raising `Infeasible_Problem` on non-positive/negative feasibility violations or `Unbounded_Problem` when the feasible region is unconstrained.
* **High-Precision Type Modeling**: Uses a custom `Value_Type` mapped to `Long_Float` with strict tolerance checking ($1.0 \times 10^{-9}$) to mitigate numerical instability during row pivot operations.

## Usage
No separate main application is necessary; the standalone test suite (`tests.adb`) doubles as a real-world usage demonstration. Execute the test suite using the Makefile:

```bash
make test
```

**Expected Output:**
The executable runs 13 distinct functional test cases covering primal optimization, dual minimization, edge cases, and exception safety, terminating with zero failures:

```text
Operations Research: Linear Programming (Simplex) Tests
=========================================================
TEST 1 — Standard Maximize
  PASS — 1.1 Objective Maximum correct
  PASS — 1.2 Sol(1) X is correct
  PASS — 1.3 Sol(2) Y is correct
...
===  42 passed,  0 failed ===
```

## Testing
The test suite implements a pessimistic verification philosophy ("assume the code is broken until proven otherwise"):
* **Functional Correctness**: Validates that computed values and basic variables strictly equal optimal vertices across 2-variable, 3-variable, and 4-variable systems.
* **Dual Alignment**: Verifies that minimization problems solved via dual transformation match primal theoretical bounds exactly.
* **Edge Cases**: Evaluates zero-vector objectives, redundant constraints, and degenerate solutions (multiple optimal points along an edge/facet).
* **Error Handling**: Verifies that infeasible bounds and unbounded objective directions cleanly trigger `Infeasible_Problem` and `Unbounded_Problem` exceptions.
* **Verification & Validation Role**: Critical for linear solvers because numerical drift, pivot cycling, and sign inversions can lead to silent calculation errors; extensive assertion testing guarantees correctness before deployment.

## Building
* **Prerequisites**: GNAT compiler supporting Ada 2022 / Ada 2023 (`ISO/IEC 8652:2023`).
* **Flags**: Compiled under `-gnatwa -gnat2022` to ensure strict type compliance and zero compiler warnings.

```bash
make all
```
