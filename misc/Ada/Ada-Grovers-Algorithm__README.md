# Grover's Algorithm in Ada 2023

## Project Overview
This project provides a robust, highly verified implementation of Grover's quantum search algorithm and its key theoretical variants (including amplitude amplification, quantum counting, and multi-solution search) simulated in Ada 2023 (ISO/IEC 8652:2023). Grover's algorithm is a fundamental quantum search technique that provides a quadratic speedup over classical unstructured search algorithms, navigating a search space of size N using approximately (pi/4) * sqrt(N/M) oracle evaluations.

## Features
- Standard Grover Search: Finds a marked target item in an unstructured search space with high probability.
- Amplitude Amplification: Generalizes the search technique to support custom initial weight distributions.
- Quantum Counting: Estimates the number of marked items in the search space.
- Multi-Solution Search: Optimized iteration scaling for search spaces containing multiple valid target items.
- Strong Typing & Contracts: Strict domain types (Search_Space_Size, Item_Index, Iteration_Count, Probability) paired with Ada contract aspects (Pre, Post).
- Comprehensive Test Suite: Standalone test executable (tests.adb) featuring 13 rigorous test categories and 39 individual assertions.

## Building and Usage
Prerequisites: GNAT compiler supporting Ada 2023 (gnatmake).

To build and run the test suite:
make test

To clean build artifacts:
make clean

Expected Output:
Running make test executes all 13 test suites, printing individual assertion outcomes (PASS) and concluding with summary confirmation (0 failed).

## Testing & Verification
The test suite (tests.adb) covers the following categories:
- Functional Correctness: Validating that standard and generalized search variants successfully identify target items across varied search space sizes (N = 2, 8, 16, 64).
- Edge Cases: Single-element search spaces, edge indices (0 and N-1).
- Error Handling: Robust exception raising (No_Solution_Found) when zero target items satisfy the oracle condition.
- Invariants & Bounds: Verification of optimal iteration formulas, monotonicity properties, and quantum counting accuracy.
