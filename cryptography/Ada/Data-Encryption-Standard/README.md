# Data Encryption Standard (DES) &amp; Triple DES in Ada 2023

---

## Project Overview

This repository provides a fully functioning, highly strict, and robust Ada 2023 implementation of the **Data Encryption Standard (DES)** algorithm, alongside its successor, **Triple DES (3DES)**. Implementing natively over securely bound arrays of `Boolean` guarantees type safety, boundary checking without runtime overhead, and zero side-effects across all memory segments. Operations such as the Initial Permutation (IP), the Feistel rounds, and Key Scheduling are completely statically dimensioned.

---

## Features

- **Strong Typing:** Employs discrete constrained indices and native logical capabilities (`XOR`, etc.) over `Packed` `Boolean` arrays natively without runtime casting.
- **Single DES (Encryption/Decryption):** Fully compliant standard round processing and key scheduling mappings.
- **Triple DES (3DES):** Encrypt-Decrypt-Encrypt structural workflow compliant with 1-Key, 2-Key, and 3-Key operation parameters.
- **Key Validation:** Functions to expose algorithmically Weak Keys and parity check/correction systems.
- **Zero Warnings:** Compiles completely clean under strict GNAT compilation (`-gnatwa -gnat2022`).

---

## Building &amp; Usage

**Prerequisites:** A modern GNAT toolchain (FSF GCC or GNAT Pro) supporting the Ada 2022/2023 standard flag.

1. Build the program and test executable:
  ```bash
   make all
  ```
2. Run the executable tests:
  ```bash
   make test
  ```

You will see the output detailing each step, concluding with:

```plaintext
===  42 passed,  0 failed ===
```

---

## Testing

The suite strictly utilizes runtime constraints via an encapsulated testing structure to guarantee zero functional omissions. Test categories encompass:

- **Functional Correctness &amp; NIST Vectors:** Evaluates against statically verifiable historical vector values to confirm baseline mathematics.
- **Symmetry Check Constraints:** Verifies exact cyclical reversion (`Decrypt(Encrypt(P)) == P`).
- **Degradation Protocols:** Ensures exact algorithm performance in cases like Weak Keys (where E == D) and 3DES equivalence when K1=K2=K3.
- **Avalanche Assurance:** Validates systemic diffusion where one bit mutation causes macroscopic systemic deviation.
- **Exception Handlers:** Uses boundary enforcement algorithms directly testing internal exception signals (`Parity_Error`).
