# Salsa20 Stream Cipher in Ada 2023

---

## Project Overview

This project provides a robust, complete, and compile-ready implementation of the **Salsa20** stream cipher in **Ada 2023** (ISO/IEC 8652:2023). Designed around strong typing and strict GNAT warnings (`-gnatwa`), it implements all standard variants including Salsa20/20, Salsa20/12, Salsa20/8, 128-bit and 256-bit key setups, and general even-round parameterization based on Daniel J. Bernstein's ARX (Add-Rotate-XOR) design.

---

## Features

- **Multiple Variants:** Support for 20-round (standard), 12-round, and 8-round variants with 256-bit keys, as well as 128-bit key variants.
- **General Round Parameterization:** `Encrypt_General` supports any arbitrary positive even round count.
- **Direct Block Generation:** `Generate_Block` allows raw 64-byte keystream generation.
- **Strong Typing:** Custom modular types (`Byte`, `Word`) and domain-specific array subtypes (`Key_256`, `Key_128`, `Nonce_64`, `Block_Bytes`, `Byte_Array`) prevent misuse.
- **Ada Contracts:** Explicit `Pre` and `Post` aspects guaranteeing safety invariants (e.g., matching buffer lengths and even round counts).
- **Comprehensive Test Suite:** 13 rigorous test categories covering functional correctness, edge cases (empty inputs, single bytes, multi-block streaming), error handling, and diffusion properties.

---

## Building and Usage

**Prerequisites:** GNAT compiler supporting Ada 2022/2023 (`gnatmake`).

To build and run the test suite:

```bash
make test
```

To clean build artifacts:

```bash
make clean
```

**Expected Output:**  
When running `make test`, the test suite executes all 13 test cases (covering 39+ assertions) and confirms zero failures:

```plaintext
Running tests...
  PASS — 1.1 Ciphertext differs from plaintext
  PASS — 1.2 Decrypted text matches original plaintext
  PASS — 1.3 Output length correct
  ...
  PASS — 13.3 Edge case arithmetic robust

===  39 passed,   0 failed ===
```

---

## Testing &amp; Validation

The test suite (`tests.adb`) validates:

- **Functional Correctness &amp; Symmetry:** Encryption and decryption round-trips across all round counts and key sizes.
- **Edge Cases:** Handling of zero-length inputs, single-byte streams, and multi-block buffers spanning multiple counter increments.
- **Error Handling:** Verification that invalid parameters (such as odd round counts or mismatched buffer lengths) raise named exceptions (`Invalid_Round_Count`, `Invalid_Data_Length`).
- **Diffusion &amp; Determinism:** Verification that changing nonces or keys alters ciphertext appropriately, while identical parameters yield deterministic streams.
