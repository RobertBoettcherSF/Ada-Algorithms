# Project Overview
This repository provides a complete, robust, and compile-clean implementation of ElGamal public-key cryptography in Ada 2023 (ISO/IEC 8652:2023). It implements asymmetric encryption, decryption, homomorphic ciphertext multiplication, and the ElGamal digital signature scheme over prime finite field arithmetic.

# Features
- Key generation supporting arbitrary generators and private keys within a prime field.
- Secure message encryption and decryption using ephemeral keys.
- Homomorphic multiplication of ciphertexts reflecting plaintext multiplication.
- ElGamal digital signature generation and verification.
- Comprehensive contract-based programming (`Pre`/`Post` conditions) and strict typing.
- Warning-clean compilation under `-gnatwa -gnat2022`.

# Usage
Run `make test` to compile the test suite and execute all verification checks. Expected output will display status PASS for all assertions across 13 test categories.

# Testing
The standalone test suite (`tests.adb`) covers 13 distinct categories with 3 or more assertions each (totaling over 39 assertions). Tested categories include modular exponentiation, greatest common divisor calculations, modular inversion, key generation invariants, encryption/decryption roundtrips, homomorphic properties, signature generation and verification, invalid signature detection, edge cases (zero and large messages), error handling for invalid ciphertexts, non-invertible elements, and multi-key consistency. These tests ensure rigorous cryptographic correctness and adherence to specification invariants.

# Building
Prerequisites: GNAT compiler supporting Ada 2023 (ISO/IEC 8652:2023). Build using `make` or directly via `gnatmake -gnatwa -gnat2022 -Pelgamal_encryption.gpr`.
