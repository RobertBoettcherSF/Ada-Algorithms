# HHL Algorithm (Harrow-Hassidim-Lloyd) in Ada 2023

## Project Overview
This project provides a robust, production-grade Ada 2023 implementation modeling the Harrow-Hassidim-Lloyd (HHL) quantum algorithm for solving linear systems of equations ($Ax = b$) and estimating quadratic forms. The implementation encapsulates core quantum subroutines including Quantum Phase Estimation (QPE), controlled eigenvalue rotation, amplitude amplification success probability modeling, and rigorous input validation conforming to strict Ada contract programming standards.

## Features
- **Full Quadratic Form Estimation**: Simulates the core HHL outcome estimation $x^T M x$ for Hermitian matrices.
- **Quantum Phase Estimation (QPE) Simulation**: Models eigenvalue phase extraction and precision scaling with register size.
- **Controlled Rotation Simulation**: Implements conditional rotation by $\arcsin(C/\lambda)$ with automatic saturation handling.
- **Amplitude Amplification Success Modeling**: Computes rigorous success probabilities of measuring the 'well' state based on condition number scaling ($1/\kappa^2$).
- **Robust Input Validation**: Validates Hermitian properties, vector non-zero norms, dimension compatibility, and condition number bounds, raising explicit named exceptions.
- **Contract-Based Programming**: Utilizes Ada 2023 `Pre` and `Post` aspects to enforce safe parameter boundaries.
- **Strict Compliance**: Fully compiles under GNAT with zero warnings using `-gnatwa -gnat2022`.

## Usage
To build and execute the test suite, run:
    make test

To clean build artifacts:
    make clean

### Expected Output
    TEST 1 — Input Validation Success
      PASS — 1.1 Valid 2x2 matrix and vector accepted
      PASS — 1.2 Matrix dimension matches vector length
      PASS — 1.3 Condition number >= 1.0
    ...
    ===  39 passed,   0 failed ===

## Testing
The test suite (`tests.adb`) implements 13 comprehensive tests comprising 39 distinct assertions covering:
- **Functional Correctness**: Verification of quadratic form estimation across 2x2 and 3x3 Hermitian systems, QPE accuracy, and controlled rotation calculations.
- **Edge Cases**: Handling of small eigenvalues, condition number boundaries ($\kappa = 1.0$), and rotation saturation limits.
- **Error Handling**: Rigorous validation of `Not_Hermitian_Error`, `Zero_Vector_Error`, `Invalid_Dimension_Error`, and condition number bounds.
- **Invariants**: Ensuring output probabilities remain strictly bounded within $[0.0, 1.0]$.

## Building
- **Prerequisites**: GNAT compiler supporting Ada 2023 (e.g., GNAT 12 or newer).
- **Language Standard**: ISO/IEC 8652:2023 (Ada 2023).
