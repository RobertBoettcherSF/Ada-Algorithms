# Hamming Distance Algorithms in Ada

## Project Overview
This repository contains a strictly-typed, mission-critical implementation of the **Hamming Distance** metric in Ada. First proposed by Richard Hamming, this algorithm measures the minimum number of substitutions required to change one sequence into another. 

## Features
This codebase implements ALL primary variants of the Hamming distance/weight calculations:
1. **General Strings:** Character-by-character comparison (used in text processing, DNA sequencing).
2. **Bit Arrays:** Strongly-typed Boolean vector comparisons (telecommunications, error-correction).
3. **Unsigned_64 Fast Popcount:** Lowest-level binary/hardware simulation using Brian Kernighan's XOR popcount algorithm for blazing-fast 64-bit integer distances.
4. **Hamming Weight:** Calculates the number of non-zero elements, strictly calculating a sequence's variance against a zero-vector baseline.

## Testing (Verification and Validation - V&V)
Reliable software starts with pessimistic assumptions. This repository relies on an aggressive assumption-disproval paradigm. The test suite operates under the assumption that the code *does not work*. Passing a test effectively *disproves* a specific assumption of failure.

### Test Categories
*   **Functional Correctness:** Verifies Wikipedia reference datasets (e.g., comparing 'karolin' and 'kathrin') to assert that the implementation natively matches mathematical specifications.
*   **Edge Cases:** Verifies boundary conditions, such as testing zero-length string comparisons and extreme boundaries (`Unsigned_64` bounds returning exactly 64 divergence bits).
*   **Error Handling (Robustness):** Verifies that comparing strings or bit vectors of unequal length correctly intercepts the fault and intentionally raises `Length_Mismatch_Error` instead of allowing memory bounds corruption.
*   **Performance / Hardware Limits:** The `Unsigned_64` variant ensures that direct bitwise operations scale without memory overhead, crucial for embedded applications.

### Why These Tests Matter
In critical systems (aerospace, cryptography, telecommunications), arbitrary assumptions lead to catastrophic faults. These tests enforce memory safety, mathematically verify deterministic outcomes, and prevent array-bounds drifting (testing sub-slices in Ada), guaranteeing compliance with rigorous V&V standards. 

## Usage
The system handles compilation via standard POSIX Makefiles wrappers around `gnatmake`.

### Compilation
```bash
# Compile both the main application and the test suite
make all
