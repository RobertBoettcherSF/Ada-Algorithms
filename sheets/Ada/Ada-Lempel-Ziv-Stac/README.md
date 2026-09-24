# Lempel-Ziv-Stac (LZS) Implementation in Ada

## Project Overview
This project provides a robust, terminal-executable implementation of the Lempel-Ziv-Stac (LZS) lossless data compression algorithm in Ada. It includes both the compression (using LZ77 sliding-window and fixed Huffman coding) and decompression variants, adhering strictly to the INCITS/RFC specifications (2048-byte sliding window, variable-bit-width tokens).

## Features
- **Compression Variant**: Implements LZ77 string matching with LZS specific token formatting (7-bit/11-bit offsets, multi-tiered length encoding).
- **Decompression Variant**: Accurately reconstitutes uncompressed data from LZS-encoded bit streams.
- **Robust Error Handling**: Checks for buffer overflows, invalid offsets, and missing end-markers.
- **Strong Typing**: Uses custom types (`Byte_Array`, `Buffer_Type`) ensuring strict constraint validation at compile and run time.
- **Standalone Verification Suite**: Includes a dedicated testing suite evaluating functionality, boundary limits, and data correctness without external dependencies.

## Testing
The test suite (`tests.adb`) adheres to core Verification and Validation (V&V) principles for critical systems. The underlying philosophy assumes the implementation is incorrect until mathematically and computationally disproved by the assertions.

### What Each Test Category Verifies:
1. **Functional Correctness (Tests 1, 2, 12, 14):** Validates that literals, basic strings, and raw binary bytes are encoded and correctly reconstituted. It proves the foundational bitwise operators work as required.
2. **Edge Cases & Boundaries (Tests 3, 4, 5, 8, 13):** Stresses extreme limits, such as completely empty buffers, the absolute minimum match threshold (2 bytes), massive offsets crossing the 128-byte 7-bit/11-bit threshold, and specific transition boundaries in length encoding.
3. **Performance & Volumetric Scaling (Tests 6, 7, 9):** Ensures that highly compressible repetitive data generates correctly tiered multi-bit length codes (e.g., `1111` repetition counting) without causing integer overflows or infinite loops.
4. **Error Handling & Malformed States (Tests 10, 11):** Verifies resilience by forcibly triggering malformed streams (e.g., truncated end markers), ensuring the system catches them gracefully via `Decompression_Error` instead of crashing unpredictably.

### Why These Tests Matter:
In critical software infrastructure, unverified compression behavior can cause memory leaks, arbitrary code execution, or data corruption. These tests validate the design against strict standards, ensuring safety, operational reliability, and deterministic execution per rigorous V&V doctrines.

## Usage

### Compilation
The project does not use a nested `src` structure; all files reside directly in the root directory. To compile the main executable and tests, simply use the provided `Makefile`:

```bash
make
