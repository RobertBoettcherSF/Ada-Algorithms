# Ada Dictionary Coder

## Project Overview
This repository provides a high-reliability implementation of a **Dictionary Coder** scheduling algorithm in Ada. A dictionary coder replaces continuous sequences in data with internal index mappings to a built dictionary, highly common in data compression algorithms.

## Features
Implemented according to the algorithm specifications found on [Wikipedia](https://en.wikipedia.org/wiki/Dictionary_coder):
*   **Static Dictionary Variant:** Uses a predefined, fixed mapping of words to Integer Codes. Highly optimized for scenarios with a heavily constrained, known vocabulary.
*   **Dynamic / Adaptive Variant (LZW):** Fully implements the Lempel-Ziv-Welch (LZW) algorithm. It builds its dictionary dynamically while reading strings.

## Testing
This project embraces a strict Verification and Validation (V&V) philosophy. The test suite operates under the assumption that the underlying code is broken. A test will only report **PASS** when it actively disproves this assumption by asserting valid boundaries, bounds checking, and handling known mathematical edge cases.

### What the test categories verify
1.  **Functional Correctness:** Ensures mappings map to their exact designated pairs and compression strictly occurs. Verifies that decoding mirrors the original strings perfectly (Testing the `Original == Decode(Encode(Original))` constraint).
2.  **Error Handling (Robustness):** Confirms that unknown codes, unknown words, and invalid initialization sequences raise explicitly designed Exceptions (`Encode_Error`, `Decode_Error`, `Dictionary_Error`), preventing unhandled segfaults.
3.  **Edge Cases (Boundaries):** Checks zero-length strings, single-character encodings, and the notoriously complex `'cScSc'` LZW edge-case pattern (e.g. string inputs like `"ABABABA"`) where the algorithm must recursively fetch data from an incomplete dictionary node.

### Why these tests matter
For mission-critical or embedded systems using Ada, safety and memory stability are prioritized. Our test suite guarantees data consistency without runtime crashes. Negative tests prove that out-of-bound variables and malformed codes are caught predictably before entering lower-level memory operations. 

## Usage

### Compilation
The codebase requires the GNAT toolchain. The included `Makefile` handles standard project directories internally without utilizing a `src` folder layout.
```bash
# Compile both the main demo and test suite
make all
