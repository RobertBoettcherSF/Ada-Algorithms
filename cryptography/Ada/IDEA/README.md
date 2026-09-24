# International Data Encryption Algorithm (IDEA) in Ada 2023

---

## Project Overview

This repository contains a full, standalone, and strictly-typed implementation of the **International Data Encryption Algorithm (IDEA)** block cipher in Ada 2023 (ISO/IEC 8652:2023). It executes all core algorithm variants, including encryption operations, decryption operations, dynamic subkey schedule generation (52 keys generated from the 128-bit master key), and both full-round and half-round variants.

---

## Features

- **Full Algorithmic Coverage:** Encrypt, decrypt, subkey expansion, and inverse subkey derivation algorithms correctly implemented.
- **Strict Typing &amp; Strong Contracts:** Employs mathematically-bounded modulo typing (`Word16`, `Word32`) preventing silent overflows. `Pre`, `Post`, and `Global` aspects apply strict execution invariants.
- **Complex Mathematics Resolved:** Includes exact programmatic mappings for multiplication modulo *216 + 1*, additive inverses modulo *216*, and Extended Euclidean computation for multiplicative inverses.
- **Zero Warning Footprint:** Assured zero warnings when compiling under strict flag rules (`-gnatwa`).
- **Standalone Verification:** Ships with a monolithic test application bypassing the need for an interactive executable, utilizing native Ada assertions.

---

## Usage

No external dependencies are required other than an Ada 2022+ compiler (like GNAT). Execution operates through the provided Makefile.

To build and run the test suite (acting as the usage demonstration program):

```bash
make test
```

**Expected Output:**

```plaintext
Running tests...
===================================================
 IDEA Algorithm Test Suite and Usage Demonstrations 
===================================================
...
  PASS — 13.1 Too short string throws format exception
  PASS — 13.2 Too long string throws format exception
  PASS — 13.3 Invalid hex characters throw format exception

===  39 passed,  0 failed ===
```

---

## Testing

The `tests.adb` acts as the definitive usage entrypoint, establishing execution validation against 13 specific test matrices (39 total checks). Testing validates functional correctness, encryption/decryption state isolation round-trips (using varying high-entropy data topologies), programmatic mathematical limit-bounding, and deliberate exception testing for input formatting (e.g., invalid string conversion checks). This ensures absolute robustness required for verifiable software constructs.

---

## Building

**Prerequisites:** GNAT Toolchain configured for Ada 2022/2023 (`-gnat2022`).

Just type `make` or `make test` at the root directory. To clean compilation artifacts, use `make clean`.
