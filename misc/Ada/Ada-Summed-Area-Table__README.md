# Summed Area Table (Integral Image) - Ada Implementation

## Project Overview
This repository contains an optimized and rigorously tested Ada implementation of the **Summed Area Table (SAT)** algorithm (also commonly known as an Integral Image). The algorithm represents a critical data structure and algorithm for generating the sum of values within a rectangular subset of a grid in constant $O(1)$ time, extensively used in computer vision (e.g., Viola-Jones object detection) and graphics filtering.

## Features
The codebase strictly enforces strong typing and memory safety, implementing the following variants documented by Wikipedia:
* **Standard 2D SAT:** Fast one-pass calculation.
* **Fast/Cascaded 2D SAT:** Cache-friendly approach calculating prefix sums independently by row, then by column. 
* **Higher-Order (Squared) SAT:** Pre-computes the sums of squared values, utilized for fast variance or standard deviation lookup.
* **Multi-dimensional (3D) SAT:** Computes integrals for volumetric (cuboid) data allowing $O(1)$ sub-volume queries.
* **O(1) Inclusion-Exclusion Queries:** Area extraction procedures designed for safe indexing and custom-bounded unconstrained grids.

## Testing (V&V Principles)
The testing suite (`tests.adb`) operates under the pessimistic assumption that the code is non-functional or susceptible to boundary violations. A test **PASSES only when it actively disproves this assumption** by demonstrating mathematically exact behavior and robust error trapping. 

The test suite consists of 13+ rigorous assertions structured around essential Verification & Validation (V&V) standards critical to reliable system engineering:
* **Functional Correctness:** Verifies that SAT generation outputs and area region queries accurately map to brute-force mathematical summations (Testing equations, cascading behavior, and 3D sub-volume bounds).
* **Edge Cases & Offset Arrays:** Confirms the algorithms are agnostic to array index bounds (e.g., using `5..6, 10..11` bounds rather than just `1..N`) which prevents insidious off-by-one pointer arithmetic faults prevalent in non-Ada implementations.
* **Error Handling & Fault Trapping:** Proves that illegal memory access queries (out-of-bounds coordinates, mathematically impossible inverted rectangles where `X1 > X2`, and mismatched input/output array dimensions) successfully trigger `Invalid_Coordinates` and `Invalid_Dimensions` exceptions before arbitrary memory can be corrupted. 
* **Performance Validation:** Cross-verifies output from the high-performance 'cascaded' generation method directly against the strict standard formulation to ensure optimization does not compromise structural data integrity.

## Usage

### Compilation Instructions
To compile the test suite using `gnatmake` / `gprbuild` alongside the provided Makefile, ensure GNAT is installed on your system.
```bash
# Clean binary and object directories
make clean

# Compile the library and test suite
make all
