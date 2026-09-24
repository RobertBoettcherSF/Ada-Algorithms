# SHA-3 (Keccak) in Ada 2023

## Project Overview
This project provides a robust, standalone implementation of the SHA-3 cryptographic hash family (Keccak) natively in Ada 2023. Based on ISO/IEC 8652:2023 and FIPS 202 specifications, the implementation supports all primary output bit lengths for fixed hashes (SHA3-224, SHA3-256, SHA3-384, SHA3-512) as well as the dynamically sized extendable-output functions (SHAKE-128, SHAKE-256).

## Features
* **Complete Algorithm Suite**: Implements all 6 standard variants (SHA3-224/256/384/512 and SHAKE-128/256).
* **Strong Typing**: Uses strict modular types for internal state bounds and byte arrays, avoiding unsafe bitwise conversions.
* **Ada Contract Support**: Annotated with `Pre`, `Post`, and `Global => null` conditions ensuring algorithmic purity and strict output length enforcement.
* **Standalone Execution**: Does not rely on any third-party external dependencies, cryptography libraries, or C bindings.
* **Robust Edge-Case Handling**: Safely processes multi-block inputs, zero-length files, massive XOF sequence squeezing, and block-boundary paddings via the pure Keccak sponge engine.

## Building
1. Ensure you have GNAT installed (tested with GNAT Community / GCC 12+).
2. The project compiles strictly enforcing the Ada 2022/2023 specification via the `-gnat2022` flag.
3. Strict warning policies (`-gnatwa`) are applied—the implementation emits zero warnings.

    make

## Usage and Testing
The project lacks a standard executable `main.adb`. Instead, `tests.adb` functions as both the test suite and an extensive usage example. The suite acts as a demonstration of API interaction.

    make test

### Expected Output
The system verifies against NIST standard test vectors. When run, it outputs detailed pass/fail diagnostics.

    Running tests...
    TEST 1 — SHA3-224 Empty Message
      PASS — 1.1 Length constraint met
      PASS — 1.2 First bound check
      PASS — 1.3 Matches NIST empty vector
    ...
    ===  42 passed,  0 failed ===

### Verification and Validation
Testing categories explicitly span:

* **Functional Correctness**: Exact matches against NIST FIPS 202 test vectors (empty messages and known substrings).
* **Sponge Extensibility**: Multi-block absorbs for long streams (surpassing 136-byte bounds) and multi-block squeezing for SHAKE XOF implementations requesting large outputs.
* **Edge Cases**: Zero-length output requests safely circumvent the engine with standard empty-array initialization rather than triggering constraint exceptions.
