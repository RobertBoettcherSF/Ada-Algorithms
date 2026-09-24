# NTRUEncrypt in Ada 2023

## Project Overview
This repository provides a complete, robust, and strongly-typed Ada 2023 (ISO/IEC 8652:2023) implementation of the NTRUEncrypt public-key cryptosystem. Operating over the truncated polynomial ring $\mathbb{Z}[X]/(X^N - 1)$, it faithfully demonstrates the primary variants and stages of the algorithm as described in standard cryptographic literature, resolving inverses via cyclic convolution matrices. 

## Features
* **Parameter Instantiation:** A generic architecture allowing developers to synthesize the NTRU cryptosystem for any strictly positive bounds (e.g. $N, p, q$).
* **Complete Algorithm Lifecycle:** Includes full implementations for `Generate_Key` (inverses mod $p$ and $q$), `Encrypt`, and `Decrypt` (with modulus centering).
* **Matrix-Driven Inversion:** Reliably resolves coefficient inverses modulo $q$ directly via Gaussian elimination on circulant matrices.
* **Safe and Validated:** Employs explicit sub-typing, custom definitions for mathematical constructs, strict SPARK-friendly boundaries (`Global => null`), and enforces error tracking via named exceptions.
* **Warning-Free Compilation:** Code maintains strict zero-warning compliance under GNAT `-gnatwa`.

## Usage
The `tests.adb` program natively behaves as both a complete validation test suite and the reference usage manual. It implements the exact $N=11, p=3, q=32$ theoretical standard parameters.
Execute it to test all operations end-to-end:

```bash
make test
```

**Expected Output:**

```text
=== NTRUEncrypt Test Suite ===
  PASS — 1. KeyGen: F_p matches Wikipedia expected value
  PASS — 2. KeyGen: F_q matches Wikipedia expected value
  PASS — 3. KeyGen: Public Key H matches Wikipedia expected value
  PASS — 4. Encrypt: Ciphertext E matches Wikipedia expected value
...
===  14 passed,  0 failed ===
```

## Testing
The embedded test suite exercises the implementation thoroughly ensuring total correctness:
* **Functional Correctness:** Ensures all cryptosystem outputs perfectly match published standard derivations (such as the Wikipedia reference polynomials step-by-step).
* **Edge Cases:** Validates wrap-around boundaries during coefficient centering operations (e.g., verifying limits of negative offsets for even-powered moduli).
* **Error Handling:** Formally tests exception propagation (`Not_Invertible`) protecting the key generation routines from structurally weak polynomial selections.
* **Invariants:** Demonstrates commutative properties and identity verifications of the cyclic convolution operations under strict generic instantiations.

## Building
**Prerequisites:** GNAT Toolchain configured for Ada 2022/2023 standard capability.
Standard `make` commands drive the `gprbuild`/`gnatmake` toolchain automatically.

```bash
make all      # Compiles all packages and tests
make test     # Executes the compiled binary
make clean    # Removes artifacts
```
