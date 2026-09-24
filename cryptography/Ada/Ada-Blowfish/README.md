# Blowfish Cipher in Ada 2023

## Project Overview
This repository contains a complete, robust, and cleanly compiled implementation of Bruce Schneier's Blowfish cipher in Ada 2023. Blowfish is a symmetric-key block cipher consisting of a 16-round Feistel network parameterized by heavily key-dependent S-boxes. The implementation accurately models the algorithm's variable key length requirements (32 bits to 448 bits), implements its Pi-fractional complex key schedule efficiently, and exposes primitive 64-bit transformations mapped to multiple cryptographic variants.

## Features
- **Key Setup Mechanism:** Dynamic expansion to populate the internal P-array and S-boxes (supports arbitrary 4-byte to 56-byte keys bounds safely).
- **Core Block Operations:** Direct `Encrypt` and `Decrypt` symmetric subprograms targeting raw dual 32-bit representations.
- **Electronic Codebook (ECB) Mode:** Variant handlers encrypting and decrypting sequences linearly aligned to 64-bit bounds.
- **Cipher Block Chaining (CBC) Mode:** Standard-compliant multi-block stream operation coupled with functional Initialization Vectors mapping feedback loops.
- **Strong Typing Isolation:** Submits to severe compiler constraints through explicit `mod 2**32` and `mod 2**8` architectures, preventing silent overflow truncations.
- **Ada Contracts and SPARK Signals:** Implements `Pre` boundary conditions and states globally isolated operations (`Global => null`).

## Building
This configuration strictly adheres to standard Ada 2023 environments (GNAT compiler suite) demanding zero-warning strict compilation.

```bash
make
```
**Prerequisites:** GNAT toolchain (via Alire or GNAT-FSF) and standard Unix Make.

## Usage
The library API operations are detailed operationally in the provided `tests.adb`. Rather than relying on a sparse main execution shell, the tests double identically as exhaustive documentation on invoking initialization, context storage, primitive execution, ECB execution, and byte packing.

```bash
make test
```
**Expected Output:**

```text
Running tests...
TEST 1 — Initialization (Normal)
  PASS — 1.1 Setup_Key completes normally
...
=== 39 passed, 0 failed ===
```

## Testing
13 unique test vectors validate all logic variants and defensive edge constraints:

- **KAT Compliance (Known Answer Tests):** Executes encryption and decryption against authoritative IETF documented test vectors preventing regression (e.g. Empty constraints, full FF sets).
- **Symmetrical Cohesion:** Random payloads chained forward and reversed deeply verify internal permutations map 1:1 precisely.
- **Boundary Enforcements:** Strains the lower-limit (32 bits) and maximal-limit (448 bits) sizes validating buffer stability.
- **Defensive API Error Traps:** Simulates buffer alignment overlaps forcing `Invalid_Data_Length` or triggering SPARK `Ada.Assertions.Assertion_Error` states ensuring bad requests physically cannot propagate unaligned data execution streams.
