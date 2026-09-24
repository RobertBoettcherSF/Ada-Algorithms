# Marr–Hildreth Edge Detection in Ada

An Ada 2012 implementation of the **Marr–Hildreth Edge Detection Algorithm** and its fast Difference-of-Gaussians (DoG) approximation.

## Project Overview

The Marr–Hildreth algorithm is an edge detection operator in computer vision. It locates continuous edge curves in digital images where rapid intensity transitions occur. The process operates by:
1. Convolving the image with a **Laplacian of Gaussian (LoG)** operator (or **Difference of Gaussians / DoG** approximation).
2. Identifying **zero-crossings** in the filtered second-derivative image to locate edge contours precisely.

## Features

- **Laplacian of Gaussian (LoG) Variant**: Exact continuous derivative operator discretized into a spatial matrix kernel (Mexican Hat Wavelet).
- **Difference of Gaussians (DoG) Variant**: Fast approximation combining two Gaussians with distinct scales ($\sigma$ and $1.6\sigma$).
- **Configurable Zero-Crossing Thresholding**: Noise suppression via minimum sign change magnitude checks.
- **Strong Typing**: Built using custom Ada types (`Intensity`, `Binary_Pixel`, fixed-dimension image grids) preventing accidental scalar scaling or unit errors.
- **Robust Exception Model**: Standardized safety validation for parameter arrays and grid dimensions.

## Testing

This project incorporates continuous Verification and Validation (V&V) standards through a pessimistic test execution approach (`tests.adb`).

### Verification & Validation (V&V) Principles
- **Verification**: Asserts that the implementation matches theoretical mathematical specifications (e.g., matrix symmetry, step function response).
- **Validation**: Ensures the algorithm performs its intended task reliably without crashing under boundary or fault conditions.

### Test Categories (13+ Tests)
1. **Parameter Validation**: Enforces odd kernel dimensions and positive standard deviations.
2. **Symmetry Checks**: Ensures LoG and DoG filter kernels remain standard symmetric Mexican hat operators.
3. **Edge Response Correctness**: Verifies step-edge detection across vertical, horizontal, and diagonal contours.
4. **Uniform Field Handling**: Disproves false-positive generation in uniform brightness regions.
5. **Exception Robustness**: Validates boundary-mismatch and parameter fault handling.
6. **Impulse Response**: Verifies single-pixel point edge boundary triggers.

Tests assume the code is broken by default and **PASS** when assertions disprove this assumption.

## Usage

### Prerequisites
- GNAT Ada Compiler (GNAT Community or GCC Ada)
- GNU Make

### Compilation
Build both main demo application and test binaries:
```bash
make
