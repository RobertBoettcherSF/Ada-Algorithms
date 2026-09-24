# Fortuna PRNG (Ada 2023 Implementation)

This project contains a complete, strictly typed, zero-warning implementation of the Fortuna Cryptographically Secure Pseudorandom Number Generator (CSPRNG) as described by Bruce Schneier and Niels Ferguson, implemented entirely in Ada 2023 (ISO/IEC 8652:2023). It accurately implements the Fortuna Accumulator (32-pool distribution and interval reseeding), the Fortuna Generator (re-keying forward secrecy operations), and Seed File mechanics. A simulated internal cipher handles structural hashing/encryption, allowing the repository to remain entirely self-contained without risking C-dependency issues.

### Features
* **Accumulator Variant**: 32 distinct entropy pools with cascading 2^k cyclic reseed integration rules.
* **Generator Variant**: Counter-based generation with immediate automated rekeying per-request (forward secrecy guarantees).
* **Seed File Control**: Safe persistence mechanisms bounded to exactly 64 bytes.
* **Design by Contract**: Robust parameter boundaries enforced directly via Ada 2022/2023 `Pre` and `Post` conditions.
* **Safe Typing**: Strong scalar limitations and custom subtypes (`Request_Size`, `Event_Size`, `Pool_Index`) nullify runtime buffer flaws natively.

### Usage
Build and run the executable using the provided Makefile. The test suite serves as the executable and directly demonstrates API interactions and variant usage:

    make test

**Expected Output:**

    Running tests...
    TEST 1 — Initialization
      PASS — 1.1 Initially not seeded
      PASS — 1.2 Generate unseeded fails
      PASS — 1.3 Auto_Reseed on empty pools changes nothing
    ...
    ===  39 passed,  0 failed ===

### Testing
The comprehensive validation suite covers:
* **Functional Correctness**: Asserting cyclic reseeds, forward secrecy rotations, and file recovery.
* **Edge Cases**: Zero-byte requests, partial-block misalignment resolutions, and empty states.
* **Error Handling & Preconditions**: Violating event buffer thresholds and capturing native Ada exceptions.
* **State Invariants**: Guaranteeing generator independence across instantiated modules.

### Building
Prerequisites: GNAT toolchain supporting Ada 2022/2023 (gnatmake). 
Execute `make all` to assemble the binaries cleanly under `-gnatwa`.
