# Hough Transform in Ada

## Project Overview
This codebase implements the mathematical **Hough Transform** algorithm in Ada, optimized for high-reliability environments. The Hough Transform is a feature extraction technique used in digital image processing to identify shapes (lines, circles) by mapping edge-detected image coordinates into parameter space. 

## Features
- **Standard Hough Transform (Lines):** Detects straight lines by calculating $(\rho, \theta)$ parameterized coordinates for every foreground pixel. Dynamically boundaries accumulators based on the geometric diagonal of the input image space.
- **Circle Hough Transform:** Detects circular shapes given a discrete array of target radii. Handles 3D parameter space generation $(X_c, Y_c, r)$.
- **Generalized Hough Transform (Interface):** Defines the strict typing boundaries for arbitrary shape detection (which requires dynamic, user-provided R-Table structural templates).
- **Strong Typing Integration:** Employs Ada's native scalar typing bounds to intrinsically prevent physical impossibilities (e.g., fractional pixels, mathematically impossible angles).

## Testing (Verification & Validation)
This project is built around strict V&V principles. The testing philosophy actively assumes the codebase is flawed, asserting heavily against boundaries, data constraints, and mathematical models to prove otherwise.

### Test Categories
1. **Functional Correctness (Tests 2, 3, 4, 6):** Validates that equations strictly correlate to intended outputs. (e.g., verifying a vertical line precisely creates a peak at $\theta=0$). This validates the mathematical mapping.
2. **Boundary & Edge Cases (Tests 1, 5, 8, 12):** Investigates algorithm behavior on 1x1 pixel grids, fully blank canvases, and mathematical limits to ensure the underlying dynamic memory allocation correctly establishes array sizes without off-by-one errors.
3. **Safety & Error Handling (Tests 7, 9, 11, 13):** Proves the code actively mitigates disaster conditions, including negative coordinate grids, array accesses mapped physically outside system memory (out-of-bound circles), and correctly propagating `Not_Implemented` safeguards on template-dependent features.
4. **Saturation Constraints (Test 10):** Ensures highly-dense noisy inputs do not result in variable integer overflows inside the accumulators.

**Why these tests matter:** In critical systems, unhandled mathematical bounds checking (like a circle center projecting beyond system memory bounds) causes systemic failure. These tests mathematically verify the code encapsulates and drops out-of-bound variables correctly.

## Usage

### Compilation
The codebase is designed to operate out of the root directory with no nested dependencies.
Ensure `gnat` and `make` are installed.

To compile all targets:
```bash
make all
