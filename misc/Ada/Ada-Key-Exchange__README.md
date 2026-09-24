# Ada Key Exchange Implementation (Ada 2023)

## Project Overview
This repository offers a robust, strict-typed Ada 2023 implementation of classical key exchange algorithms as conceptualized in standard cryptographic literature (like Diffie-Hellman, SPEKE, and Shamir's Three-Pass Protocol). It implements all necessary modular arithmetic from scratch, leveraging 64-bit bounds internally safely while exposing strongly-typed 32-bit interfaces for domain integrity. The code contains rigorous DbC (Design by Contract) properties such as Pre, Post, and Global aspects.

## Features
* **Anonymous Diffie-Hellman**: Implementation of the standard, unauthenticated key agreement protocol. Includes public key small-subgroup validation.
* **Password-Authenticated Key Agreement (PAKA/SPEKE)**: Prevents Man-in-the-Middle attacks by integrating a pre-shared password functionally substituted as the group generator.
* **Shamir's Three-Pass Protocol**: An application of commutative modular exponentiation allowing secure message exchange without any prior shared secrets or certified public keys.
* **Zero Dependencies**: Mathematical core (modular inverse, addition, multiplication, and exponentiation) implemented purely using base Ada language constructs. 
* **High Assurance**: Validated with `-gnata` and compiled seamlessly under strict `-gnatwa` warning checks.

## Usage
To execute the interactive test suite which doubles as our usage examples:

```bash
make test
```

**Expected Output:**
The system compiles the binaries cleanly and executes 13 comprehensive test clusters, resulting in `===  39 passed,  0 failed ===`.

## Testing
The embedded test suite (`tests.adb`) thoroughly verifies:
* **Functional Correctness**: Computations like `Modular_Exponentiation` and the symmetric property of the key exchanges return identically matched keys between the distinct simulated parties (Alice and Bob).
* **Edge Cases**: Zero conditions, wrap-arounds, trivial constants (e.g., M=1 or Private Keys=0).
* **Error Handling & Invariants**: Strictly enforced Pre-conditions and explicit named exceptions natively trigger (`Invalid_Parameters_Error`) when exposed to invalid domains like mathematically impossible modular inverses (non-coprimes) or sub-group vulnerable keys.

## Building
**Prerequisites:** GNAT toolchain (GCC Ada compiler).
This project dictates the **Ada 2023** standard (internal switch `-gnat2022`).

```bash
make all      # Builds bin/tests
make clean    # Eliminates build artifacts
```
