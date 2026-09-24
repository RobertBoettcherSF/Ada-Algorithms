# Hadamard Test Implementation in Ada 2023

## Project Overview
This project provides a robust, production-ready Ada 2023 implementation of the Hadamard test algorithm and its variants. In quantum computation and quantum simulation, the Hadamard test is a fundamental algorithmic primitive used to estimate the real and imaginary parts of the expectation value $\langle\psi\vert{}U\vert{}\psi\rangle$ of a unitary operator $U$ with respect to a quantum state $\vert{}\psi\rangle$, as well as estimating inner products between arbitrary quantum states.

## Features
- **Real Part Estimation**: Extracts the real component of expectation values $\text{Re}(\langle\psi\vert{}U\vert{}\psi\rangle)$ via simulation of the Hadamard test circuit.
- **Imaginary Part Estimation**: Extracts the imaginary component $\text{Im}(\langle\psi\vert{}U\vert{}\psi\rangle)$ using phase-shifted ancilla measurements.
- **Inner Product Estimation**: Implements the modified Hadamard test (SWAP-test-related primitive) to compute inner products $\langle\phi_1\vert{}\phi_2\rangle$.
- **Validation Helpers**: Rigorous checks for quantum state normalization and matrix unitarity.
- **Strong Typing & Contracts**: Full use of custom domain types (`Component_Value`, `Complex_Number`, `State_Vector`, `Unitary_Matrix`) and Ada 2023 contracts (`Pre`, `Post`, `Global => null`).
- **Comprehensive Test Suite**: 13 standalone tests covering functional correctness, edge cases, error handling, and matrix/state invariants.

## Usage
To build and run the test suite, use the provided Makefile:

    make test

Expected output:

    Running tests...
      PASS — 1.1 Real part is 1.0 for |0> and Identity
      ...
    === 39 passed, 0 failed ===

## Testing
The test suite (`tests.adb`) verifies:
- **Functional Correctness**: Exact expected values for identity, Pauli-X, Pauli-Z, and Pauli-Y operators across various basis and superposition states.
- **Edge Cases**: Single-element states and boundary conditions.
- **Error Handling**: Robust exception safety (`Invalid_Dimension`) on dimension mismatches.
- **Invariants**: Verification of state normalization and matrix unitarity constraints.

## Building
Prerequisites:
- GNAT compiler supporting Ada 2023 (ISO/IEC 8652:2023) and flag `-gnat2022`.
- GNU Make.

Build command:

    make

Clean build artifacts:

    make clean
