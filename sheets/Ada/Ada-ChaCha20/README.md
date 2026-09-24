# Ada 2023 ChaCha Implementation

## Project Overview
This repository contains a complete, strongly-typed Ada 2023 (ISO/IEC 8652:2023) implementation of the ChaCha stream cipher. It offers the widely standardized IETF RFC 7539 variant (256-bit key, 96-bit nonce, 32-bit counter) as well as the original Bernstein variant (256-bit key, 64-bit nonce, 64-bit counter). The algorithm operates cleanly in a memory-safe context without pointer math, relying entirely on Ada's strong bounds checking and contract aspects.

## Features
* **Full Protocol Variants:** Choose natively between `Encrypt_IETF` and `Encrypt_Original`.
* **Dynamic Round Capabilities:** Supports `ChaCha8`, `ChaCha12`, and `ChaCha20` round specifications via a strongly-typed Enum parameter.
* **Strong Typing:** `Key_256`, `Nonce_96`, and `Nonce_64` are distinct domain subtypes, enforcing length invariants at compilation/runtime limit checks.
* **Edge-case Safety:** Robust internal block chunking operates gracefully for non-aligned data, single-byte slices, and strictly-empty vectors. 
* **Zero Warnings:** Completely `-gnatwa` compliant without suppressing rules.

## Building
**Prerequisites:** GNAT Toolchain configured for Ada 2022/2023.

```bash
make test
```

## Testing
The `tests.adb` test suite acts as both unit verification and a usage example. It will automatically build and execute exactly 13 individual tests with a total of 42 distinct assertions.

* **Functional Correctness:** Ensures deterministic quarter-round execution aligns with official IETF documentation test vectors.
* **Edge Cases:** Validates cipher identity properties by ensuring that exact values are reinstated and confirms operation stability against zero-length inputs without crashing or bounding faults.
* **Invariants & Types:** Verifies that internal index limits operate predictably and bounds definitions adhere accurately to the type contracts.

**Expected Output:**

```text
Running tests...
TEST 1 — Quarter Round Functional Correctness
  PASS — 1.1 Word A matching RFC
  PASS — 1.2 Word B matching RFC
...
===  42 passed,  0 failed ===
```
