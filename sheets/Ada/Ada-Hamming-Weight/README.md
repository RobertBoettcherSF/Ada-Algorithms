# Hamming Weight (Population Count) Ada Implementation

## Project Overview
This project provides a robust, strongly-typed Ada implementation of the Hamming Weight algorithm (also known as population count or popcount) based on the computational models outlined on Wikipedia. It determines the number of '1' bits set in a given 32-bit binary number.

## Features
The codebase provides `Word_32`, a highly secure modular 32-bit type, mapping across five standard algorithm implementations:
- **Naive Count:** A shift-and-count iteration validating every bit position.
- **Brian Kernighan's / Wegner's:** An optimized loop that directly clears the lowest set bit, highly performant on sparse bit patterns.
- **Parallel SWAR (Tree-like Reduction):** SIMD Within A Register algorithm operating in constant O(1) time without looping.
- **SWAR with Multiplication:** An optimization on the parallel method utilizing 32-bit modular arithmetic overflow tricks to compile counts via multiplication.
- **Lookup Table:** Instantiates a pre-computed 256-element cache array mapping every possible 8-bit chunk directly to its resulting popcount.

## Testing
This project integrates stringent Verification and Validation (V&V) principles standard for critical systems programming.

### What The Tests Verify
1. **Functional Correctness:** Ensures bit configurations (e.g. alternating `0xAAAA_AAAA`) match exact known integer values.
2. **Edge Cases:** Directly interrogates system boundaries such as `0` and Max Value (`0xFFFF_FFFF`). 
3. **Equivalence (Cross-Validation):** Evaluates if drastically different implementations yield uniform output identically on complex values (e.g., verifying `SWAR_Count(0xDEAD_BEEF)` against `Naive_Count(0xDEAD_BEEF)`).
4. **Error Handling/Overflows:** Assures modular arithmetic accurately wraps overflow values (specifically relevant in the SWAR multiplication trick) rather than triggering `Constraint_Error`.

### Why These Tests Matter (V&V Principles)
In safety-critical development, assumptions are treated pessimistically. We test under the hypothesis that the module is *defective* or subject to arithmetic overflow. The tests provide terminal validation that system behavior matches software requirements under hostile boundary conditions (Verification) and correctly satisfies the objective mathematically (Validation). A "PASS" inherently disproves the failing assumption.

## Usage

### Compilation
The codebase incorporates standard GNAT compilation. A Makefile is provided for convenience.
From the terminal, build the project utilizing:
```bash
make all
