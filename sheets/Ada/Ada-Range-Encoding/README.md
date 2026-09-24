# Range Encoding Algorithm in Ada

## Project Overview
This repository implements the **Range Encoding** data compression algorithm in Ada. Range encoding is an entropy coding method structurally isomorphic to arithmetic coding. It represents a sequence of symbols as a fraction within a specific range, iteratively narrowing the range based on symbol probabilities.

## Features
This package includes implementations of the two primary algorithmic variants detailed in literature:
1. **Floating-Point Mathematical Variant**: A conceptual implementation mapped perfectly to the `[0, 1)` range utilizing `Long_Float`. Best for understanding the pure mathematics, though limited by 64-bit precision boundaries for long strings.
2. **Integer Arithmetic Variant**: The practical, system-level implementation utilizing `Unsigned_64` integer arithmetic and dynamic byte/digit normalization. This implementation prevents underflow/overflow and is functionally identical to the standard Base-10 encoding algorithm shown in the Wikipedia model.

## Testing (Verification & Validation)
This project adheres to rigorous Verification and Validation (V&V) principles standard in high-reliability software. 

A pessimist-driven test suite (`tests.adb`) assumes the codebase contains latent defects. The suite contains **14 targeted tests** that challenge this assumption. A `PASS` signifies that the specific vulnerability assumption has been proven false.

### What We Verify
* **Functional Correctness (Tests 1-4):** Ensures outputs match theoretical mathematical calculations (e.g., bounds checking against expected Wikipedia fractional segments). 
* **Edge Cases (Tests 5, 6, 10, 11):** Challenges the code with limits, such as zero-length inputs or single characters, ensuring stability at array boundaries.
* **Error & Exception Handling (Tests 7, 8, 9, 14):** Verifies that malformed inputs (invalid symbols, buffer overflows, mismatched data streams) immediately raise deterministic exceptions (`Encoding_Error`, `Decoding_Error`) instead of silently failing.
* **State Integrity (Test 13):** Proves the algorithm is side-effect-free and does not mutate shared probability models during execution.

### Why It Matters
For critical systems, data compression can mask data corruption if not strictly bounded. Our test suite guarantees that out-of-band data triggers immediate structural failures (Fail-Safe), confirming correctness and memory safety per standard software safety regulations.

## Usage

### Compilation
The codebase uses a GNAT Project file integrated with a standard Makefile. Ensure `gnatmake` is installed.
```bash
make all
