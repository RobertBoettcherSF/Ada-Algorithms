# Quantum Counting Algorithm in Ada 2023

## Project Overview
This project provides an expert Ada 2023 (ISO/IEC 8652:2023) implementation of the **Quantum Counting Algorithm**, a prominent quantum computing algorithm that combines Grover's search algorithm and the quantum phase estimation (QPE) algorithm to efficiently estimate the number of marked solutions in an unstructured search space.

## Features
- **Standard Quantum Counting**: Estimates the number of solutions $k$ in a database of size $N$ using $t$ precision qubits.
- **Quantum Existence Problem**: Solves the specialized decision problem of determining whether any solution exists ($k > 0$) in the search space.
- **Grover's Search with Unknown Count**: Integrates quantum counting estimation to determine optimal Grover iteration bounds when the exact number of solutions is initially unknown.
- **Eigenvalue Phase Calculation**: Computes the Grover operator phase angle $\theta$ corresponding to the proportion of marked entries.
- **Robust Strong Typing & Contracts**: Leverages custom domain types, preconditions (`Pre`), postconditions (`Post`), and strict error handling via named exceptions.

## Usage
To build and run the test suite, use the provided Makefile:

    make test

Expected output:

    === STARTING QUANTUM COUNTING SUITE ===
      PASS — 1.1 Estimated count is zero
      ...
    === 39 passed, 0 failed ===

To clean build artifacts:

    make clean

## Testing
The test suite (`tests.adb`) adheres to rigorous verification standards containing 13 comprehensive test cases across multiple assertions each (39+ assertions total):
- **Functional Correctness**: Validates accuracy across zero, partial, and maximum solution densities.
- **Edge Cases**: Tests boundary conditions, minimum database sizes, and extreme precision configurations.
- **Error Handling**: Verifies that invalid inputs correctly trigger named exceptions (`Invalid_Parameters`).
- **Invariants**: Ensures all mathematical bounds and postconditions are consistently met.

## Building
### Prerequisites
- GNAT compiler with Ada 2023 support (`-gnat2022`).
- GNU Make.

### Compilation
Build directly using the GNAT project file:

    gprbuild -Pquantum_counting.gpr
