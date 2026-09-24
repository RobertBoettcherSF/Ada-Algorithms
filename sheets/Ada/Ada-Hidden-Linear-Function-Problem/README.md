# Hidden Linear Function Problem in Ada 2023

## Project Overview
This project provides a complete, high-integrity Ada 2023 implementation of the **Hidden Linear Function (HLF)** problem, which generalizes the Bernstein-Vazirani problem to quadratic forms over binary matrices and vectors evaluated modulo 4. The implementation adheres to rigorous software engineering standards, utilizing strong typing, Ada contracts (`Pre`/`Post`), and clean compilation under GNAT (`-gnatwa -gnat2022`).

## Features
- **Strong Typing**: Custom domain types (`Bit`, `Mod_4`, `Bit_Vector`, `Matrix`) ensuring domain safety and preventing raw integer misuse.
- **Contract-Based Programming**: Public subprograms annotated with `Pre` and `Post` conditions to enforce valid problem specifications and ranges.
- **Quadratic Form Evaluation**: Computes $q(x) = (2 x^T A x + b^T x) \bmod 4$ for upper-triangular binary matrices and binary vectors.
- **Subspace Membership**: Evaluates vector membership in the linearity subspace $L_q$.
- **Hidden Vector Discovery & Verification**: Automatically searches for and verifies hidden linear vectors $z$ satisfying $q(x) = 2 z^T x$ on $L_q$.
- **Comprehensive Test Suite**: Standalone test suite (`tests.adb`) featuring 14 distinct test categories with multiple assertions per test.

## Building
Prerequisites:
- GNAT compiler with Ada 2023 support (`-gnat2022`)
- `gnatmake` build tool
- GNU `make`

To build the executable test suite:
```bash
make
```

## Usage
To run the test suite and verify correct functionality:
```bash
make test
```

Expected output:
```text
Running tests...
=== STARTING HIDDEN LINEAR FUNCTION TEST SUITE ===
TEST 1 — Upper Triangular Matrix Validation
  PASS — 1.1 Valid upper triangular matrix returns true
  ...
=== 42 passed, 0 failed ===
```

To clean build artifacts:
```bash
make clean
```

## Testing & Verification
The test suite (`tests.adb`) covers multiple validation categories:
1. **Functional Correctness**: Validates quadratic form calculations, subspace membership, and vector discovery across various matrix dimensions ($2 \times 2$ and $3 \times 3$).
2. **Edge Cases**: Tests zero matrices, zero vectors, and boundary dimension constraints.
3. **Error Handling**: Verifies robust handling of non-upper-triangular matrices, dimension mismatches, and invalid vector lengths.
4. **Invariants**: Ensures contractual pre/post-conditions hold across all operational boundaries.
