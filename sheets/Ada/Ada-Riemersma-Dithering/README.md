# Riemersma Dithering

## Project Overview
This repository provides an Ada implementation of the Riemersma Dithering algorithm. Riemersma Dithering restricts the influence of a dithered pixel to a small, localized area by storing an exponentially decaying history of quantization errors. It translates a continuous-tone grayscale image into a purely black-and-white (binary) image. The algorithm reduces directional artifacts commonly found in standard error diffusion by traversing the image along a space-filling Hilbert curve.

## Features
- **Hilbert Curve Traversal:** Core space-filling curve technique to prevent distracting line-by-line artifacts.
- **Serpentine & Raster Traversals:** Included as algorithmic variants for varying directional results.
- **Exponential & Linear Decay Models:** Custom weighting profiles for historical error decay.
- **Configurable History Size:** Dynamically adjust the memory footprint for error storage (default: 16).
- **Graceful Edge-Case Handling:** Safe mathematical processing for non-square grids, 1x1 extremes, and completely empty matrices.

## Testing
This codebase is equipped with a strict Verification & Validation (V&V) test suite focused on critical systems correctness. We approached the codebase initially assuming the implementation to be incorrect/broken. The test suite is intentionally designed to aggressively disprove this assumption by asserting valid operation under tight constraints.

- **Functional Correctness:** Validates Hilbert space mappings (`D2XY`), proving that curve coordinates are accurately plotted along power-of-two grids, and weight matrices accurately compute normalized values totaling precisely 1.0.
- **Error Handling:** Asserts that out-of-band definitions (like attempting to define a `History_Size` of 0) will result in a safely handled `Invalid_Parameter_Error` exception rather than a silent corruption.
- **Edge Cases:** Proves safe processing bounds on an empty (0x0) array, bounds constraints on a single (1x1) pixel, pure darkness grids, full brightness grids, and irregular non-square array dimensions.
- **Performance & Constraints:** Checks against out-of-range historical accumulations and enforces rigorous state checks (verifying that all resulting pixels evaluate perfectly to either `0` or `255`).

Passing the 14 integrated test assertions proves that the algorithm handles theoretical anomalies successfully and establishes that the codebase meets V&V standards.

## Usage
### Compilation
To compile the system, ensure the GNAT compiler is installed and simply invoke `make`.
```bash
make all
