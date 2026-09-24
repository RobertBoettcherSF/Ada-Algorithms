# Ordered Dithering Algorithm in Ada

## Project Overview
This project provides a robust, strongly-typed Ada implementation of the **Ordered Dithering** image processing algorithm. Ordered dithering is an image dithering algorithm used to display a continuous image on a display of less color depth. The algorithm reduces color depth while maintaining visual fidelity by applying a pre-calculated threshold map (known as a Bayer matrix) to pixel values, creating crosshatch patterns instead of abrupt color bands. 

## Features
This module fully implements all major variants described in algorithm literature:
* **Pre-calculated Threshold Maps:** Dynamic generation of normalized Bayer Matrices for any power-of-two size ($2\times2$, $4\times4$, $8\times8$, etc.).
* **Monochrome Dithering:** Applies ordered dithering to single-channel (Grayscale) imagery.
* **Color Dithering:** Independent channel quantization applying the Bayer matrix logic across standard RGB imagery.
* **Custom Quantization Levels:** Support for variable target bit depths (e.g., 2 levels for 1-bit Black & White, 4 levels for 2-bit grayscale, scaling uniquely per RGB channel).

## Testing (Verification & Validation)
This repository includes a stringent Validation & Verification (V&V) test suite built into `tests.adb`. Following critical-systems testing philosophy, the suite explicitly **assumes the code is incorrect and broken**. A test only registers a `PASS` when that pessimistic assumption is irrefutably disproved by system behavior.

### What the test categories verify:
1. **Mathematical Accuracy (Functional Correctness):** Ensures the recursive Bayer matrix logic strictly matches the mathematical definition $M(i,j)/n^2 - 0.5$ and perfectly aligns with historical matrices (Tests 1, 6).
2. **Edge Cases & Boundaries:** Validates behavior on minimum constraints like $1\times1$ images, matrix misalignment across non-even image dimensions, and boundary inputs ($0.0$, $1.0$, pure Black, pure White). 
3. **Robust Error Handling:** Checks safe failure. Submits mathematically invalid operations (e.g., $3\times3$ dimensions, 1-level quantization constraints, empty pixel arrays) and guarantees safe interceptions via custom Exceptions (Tests 2, 7, 8, 11).

### Why these tests matter:
In low-level processing domains, uncaught algorithmic scale errors result in memory segmentation faults or graphic artifacting. By proving the exception handlers and matrix array bounds are impenetrable, we fulfill high-assurance verification standards before the algorithm processes raw data arrays.

## Usage
The system does not require an external `src` folder; all source files belong in the project root.

### Compilation
Ensure you have the GNAT Ada compiler installed. Compile utilizing the provided `Makefile`:
```bash
make all
