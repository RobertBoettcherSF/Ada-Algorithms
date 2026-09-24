# VEGAS Multidimensional Monte Carlo Integrator

## Project Overview
This repository implements the VEGAS algorithm in Ada. Originally developed by G. P. Lepage (1978), VEGAS is an advanced Monte Carlo technique for multidimensional numerical integration. It utilizes importance sampling by dynamically adapting a multi-dimensional grid to concentrate evaluations where the integrand has the highest magnitude, thus significantly reducing estimation variance.

## Features
- **Multidimensional Integration:** Supports $N$-dimensional integration boundaries.
- **Adaptive Grid Optimization:** Continuously updates grid segment distributions iteratively.
- **Static Variant:** Toggleable parameter to bypass grid updates, transforming the method into standard uniform Monte Carlo Integration.
- **Grid Smoothing Variant:** Standard VEGAS employs neighboring-bin smoothing to prevent rapid grid distortions; this implementation allows toggling this feature on or off to accommodate specific function behaviors.
- **Strong Typing:** Written in robust Ada, utilizing constraint-checked generic arrays for memory safety and parameter confidence.

## Testing
This repository includes a stringent Verification & Validation (V&V) test suite structured explicitly to challenge pessimistic assumptions about the codebase (i.e., assuming the implementation will crash or miscalculate under pressure until proven otherwise). 

### What The Tests Verify
1. **Functional Correctness:** Verifies basic geometric evaluations (1D Constant, 1D Linear, 2D planes, 3D hyper-cubes).
2. **Algorithmic Edge Cases:** Validates robustness concerning functions traversing negative values (requiring accurate absolute weight tracking within the VEGAS accumulation arrays) and infinitesimally small integration boundaries. 
3. **Control Constraints & Error Handling:** Explicitly tests zero-dimension input, null-pointer integrands, negative iterations, or inverted `(Upper, Lower)` domain limits. Ensures `Constraint_Error` or `Invalid_Input_Error` traps execution gracefully.
4. **Variant Coverage:** Validates correct execution pathways when Grid Smoothing and Adaptability features are independently disabled.

### Why These Tests Matter
In critical numeric computation systems, a mathematical failure (like a divide-by-zero during probability mapping, or silent NaNs propagating from empty grids) can cascade into catastrophic system errors. These tests validate safety principles (catching invalid states before memory manipulation) and verify adherence to original algorithm requirements per strict V&V standards. When a test prints `PASS`, it objectively disproves the assumption that a specific operational threshold causes failure.

## Usage

### Compilation
The project requires the GNAT toolchain. Compilation uses a single root-directory `Makefile`. No sub-directories (`src`, `obj`, etc.) are necessary.

To compile:
```bash
make
