# Lemke-Howson Algorithm in Ada

## Project Overview
This project provides a robust, strongly-typed Ada implementation of the **Lemke-Howson Algorithm** for calculating Nash Equilibria in two-player non-zero-sum bimatrix games. The algorithm leverages complementary pivoting across dual tableaux to derive mathematically proven strategy probabilities.

## Features
- **Strictly Positive Transformation**: Automatically normalizes and safeguards matrix data containing zero or negative payoffs.
- **Variant Support (Initial Dropped Label)**: Implements algorithmic branching via the initial dropped label. Modifying the initial label permits discovery of alternate equilibria inside games containing multiple (e.g., Battle of the Sexes).
- **Asymmetric Support**: Fully calculates matrices of differing dimensions (N x M vs M x N mappings).
- **Graceful Error Handling**: Implemented safety boundaries using Ada's strict typing and Exception models.
- **Dynamic Sizing**: Implemented via discriminant records `Equilibrium (M, N)`.

## Testing 

This suite adopts stringent Verification and Validation (V&V) methodologies, essential for critical systems architecture. Our testing operates under a pessimistic assumption: **the algorithm is broken until dynamically proven otherwise via asserting absolute optimality.**

Tests are categorized as follows:
- **Functional Correctness (Validation)**: Rather than hard-coding pivoting paths, we evaluate the system’s mathematical consequence. For any provided matrix array `A` and `B`, the test suite dynamically models utility expectations and checks that `Eq` provides a perfect **Nash Equilibrium**, validating intended mathematical use.
- **Error Handling (Verification)**: We verify bounds logic, asserting exceptions are caught on shape mismatch, empty inputs, or out-of-bounds label drops. 
- **Edge Cases**: Zero payoffs, trivial 1x1 limits, and asymmetrical dimensions (2x3).
- **Performance/Robustness**: Assertions evaluate floating-point stability limits across excessively large values (`1.0e6`) and micro-fractions (`1.0e-6`), preventing matrix singularity or division-by-zero defects.

These tests guarantee reliability and logical safety. They definitively prove the code works because any failure to calculate optimal local maximal utilities throws an immediate assertion violation. A `PASS` means the sub-optimal assumption was comprehensively disproven.

## Usage

### Compilation
The codebase uses a GNAT Project file alongside a simplified `Makefile`. To compile:
```bash
make all
