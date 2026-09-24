# Elias Omega Coding in Ada

## Project Overview
This project provides a robust, production-grade Ada implementation of **Elias Omega Coding**, a universal code developed by Peter Elias for encoding positive integers. Unlike fixed-length prefix codes, Elias omega coding recursively encodes integers and is especially optimal for distributions where small values occur significantly more frequently than large values. The codebase includes standard positive integer encoding/decoding as well as generalizations for non-negative integers and signed integers.

## Features
- **Standard Elias Omega Encoding & Decoding**: Efficiently encodes and decodes positive integers ($N \ge 1$) using recursive binary prefixing.
- **Non-Negative Integer Variant**: Extends the universal code to support $N \ge 0$ via a simple offset shift ($N + 1$).
- **Signed Integer Variant**: Implements a bijective mapping function to seamlessly encode and decode all integers ($0, 1, -1, 2, -2, \dots$).
- **Strong Typing & Safety**: Uses custom Ada types (`Bit`, `Bit_Array`) and explicit exception handling (`Decoding_Error`, `Invalid_Input`) to ensure safety and prevent silent failures.
- **GNAT Project Integration**: Fully compatible with standard GNAT tools via `elias_omega.gpr` and automated via `Makefile`.

## Testing
The test suite assumes code is incorrect or non-functional and applies rigorous Verification and Validation (V&V) principles to prove correctness.

### Test Categories Verified
1. **Functional Correctness**: Validates that standard positive integer encoding and decoding produce exact round-trip equality across small and large integer ranges.
2. **Error Handling & Robustness**: Verifies that malformed, incomplete, or truncated bit streams correctly raise `Decoding_Error` rather than exhibiting undefined behavior.
3. **Variant Validation**: Tests non-negative integer mappings ($N \ge 0$) and full signed integer bijections across positive and negative domains.
4. **Sequential Stream Processing**: Confirms that multiple encoded values can be packed into a single continuous bit stream and successfully decoded sequentially.

### Why These Tests Matter
Per rigorous V&V standards, testing critical data compression and encoding algorithms ensures memory safety, overflow protection, and bitwise exactness. By assuming initial failure, the test suite systematically exercises boundaries, edge cases (such as base case $N=1$ and zero values), and failure modes, proving that the implementation adheres strictly to mathematical specifications.

## Usage

### Compilation
To compile both the main demonstration program and the test suite using the GNAT project file:
```bash
make all
