# Trigonometric Interpolation in Ada

## Project Overview
This codebase provides a robust, strongly-typed Ada implementation of the **Trigonometric Interpolation** algorithm. Based on Discrete Fourier Transform (DFT) principles, it constructs a continuous trigonometric polynomial $p(x)$ that exactly passes through a set of uniformly spaced discrete data points $y_k$ on the periodic interval $[0, 2\pi)$. 

## Features
- **Even (N = 2K) Variant:** Correctly calculates highest frequency (Nyquist) term normalized by $1/N$.
- **Odd (N = 2K + 1) Variant:** Standard DFT normalization handling for symmetric frequency pairs.
- **Strong Typing:** Encapsulated in cleanly typed records defining bounds and dimensions mathematically correctly.
- **Dynamic Array Length Support:** Automatically configures limits, bounds, and normalizations according to the length of the supplied Real Array.
- **Arbitrary Index Tolerance:** Input arrays can use any valid arbitrary Ada index ranges (0-based, 1-based, or n-based) uniformly mapped to standard evaluation intervals.

## Testing
This repository adheres strictly to Validation & Verification (V&V) standards to guarantee algorithm accuracy. Using a pessimistic assumption that the code is non-functional by default, tests are designed to disprove these assumptions only if the underlying logic is perfectly executed.

### What the Tests Verify
- **Functional Correctness:** Ensure exact node interpolation for both Even and Odd variants, including correct behavior on pure standard trigonometric waves (Sine/Cosine decomposition).
- **Boundary/Edge Cases:** Proving stability at $N=1$ (constants), $N=2$ (Nyquist boundary), and arbitrary shift equivalence.
- **Error Handling:** Validates robustness via exception trapping against meaningless parameters ($N=0$).
- **Mathematical Continuity:** Proves trigonometric wrap-around properties, asserting that mathematically $f(0) \equiv f(2\pi) \equiv f(4\pi)$.

### Why These Tests Matter
In critical numeric/scientific computing, assumptions risk severe propagation errors. These tests validate:
1. **Verification (Code matches spec):** Ensures formulas properly replicate theoretical continuous analogs mapped from discrete samples.
2. **Validation (Code meets intent):** Asserts bounded responses outside node points avoiding spurious interpolation resonances (Runge's phenomenon).
3. **Reliability:** Preemptively prevents crashes (e.g. division by zero bounds) and enforces expected operational boundaries.

By passing 13+ rigorous validations mapping across frequencies, dimensional scaling, and exact geometric constraints, the tests prove the functional integrity of the Ada codebase over baseline pessimistic assumptions. 

## Usage

### Compilation
The provided Makefile configures compiling both the primary demonstrator and the test suite seamlessly:
```bash
make all
