# Secret Sharing in Ada 2023

This project provides a robust, strictly-typed Ada 2023 implementation of cryptographic Secret Sharing algorithms. It implements two distinct variants of secret splitting and reconstruction as described in the theoretical cryptography literature: Shamir's Secret Sharing (a threshold $k$-out-of-$n$ scheme relying on polynomial interpolation over a finite prime field) and a Trivial Additive/XOR Sharing (an $n$-out-of-$n$ scheme relying on binary XOR operations).

## Features

* **Shamir's Secret Sharing (k-out-of-n):** Generates $N$ distinct shares using polynomial evaluation over the prime field $GF(2^{31}-1)$, allowing reconstruction using any subset of $K$ (Threshold) shares via Lagrange interpolation.
* **Additive/XOR Secret Sharing (n-out-of-n):** Provides an efficient bitwise algorithm splitting a 32-bit secret into $N$ parts, requiring all $N$ parts to reconstruct the original data word.
* **Ada 2022/2023 Aspects:** Built strictly using native Ada constraints, pre/post conditions (`Pre`, `Post`), and built-in modular types providing zero-overhead, mathematically exact field arithmetic.
* **Robust Error Handling:** Checks against malicious or accidental malformed data, such as attempting reconstruction with identical share IDs, mitigating division-by-zero runtime errors.

## Building

Prerequisites: A modern GNAT compiler supporting Ada 2022/2023 (e.g., GNAT FSF or GNAT Pro) and `make`.

To build the project:
```bash
make all
```

## Usage and Testing

The test suite (`tests.adb`) doubles as a living specification and integration test. It covers combinations of share generation, valid and invalid thresholds, varying share subsets, and edge cases (such as limits of the prime field).

To run the verification suite:
```bash
make test
```

**Expected Output:**
```text
Running tests...
Starting Secret Sharing Test Suite...
=====================================
TEST 1 — Shamir Basic Setup (N=5, T=3)
  PASS — 1.1 Split created exactly 5 shares
  PASS — 1.2 Reconstructed correctly from shares {1, 2, 3}
  PASS — 1.3 Reconstructed correctly from shares {3, 4, 5}
...
===  39 passed,  0 failed ===
```

These functional tests ensure high validation and correctness metrics. By checking edge inputs like single elements and mathematical bounds, the test suite guarantees that the polynomial field operations are implemented correctly without overflows, establishing high confidence in the underlying arithmetic.
