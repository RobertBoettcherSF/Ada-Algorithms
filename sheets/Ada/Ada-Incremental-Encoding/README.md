# Incremental Encoding in Ada

## Project Overview
This repository provides an Ada 2012 implementation of the **Incremental Encoding** algorithm (also known as front compression or delta encoding). This algorithm efficiently compresses sorted lists of strings by finding the common prefix shared with the preceding string, storing the prefix length, and appending only the remaining suffix. 

## Features
*   **Standard / Forward Encoding Variant**: Fully implemented. Compresses string arrays into arrays of `(Prefix_Length, Suffix)` tuples.
*   **Decoding Variant**: Accurately reconstructs the original strings from an incrementally encoded array.
*   **Robust Edge-Case Handling**: Includes specific guards and exceptions against empty inputs, invalid decoding data constraints, and identical consecutive arrays.
*   **Strong Typing**: Utilizes Ada's static type system (`Unbounded_String`, `Natural` sizes) to heavily limit invalid data structures at compile time.

## Testing (Verification & Validation)
The codebase includes a strict V&V-focused test suite (`tests.adb`) containing 14 extensive tests. 

Our testing philosophy revolves around **falsification**: the test suite operates on the pessimistic assumption that the code is broken. Tests only PASS when an assumption of failure is decisively disproven (e.g., "Assume division by zero escapes -> PASS when Constraint_Error is correctly raised").

### What the Test Categories Verify
*   **Functional Correctness**: Ensures mathematical symmetry (Encode -> Decode yields original input). Validates core logic operations (Prefix calculation, string extraction).
*   **Error Handling (Safety)**: Ensures malicious or corrupt encoded data (e.g., prefix lengths longer than actual preceding strings, or non-zero prefixes on the first element) raises appropriate `Invalid_Data_Error` exceptions rather than causing memory leaks or out-of-bounds crashes.
*   **Edge Cases (Robustness)**: Verifies the code handles boundary scenarios, such as identical consecutive strings, completely empty string inputs, decreasing length structures, and single-item arrays.
*   **Performance / Semantics**: Ensures spacing, structural characters, and case-sensitivity behave exactly as requested by the encoding definition without crashing iteration loops.

### Why these tests matter
For mission-critical and strict computing environments (common in Ada domains), V&V standards dictate that passing "happy paths" is insufficient. These tests ensure high reliability and memory safety by aggressively targeting system bounds. Validating edge constraints prevents arbitrary code execution vulnerabilities common in string manipulation algorithms.

## Usage

### Compilation
Ensure you have the GNAT compiler installed. You can compile via the provided Makefile:
```bash
make all
