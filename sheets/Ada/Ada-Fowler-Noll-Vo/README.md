# FNV Hash Implementation in Ada

## Project Overview
This project provides a robust, type-safe implementation of the Fowler-Noll-Vo (FNV) hash algorithm in Ada. It includes support for both 32-bit and 64-bit variants of the FNV-1 and FNV-1a hashing algorithms.

## Features
- **FNV-1 (32-bit & 64-bit):** Standard FNV hash implementation.
- **FNV-1a (32-bit & 64-bit):** Modified FNV hash with improved dispersion for small data.
- **Strong Typing:** Utilizes `Interfaces.Unsigned_32` and `Interfaces.Unsigned_64` for precise arithmetic.
- **Modular Design:** Clear separation between specification (`.ads`) and implementation (`.adb`).

## Testing
The test suite consists of 13+ test cases designed to verify functional correctness, algorithm divergence between FNV-1 and FNV-1a, and mathematical precision.
- **Functional Correctness:** Ensures hashes are deterministic and consistent.
- **Edge Cases:** Handles empty strings, null characters, and high-ASCII characters.
- **Robustness:** Verifies mathematical order of operations for both algorithm variants.

## Usage
### Compilation
To compile the project:
```bash
make
