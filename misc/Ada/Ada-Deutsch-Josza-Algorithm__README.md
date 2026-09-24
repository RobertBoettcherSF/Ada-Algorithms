# Deutsch-Jozsa Algorithm in Ada 2023

## Project Overview
This project implements the Deutsch–Jozsa algorithm—one of the earliest and most celebrated quantum algorithms demonstrating exponential speedup over classical deterministic algorithms for a black-box problem—alongside classical deterministic and randomized verification counterparts in Ada 2023 (ISO/IEC 8652:2023).

## Features
- **Deutsch's Algorithm ($n = 1$)**: Specialized single-bit input quantum simulation variant.
- **General Deutsch-Jozsa Algorithm ($n \ge 1$)**: Quantum oracle simulation via truth tables and function pointers.
- **Classical Deterministic Verification**: Worst-case deterministic checking.
- **Classical Randomized Verification**: Probabilistic checking using discrete random generation.
- **Robust Error Handling**: Explicit custom exceptions for dimension mismatches and invalid functions.
- **Ada 2023 Contracts**: Pre- and post-conditions (`Pre`, `Post`) on all public subprograms.

## Usage
To build and run the test suite, use the provided Makefile:

    make test

Expected output:

    Running tests...
      PASS — 1.1 Result is Constant_Zero
      ...
    === 39 passed, 0 failed ===

To clean build artifacts:

    make clean

## Testing
The test suite (`tests.adb`) comprises 13 comprehensive tests with over 39 individual assertions covering:
- **Functional Correctness**: Verification of constant-0, constant-1, and balanced functions for both $n=1$ and general $n$.
- **Edge Cases**: Handling different input vector sizes and truth table configurations.
- **Error Handling**: Verification of `Invalid_Dimension_Error` exceptions.
- **Invariants**: Strict adherence to Ada contract pre- and post-conditions.

## Building
Prerequisites: GNAT compiler supporting Ada 2023 (e.g., GNAT 13 or newer).

    gnatmake -gnatwa -gnat2022 -Pdeutsch_jozsa.gpr
