# Bluestein's FFT Algorithm (Chirp-Z Transform)

## Project Overview
This project provides a robust, strongly-typed Ada implementation of Bluestein's FFT Algorithm (also known as the Chirp-Z Transform). While standard Radix-2 FFT algorithms are strictly constrained to dataset lengths that are powers of two, Bluestein's algorithm elegantly reformulates the Discrete Fourier Transform (DFT) as a cyclic convolution, thereby allowing for the rapid $O(N \log N)$ transformation of arrays of *any arbitrary size* (including primes).

## Features
- **Forward DFT (Bluestein variant):** Extends FFT speeds to non-power-of-two inputs.
- **Inverse DFT:** Fully reconstructs the original signal with precise numerical scaling.
- **General Chirp-Z Transform (CZT):** Computes generalized frequency spectra along spiral contours instead of merely evaluating on the unit circle (using customized $A$ and $W$ parameters).
- **Embedded Radix-2 Cooley-Tukey Engine:** Native fallback function used internally to compute the cyclic convolution.

## Testing
This repository embraces rigid Verification & Validation (V&V) standards critical to Ada's role in safety-oriented and reliable systems. The test suite is designed under the philosophy that the code is *assumed broken* until empirically proven functional across a battery of functional, edge, and robustness checks. 

Categories of tests include:
- **Functional Correctness:** Ensures accurate phase/magnitude calculations by comparing standard cases (DC signals, impulses) against theoretically perfect expected outcomes. Tests verify that the Inverse DFT successfully recovers the original Forward DFT signal.
- **Edge Cases:** Proves safe handling of potentially hazardous inputs including sequences of size `1`, strictly verified handling of array boundaries offset from index `0`, and explicitly rejected size `0` boundaries.
- **Performance & Constraints Validation:** Ensures the system correctly handles larger Prime numbers (e.g., $N=13$) where Bluestein's $O(N \log N)$ zero-padded convolution strategy activates.
- **Error Handling:** Validates that exceptions (`Invalid_Size`) are correctly raised on math logic errors instead of crashing the environment natively.

These tests prove that regardless of pessimistic assumptions, memory boundaries, or variable mathematical contexts, the API handles operations reliably.

## Usage
### Compilation
The project does not enforce a rigid subdirectory structure. Ensure you are in the root directory where the files reside. Use `make` or `gprbuild`.
```bash
# Using Make
make all

# Using GNAT project files natively
gprbuild -P bluestein.gpr
