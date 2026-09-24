# Zobrist Hashing in Ada

## Project Overview
This project implements Zobrist Hashing, a technique commonly used in computer game programming (e.g., Chess, Go) to create unique hash keys for board states using XOR summation.

## Features
- **Strong Typing**: Ada-specific types for Pieces, Board Positions, and Hashes.
- **Initialization**: Secure generation of random 64-bit hash values for every piece-position combination.
- **Update Logic**: Efficient calculation and state updates using bitwise XOR.
- **Robust Testing**: A comprehensive test suite validating hashing mathematical properties.

## Testing
The test suite assumes the implementation might be flawed and runs 13 specific assertions to verify:
- **Functional Correctness**: Hash values are unique and non-zero where expected.
- **Algebraic Validity**: Verification that `A XOR A = 0` (cancellation) and `A XOR B = B XOR A` (commutativity).
- **Edge Cases**: Empty board states, multiple piece movements, and boundary conditions (index 8,8).
- **Validation**: Ensures the implementation behaves as a reliable mathematical mapping for state tracking.

## Usage
### Compilation
Ensure you have the GNAT compiler installed.
```bash
make
