# Ada Watershed Algorithm Implementation

## Project Overview
This repository provides a strict, type-safe Ada implementation of the **Watershed Algorithm**, a core transformation in mathematical morphology used primarily for image processing and segmentation. The algorithm interprets grayscale image pixels as a topographic surface, mapping intensity to elevation, to compute catchment basins and watershed lines.

## Features
This package implements all three major variants of the algorithm as discussed in standard morphological literature (e.g., Wikipedia):
1. **Marker-Based Watershed (Meyer's Algorithm)**: Utilizes a priority queue to simulate targeted flooding from user-defined marker positions. Ideal for avoiding over-segmentation.
2. **Immersion Algorithm (Vincent & Soille)**: Sorts pixels by intensity level and simulates water rising evenly from local minima to find natural catchment basins.
3. **Topological / Drop of Water**: Computes the steepest descent path for every pixel, naturally assigning paths that fall into the same local minimum to identical segments.

Code handles strict typing, boundary protections, 4-way spatial connectivity, and prevents invalid grid manipulation.

## Testing
We adhere strictly to Verification & Validation (V&V) standards to ensure high reliability for potential systems programming contexts. The test philosophy explicitly operates on the **Disproof of Pessimistic Assumptions**—tests assume the code will fail (e.g., crash, miscalculate, breach boundaries), and a `PASS` state proves the assumption false.

### Verification Matrix
- **Functional Correctness**: Validates that Meyer's algorithm creates `WATERSHED_LINE` boundaries and Topological paths accurately track steepest descents.
- **Error Handling**: Verifies exceptions (`Dimension_Mismatch`) are raised strictly to prevent memory corruption or index-out-of-bounds accesses during array manipulations.
- **Edge Cases**: Ensures 1x1 matrices, zero-marker grids, completely flat plateaus, and disjoint arrays resolve deterministically without fatal loops.
- **Boundary Robustness**: Confirms that connectivity mathematics do not artificially wrap around borders.

*Why this matters:* In strict typed systems (Ada), runtime exceptions or silent matrix wraparounds cause critical failures. By proving algorithms handle plateaus and bounds, we ensure safety and deterministic processing times.

## Usage

### Compilation
The project requires the `gnatmake` compiler. Compilation is handled via the included Makefile.
```bash
# Compile both the main program and the test suite
make all
