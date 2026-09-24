# HMAC (Keyed-Hash Message Authentication Code) in Ada 2023

## Project Overview
This repository provides a complete, strictly-typed implementation of the Keyed-Hash Message Authentication Code (HMAC) as defined in RFC 2104. The algorithm uses a cryptographic hash function in combination with a secret cryptographic key to verify both data integrity and authentication. By leveraging Ada 2023's powerful generic packages, this single implementation provides all hashing variants (e.g., HMAC-MD5, HMAC-SHA1, HMAC-SHA256) seamlessly; developers simply instantiate the package with their preferred hash algorithm, block size, and hash size.

## Features
* **Generic Cryptographic Backend:** Supports any underlying hash function via generic instantiation without hardcoded lengths or limitations.
* **Strong Typing:** Uses safe native bounds and custom subtypes (e.g., `Byte`, `Byte_Array`) to ensure domain safety instead of relying on loose `String` or `Integer` types.
* **All RFC 2104 Variants Handled Automatically:** 
  * Transparently handles short keys via standard zero-padding.
  * Transparently hashes extremely long keys down to block size.
* **Strict Contracts:** Employs Ada Pre, Post, and Global aspects for design-by-contract behavioral guarantees (e.g., ensuring Block Size always bounds Hash Size).
* **Two Frontends:** `Compute` evaluates native cryptologic `Byte_Array` variables, while `Compute_String` provides convenience wrappers for ASCII/Latin-1 conversions.

## Usage
To test the functionality in an isolated, pure-Ada runtime:

```bash
make test
```

**Expected Output:**

```text
Running tests...
=== Testing HMAC Variants & Edge Cases ===
TEST 1 — Normalize Short Key
  PASS — 1.1 K' length is block size (8)
  PASS — 1.2 First bytes match key
  PASS — 1.3 Remaining bytes are padded zero
...
===  39 passed,  0 failed ===
```

## Testing
The embedded test suite (`tests.adb`) achieves rigorous functional and structural testing without external crypto dependencies by utilizing a deterministic mock block-hash algorithm.

* **Functional Correctness:** Verifies padding mechanics (`ipad` and `opad` generation), output determinism, and array sizing limits.
* **Edge Cases:** Evaluates empty keys, empty messages, 1-byte arrays, massive strings, and exactly-block-sized data constraints.
* **RFC Invariants Validation:** Specifically tests the core equivalence property `HMAC(K, M) == HMAC(Hash(K), M)` for oversized keys, ensuring the algorithm mathematically aligns with specification rules.

## Building
**Prerequisites:**
* GNAT Ada Compiler (supporting Ada 2022/2023 constructs)
* Unix Make utility

Execute `make` to compile the library and test driver, then run `make clean` to scrub artifacts (`obj/` and `bin/`). Zero warnings guaranteed when compiled under `-gnatwa`.
