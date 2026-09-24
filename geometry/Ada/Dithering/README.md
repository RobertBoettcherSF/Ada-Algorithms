# Ada Image Dithering Library

## Project Overview
This repository implements a modular, high-performance Ada library for Image Dithering algorithms. Dithering is a technique used in computer graphics to create the illusion of color depth in images with a restricted color palette by applying noise or quantization error diffusion.

## Features
The library features strong typing (`Color_Value` and `Image` arrays) and includes the following fully implemented dithering algorithms:
*   **Thresholding**: Standard hard quantization (no dithering).
*   **Random Dithering**: Uniform noise distribution prior to quantization.
*   **Ordered Dithering**: Uses a 2x2 Bayer Matrix for distinct geometric patterning.
*   **Floyd-Steinberg**: The standard error diffusion algorithm (7-3-5-1 matrix).
*   **Atkinson**: Error diffusion that preserves sharp edges by only propagating 75% of the calculated error.
*   **Jarvis-Judice-Ninke**: Heavy duty error diffusion utilizing a massive 48-divisor matrix.
*   **Stucki**: A slightly faster, lower artifact-prone alternative to JJN error diffusion.

## Testing
This project embraces strict Verification and Validation (V&V) standards tailored for resilient, fault-tolerant critical systems. A dedicated test suite evaluates the codebase to prove that initial pessimistic assumptions (e.g., "error diffusion will crash with Out_Of_Bounds on edge pixels") are false.

**Test Categories & What They Verify:**
*   **Functional Correctness**: Ensures mathematical functions (Rounding, Clamping) output exactly `0.0` or `1.0` as intended.
*   **Boundary & Edge Cases**: Tests extreme edge cases such as empty images (`1..0`), 1x1 grids, and out-of-range floats. Validates that deep nested-neighbor matrices (JJN/Stucki) do not trigger `Constraint_Error` array violations.
*   **Error Handling**: Confirms quantization error successfully shifts to the immediate right neighbor in standard 2x2 error propagation without breaching safety constraints.

**Why these tests matter:**
In systems programming, unhandled array out-of-bounds calculations are catastrophic. Error diffusion matrices push errors mathematically "forward" and "downward" into arrays. Testing verifies that all variants cleanly check spatial constraints before attempting matrix application, preventing memory access violations and ensuring absolute reliability.

## Usage

### Compilation
The codebase provides a `Makefile` and `dithering.gpr` for streamlined building. Everything sits in the root directory.

To build the executable and the test suite:
```bash
make all
