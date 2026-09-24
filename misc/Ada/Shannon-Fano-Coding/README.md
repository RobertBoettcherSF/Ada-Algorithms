# Shannon-Fano Coding in Ada

## Project Overview
This repository implements the Shannon-Fano lossless data compression algorithm in Ada 2012. It provides an efficient mechanism for constructing prefix-free codes based on a set of symbols and their probabilities (or frequencies). The implementation is designed with strong typing, robust error handling, and covers the two distinct mathematical approaches historically attributed to Claude Shannon and Robert Fano.

## Features
- **Fano's Method (Top-Down Splitting):** A recursive algorithm that sorts symbols by probability and repeatedly divides them into two halves such that the sum of probabilities in each half is as balanced as possible.
- **Shannon's Method (Cumulative Probabilities):** An approach outlined in Shannon's 1948 paper that uses cumulative probabilities and logarithmic calculations (`l_i = ceil(-log2(p_i))`) to determine code lengths and extract prefix binary strings.
- **Automatic Data Normalization:** Safely accepts raw frequencies/counts and transparently normalizes them into true decimal probabilities.
- **Strict Exception Handling:** Protects against `Empty_Input` and `Invalid_Probability` (e.g., negative or zero weights).

## Testing (Verification & Validation)
This codebase adheres to rigorous V&V principles suitable for mission-critical logic, validating that requirements are fully satisfied and that the code operates exactly as intended. 

**Test Philosophy:** The included test suite is built on a pessimistic assumption: *the code is assumed broken*. Tests pass only when assertions actively disprove this assumption by demonstrating flawless behavior under stress.

**What the tests verify:**
- **Functional Correctness:** Ensures Fano's method creates minimal difference splits and Shannon's method strictly adheres to the mathematical logarithmic bounds.
- **Edge Cases:** Validates handling of single-element arrays and non-normalized probability sums (e.g., weights adding up to $>1.0$ or $<1.0$).
- **Error Handling:** Intentionally induces `Constraint_Error` triggers using `0.0` or negative weights to guarantee exceptions are thrown, caught, and appropriately logged rather than silently failing.
- **System Robustness:** Confirms that internally mutated states (like auto-sorting unordered arrays) do not violate deterministic code generation logic.

**Why these tests matter:**
In encoding schemes, a single incorrect bit assignment corrupts the entire downstream decoding phase. Prefix-free guarantees and math normalization must be infallible. These tests prove the mathematical assertions under edge constraints, ensuring reliability and safety. 

## Usage

### Compilation
The project requires the GNAT toolchain. A GNAT Project file (`shannon_fano.gpr`) and a `Makefile` are provided.

To compile both the main demo and test suite, run:
```bash
make all
