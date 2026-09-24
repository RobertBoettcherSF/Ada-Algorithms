# Elliptic Curve Cryptography in Ada 2023

## Project Overview
This project provides a robust, standalone Ada 2023 implementation of Elliptic Curve Cryptography (ECC) operations over finite fields (F_p). It models curves in the standard Weierstrass form (y^2 = x^3 + ax + b mod p) and includes fundamental operations critical to modern cryptography such as point addition, point doubling, and scalar multiplication (using the double-and-add algorithm). The implementation utilizes strong typing to prevent representation errors and employs Ada 2022/2023 contracts (Pre, Post, Global) to guarantee mathematically valid states across computations. 

## Features
* Curve Validation: Rejects cryptographically invalid curves (i.e. those with a discriminant of 0).
* Point Operations: Includes mathematically sound Point Addition and Point Doubling.
* Scalar Multiplication: Efficient Double-and-Add mechanism for producing public keys and shared secrets.
* Extended Euclidean Algorithm: Safely calculates the modular inverse for field division.
* Identity Handling: Properly represents and propagates the Point at Infinity in all geometric functions.
* Contract-Driven Design: Leverages Ada's Design-by-Contract features to assert that inputs and outputs remain on the curve dynamically.

## Usage
The code compiles into a test harness (tests.adb) which acts as both the validation suite and the API usage example. To build and run, execute "make test".

Expected Output:
The executable will output a series of PASS logs verifying valid curves, modular arithmetic constraints, coordinate mathematics, and a simulated Diffie-Hellman Key Exchange. It will conclude with "=== 39 passed, 0 failed ===".

## Testing
The standalone test suite implements 13 distinct categories, executing at least 3 assertions each (39 checks total). Categories covered:
* Functional Correctness: Explicit tracing of point multiples and Diffie-Hellman shared secret alignments.
* Edge Cases: Asserts identity operations against the Point at Infinity and handles tangent-line operations when Y = 0.
* Error Handling: Validates expected behaviors for division-by-zero constraints (Not_Invertible_Error).
* Invariants: Continuously guarantees that points returned by cryptographic manipulations natively resolve to the Weierstrass equation of the curve parameterized.

## Building
Prerequisites: GNAT Toolchain
Language Standard: Ada 2023 (compiled using -gnat2022 as implemented in standard GNAT releases to support ISO/IEC 8652:2023 features).
