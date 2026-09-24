# Diffie-Hellman Key Exchange (Ada 2023)

## Project Overview
This repository contains an expert, zero-warning implementation of the Diffie-Hellman Key Exchange algorithm in Ada 2023 (ISO/IEC 8652:2023). Based on the formal properties detailed on Wikipedia, the package robustly calculates public keys and shared secrets over multiplicative integer groups modulo p. It comprehensively supports Standard Two-Party Diffie-Hellman, Ephemeral Session Key Generation, and Multi-Party Diffie-Hellman ring protocols.

## Features
* Standard Two-Party Diffie-Hellman: Secure shared secret derivation between two parties.
* Multi-Party Diffie-Hellman: Specialized subprogram variants for chains spanning 3, 4, or more users.
* Constant-Time Safe Modular Arithmetic: `Mod_Mul_Safe` handles 64-bit products internally via the Russian Peasant algorithm to guarantee no standard overflow bounds are exceeded during exponentiation.
* Strong Typing: Specific types for Modulus, Base, Public Keys, and Private Keys to eradicate accidental cross-domain mixing.
* Defensive Security Checks: Preconditions and strict runtime parameter validation intercept non-compliant primitives and thwart Small Subgroup Attacks (NIST SP 800-56A compliant).

## Usage
The library is completely encapsulated within `diffie_hellman.ads` and `diffie_hellman.adb`. The test suite serves as the executable entry point illustrating practical instantiation. 

To run and verify:
$ make test

Expected output will iterate over 13 distinct functional blocks yielding:
  PASS — 1.1 Alice Public Key is 4
  ...
===  39 passed,  0 failed ===

## Testing
The standalone test runner (`tests.adb`) doubles as the integration guide. It evaluates the framework across four critical domains:
* Functional Correctness: Evaluates known modular equivalencies against standard Wikipedia examples.
* Variant Execution: Chains multi-party derivations to guarantee consistent cyclic resolution.
* Edge Cases: Stresses the module up to the maximum 64-bit unsigned bounds (Prime 2^64-59).
* Error Handling & Invariants: Actively catches deliberate security misconfigurations such as private keys out-of-bounds, unsafe public sub-group injections, and invalid cyclic bases, proving contract enforcement.

## Building
* Prerequisites: GNAT Toolchain (e.g., Alire/GNAT FSF).
* The Makefile enforces strict `-gnatwa` (all warnings) and targets Ada 2022/2023 constructs via `-gnat2022`.
* Call `make` to compile objects into `obj/` and the executable into `bin/`.
