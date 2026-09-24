# Reed-Solomon Error Correction (Ada 2012)

A full Ada 2012 implementation of Reed-Solomon error correction over **GF(2⁸)**. Supports both **Original View** (non-systematic) and **BCH View** (systematic) encoding, with a complete decoding chain: Berlekamp-Massey, Chien Search, and Forney algorithm.

---

## Features

- **Original View Encoding**: Generates non-systematic codewords by evaluating messages as polynomials against roots of *α*.
- **BCH View Encoding**: Derives generator polynomials of arbitrary degree for systematic codewords (retains original message + parity symbols).
- **Syndrome Checking**: Validates codeword integrity against expected polynomial evaluation points.
- **Full Decoding Chain**:
  - Berlekamp-Massey: Finds error locator polynomial.
  - Chien Search: Computes roots.
  - Forney Algorithm: Computes error magnitudes and repairs corrupted bytes in-place.
- **Error Handling**: Raises `Decoding_Error` if corruption exceeds correctable capacity (⌊`ECC_Count / 2`⌋).

---

## Usage

### Building &amp; Testing

**Prerequisites**: GNAT (Ada 2012 compatible).

```sh
make test
```

**Expected Output**:  
All 13 test categories pass, confirming:

```
===  39 passed,  0 failed ===
```

---

## Testing

The test suite (`tests.adb`) validates:

- **Functional Correctness**: GF(2⁸) operations, polynomial evaluation/addition/convolution.
- **Data Integrity**: Cleanly encoded data yields zeroed syndromes and remains unaltered after decoding.
- **Error Recovery**: Injects corruption to verify Berlekamp-Massey and Forney phases resolve up to theoretical capacity.
- **Error Handling**: Hard-injects uncorrectable errors to ensure graceful failure (no infinite recursion or silent corruption).

---

## Building

- **Language Standard**: Ada 2012 (uses `pragma Preelaborate`, contract aspects `Pre`/`Post`, expression functions).
- **Makefile**: Invokes `gnatmake` with `-gnatwa -gnat2022` for strict parsing and zero warnings.
