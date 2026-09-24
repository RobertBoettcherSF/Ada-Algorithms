# Difference-map Algorithm (Ada Implementation)

## Project Overview
This repository contains a robust, highly-typed Ada implementation of the **Difference-map algorithm**, a powerful meta-algorithm used for finding the intersection of constraint sets. Originally developed for phase retrieval, it applies broadly to general constraint satisfaction problems (such as solving Sudoku, graph coloring, or physical design constraints). 

The module defines the algorithm in Euclidean space, enabling continuous optimizations using discrete projections. 

## Features
This package implements **ALL** primary algorithmic variants defined by theoretical consensus:
1. **Generalized Difference Map:** Total configuration over $\beta, \gamma_A,$ and $\gamma_B$ parameters.
2. **Standard Difference Map:** Automatically couples $\gamma_A = \gamma_B = 1/\beta$.
3. **Douglas-Rachford Splitting:** A highly stable sub-variant acting strictly at $\beta = 1.0$.
4. **Alternating Projections:** A rudimentary comparison baseline determining $x_{k+1} = P_B(P_A(x_k))$.
5. **Dynamic Solver Engine:** Full iterative execution tracking Euclidean step-error against parameterized thresholds with max-iteration guarantees.

## Testing
This project embraces strict **Verification & Validation (V&V)** principles. The test suite (`tests.adb`) operates on a pessimistic assumption: *The code is broken until proven functional via execution.* 

Tests are categorized into four critical verification domains:

1. **Functionality Correctness:** Verifies basic math (vector addition, projection combinations, subtraction) to ensure algorithms execute the mathematical specification identically to the Wikipedia definition.
2. **Error Handling & Fault Injection:** Proves the application fails *gracefully* when provided impossible data (e.g., dividing by zero when $\beta=0$, or mismatched array lengths).
3. **Edge Cases:** Evaluates extreme boundary inputs (e.g., arrays of zero length) to validate against unexpected memory faults.
4. **Performance & Halting:** Asserts that iterative loops respect finite bounds (livelock prevention). A solver is proven functional because tests force both immediate convergence conditions and impossible (infinite) topologies to verify exact step-counts.

These tests guarantee reliability in mission-critical environments by confirming adherence to strict safety limits (e.g. Constraint_Error / Dimension_Error).

## Usage
The system compiles into object files within `/obj` and executables within `/bin` natively. There is no `src` folder; the structure is entirely flat.

### Compilation
Build all executables using the provided GNU Make wrapper:
```bash
make all
