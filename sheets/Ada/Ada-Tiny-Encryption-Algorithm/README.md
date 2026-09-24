# Tiny Encryption Algorithm (Ada 2023 Implementation)

---

## Project Overview

This project provides a robust, strongly-typed Ada 2023 implementation of the **Tiny Encryption Algorithm (TEA)** family of cryptography tools. Built exactly against the design specifications documented on Wikipedia, it encompasses the original TEA algorithm, the eXtended TEA (XTEA) which addresses key schedule weaknesses, and the Corrected Block TEA (XXTEA) which efficiently scales for variable-length arbitrary data block sizes using its intricate mixing function (MX).

---

## Features

- **TEA (Tiny Encryption Algorithm):** Base 64-bit block cryptography employing a 128-bit key and 64 Feistel rounds (32 cycles).
- **XTEA (eXtended TEA):** Reordered shifts and XORs mitigating equivalent key weaknesses present in original TEA, offering adjustable cycle parameters.
- **XXTEA (Corrected Block TEA):** Dynamic variable-length block support (64-bits or larger arrays of 32-bit words). Employs specialized bound mapping logic that transparently accepts arbitrary `First`/`Last` range definitions in Ada.
- **High Assurance Design:** Rigorous Ada contracts, comprehensive custom types eliminating bare-integer logic errors, inline documentation, completely warning-free compilation (`-gnatwa`), and explicitly crafted error exception handling (`Invalid_Block_Size`).

---

## Usage

Simply clone this repository and trigger the `Makefile`.

```bash
make test
```

The console will build the testing framework natively into `bin/tests` and execute a suite producing detailed structural verifications:

**Expected Output:**

```plaintext
Running tests...
TEST 1 - TEA Basic Zero
  PASS - 1.1 Encrypt alters data
  PASS - 1.2 First word is non-zero (deterministic check)
  PASS - 1.3 Decrypt cleanly restores data
...
===  42 passed,  0 failed ===
```

---

## Testing

This test suite inherently acts as an active usage demonstrator (`tests.adb`).

- **Functional Correctness:** Verifies data determinism, round-tripping symmetric encryption/decryption on zeros and heavily patterned blocks.
- **Avalanche Edge Cases:** Includes specialized tests asserting 1-bit adjustments to keys (TEA) or layout data (XXTEA) cleanly propagate robust changes masking out the primary payloads.
- **Bounds &amp; Invariant Enforcement:** Verifies explicit mapping protections regarding non-zero array bounds mapping (arrays indexed 100 .. 103) without throwing out-of-range index errors.
- **Error Handling:** Actively ensures that structural layout preconditions dynamically trap and safely reject invalid array parameters shorter than 64 bits (size &lt; 2).

---

## Building

**Prerequisites:** GNAT compiler supporting the Ada 2022/2023 language standards (`-gnat2022` or later). Standard GNU Make.

```bash
make clean
make all
```
