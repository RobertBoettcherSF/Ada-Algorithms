# Shor's Algorithm in Ada 2023

## Overview

Production-grade Ada 2023 implementation of **Shor's Algorithm** for integer factorization, discrete logarithms, and period-finding. Implements classical reduction steps, modular arithmetic, order-finding, and deterministic execution with rigorous testing.

## Features

- **Period-Finding (Order-Finding)**: Smallest positive integer *r* such that *ar ≡ 1 mod N* for coprime *a* and *N*
- **Integer Factorization**: Reduces factorization to order-finding via modular exponentiation and GCD
- **Discrete Logarithm Problem**: Solves *gx ≡ h mod p* for prime moduli
- **Strong Typing**: `Number`, `Exponent`, `Period_Result`, `Factor_Pair`
- **Ada Contract Aspects**: Extensive `Pre`/`Post` conditions
- **Error Handling**: `Invalid_Argument`, `Factorization_Failed`, `Order_Not_Found`, `Discrete_Log_Failed`

## Usage

### Building

**Prerequisites:**

- GNAT compiler with Ada 2023 support (`-gnat2022`)

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
=== STARTING SHOR'S ALGORITHM TEST SUITE ===
  PASS — GCD Functional Correctness
...
=== 39 passed, 0 failed ===
```

**Test Coverage:**

- Functional correctness (GCD, modular exponentiation, period finding, factoring composites: 15, 21, 35, 77, discrete logarithms)
- Edge cases (zero values, modulus 1, even numbers, small/boundary inputs)
- Error handling (invalid arguments, non-coprime orders)
- Invariants (factor product correctness, period positivity)
