# Ada 2023 ECDSA Implementation

## Project Overview
This repository contains a complete, strictly-typed implementation of the Elliptic Curve Digital Signature Algorithm (ECDSA) written in standard Ada 2023 (ISO/IEC 8652:2023). It executes over a custom generic finite prime field, explicitly defining necessary properties of Elliptic Curves and domain parameters. The suite accurately mimics the step-by-step cryptographic mathematics laid out by standard specifications, successfully handling point addition, doubling, double-and-add scalar multiplication, and modular inverses without reliance on external big-integer libraries (implemented over small verifiable primes for architectural demonstration). 

## Features
*   **Key Generation:** Deterministic derivation of the Elliptic Curve Public Key (`Q`) from a scalar Private Key (`D`).
*   **Signature Generation:** Secure derivation of an `(R, S)` signature via mathematically rigorous steps. It includes robust failure handling specifically aligned with ECDSA specifications, raising a targeted `Retry_K_Error` during highly improbable R=0 or S=0 edge cases.
*   **Signature Verification:** Implementation of complete algebraic verification confirming that point extraction authentically matches the signature sequence mathematically.
*   **Safety & Contracts:** Features full Ada `Pre` and `Post` contract integrations, eliminating edge-case states before execution. Custom `Value_Type` abstractions prevent variable overflow during transitional modulo multiplications.

## Usage
Execute the test suite to observe exactly how parameter assignment and signatures interact mathematically:

    make test

**Expected Output:**
The program will evaluate 16 distinct test suites logging `PASS` for each constituent assertion (48 total checks), concluding with:
`===  48 passed,  0 failed ===`

## Testing
The standalone test executable (`tests.adb`) doubles as our integration documentation. Testing covers:
*   **Modular Arithmetic Correctness:** Demonstrates fundamental Field Mathematics including additive inverses and the Extended Euclidean algorithm natively.
*   **Curve Operation Reliability:** Asserts expected geometric behavior for distinct Point Addition, Point Doubling, and resolving the Point at Infinity boundary.
*   **Algorithmic Verification:** Runs fully symmetric end-to-end ECDSA key-generation, signature generation, and verification cycles using validated parameters.
*   **Failure & Edge Cases Handling:** Recreates improbable situations requiring a signature retry (R=0 and S=0) validating that custom exceptions raise flawlessly, and ensures out-of-bound signature tampering resolves to `False`.

## Building
**Prerequisites:** GNAT Toolchain (GCC-based Ada compiler).
Ensure you build via the provided Makefile to apply strict warning detection and compatibility flags (`-gnatwa` and `-gnat2022`/Ada2023):

    make all
