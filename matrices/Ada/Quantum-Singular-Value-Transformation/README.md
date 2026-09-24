# Quantum Singular Value Transformation (QSVT) in Ada 2023

## Overview

Production-grade Ada 2023 implementation of the **Quantum Singular Value Transformation (QSVT)** framework. Enables arbitrary polynomial transformations of block-encoded matrices via Chebyshev polynomials, QSP phase sequences, and specialized variants for matrix inversion and eigenvalue transformations.

## Features

- **Chebyshev Polynomial Evaluation**: High-precision iterative computation of *Tn(x)* for *x ∈ $$-1, 1$$*
- **Block Encoding Validation**: Submatrix operator norm verification
- **Quantum Signal Processing (QSP) Simulation**: Phase rotation sequences (𝜑⃗) on signal amplitudes
- **Parity-Preserving QSVT**: Odd, even, and mixed polynomial transformations
- **Specialized Transformations**: Singular Value Transformation, Quantum Eigenvalue Transformation, regularized Matrix Inversion
- **Strong Typing &amp; Contracts**: Ada 2023 strong typing, custom subtypes, Pre/Post conditions

## Usage

### Building

**Prerequisites:**

- GNAT compiler supporting Ada 2023 (`gnatmake`)

**Build:**

```bash
make
```

**Clean:**

```bash
make clean
```

### Testing

Run the test suite:

```bash
make test
```

**Expected output:**

```
=== STARTING QUANTUM SINGULAR VALUE TRANSFORMATION TESTS ===
  PASS — 1.1 T_0(0.5) equals 1.0
...
=== 39 passed, 0 failed ===
```

**Test Coverage:**

- Functional correctness (Chebyshev recurrence relations, Horner's method polynomial evaluation)
- Edge cases (boundary values at *x = ±1.0, 0.0*, matrix norm constraints)
- Error handling &amp; preconditions (domain validation, exception safety)
- Invariants (boundedness of orthogonal polynomials, transformation linearity)
