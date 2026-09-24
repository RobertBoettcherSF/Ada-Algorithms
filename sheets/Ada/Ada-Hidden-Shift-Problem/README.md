# Hidden Shift Problem (Ada 2023 Implementation)

## Project Overview
The Hidden Shift Problem is an oracle-based computational problem where two functions $f$ and $g$ over a common domain are related by a hidden shift $s$ such that $g(x) = f(x + s)$ for all elements $x$. This repository provides a complete, robust, and strongly typed Ada 2023 implementation modeling both exhaustive search (brute-force) and heuristic correlation peak analysis (simulating Fourier/algebraic shift recovery methods) over cyclic domains.

## Features
- **Strongly Typed Domain**: Uses modular types (`Domain_Element`) and custom range types (`Range_Element`) to ensure domain safety and correct arithmetic wrap-around.
- **Variant 1 (Brute-Force Search)**: `Solve_Brute_Force` performs exhaustive validation across all domain elements to find the unique hidden shift with contract enforcement (`Post`).
- **Variant 2 (Correlation Search)**: `Solve_Correlation_Search` computes cross-correlation scores across shifts to locate maximum agreement peaks, simulating advanced algebraic/frequency-sampling solvers.
- **Verification & Helper Functions**: Includes `Verify_Shift` and `Compute_Correlation` with formal contract aspects (`Pre`/`Post`).
- **Robust Error Handling**: Explicitly raises named exceptions (`No_Shift_Found`, `Invalid_Function_Data`) when no valid shift relation exists.
- **Comprehensive Test Suite**: Includes 13 detailed test categories covering functional correctness, edge cases, wrap-arounds, invariant preservation, and error handling.

## Building
Prerequisites:
- GNAT compiler with Ada 2023 support (`-gnat2022`).

To build the project:
$ make

## Usage
To run the test suite and verify all public subprograms:
$ make test

Expected output:
=== STARTING HIDDEN SHIFT PROBLEM TEST SUITE ===
  PASS — 1.1 Brute force finds shift for identical functions
  ...
  PASS — 13.3 Correlation score for shift 15 is 16

=== 39 passed, 0 failed ===

To clean build artifacts:
$ make clean

## Testing & Verification
The test suite (`tests.adb`) implements 13 rigorous test categories with 39 distinct assertions covering:
- **Functional Correctness**: Zero-shift, non-zero shifts, and high-order wrap-arounds.
- **Algorithmic Parity**: Cross-verifying that brute-force and correlation search produce identical results.
- **Edge Cases & Error Handling**: Disjoint function ranges, constant functions, and detection of inconsistent mappings raising `No_Shift_Found`.
- **Invariants**: Round-trip consistency between shift generation and verification.
