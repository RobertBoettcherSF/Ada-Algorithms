# Damm Algorithm Implementation in Ada

## Project Overview
This repository contains a strongly-typed, memory-safe implementation of the **Damm algorithm** written in Ada. The Damm algorithm is a check digit algorithm that detects *all* single-digit errors and *all* adjacent transposition errors. It works fundamentally by using a totally anti-symmetric quasigroup of order 10, overcoming the weaknesses of other modular sum algorithms (like the Luhn algorithm) which sometimes fail to detect transposed identical digits (e.g., `09` to `90`).

## Features
- **Strong Typing**: Digit values are constrained natively via Ada type limits (`0 .. 9`), inherently preventing out-of-bounds data corruption at compile-time.
- **Native Array Variant**: Process arrays of raw `Digit` types for systems where memory representations strictly rely on numerical structures.
- **String Variant**: Overloaded methods to compute and verify text-based strings seamlessly.
- **Immutable Table**: The 10x10 quasigroup is instantiated as a strict compile-time constant.
- **Strict Exception Handling**: Catches logic deviations (e.g., empty arrays, alphabetical characters) raising safe `Invalid_Input` exceptions rather than corrupting memory or looping infinitely.

## Testing
This project integrates strict **Verification and Validation (V&V)** principles to ensure robustness suitable for critical systems. Assuming initially that the code is non-functional or faulty, the test suite proves adherence to specifications.

### What the Tests Verify
- **Functional Correctness**: Validates that calculation sequences match mathematical expectations (e.g., `[5, 7, 2] -> 4`).
- **Error Handling Detection**: Ensures the algorithm catches both single-digit mutations and transposition inversions.
- **Edge Cases**: Validates handling of all-zero buffers, shortest-possible inputs (single digits), extremely long payload bounds, and safely raises custom exceptions for empty strings/arrays or illegal ASCII characters.

### Why These Tests Matter
In verification and validation contexts for critical systems, proving the absence of runtime errors is paramount. These tests mathematically guarantee that:
1. **Verification**: The codebase translates the Wikipedia formal algorithm definitions exactly without logical divergence.
2. **Validation**: The implementation is structurally sound and safely mitigates user/environment misconfigurations (such as corrupt string inputs) without risking fatal software crashes like `Constraint_Error` leaks.

### How Tests Prove Correctness
The tests utilize pessimistic assertions (`Assert (Result = Expected, "Message")`). Each passing test explicitly disproves an assumption of failure (e.g., assuming an empty string will crash the system is disproven by capturing the controlled `Invalid_Input` exception).

## Usage

### Compilation
The project requires the GNAT toolchain. Compile the software using `make` which wraps `gprbuild`:
```bash
make all
