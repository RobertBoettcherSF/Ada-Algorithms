# Unary Coding Algorithms in Ada

## Project Overview
This repository contains a strictly-typed, mission-critical implementation of the **Unary Coding** data compression algorithm written in Ada. Unary coding represents a natural number *n* using *n* identical bits terminated by a single opposite bit. It is widely used in Golomb coding, Elias gamma coding, and network data structures. 

## Features
This package fully implements all standard variants of Unary Coding as specified in mathematical and computer science literature:
*   **Standard Variant (Ones-Zero):** Encodes non-negative integer $N$ as $N$ ones followed by a zero (e.g., `3 -> "1110"`).
*   **Alternative Variant (Zeros-One):** Encodes $N$ as $N$ zeros followed by a one (e.g., `3 -> "0001"`).
*   **Positive Integer Variant (1-based Indexing):** Designed for strictly positive numbers ($N \ge 1$), encoding $N$ as $N-1$ ones followed by a zero.

It features **strong typing** via custom `Unary_Value` types to prevent cross-domain integer logic errors, and strict runtime exception handling (`Invalid_Encoding`) for corrupted payload strings.

## Testing
This codebase is governed by rigorous Verification and Validation (V&V) standards. We test under a "pessimistic assumption" model: the initial assumption for every test is that the code is non-functional or broken. A test **PASSES** only when it explicitly disproves this assumption.

### What We Verify
1.  **Functional Correctness:** Ensures base mathematical laws apply (e.g., `0` encodes cleanly to `0` or `1` depending on the variant). Verifies that round-trip encoding/decoding perfectly preserves the original domain object.
2.  **Error Handling:** Validates that malformed streams (e.g., strings missing terminators, premature terminators, random alphanumeric characters) raise controlled `Invalid_Encoding` exceptions rather than causing arbitrary memory access errors or endless loops.
3.  **Boundary & Edge Cases:** Verifies that empty strings and exceptionally large numbers are handled dynamically without crashing or buffer overflows.

### Why These Tests Matter
In strictly typed languages designed for reliability like Ada, unhandled bounds or logical errors can disrupt critical systems. By proactively bombarding the algorithm with malformed bit-streams and out-of-range bounds, we ensure the subsystem fails gracefully and securely, ensuring correctness per V&V standards.

## Usage

### Compilation
The codebase uses a GNAT toolchain managed by a standard Makefile. Everything resides locally in the root directory.

To build the executable test suite:
```bash
make
