# Ada 2023 Post-Quantum Cryptography (LWE)

---

## Project Overview

This repository provides a self-contained, cryptographically representative implementation of a **Learning With Errors (LWE)** public-key encryption scheme in Ada 2023. LWE forms the primary lattice-based basis for modern post-quantum cryptography standards (like ML-KEM). To satisfy structural system design requirements, the scheme is segmented into distinct variants covering static/deterministic vs. dynamic key generation, and preemptive/single-bit vs. non-preemptive/batch multi-bit encryption processing.

---

## Features

- **Static/Deterministic Variant:** Allows explicitly setting `A`, `S`, and error `E` vectors for exact reproducible cryptographic scenarios.
- **Dynamic Variant:** Leverages system pseudorandom entropy to dynamically build unpredictable private `S` dimensions.
- **Preemptive Variant (Single-Bit):** Cryptographically targets the exact threshold mapping formulas against a single plaintext bit.
- **Non-Preemptive Variant (Batch):** Seamlessly operates on generic sized `Bit_Array` types enforcing lengths via formal Ada 2023 `Pre`/`Post` bounds.
- **No Dependency Purity:** Entirely implemented without `Big_Int` or external cryptographic libraries.
- **Zero Warning Policy:** Strictly conforms to `-gnatwa`.

---

## Building

**Prerequisites:** GNAT Toolchain configured for Ada 2022/2023 compatibility (`-gnat2022`).

Build the test suite by running:

```bash
make
```

---

## Testing

To run the automated suite:

```bash
make test
```

---

## Coverage

The suite (`tests.adb`) comprises 14 extensive tests (42 assertions) targeting:

- **Functional Correctness:** Encryption mathematical symmetry across different vectors and lengths.
- **Edge Cases:** Verifying exact error bounds mathematically mapping to 63 vs 64 (the LWE 0/1 decision threshold boundary in Mod 256).
- **Error Handling:** Testing how the package contracts and guards explicitly halt empty lengths or invalid data.
- **Invariants:** Validating cryptographic entropy diverges when operating on different seeds but maintains exact reproducibility on identical seeds.
