# Quantum Phase Estimation Algorithm in Ada 2023

## Project Overview
This project provides a robust, production-grade implementation of the **Quantum Phase Estimation (QPE)** algorithm in Ada 2023 (ISO/IEC 8652:2023). QPE is a cornerstone quantum algorithm used to estimate the phase corresponding to an eigenvalue of a unitary operator, serving as a vital subroutine in Shor's algorithm, quantum linear solvers, and quantum counting. This implementation models the quantum register evolution, success probability distributions, toy 1-qubit circuits, and precision requirements.

## Features
- **Strong Typing**: Custom domain types (`Qubit_Count`, `Phase`, `Probability`) prevent invalid domain mixing and ensure type safety.
- **Contract-Based Programming**: Comprehensive `Pre` and `Post` aspects verify function inputs and guarantee valid output bounds.
- **Multiple Algorithm Variants**:
  - Full standard QPE simulation (`Simulate_QPE`).
  - Exact success probability distribution calculation (`Compute_Success_Probability`).
  - 1-qubit toy example simulation (`Toy_One_Qubit_QPE`).
  - Required qubit sizing for target precision (`Required_Qubits`).
- **Rigorous Test Suite**: 14 comprehensive tests with 42 assertions validating functional correctness, edge cases, and exception handling.
- **Clean Compilation**: Zero warnings under strict GNAT compiler flags (`-gnatwa -gnat2022`).

## Usage
To build and run the test suite, use the provided Makefile:

```bash
make test
```

Expected output:
```text
Running tests...
=== Running Quantum Phase Estimation Test Suite ===
  PASS — TEST 1 — Standard QPE with Theta = 0.0
  ...
=== 42 passed, 0 failed ===
```

## Testing
The test suite (`tests.adb`) rigorously evaluates the package across multiple categories:
- **Functional Correctness**: Validates QPE simulation outcomes against known exact dyadic fractions ($\theta = 0.0, 0.5$) and arbitrary phases.
- **Probability Distributions**: Verifies exact success probability formulas and lower bounds ($\ge 4/\pi^2$).
- **Toy Models**: Tests 1-qubit phase estimation against analytical formulas for $\lambda = 1, -1, e^{2\pi i / 3}$.
- **Error Handling**: Tests validation aspects and custom exceptions (`Invalid_Phase`) for out-of-range inputs.
- **Boundary Conditions**: Tests minimum ($N=1$) and maximum ($N=24$) qubit configurations.

## Building
### Prerequisites
- GNAT compiler supporting Ada 2023 (`-gnat2022`).
- GNU Make.

### Build Commands
- `make` — Compiles the project and builds the test executable in `bin/tests`.
- `make test` — Compiles and executes the test suite.
- `make clean` — Removes build artifacts (`obj/` and `bin/`).
