# Blind Deconvolution in Ada

## Project Overview
This project provides a robust, strictly-typed Ada implementation of **Blind Deconvolution** algorithms. Blind deconvolution permits the recovery of a target scene or signal from blurred data when the Point Spread Function (PSF) is unknown or poorly defined. 

This library focuses on 1D signal arrays (useful in audio and seismic processing, or as a fundamental building block for 2D images) and ensures mathematical safety using Ada's intrinsic constraints.

## Features
- **Variant 1: Maximum Likelihood (Richardson-Lucy Blind Deconvolution)** - Iteratively updates both the Signal and PSF while maintaining positivity constraints and energy conservation.
- **Variant 2: Alternating Minimization (Gradient Descent Proxy)** - A generalized iterative approach inspired by Ayers-Dainty that minimizes residual error over time.
- **Variant 3: Wiener Filter Proxy (Regularized Linear Inverse)** - A non-iterative approximation utilized primarily in seismic and audio data where the Signal-to-Noise Ratio (SNR) acts as a regularization parameter.
- **Strong Typing & Safety:** Uses custom `Real` and `Signal_Array` types. Handled division-by-zero, bounds mismatches, and energy normalization.

## Testing
This software is built around stringent **Verification and Validation (V&V)** principles. The test suite operates on the pessimistic assumption that the code is non-functional or broken. A `PASS` proves the assumption false (meaning the system behaves perfectly).

### What Each Test Category Verifies
1. **Functional Correctness (Tests 3, 4, 10, 12):** Validates underlying mathematical operations (Convolution, Cross-Correlation) are mathematically sound.
2. **Error Handling (Tests 5, 6, 8):** Checks that custom exceptions (`Dimension_Mismatch`, `Invalid_Input`) trigger correctly.
3. **Edge Cases (Tests 2, 11, 14):** Ensures the code can survive zeroes, extreme SNR parameters, and physically impossible negative signals without returning `NaN` or crashing.
4. **Safety & Bounds (Tests 1, 7, 13):** Verifies Ada's strong typing traps logic faults (e.g., zero iterations) and algorithms maintain energy boundaries (normalization).

### Why These Tests Matter
In critical systems (like seismic plotting for drilling or astronomical imaging), undetected NaNs or dimension violations can lead to catastrophic downstream software failures. These tests ensure reliability, prevent memory leaks, and assert absolute correctness against requirements.

## Usage
### Compilation
The codebase requires an Ada 2012 compliant compiler (GNAT). Run the provided Makefile to compile:
```bash
make
