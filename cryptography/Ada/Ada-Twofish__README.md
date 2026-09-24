# Twofish Cipher Implementation in Ada 2023

---

## Project Overview

This project provides a robust, complete, and fully compilable implementation of the **Twofish** symmetric key block cipher in Ada 2023 (ISO/IEC 8652:2023). Twofish is a 128-bit block cipher supporting variable key lengths of 128, 192, and 256 bits, structured around a 16-round Feistel network with key-dependent S-boxes, a Maximum Distance Separable (MDS) matrix, Pseudo-Hadamard Transforms (PHT), and whitening steps.

---

## Features

- **Strong Typing:** Strict domain types (`Byte`, `Word32`, `Byte_Array`, `Word_Array`, `Key_128_Bytes`, `Key_192_Bytes`, `Key_256_Bytes`, `Block_Bytes`, `Block_Words`) using `Interfaces` unsigned types.
- **Contract-Based Programming:** Annotated public subprograms with `Pre` and `Post` conditions ensuring correctness of parameter bounds and context states.
- **Key Length Variants:** Full support for 128-bit, 192-bit, and 256-bit key setup and expansion.
- **Comprehensive Test Suite:** Includes 14 rigorous tests covering functional correctness, roundtrip integrity, avalanche effects, key sensitivity, boundary conditions, and context independence.

---

## Usage

To build and run the test suite, ensure you have a GNAT compiler supporting Ada 2023, then run:

```bash
make
make test
```

To clean up build artifacts:

```bash
make clean
```

**Expected Output:**  
When running `make test`, the test suite executes all verification assertions, prints individual pass/fail statuses, and confirms success:

```plaintext
Running tests...
  PASS — 1.1 Context key length is Key_128
  ...
  PASS — 14.3 Full 16-byte integrity verified
=== 42 passed, 0 failed ===
```

---

## Testing &amp; Validation

The test suite (`tests.adb`) verifies:

- **Functional Correctness:** Successful encryption and decryption across 128, 192, and 256-bit key schedules.
- **Roundtrip Invariants:** Ensuring `Decrypt(Key, Encrypt(Key, Plaintext)) = Plaintext`.
- **Avalanche Effect:** Verifying that altering plaintext bytes results in distinct ciphertexts.
- **Key Sensitivity:** Confirming that different keys produce completely different ciphertexts for the same plaintext.
- **Edge Cases:** Handling zero blocks, all-ones blocks, and boundary byte patterns.

---

## Building

**Prerequisites:** GNAT compiler with Ada 2023 support (`-gnat2022`).

**Compiler Flags:** `-gnatwa -gnat2022` (strict warnings enabled, zero warnings policy).
