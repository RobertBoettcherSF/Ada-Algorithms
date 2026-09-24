# Whirlpool Cryptographic Hash Function in Ada 2023

## Project Overview
This project provides a complete, robust, and type-safe implementation of the **Whirlpool** 512-bit cryptographic hash function in Ada 2023 (ISO/IEC 8652:2023), adhering to the ISO/IEC 10118-3 standard and NESSIE cryptographic recommendations. Designed by Vincent Rijmen and Paulo S. L. M. Barreto, Whirlpool uses a Miyaguchi-Preneel construction based on an AES-like block cipher operating on an 8x8 matrix of bytes over GF(2^8).

## Features
- **Strong Typing:** Domain-specific types (`Byte`, `State_Matrix`, `Digest`, `Block`, `Message`) prevent mixing raw integers with cryptographic states.
- **Contract-Based Programming:** Annotated with Ada pre- and postconditions (`Pre`, `Post`) ensuring input bounds and invariant output sizes.
- **ISO/IEC Padding:** Implements standard padding appending a '1' bit followed by zero-padding and a 256-bit big-endian bit length.
- **Complete Cipher Pipeline:** Implements SubBytes (γ), ShiftColumns (π), MixRows (θ), and AddRoundKey (σ) across 10 rounds with full key schedule generation.
- **Zero Warnings:** Clean compilation under strict GNAT warning flags (`-gnatwa -gnat2022`).

## Usage
To build and run the test suite:

    make test

To clean build artifacts:

    make clean

## Testing
The test suite (`tests.adb`) comprises 13 comprehensive test categories with multiple assertions each:

1. **Functional Correctness:** Empty strings, single characters, standard ASCII strings, and multi-block messages.
2. **Edge Cases:** Single-byte messages, exact block boundaries (64 bytes), and block boundary overflow (65 bytes).
3. **Data Encoding & Formatting:** Hexadecimal digest serialization (`Digest_To_Hex`) and wrapper API equivalence.
4. **Collision Resistance & Determinism:** Verification that distinct inputs yield unique 512-bit digests.
5. **Robustness & Invariants:** Exception safety and contract validation.

## Building
- **Prerequisites:** GNAT compiler with Ada 2023 support (`-gnat2022`).
- **Build Tool:** GNU Make & GNAT project manager (`gprbuild` / `gnatmake`).
