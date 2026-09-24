# LZJB Ada Implementation

## Project Overview
This project provides a robust, native Ada implementation of the Lempel-Ziv Jeff Bonwick (LZJB) lossless data compression algorithm. Originally engineered for the ZFS filesystem to achieve rapid crash dump and block-level compression, it features a sliding-window lookup leveraging a bit-encoded control byte (0 = Literal byte, 1 = 2-byte Match/Offset encoding).

## Features
- **LZJB Compression (`Compress`):** Implements dynamic sliding dictionary lookups using XOR hashing to achieve rapid O(1) subset matches. Handles payloads with a dynamic, heap-bound output slicing to fit exact dimensions.
- **LZJB Decompression (`Decompress`):** Implements the inverse decoding map securely. Mandates `Expected_Size` validation, natively repelling buffer-overflow tampering vectors inherent to LZ algorithms.
- **Strong Typing & Safety Constraints:** Utilizes precise `Byte` module variants masking, explicit boundary checking on every shift offset, and custom exceptions (`LZJB_Error`) for stream corruption detection.

## Testing
This codebase is governed by a destructive-assumption Validation and Verification (V&V) philosophy. The unit tests are written assuming the code is fundamentally broken, requiring strict empirical proofs to assert functionality.

1. **Functional Correctness:** Disproves failure assumptions by enforcing that compressing and sequentially decompressing data structurally reinstates the mathematically identical payload.
2. **Error Handling:** Validates that maliciously corrupted streams (e.g., tampered boundaries, altered offsets, truncated stream tails) properly assert `LZJB_Error` constraints rather than invoking `Constraint_Error` crashes or executing out-of-bounds reads.
3. **Edge Cases:** Proves correctness on limit tests (size-zero byte arrays, entirely uncompressible payloads, heavily redundant block data mimicking ZFS zeros).
4. **State Independence:** Verifies memory and hashing safety limits, ensuring consecutive invocations suffer zero cross-contamination.

These standards are critically important to ensure systems reliant on this algorithm do not incur silently corrupt block states or vulnerabilities during file unpacking operations.

## Usage
### Compilation instructions
This implementation comes with standard POSIX Make and GNAT workflows:
```bash
# Build the test binary via Makefile
make all

# Alternatively, compile natively via GNAT Project
gprbuild -P lzjb.gpr
