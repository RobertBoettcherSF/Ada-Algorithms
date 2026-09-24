# Digital Differential Analyzer (DDA) in Ada 2023

## Project Overview
This project implements the Digital Differential Analyzer (DDA) graphics algorithm in Ada 2023 (ISO/IEC 8652:2023). The DDA algorithm is a scan-conversion line algorithm used in computer graphics to compute pixel coordinates approximating a straight line segment between two endpoints.

## Features
- **Floating-Point DDA Variant**: Uses floating-point arithmetic to step along the dominant axis and calculate intermediate pixel positions.
- **Integer-Only / Fixed-Point DDA Variant**: Uses fixed-point scaling factor arithmetic to avoid floating-point performance penalties while maintaining raster precision.
- **Strong Typing**: Strongly typed coordinate domains, bounded pixel buffers to prevent heap allocations, and strict Ada 2023 contract annotations (`Pre`, `Post`).
- **Comprehensive Test Suite**: Includes 13 rigorous test categories verifying edge cases, negative slopes, horizontal/vertical lines, and helper functions.

## Usage
To build and run the test suite, use the provided Makefile:

make test

Expected output upon successful execution:

Running tests...
  PASS — 1.1 Buffer length is 1 for identical points
  ...
===  39 passed,  0 failed ===

## Testing
The test suite (`tests.adb`) verifies:
1. **Functional Correctness**: Rasterization accuracy across horizontal, vertical, diagonal, and arbitrary slope lines.
2. **Edge Cases**: Zero-length lines (single points), negative coordinate quadrants.
3. **Algorithm Variants**: Side-by-side verification of both Floating-Point DDA and Integer DDA implementations.
4. **Invariants**: Buffer bounds, pre-condition adherence, and step counting correctness via helper functions.

## Building
### Prerequisites
- GNAT compiler supporting Ada 2023 (e.g., GNAT 13+ or equivalent).
- GNU Make.

### Build Commands
- `make` or `make all`: Compiles the project and builds the executable inside `bin/`.
- `make test`: Builds and executes the standalone test suite.
- `make clean`: Removes build artifacts (`obj/` and `bin/`).
