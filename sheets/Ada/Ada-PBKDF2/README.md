# Ada 2023 PBKDF2 Implementation

A strict, type-safe, and pure Ada 2023 implementation of the Password-Based Key Derivation Functions (PBKDF) standardized in RFC 2898. The implementation leverages Ada generic packages to remain strictly orthogonal from any specific hashing or PRF (HMAC) dependency, permitting seamless integration into various constrained embedded and high-assurance architectures.

## Features

* **PBKDF1:** The classical standard algorithm enforcing output bounds tied directly to the primitive Hash function.
* **PBKDF2:** The modern successor utilizing PRFs for arbitrary key lengths constructed through iteration blocking. 
* **Zero Allocations & Generic Injections:** Requires no external cryptography dependencies. Supply your project's cryptographic interface (e.g. SHA-256) into the generic.
* **Ada 2023 Cleanliness:** Written specifically leveraging modern features (aggregate array initialization, contracts) with rigid precondition/postcondition specifications. Tested against strict `-gnatwa` constraints.

## Usage

This project utilizes a `Makefile` referencing a GNAT `.gpr` file. The entrypoint builds and strictly exercises `tests.adb` serving dually as the API usage example. 

```bash
make test
```

**Expected Output:**

```text
Running tests...
Starting PBKDF1 and PBKDF2 test suite...
========================================
TEST 1 - PBKDF2 Length Correctness
  PASS - 1.1 Partial block (1 byte) returned correctly
  PASS - 1.2 Exact block size (4 bytes) returned correctly
  PASS - 1.3 Spanning blocks (10 bytes) returned correctly
TEST 2 - PBKDF2 Determinism
...
===  39 passed,  0 failed ===
```

## Testing Methodology

The comprehensive test suite features 13 behavioral tests evaluating both derivation algorithms via dummy `Mock_Hash` and `Mock_PRF` functions providing deterministic execution environments:

1. **Output Bounds**: Guaranteeing block extraction appropriately truncates arbitrarily long requested key iterations.
2. **Determinism**: Identical salts + iterations mathematically reconstruct identical byte sequences.
3. **Prefix Stability**: Deriving an $N$-length key guarantees its first $N/2$ bytes strictly equal deriving an $N/2$-length key.
4. **Algorithmic Bounds Checking**: Validating expected named exceptions (`Derived_Key_Too_Long`) properly halt illegal PBKDF1 states.
5. **Bitwise Arithmetic Functions**: Endian-shifting operations heavily vetted against literal data sets.

## Building & Prerequisites

* **Compiler Requirement**: A GNAT toolchain supporting `-gnat2022` (equivalent to Ada 2023 / ISO/IEC 8652:2023 draft standards).
* **Build environment**: GNU Make.
