# Elias Delta Coding in Ada

## Project Overview
This project provides a robust, production-ready Ada implementation of the **Elias delta coding** algorithm, a universal prefix code developed by Peter Elias for encoding integers $\ge 1$ with high compression efficiency for smaller numbers. In addition to core delta encoding and decoding, the package implements advanced variants for non-negative integers ($X \ge 0$) and all signed integers (using ZigZag mapping), complete with a comprehensive test suite and GNAT build configuration.

## Features
- **Core Elias Delta Coding**: Full encoding and decoding for strictly positive integers ($X \ge 1$).
- **Bit-Vector Interface**: Support for strongly-typed `Bit_Vector` representations (`Zero`, `One`).
- **Non-Negative Integer Variant**: Extension supporting $X \ge 0$ via a +1 offset mapping.
- **Signed Integer Variant**: Extension supporting all integers (positive, zero, and negative) via ZigZag bijective mapping.
- **Helper Utilities**: Exposed modular helper functions for binary conversion and Elias gamma coding.
- **Robust Error Handling**: Explicit custom exceptions (`Invalid_Code`, `Invalid_Input`) for malformed bitstreams and invalid inputs.

## Testing & Verification (V&V Principles)
The test suite implements 13+ rigorous test categories (comprising 39 distinct assertions) operating under the core Verification & Validation (V&V) assumption that the underlying code is initially incorrect. Tests are designed to prove or disprove this pessimistic assumption across normal inputs, boundaries, edge cases, and error modes.

### Test Categories & Verification Scope
1. **Functional Correctness**: Verifies that standard integer inputs ($1, 2, 3, 4, 15, 16$) match mathematically precise Elias delta bitstreams.
2. **Round-Trip Consistency**: Validates lossless encoding and decoding cycles across small, medium, and large integers up to $65,535$.
3. **Variant Validation**: Tests specialized wrappers for non-negative integers and signed integers (ZigZag encoding).
4. **Helper & Boundary Verification**: Checks internal binary conversion (`Integer_To_Binary`, `Binary_To_Integer`) and Elias gamma sub-routines.
5. **Robustness & Error Handling**: Confirms that malformed bitstreams, empty strings, and invalid characters correctly raise `Invalid_Code` exceptions rather than failing silently or crashing.

## Usage
### Compilation
To compile the main program and the test suite using `gnatmake` and the provided Makefile:
```bash
make
