# Lempel–Ziv–Storer–Szymanski (LZSS) Implementation

## Project Overview
This repository contains a robust, highly modular Ada implementation of the LZSS data compression algorithm. Originally published in 1982, LZSS improves upon the LZ77 algorithm by replacing length-and-distance pairs with a 1-bit flag that distinctly separates uncompressed literal bytes from compressed reference sequences. 

The implementation avoids dynamic memory allocation constraints by relying on strongly-typed sliding bitwise arrays and safe array sizing mechanics inherent to the Ada 2012 specification.

## Features
- **Variant 1: Pure Logical Algorithms:** Contains `Compress_Logical` and `Decompress_Logical`, which emit arrays of `Token` variants rather than bits. Highly useful for academic observation of sliding dictionary mechanics.
- **Variant 2: Fully Bit-Packed Data Streams:** Production-standard implementation wrapping 1-bit literal/reference flags against 8-bit characters or 16-bit dictionary lookups (12-bit distance, 4-bit length).
- **Strong Safety Bounds:** Complete handling of array truncation bounds, sliding dictionary boundary faults, and corruption limits.

## Testing
This codebase has been engineered through pessimistic Verification and Validation (V&V) methodologies. The test suite strictly assumes the codebase is fundamentally broken/malformed. Passing the test suite indicates these failure assumptions have been demonstrably disproven.

The categories validated include:
- **Functional Correctness:** Asserts that data (both continuous loops and standard patterns) remains bit-perfect post-decompression. Proves that the algorithm faithfully models the requirement spec.
- **Error Handling:** Intentionally forces the decoder to ingest corrupted buffers, truncated streams, and maliciously mapped backward-references. Asserts that the codebase safely catches the faults via `Compression_Error` exceptions rather than executing illegal memory reads.
- **Edge Cases & Window Management:** Ingests arrays extending just beyond the exact `Window_Size` constraint (4096 bytes) and forces match length bounds against the `Lookahead_Size` (18 bytes).
- **Performance Constraints:** Evaluates logic against completely uncompressible high-entropy data, asserting the algorithm expands predictably without crashing.

V&V Standard Importance: By asserting failure boundaries over simple "happy paths", the system mathematically guarantees reliability for mission-critical runtime scenarios.

## Usage

### Compilation
The project requires the GNAT toolchain (e.g., GCC Ada compiler). To compile the project, run:
```bash
make
