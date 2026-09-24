# Hamiltonian Simulation in Ada 2023

## Project Overview
This project provides a robust, high-performance implementation of quantum Hamiltonian simulation algorithms in Ada 2023 (ISO/IEC 8652:2023). Hamiltonian simulation is a core problem in quantum information science that involves approximating the time evolution operator e^{-iHt} for a quantum state vector governed by a sum-of-terms Hamiltonian composed of Pauli operators. The package supports product formula approximations (first-order Trotter-Suzuki decomposition and second-order Strang splitting) as well as truncated Taylor series expansions.

## Features
- First-Order Product Formula (Simulate_Trotter_1st): Standard Trotterization implementing time-slice propagation across individual Pauli interaction terms.
- Second-Order Product Formula (Simulate_Trotter_2nd): Symmetric Strang splitting providing higher-order accuracy for non-commuting Hamiltonian terms.
- Truncated Taylor Series (Simulate_Taylor): Direct polynomial expansion of the matrix exponential operator up to order 10.
- Error Estimation (Estimate_Trotter_Error): Analytical bound calculations for product formula discretization errors.
- Strong Typing & Contracts: Custom domain types for time, qubit indices, state vectors, and Pauli components backed by Ada contract aspects (Pre, Post).

## Usage
To build and execute the test suite, run:
make test

Expected output format:
TEST 1 — Trotter 1st Order Z Rotation
  PASS — 1.1 State length preserved
  PASS — 1.2 Amplitude 0 magnitude approx 1.0
  PASS — 1.3 Amplitude 1 remains zero
...
=== 39 passed, 0 failed ===

To clean build artifacts:
make clean

## Testing
The test suite (tests.adb) contains 13 comprehensive test cases covering 39 individual assertions. It validates:
- Functional Correctness: Single and multi-qubit state vector evolutions under various Pauli generators (X, Y, Z, I).
- Algorithm Variants: Comparative validation of 1st-order Trotter, 2nd-order Trotter, and Taylor expansion methods.
- Edge Cases: Zero-time simulation, boundary qubit limits, and normalization/probability conservation.
- Error Handling: Custom exception propagation (Invalid_Hamiltonian) upon encountering malformed operator inputs.

## Building
- Prerequisites: GNAT compiler supporting Ada 2023 (-gnat2022).
- Standard: ISO/IEC 8652:2023.
