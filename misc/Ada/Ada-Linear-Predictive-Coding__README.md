# Linear Predictive Coding (LPC) in Ada

## Project Overview
This repository implements the Linear Predictive Coding (LPC) scheduling and filtering algorithms. LPC is heavily utilized in audio signal processing and speech encoding to represent the spectral envelope of a digital signal using the information of a linear predictive model. This critical-system oriented Ada codebase is robust against unbounded inputs and mathematically unsafe parameters.

## Features
- **Autocorrelation Method:** Uses Levinson-Durbin recursion for efficient Toeplitz matrix execution.
- **Covariance Method:** Employs natively implemented linear system solvers via Gaussian elimination.
- **Burg's Method:** Calculates reflection coefficients natively minimizing forward/backward errors directly ensuring filter stability.
- **Full Life-Cycle Synthesis:** Bi-directional implementation (Analysis and full residual-based Synthesis). 
- **Graceful Error Handling:** Explicit exceptions (`Invalid_Order`, `Empty_Signal`, `Math_Error`) to intercept system failure modes securely.

## Testing (V&V Principles)
The testing suite (`tests.adb`) takes a strictly pessimistic Verification and Validation (V&V) philosophy. **Tests assume the system is non-functional or structurally flawed, and a test only PASSES when that assumption is actively disproven.**

- **Functional Correctness:** Ensures Analysis followed by Synthesis perfectly replicates the original signal (identity principle).
- **Error Handling:** Validates that native exceptions (`Empty_Signal`, `Math_Error`) trigger safely in edge bounds without propagating lower-level `Constraint_Error` crashes. 
- **Edge Cases:** Evaluates division-by-zero behaviors natively (e.g., passing entirely flat or 0-bounded signals to the Levinson-Durbin recursions).
- **Why this matters:** Safety-critical domains using Ada require provable deterministic behavior. Treating the code as "guilty until proven safe" guarantees reliability aligned with high-integrity software standards.

## Usage

### Compilation
The codebase uses a simple Makefile utilizing `gnatmake` (ensure GNAT is installed on your system). Everything operates from the project root.

```bash
make all
