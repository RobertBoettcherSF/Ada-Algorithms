# Fast Cosine Transform (Ada)

## Project Overview
This project provides a robust, strongly-typed Ada implementation of the Discrete Cosine Transform (DCT) family of algorithms. It primarily features the "Fast Cosine Transform", utilizing Makhoul’s algorithm to convert an $O(N^2)$ direct mathematical calculation into an $O(N \log N)$ execution via a customized Decimation-in-Time Complex Fast Fourier Transform (FFT).

## Features
- **DCT-II (Standard Fast Cosine Transform)**: Dynamically routes data through a Radix-2 FFT when $N$ is a power of 2 for maximum performance.
- **DCT-III (Inverse Fast Cosine Transform)**: Reversible mapping back to the time-domain.
- **DCT-I & DCT-IV**: Includes alternative transform definitions often used in signal processing and differential equation mapping.
- **Dynamic Fallbacks**: Automatically falls back to a precise $O(N^2)$ direct computation if an array's length is not a power of 2.
- **Ada Safe Types**: fully handles 1-based indices, 0-based indices, and arbitrary array slice bounds via `Array'First` bindings without raising native `Constraint_Error`s.

## Testing
This codebase adopts strict Verification and Validation (V&V) principles standard in safety-critical Ada systems. 
- **Pessimistic Assumption Strategy**: The test suite operates under the assumption that the code is incorrect or prone to failure. A `PASS` specifically indicates that the failure assumption has been mathematically or behaviorally disproved.

### What the Tests Verify
- **Functional Correctness**: Proofs of reversibility (running an array through DCT-II then DCT-III to recover the original signal) and mathematically proven responses to DC and Impulse inputs.
- **Error Handling**: Verifies that violating pre-conditions (e.g. Empty arrays, Array length < 2 for DCT-I) reliably safely faults to `Invalid_Argument_Error` rather than unpredictable segmentation faults.
- **Edge Cases**: Zero-length arrays, Length-1 arrays, and Arrays with non-standard boundary scopes (e.g., initialized `array (5..8)`).
- **Performance Thresholds**: Evaluates the stability of the recursive/iterative Cooley-Tukey nested loops with large bounds (N=32+ arrays).

### Why These Tests Matter
Mathematical modeling algorithms heavily abstract pointer manipulations. Without rigid validation of boundary checks and type coercion sizes, the reordering loops inherently present buffer overflow and alignment risks. These tests prove strict compliance with specification requirements despite varying memory offsets.

## Usage

### Compilation
The project supports compilation directly from the root structure using the GNAT compiler wrapper `make`:

```bash
# Compile both the main executable and the test suite
make all
