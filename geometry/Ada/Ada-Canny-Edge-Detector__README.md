# Canny Edge Detector (Ada Implementation)

## Project Overview
This repository contains a complete Ada implementation of the Canny Edge Detector algorithm. The code accurately models the multi-stage image processing algorithm used to detect a wide range of edges in images, mapping strictly to mathematical definitions (such as Gaussian blurring, Sobel Operators, Non-maximum suppression, and Hysteresis thresholding). 

## Features
- **Strong Typing**: Image parameters utilize strict `Intensity` types ranging from `0.0` to `255.0` to enforce memory safety and mathematical correctness.
- **Algorithm Variants**: Features two distinct methods for Step 2 Gradient Magnitude calculation:
  - `Exact`: Computes Euclidean distance `sqrt(Gx^2 + Gy^2)`.
  - `Approximated`: Computes Manhattan distance `|Gx| + |Gy|` for performance optimization.
- **Preemptive Edge Handling**: Bounds checking and parameter validations safely halt processing before undefined memory is accessed.
- **Fully Modular**: Individual processing steps (`Gaussian_Blur`, `Compute_Gradients`, `Non_Maximum_Suppression`, `Double_Threshold_And_Hysteresis`) are decoupled and can be invoked or tested individually.

## Testing 

This codebase follows strict **Verification and Validation (V&V)** principles. The philosophy of our test suite is pessimistic: *We assume the code is broken or incorrect.* A test only reports a **PASS** when it actively disproves this assumption by verifying specific requirements.

### What Each Test Category Verifies
1. **Functional Correctness (Algorithm Steps):** Verifies that horizontal, vertical, and diagonal lines produce correct directional angles (0, 45, 90, 135 degrees) and correct magnitudes matching mathematical theory. 
2. **Error Handling (Defensive Constraints):** Validates that inputs violating constraints (e.g., Low Threshold > High Threshold, or Image dimensions smaller than the 5x5 Kernel size) accurately throw `Invalid_Thresholds` or `Invalid_Image_Size` exceptions.
3. **Edge Cases:** Validates handling of uniform arrays (e.g., fully black or fully white images) ensuring algorithms don't produce false positive gradient edges or divide-by-zero exceptions.
4. **Hysteresis Logic:** Validates the connectivity mapping—specifically that a weak edge disconnected from a strong edge is eliminated to `0.0`, while a weak edge neighboring a strong edge is accurately propagated to `255.0`.

### Why These Tests Matter
In critical systems, edge detection is often the first step in machine vision (e.g., autonomous driving or medical imaging). Validation ensures that the pipeline satisfies the intended domain requirements, while Verification asserts that individual mathematical models (like Arctan matrix mappings) don't undergo silent data loss or integer overflow. By exhaustively testing the limits, we guarantee the reliability and determinism required by safety-critical Ada systems.

## Usage

### Compilation
Ensure you have the GNAT Ada toolchain installed. To build the test executable:
```bash
make all
