# Richardson-Lucy Deconvolution in Ada

## Project Overview
This repository provides a robust, type-safe implementation of the Richardson-Lucy deconvolution algorithm. This algorithm is an iterative procedure used to recover a latent image that has been blurred by a known Point Spread Function (PSF).

## Features
- **Strongly Typed Matrix Operations:** Custom `Matrix` type handling for 2D numerical data.
- **Richardson-Lucy Core:** Iterative deconvolution logic using adjoint (flipped) kernels.
- **Robust Convolution:** 2D convolution helper with boundary handling.
- **Error Handling:** Built-in checks for invalid PSF dimensions and constraint violations.

## Testing
The project uses a dedicated `tests.adb` suite to verify both functional correctness and numerical robustness. 
- **Verification:** Ensures the code matches the mathematical requirements (e.g., identity kernel identity).
- **Validation:** Ensures the code meets real-world constraints (e.g., handling edge-case inputs like zeros and empty arrays without crashing).

These tests act as a "break-the-code" challenge:
1. **Functional Correctness:** Verifying that standard inputs yield expected outputs.
2. **Error Handling:** Asserting that the system properly raises exceptions on invalid data (e.g., Even-dimension kernels).
3. **Boundary Testing:** Checking behavior on extreme input sizes and edge cases (zeros, 1x1 matrices).

## Usage
### Compilation
Ensure you have `gnatmake` installed.
```bash
make all
