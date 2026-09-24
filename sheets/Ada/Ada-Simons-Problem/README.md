# Simon's Problem Algorithm in Ada 2023

## Overview

Complete Ada 2023 implementation of Simon's problem. Determines whether an oracle function is bijective or two-to-one with a hidden periodic shift, implementing decision-making, classical collision search, algebraic sampling, and promise verification.

## Features

- **Strong Typing**: `Bit`, `Bit_Vector`, `Function_Table`, `Equation_Matrix`
- **Ada 2023 Contracts**: Precondition (`Pre`) aspects on public subprograms
- **Algorithm Variants**:
  - Decision version (`Is_One_To_One_Function`)
  - Deterministic classical collision search (`Find_Secret_Classical`)
  - Algebraic system solver over GF(2) (`Solve_Simon_System`)
  - Randomized sampling simulation (`Find_Secret_Randomized_Sampling`)
  - Promise verification (`Verify_Simon_Promise`)
- **Error Handling**: `Invalid_Function_Error`, `Invalid_Dimension_Error`
- **Test Suite**: 13 tests, 39 assertions in `tests.adb`

## Usage

### Building

**Prerequisites:**

- GNAT compiler with Ada 2023 support (`-gnat2022`)

**Build System:**

- GNAT project file (`simons_problem.gpr`)
- GNU Make

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
Running tests...
  PASS — 1.1 4 is power of two
  PASS — 1.2 8 is power of two
...
=== 39 passed, 0 failed ===
```

**Test Coverage:**

- Functional correctness (bijective/periodic function analysis, XOR/dot product over GF(2))
- Edge cases (power-of-two validations, small-domain inputs)
- Error handling (invalid table dimensions, mismatched vector lengths)
- Invariants (round-trip conversions, algebraic consistency)
