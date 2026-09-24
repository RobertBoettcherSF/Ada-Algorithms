# Elliptic-Curve Diffie-Hellman (ECDH) in Ada 2023

This project provides an Ada 2023 implementation of the Elliptic-curve Diffie-Hellman (ECDH) key agreement protocol over prime fields. The core mathematics enforce rigorous validations of domain parameters and point operations natively via the standard `Ada.Numerics.Big_Numbers.Big_Integers` library (introduced in Ada 2022). It supports establishing secure shared secrets over insecure channels without transmitting the private keys.

### Features
*   **Arbitrary Precision Math**: Relies on built-in standard `Big_Integer` types with custom deterministic Modular Exponentiation preventing memory exhaustion.
*   **Protocol Variants Handled**:
    *   **Static ECDH**: Explicit endpoints leveraging long-term public and private keys.
    *   **Ephemeral ECDHE**: Session-unique key variants implementing perfect forward secrecy.
    *   **Anonymous ECDH**: Specialized subset where one party utilizes a static identity while the other utilizes an ephemeral connection identity.
*   **Secure API Contracts**: Defensive subprograms explicitly decorated with Ada 2022 `Pre` and `Post` contracts and comprehensive input sanitization that reliably emits strict, named exceptions (e.g. `Invalid_Domain_Parameters`, `Invalid_Point`).
*   **Fully Type-Safe**: Custom data typing for `Curve_Point` and `Domain_Parameters` ensuring isolated and logical abstractions.

### Usage
Executing the standalone test suite demonstrates practical API usage for domain configuration, key pair generation, and shared secret derivation matching. Running the build environment executes mathematical edge cases automatically.

Expected Output upon successful execution:

  PASS — 1.1 Domain parameters are valid mathematically
  PASS — 1.2 Curve prime is positive
  ... (Truncated for brevity) ...
  PASS — 13.2 Caught Invalid_Point for infinity point
  PASS — 13.3 Key agreement gracefully aborted bad peer points

===  39 passed,  0 failed ===


### Testing
To assure verification and protocol safety, 13 test categories evaluating 39 distinct mathematical and logical properties operate iteratively. Tested scenarios include:
*   Functional Correctness: Confirming scalar derivations via doubling vs. successive addition matches theoretically guaranteed cryptographic coordinates.
*   Variant Simulation: Enforcing that Static ECDH, Ephemeral ECDHE, and Anonymous ECDH variants cleanly and securely derive identical symmetrical secrets respectively.
*   Edge Cases & Invariants: Validating handling for points at Infinity, inverse addition yielding Infinity, and validating scalar parameters at interval boundaries.
*   Error Handling: Verifying that out-of-bounds private keys or off-curve forged public points immediately and cleanly abort execution via named exceptions.

### Building
**Prerequisites:** GNAT compiler supporting at least Ada 2022/2023 (e.g., GCC 12+ or GNAT Community).

Run tests directly using make:

    make test

Clean up object files and executables:

    make clean
