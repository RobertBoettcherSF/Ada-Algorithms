# Rice & Golomb Entropy Encoding (Ada Implementation)

## Project Overview
This repository contains a robust, statically typed Ada implementation of **Rice coding** and its generalized parent algorithm, **Golomb coding**. These algorithms are lossless data compression methods (entropy encodings) utilizing unary and truncated binary representations to compress geometric distributions.

## Features
*   **Standard Rice Coding:** `Encode_Rice` / `Decode_Rice` for non-negative integers (optimized where divisor $M = 2^k$).
*   **Signed Rice Coding:** `Encode_Signed_Rice` / `Decode_Signed_Rice` utilizing ZigZag (overlap) mapping (e.g., $0\to0$, $-1\to1$, $1\to2$, $-2\to3$) to safely encode negative values.
*   **Generalized Golomb Coding:** `Encode_Golomb` / `Decode_Golomb` handling arbitrary $M$ divisors, dynamically calculating variable cutoff boundaries and executing truncated binary mapping natively.
*   **Robust Type System:** Prevents integer underflows and enforces parameter boundaries at compile time through `Unsigned_Value`, `Rice_Parameter`, and `Golomb_Parameter`.

## Testing
This project follows rigorous Verification and Validation (V&V) principles to ensure the correctness of data mapping and decompression safety. The default assumption is that the code is non-functional; the test suite is designed to aggressively disprove this assumption through empirical execution.

### What the tests verify:
*   **Functional Correctness:** Verifies the mathematical implementations of $q$ and $r$ mapping exactly match standard information theory literature (Verification). Validates that encoding and immediately decoding returns the exact same data without drift (Validation). 
*   **Edge Cases:** Verifies limits like $K=0$ (where no binary remainder exists) and negative boundaries in ZigZag mapping are gracefully handled.
*   **Error Handling / Robustness:** Explicitly tests malformed inputs—such as bitstreams with missing unary terminators or truncated binary remainders—ensuring `Decoding_Error` is raised rather than producing silent corruption or memory faults.

### Why these tests matter:
In data compression—especially within mission-critical or storage-heavy ecosystems—silent data corruption is catastrophic. By explicitly checking how the decoders handle truncated or invalid bitstreams, we validate the system's safety characteristics to ensure reliability.

## Usage

### Compilation
The codebase requires an Ada 2012 compliant compiler (like GNAT). You can build everything directly from the root directory via the provided `Makefile`:

```bash
make all
