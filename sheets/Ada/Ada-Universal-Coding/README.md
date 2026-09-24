# Universal Codes (Data Compression Algorithms)

## Project Overview
This repository contains a high-reliability Ada implementation of various **Universal Codes** used in data compression. Universal codes are prefix codes that map positive integers onto binary codewords, serving as essential components in lossless compression formats by efficiently encoding unbounded sequences without transmitting predefined lengths. 

## Features
The `Universal_Codes` package provides both encoders and decoders for all major variants outlined on Wikipedia:
* **Unary Coding**: Baseline coding where $N$ is encoded as $N-1$ ones followed by a zero.
* **Elias Gamma Coding**: Asymptotically optimal encoding for probability profiles decreasing as a power of 2.
* **Elias Delta Coding**: Optimized Elias coding ideal for much larger integers.
* **Elias Omega Coding**: A recursive string construction ideal for very large values.
* **Fibonacci Coding**: Robust encoding built on Zeckendorf's theorem using the Fibonacci sequence, guaranteeing self-synchronization by utilizing consecutive `1`s as payload boundaries.

All algorithms use strong domain-specific typing (`Bit`, `Bit_Array`) overriding standard string behaviors to eliminate integer/character conflation.

## Testing
This software is built around pessimistic **Verification and Validation (V&V)** principles. The test suite operates on the foundational assumption that the algorithms are fundamentally non-functional, edge-case fragile, and unsafe. Tests PASS explicitly only when these assumptions are demonstrably disproved. 

### What the test categories verify
1. **Functional Correctness (Tests 1-5)**: Verifies that expected bitstreams accurately match known theoretical payloads generated for fixed parameters $N$.
2. **Edge Cases**: Validates boundaries, especially $N=1$, which conventionally stresses integer-based recursive or log-scale math routines. 
3. **Error Handling & Robustness (Test 6)**: Actively feeds truncated, missing-terminator, and malformed streams into the decoders to verify that strict algorithmic boundaries are preserved via Ada exception mechanisms rather than buffer overflow or infinite loop regressions.

### Why these tests matter
Universal codes operate at the bitwise stream level, often without delimiters. A single bit mutation can de-synchronize an entire file in production. Using V&V methodology ensures reliability, guarantees safety (zero out-of-bounds memory accesses), and verifies absolute correctness against compression standards.

### How tests prove the code works
Assertions deliberately demand the algorithms raise structured custom exceptions (`Decoding_Error`). The testing process confirms that if corrupt data enters, the software safely halts the logic path and immediately flags corruption instead of executing uncontrolled data reads.

## Usage

### Compilation
The codebase sits in the root directory. You can utilize the provided Makefile:
```bash
make all
