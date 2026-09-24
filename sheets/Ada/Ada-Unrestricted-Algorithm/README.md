# Ada Unrestricted Algorithm Implementation

## Project Overview
This repository implements mathematical **Unrestricted Algorithms** in Ada. In computer science, an unrestricted algorithm allows calculations to be run to arbitrary precision limits defined dynamically at runtime, rather than being bound by hardware memory limits of fixed floating-point representations. 

The primary implementation is an unbounded Taylor Series calculator computing **Euler's Number (e)** and exact inverse ratios (1/N) to arbitrary decimal capacities. 

## Features
- **Arbitrary Precision Arithmetic Data Types**: Array-based unbounded mathematical modeling (`Digit_Array`).
- **Variant 1**: Iterative arbitrary precision Inverse calculation (generates 1/N step-by-step).
- **Variant 2**: Recursive arbitrary precision Inverse calculation.
- **Variant 3**: Infinite Taylor Series unrestricted approximation for mathematical constants (computes *e* to N decimals).
- Robust edge-case management preventing Array bound mismatches.

## Testing (Validation & Verification)
Critical systems require explicit **Validation** (Are we calculating the right mathematical logic?) and **Verification** (Did we build the code structures correctly against safety paradigms?). 

This project operates on a pessimistic testing assumption: **The codebase is assumed critically broken until empirical unit tests prove otherwise.**

### What Each Test Category Verifies:
1. **Functional Correctness (Validation)**:
   - Evaluates base case logic (calculating known decimal expansions of 1/2, 1/3, and *e*).
   - Validates that custom internal arithmetic mimics base-10 mathematics without arbitrary data loss.
2. **Error Handling & Bounds (Verification)**:
   - Uses Ada's strong typing (`Positive` vs `Natural`) to prevent invalid memory generation (0 precision).
   - Verifies explicit Exception Handling (`Precision_Mismatch_Error`) fires natively if mismatched precision arrays are injected into logical adders.
3. **Performance/Deep Precision (Robustness)**:
   - Evaluates state persistence when carrying arrays out to deeper limits (Precision = 10, Precision = 50).

### Proving Correctness:
A test results in `PASS` only when an explicit assumption of failure is proven false. Testing confirms not only that the calculation yields correct outputs (functional logic) but that it will actively stop the program (Exception generation) on physically invalid runtime state injections, ensuring software safety parameters are upheld.

## Usage

### Compilation
Ensure you have the GNAT Ada toolchain installed.
```bash
# Compiles both the main application and test suite binaries
make
