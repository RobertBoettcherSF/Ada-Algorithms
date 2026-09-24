# Levenshtein Coding (Ada Implementation)

## Project Overview
This project provides a robust, strongly-typed Ada implementation of the **Levenshtein coding** algorithm. Levenshtein coding is a universal code used to mathematically map non-negative integers into an optimal binary sequence. Unlike other universal codes (e.g. Elias omega), Levenshtein coding directly supports the encoding of zero. This system safely encodes and decodes arbitrary non-negative integers up to the bounds of Ada's 64-bit maximum integer sizes.

## Features
*   **Encoding Module:** Converts any non-negative integer into a valid Levenshtein bit pattern.
*   **Decoding Module:** Securely parses a Levenshtein bit pattern back into a numeric identifier, strictly validating internal lengths and sequences to prevent buffer overflow.
*   **Strong Custom Typing:** Implements a strict `Bit_String` and enumerated `Bit` type to guarantee that invalid characters or payload injections cannot be processed at the type-system level.
*   **Resiliency Protocols:** Explicit logic correctly flags trailing payload bits, missing determiners, and arithmetic overflows without triggering undefined behavior.

## Testing
This project integrates rigorous **Verification and Validation (V&V)** principles. The test suite operates on a pessimistic testing philosophy: it assumes the core codebase is non-functional, and the test assertions must categorically "disprove" this assumption across 13 distinct avenues.

*   **Functional Correctness:** Assesses algorithm parity against the documented benchmark patterns (e.g. verifying that `16` maps specifically to `1111000000000`). Tests prove the algorithm processes both Base Cases and Large Integers dynamically correctly.
*   **Robustness / Error Handling:** Attacks the decoding parser with maliciously constructed data (truncated suffixes, extraneous bits after zeroes, uncompleted iterators) to guarantee that the bespoke `Invalid_Encoding` exception is properly raised over uncontrolled faults or memory access leaks.
*   **Performance Boundaries:** Executes loop thresholds with large inputs (65535) confirming runtime iterations and algorithmic scalability.
*   **Side-effects / Idempotence:** Confirms `Encode(Decode(X))` outputs cleanly loop back strictly to `X`, evidencing no state leaking between functional executions.

These mechanisms are paramount for critical systems design, where an unreliable packet parser must fail gracefully (raising recognizable exceptions) instead of producing inaccurate runtime integers.

## Usage
### Compilation
The codebase lives natively in the root directory and leverages a GNAT project file. Build the executables via `make`:
```bash
make all
