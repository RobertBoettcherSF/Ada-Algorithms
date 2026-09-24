# Adler-32 Ada Implementation

## Project Overview
This repository contains a strictly-typed, modular implementation of the Adler-32 checksum algorithm in Ada. Adler-32 is a checksum algorithm which trades some reliability for speed, making it highly effective for stream tracking (such as in zlib compression).

## Features
- **Basic Variant**: A byte-by-byte exact implementation of the mathematical formula.
- **Optimized Variant**: As detailed in Wikipedia's documentation, calculating `mod 65521` at every step is computationally expensive. This variant defers modulo operations across chunks of up to 5,552 bytes, maximizing performance while strictly guarding against 32-bit arithmetic overflow.
- **Helper Utilities**: Strongly typed implementations including string-to-byte arrays ensuring complete memory control.

## Testing (Verification & Validation)
This project enforces rigorous V&V principles, verifying that the algorithms conform mathematically to requirements and validating that the optimized code handles memory safely under edge-case loads.

### Test Categories
- **Functional Correctness**: Ensures "Wikipedia" and standard checksum comparisons produce exact documented outputs (e.g., `0x11E60398`).
- **Error Handling & Robustness**: Uses non-standard array indices (arrays starting at bounds > 1) to ensure the loops dynamically adapt to memory layout.
- **Edge Cases**: Validates empty byte streams, arrays containing NULL components (`0x00`), and streams full of maximum Unsigned_8 values (`0xFF`). 
- **Performance Boundaries**: Stresses the 5,552-byte deferred modulo boundary block. We verify chunks exactly equal to, and vastly exceeding this size, comparing the outcome continuously against the base variant.

### The "Assumption of Failure"
Tests here are constructed under a "pessimistic bias." We assume the algorithm fails on edge-cases, block limits, and memory conversions. When the test suite prints `[PASS] DISPROVED: <Statement>`, it acts as verifiable mathematical proof that the logic remains uncorrupted despite these harsh bounds.

## Usage
### Compilation
The codebase can be compiled instantly from the root directory using the provided Makefile (which relies on `gnatmake`):
```bash
make all
