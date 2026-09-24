# Argon2 Key Derivation Function in Ada 2023

## Project Overview
This project provides a robust, clean, and fully compilable Ada 2023 implementation of the Argon2 memory-hard key derivation function (standardized in RFC 9106 and winner of the Password Hashing Competition). Argon2 is designed for secure password hashing and key derivation, incorporating tunable memory consumption, execution time, and parallelism to resist both brute-force and side-channel attacks.

## Features
- **Three Core Variants:** Fully implements Argon2d (data-dependent addressing for TMTO resistance), Argon2i (data-independent addressing for side-channel resistance), and Argon2id (hybrid variant recommended by RFC 9106).
- **Strong Typing:** Domain-specific custom types and subtypes for memory cost, time cost, parallelism, tag length, variants, and byte arrays.
- **Contract-Based Programming:** Preconditions and postconditions (`Pre`, `Post`) on all public subprograms ensuring valid parameters and return invariants.
- **Robust Error Handling:** Named exceptions (`Invalid_Parameter`, `Invalid_Password`, `Invalid_Salt`, `Verification_Failed`) for invalid inputs and edge cases.
- **Comprehensive Test Suite:** Includes 14 rigorous tests covering functional correctness, parameter variations, verification success/failure, and exception handling.

## Building
Prerequisites:
- GNAT compiler with Ada 2023 support (`-gnat2022`).
- GNU Make.

To build the executable test suite:
```bash
make
```

## Usage and Testing
To run the test suite and verify implementation correctness:
```bash
make test
```

Expected output:
```text
Running tests...
=== Starting Argon2 Test Suite (ISO/IEC 8652:2023 / RFC 9106) ===
  PASS — TEST 1 — Argon2d Basic Hashing & Invariants ...
  ...
=== 42 passed, 0 failed ===
```

To clean build artifacts:
```bash
make clean
```

## Testing & Validation
The test suite (`tests.adb`) verifies:
1. **Functional Correctness:** Deterministic hash generation across all three variants (Argon2d, Argon2i, Argon2id) and generic dispatch.
2. **Parameter Variations:** Correct handling of varying password lengths, salt lengths, memory cost, time cost, and parallelism.
3. **Verification Logic:** Successful verification of matching credentials and robust rejection of mismatched passwords, salts, or hash lengths.
4. **Edge Cases & Error Handling:** Proper raising of named exceptions for empty passwords, insufficient salt lengths (< 8 bytes), and invalid memory cost configurations.
