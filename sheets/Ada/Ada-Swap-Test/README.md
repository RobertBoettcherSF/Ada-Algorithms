# Swap Test Implementation in Ada 2023

## Overview

Production-grade Ada 2023 implementation of the quantum **Swap Test** algorithm. Computes overlap between quantum state vectors with exact analytical calculations, Monte Carlo simulations, and batched pairwise matrices for quantum ML applications.

## Features

- **Strong Typing**: `Complex_Num`, `State_Array`, `Probability`, `Shot_Count`, `Overlap_Value`
- **Ada Contracts**: Static verification via `Pre`/`Post` conditions
- **Algorithmic Variants**:
  - Exact analytical overlap: |⟨ψ₁|ψ₂⟩|²
  - Ancilla measurement probability: *P*(ancilla = 0)
  - Monte Carlo/shot-based simulation
  - Parameterized swap test (phase rotation θ)
  - Batched overlap matrix
- **Exception Safety**: `Invalid_State_Exception`, `Dimension_Mismatch_Exception`
- **Zero Warnings**: Fully compliant with `-gnatwa -gnat2022`

## Usage

### Building

**Prerequisites:**

- GNAT compiler (GCC 13+ or GNAT Community)
- Make

**Build:**

```bash
make
```

### Testing

Run the test suite:

```bash
make test
```

**Expected output:**

```
TEST 1 — Complex Magnitude Squared
  PASS — 1.1 Magnitude squared of 3 + 4i is 25
  PASS — 1.2 Magnitude squared of 0 + 0i is 0
  PASS — 1.3 Magnitude squared of 1 - i is 2
...
=== 42 passed, 0 failed ===
```

**Test Coverage:**

- Functional correctness (complex arithmetic, normalization, overlap computations)
- Edge cases (single-element states, boundary probabilities, zero-length vectors)
- Error handling (dimension mismatches, unnormalized states)
- Invariants (postconditions, range constraints)
