# Ada 2023 Digital Signature Algorithm (DSA) Implementation

## Project Overview
This repository contains an expert-level Ada 2023 (ISO/IEC 8652:2023) implementation of the Digital Signature Algorithm (DSA). It features strong typing, modular architecture, and enforces strict boundary condition invariants as pre/postconditions where applicable. The logic supports 32-bit prime spaces ensuring intermediate multiplication bounds safely fit into 64-bit mathematical spaces without unintended overflow, simulating a complete implementation. 

## Features
* **Standard / Preemptive DSA Signatures**: The base algorithm permitting manual / random assignment of the per-message secret `K`.
* **Deterministic / Dynamic DSA Signatures**: Simulates an RFC 6979 configuration whereby the signature generation dynamically evaluates `K` through the Private Key and hash components without external entropy.
* **Full Verification Coverage**: Extended Euclidean algorithms and exponentiation handlers reject corrupted, forged, or misconfigured key bindings automatically.
* **Strong Typing**: Employs `DSA_Value` throughout, preventing arbitrary integer blending and compiler ambiguity.

## Usage
The package strictly separates tests and execution to enforce usage clarity. To build and run the test suite, standard Make targets are provided.

    make test

Expected Output:

    Running tests...
    --- Starting DSA Implementation Tests ---
    TEST 1 — Modular Exponentiation Core
      PASS — 1.1 Standard: 4^7 mod 23 = 8
    ...
    ===  39 passed,  0 failed ===

## Testing
The suite inside `tests.adb` conducts 13 distinct test sets with 3+ assertions each (39 checks total):
* **Functional Correctness**: Validates modular exponentiation, modular inverses, generating properties, and the mathematical correctness of resulting (R, S) vectors.
* **Edge Cases & Invariants**: Intentionally forces conditions such as out-of-bounds modular configurations or non-coprime evaluations.
* **Error Handling**: Verifies custom package-defined exceptions dynamically intercept malformed configurations effectively prior to fault conditions.
* **Algorithm Constraints**: Explores boundaries ensuring signature components R=0, S=0, or vectors exceeding the Q bounding parameter appropriately break verification attempts.

## Building
* **Prerequisites**: GNAT compiler suite supporting the `-gnat2022` flag (Ada 2023 features).
* **Environment**: Unix-like `make` orchestration provided out of the box, fully conforming to strict compiler warnings via `-gnatwa` without pollution.
