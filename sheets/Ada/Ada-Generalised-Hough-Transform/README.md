# Generalised Hough Transform (GHT)

## Project Overview
This repository provides a reliable, strong-typed Ada implementation of the **Generalised Hough Transform** algorithm. The algorithm allows the detection of arbitrary, complex shapes in image data that cannot be cleanly defined by analytic equations (like lines or circles). It achieves this by creating an R-table (Reference Table) derived from a template image, and subsequently voting on potential center locations in a target image based on edge gradients. 

## Features
- **Standard Translation Variant**: Detects spatial shifts of the template within the target frame.
- **Extended Variant**: Accounts for geometric transformations, specifically composite **Scaling** and **Rotation**.
- **Strong Typing**: Ada-specific numerical abstractions (`Angle_Radian`, `Coordinate`, `Scale_Factor`, `Angle_Degree`) strictly protect variables from semantic cross-contamination.
- **V&V Tested**: Rigorous assertion testing enforcing boundaries, parameter constraints, and numerical precision.

## Testing 
Testing is implemented in a monolithic executable focused strictly on **Verification and Validation (V&V)**. 
We assume by default that the application logic is pessimistic (broken, misaligned, or unguarded) and the suite verifies correctness by definitively disproving these assumptions.

### Test Categories
- **Functional Correctness**: Verifies the core math (e.g., coordinate rotation mapping correctly inside `Cos`/`Sin` arrays, R-table grouping entries correctly by their gradient buckets).
- **Error Handling**: Verifies the API gracefully guards against bad inputs (`Empty Arrays`, `Invalid Min/Max Constraints`) raising appropriate custom exceptions rather than causing undefined behavior.
- **Edge Cases**: Validates modular math wrap-arounds (e.g., negative radians bounding to standard 360-degree lookups) and points voting out of bounds.
- **Robustness**: Verifies signal-to-noise ratios. By injecting randomly misaligned target gradients, it tests that false positives are not overwhelmingly stacked into false peaks.

### Why these tests matter
In critical systems, edge detection systems must not corrupt memory or enter hard-faults (such as unhandled divide-by-zero or array index-out-of-bounds) regardless of target noise. These pessimistic assumption tests prove that the array bounds remain intact even when the image transformation maps shapes drastically outside the camera viewport.

## Usage

### Compilation
The codebase uses GNAT. A `Makefile` orchestrates the GPRbuild system. No subdirectories are used for source files; everything compiles cleanly from root.
```bash
make
