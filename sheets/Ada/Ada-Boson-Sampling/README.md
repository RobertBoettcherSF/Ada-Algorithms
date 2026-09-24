# Boson Sampling in Ada 2023

## Project Overview
This project provides a robust, highly reliable, and strongly typed Ada 2023 implementation of the **Boson Sampling** computational model as introduced by Scott Aaronson and Alex Arkhipov. Boson sampling is a specialized non-universal model of quantum computation that simulates identical bosons (such as photons) interfering through a passive linear optical interferometer. Classically simulating this phenomenon requires calculating the matrix permanent, which is a #P-hard computational problem. This library implements core mathematical operations, matrix permanents via Ryser's formula, Standard Boson Sampling, Scattershot Boson Sampling, unitarity validation, and classical complexity scaling estimation.

## Features
- **Strong Typing & Domain Subtypes**: Custom types for modes, photon counts, real numbers, and complex numbers (`Mode_Index`, `Mode_Count`, `Photon_Count`, `Complex_Number`, `Complex_Matrix`).
- **Ada 2023 Contracts**: Public subprograms annotated with `Pre` and `Post` conditions to ensure safe boundaries and invariants.
- **Ryser's Matrix Permanent Algorithm**: Exact computation of complex matrix permanents for multi-photon interference amplitudes.
- **Interferometer Unitarity Validation**: Robust verification that optical network matrices satisfy $U U^\dagger = I$ within defined tolerances.
- **Standard Boson Sampling**: Transition amplitudes and probability distribution calculations for Fock state inputs and outputs.
- **Scattershot Boson Sampling**: Multi-photon pair input configurations across arbitrary mode masks.
- **Classical Simulation Complexity**: Exponential cost scaling estimations reflecting #P-hard complexity.

## Building
Prerequisites:
- GNAT compiler with Ada 2023 support (ISO/IEC 8652:2023, e.g., GNAT 13+).
- GNU Make.

To build the test suite executable:
`make all`

To remove build artifacts:
`make clean`

## Usage
Run the standalone test suite and demonstration executable using:
`make test`

Expected output:
Running tests...
=== Running Boson Sampling Test Suite (Ada 2023) ===
TEST 1 — Complex Arithmetic Operations
  PASS — 1.1 Add real parts correctness
  ...
=== 39 passed, 0 failed ===

## Testing
The test suite (`tests.adb`) doubles as a comprehensive usage example and test harness containing 13 distinct test categories (39 individual assertions):
1. Functional Correctness: Complex number arithmetic and magnitude calculations.
2. Matrix Permanents: 1x1 and 2x2 matrix permanent evaluations via Ryser's algorithm.
3. Unitarity Verification: Validation of valid unitary matrices and detection of non-unitary inputs.
4. Transition Amplitudes & Probabilities: Standard and scattershot boson sampling probability computations.
5. Edge Cases: Single-mode configurations and minimal input dimensions.
6. Error Handling: Exception raising and robustness checks.
7. Mathematical Invariants: Probability conservation sum properties and amplitude symmetries.
