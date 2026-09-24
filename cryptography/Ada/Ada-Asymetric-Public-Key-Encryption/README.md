# Asymmetric Key Algorithm (Textbook RSA Implementation in Ada 2023)

## Project Overview
This project provides a complete, robust, and verifiable implementation of asymmetric key cryptography (specifically textbook RSA) in Ada 2023 (ISO/IEC 8652:2023). Public-key cryptography utilizes two mathematically linked keys—a public key for encryption and key encapsulation, and a private key for decryption and digital signing—enabling secure communication over insecure channels without requiring prior shared secret keys.

## Features
- **Key Generation:** Generates public and private RSA key pairs from user-supplied distinct prime numbers with automatic public exponent selection and modular inverse calculation via the Extended Euclidean Algorithm.
- **Encryption & Decryption:** Supports mathematical message encryption using public keys and decryption using private keys with modular exponentiation (square-and-multiply algorithm).
- **Digital Signatures:** Provides signing capabilities using private keys and verification using public keys for authentication and integrity checking.
- **Strong Typing & Contracts:** Fully utilizes Ada 2023 strong typing, custom subtypes (Prime_Value, Key_Component, Message_Type), and pre/postconditions to guarantee domain safety and prevent invalid states.
- **Comprehensive Error Handling:** Explicit custom exceptions (Invalid_Prime_Error, Invalid_Key_Error) for robust error management.

## Usage
To build and execute the comprehensive test suite, run:

    make test

Expected output will show all individual test assertions passing with a summary line confirming zero failures.

## Testing
The test suite (tests.adb) implements 13 rigorous test categories, each containing 3 or more explicit assertions (pragma Assert-based checks):
1. **Prime Validation:** Verification of prime versus composite number checking.
2. **Key Generation Properties:** Correct modulus multiplication and exponent initialization.
3. **Encryption/Decryption Roundtrips:** Validation across small and medium message domains.
4. **Digital Signatures:** Creation, successful verification, and tampering detection (message and signature corruption).
5. **Exception Handling:** Robust catching of invalid prime inputs and identical prime parameters.
6. **Edge Cases:** Handling of boundary message values (0 and 1).
7. **Key Separation:** Verification that distinct key pairs do not cross-decrypt.

## Building
### Prerequisites
- GNAT compiler supporting Ada 2023 (GNAT 12 or newer recommended).
- GNU Make.

### Compilation Flags
Compiled under strict GNAT compiler warnings (-gnatwa -gnat2022).

    make all
