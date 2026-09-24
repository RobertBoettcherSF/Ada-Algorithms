# Hadamard Transform in Ada 2023

## Project Overview

This project provides a robust, expert-level implementation of the Hadamard transform (also known as the Walsh-Hadamard transform) in Ada 2023 (ISO/IEC 8652:2023). The Hadamard transform is an orthogonal, symmetric, linear operation that decomposes input vectors into a superposition of Walsh functions, widely used in signal processing, image compression, error-correcting codes, and quantum computing.

## Features

- **Unnormalized Fast Walsh-Hadamard Transform (FWHT)**: Integer-based butterfly computation requiring only additions and subtractions ($O(N \log N)$ complexity).
- **Normalized FWHT**: Floating-point transform scaled by $1 / \sqrt{N}$ to maintain unitary properties.
- **Inverse FWHT**: Reconstruction of original signals via orthogonal inversion.
- **Sequency-Ordered FWHT (Walsh Transform)**: Output reordering by sequency (zero-crossings) using bit-reversal permutation.
- **Strong Typing & Safety**: Custom domain types (`Vector_Integer`, `Vector_Float`), explicit Pre/Post contract aspects, and explicit exception handling (`Null_Input_Exception`, `Invalid_Length_Exception`).

## Usage

To build and run the test suite, ensure GNAT (supporting Ada 2023) is installed, then run:

```bash
make test
```

To clean build artifacts:

```bash
make clean
```

### Expected Output

```text
Running tests...
=== STARTING HADAMARD TRANSFORM TEST SUITE ===
  PASS — 1.1 zero is not power of two
  ...
=== 42 passed, 0 failed ===
```

## Testing

The test suite (`tests.adb`) implements 14 rigorous test cases with over 40 distinct assertions covering:
- **Functional Correctness**: Validating against known mathematical definitions and Wikipedia reference examples (sizes 1, 2, 4, 8).
- **Edge Cases**: Single-element inputs and exact power-of-two validations.
- **Error Handling**: Verification that empty inputs and non-power-of-2 lengths correctly raise named exceptions (`Null_Input_Exception`, `Invalid_Length_Exception`).
- **Mathematical Invariants**: Testing algebraic properties including linearity, involutive scaling, and orthonormal roundtrip recovery.

## Building

- **Prerequisites**: GNAT compiler with `-gnat2022` support.
- **Standard**: Ada 2023 (ISO/IEC 8652:2023).
