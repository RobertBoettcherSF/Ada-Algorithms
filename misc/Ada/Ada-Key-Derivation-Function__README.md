# Key Derivation Functions (Ada 2023)

Project Overview: This package implements the standard cryptographic Key Derivation Function (KDF) algorithms described in general cryptographic specifications. KDFs derive one or more secret keys from a master secret, password, or key-exchange material. This self-contained Ada implementation includes a simulated PRF/HMAC primitive to demonstrate standard mechanisms without requiring external libraries.

Features:
* PBKDF2 Variant: Password-Based Key Derivation utilizing iterational hashing and salting to mitigate brute-force and dictionary attacks.
* HKDF Variant: HMAC-based Extract-and-Expand construction (RFC 5869) capable of extracting strong key material (PRK) from weak initial material and expanding it to any requested length.
* Simple KDF Variant: Direct hash-based construction appending block counters (similar to KDF1/KDF2/ANSI X9.63).
* Pure, strictly typed Ada 2023 arrays bounded safely to avoid memory vulnerabilities.
* Explicit contract-based design leveraging `Pre` and `Post` conditions to ensure safe operation.

Usage: 
To build and execute the demonstration test suite:
`make test`
You should expect an output displaying 14 distinct tests covering all function variants, generating output lines displaying "PASS" for 42 independent assertions, followed by a total summary indicating 0 failures.

Testing:
The test suite systematically verifies structural validation, bounds checking, and functional constraints:
* Functional Correctness: Deterministic generation, length compliance, iteration effects.
* Edge Cases: Passing empty data constraints (0-length Salt, Passwords, Keys), boundary sizes, crossing internal block boundaries gracefully.
* Error Handling & Invariants: Validating type system robustness by deliberately providing illegal lengths and lengths causing stack overflow or truncation (capturing custom Invalid_Length_Error and standard Constraint_Error exceptions natively). This rigorous methodology aligns deeply with zero-trust programming required for security components.

Building:
Requirements: GNAT Ada Compiler.
Compilation targets Ada 2022/2023 Standard (ISO/IEC 8652:2023) cleanly under `-gnatwa -gnat2022` with zero warnings generated.
