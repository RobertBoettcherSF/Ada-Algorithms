# Pearson Hashing Algorithm in Ada

## Project Overview
This project implements the Pearson Hashing algorithm in Ada. Pearson hashing is a hash function designed for fast execution on processors with 8-bit registers, utilizing a permutation table to map input bytes to a final hash value.

## Features
- **Standard Pearson Hashing**: Implementation for `String` inputs.
- **Binary Data Support**: Implementation for `Byte_Array` inputs.
- **Variant Support**: The implementation supports custom Permutation Tables, allowing for domain-specific hashing variants.
- **Strong Typing**: Uses Ada's `Unsigned_8` and custom array types for robust data handling.

## Testing
The project includes a comprehensive test suite (`tests.adb`) that verifies the correctness of the algorithm.

### Verification and Validation (V&V)
- **Functional Correctness**: Ensures inputs map to consistent outputs.
- **Robustness**: Verifies handling of edge cases (empty strings, large inputs, null bytes).
- **Correctness**: Asserts that different tables and inputs result in distinct hash distributions.
- **Consistency**: Proves that string-based and byte-based inputs are treated identically where appropriate.

## Usage

### Compilation
Ensure you have the GNAT compiler installed. Compile using the Makefile:
```bash
make
