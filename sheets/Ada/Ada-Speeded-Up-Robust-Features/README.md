# SURF (Speeded Up Robust Features) in Ada

## Project Overview
This project implements the Speeded Up Robust Features (SURF) algorithm in Ada, prioritizing strong typing, algebraic safety, and strict Verification and Validation (V&V) methodologies. SURF is a patented local feature detector and descriptor algorithm used in computer vision tasks like object recognition, image registration, and 3D reconstruction.

## Features
- **Integral Images:** O(1) query time for arbitrary rectangular area sums.
- **Fast-Hessian Detector:** Box-filter approximations of Gaussian second-order derivatives.
- **All Core SURF Variants:**
  - `Standard_SURF`: Scale/rotation invariant, 64-dimensional descriptor.
  - `U_SURF` (Upright SURF): Faster extraction ignoring rotation, robust to $\pm 15^\circ$ tilts.
  - `SURF_128`: Extended 128-dimensional descriptor for distinctive features.
  - `U_SURF_128`: Upright variant with 128 dimensions.

## Testing (Verification & Validation)
Testing operates on a **pessimistic assumption philosophy**: we assume the mathematical approximations and logical dispatchers are fundamentally flawed, and write assertions that *pass only when those pessimistic assumptions are disproven*. 

### Test Categories
- **Functional Correctness:** Ensures algebraic equations (like Integral Images and box filters) perfectly mimic Gaussian derivative calculations (Tests 1, 3).
- **Edge Cases:** Validates robustness against boundary logic and illegal constraints, such as Zero-dimensional matrices (Tests 2, 4).
- **Error Handling:** Asserts strict isolation between 64-bit and 128-bit variant pipelines, preventing catastrophic pointer/memory overlaps common in array-heavy CV implementations (Tests 9, 10).
- **Performance Constraints:** Verifies Haar-wavelet logic bypasses in U-SURF execute appropriately, ensuring computational load is actually shed during upright operation (Tests 6, 12).

### Why These Tests Matter
In critical systems (such as visual odometry for aviation/robotics), feature-matching inaccuracies or out-of-bounds matrix evaluations cause cascading failure. Validating the core Hessian approximation and bounding limits proves the foundation matches formal algorithmic constraints.

## Usage

### Compilation
To compile the library and executables using GNAT, run:
```bash
make all
