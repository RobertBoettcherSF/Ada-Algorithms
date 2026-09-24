# Blum Blum Shub Pseudorandom Number Generator in Ada 2023

## Project Overview
This project provides a complete, robust, and strongly typed implementation of the Blum Blum Shub (BBS) pseudorandom number generator in Ada 2023 (ISO/IEC 8652:2023). The BBS generator is a cryptographically secure pseudorandom number generator (CSPRNG) proposed in 1986 by Lenore Blum, Manuel Blum, and Michael Shub. Its security is based on the quadratic residuosity problem.

## Features
- **Strong Typing & Domain Types**: Custom subtypes (`Prime_Type`, `Modulus_Type`, `Seed_Type`) ensuring domain safety.
- **Comprehensive Parameter Validation**: Validates that prime factors p and q are true Blum primes (p ≡ 3 mod 4 and q ≡ 3 mod 4) and that the seed is coprime to M = p * q.
- **Multiple Output Variants**:
  - `Next_Bit`: Extracts individual bits (least significant bit of state squared mod M).
  - `Next_Byte`: Packs bits into 8-bit octets (`Unsigned_8`).
  - `Next_Bits`: Generates variable-length bit blocks (up to 64 bits).
  - `Peek_State`: Inspects the internal state without advancing the generator.
- **Ada Contracts**: Annotated with `Pre` and `Post` contract aspects.
- **Strict Compilation**: Clean compilation under GNAT with `-gnatwa -gnat2022`.

## Building and Running
Prerequisites: GNAT compiler supporting Ada 2023.

To build and run the comprehensive test suite:
```bash
make test
```

To clean build artifacts:
```bash
make clean
```

## Testing
The standalone test suite (`tests.adb`) contains 13 rigorous test categories with 39+ individual assertions covering:
- Functional correctness and determinism across generator instances.
- Parameter validation and exception handling (`Invalid_Parameters`, `Invalid_Seed`).
- Output variant verification (bits, bytes, bit blocks).
- State transition and boundary conditions.
- Scalability with larger Blum primes.
