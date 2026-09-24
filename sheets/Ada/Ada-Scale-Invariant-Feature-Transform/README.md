# SIFT Implementation in Ada

## Project Overview
This repository contains a robust implementation of the Scale-Invariant Feature Transform (SIFT) algorithm, designed with Ada's strong typing principles for safety and reliability.

## Features
- **Scale-Space Construction:** Multi-octave Gaussian blur implementation.
- **Keypoint Detection:** Difference-of-Gaussian (DoG) extrema detection logic.
- **Localization:** Sub-pixel refinement via Taylor series expansion.
- **Orientation Assignment:** Robust gradient histogram generation.
- **Descriptor Generation:** 128-dimensional feature vector extraction.

## Testing
The test suite validates the algorithm using Verification & Validation (V&V) principles:
- **Verification:** Ensures the architectural components (types, procedures) align with the mathematical requirements of SIFT.
- **Validation:** Ensures the implementation handles invalid inputs (e.g., zero-dimensions) and edge cases without crashing.
- **Robustness:** Using `pragma Assert` to verify invariant states across the pipeline.

## Usage
### Compilation
```bash
make
