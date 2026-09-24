# Gerchberg-Saxton Phase Retrieval Algorithm (Ada)

## Project Overview
This project implements the Gerchberg-Saxton (GS) algorithm in Ada. Originally developed in optics, GS is an iterative phase retrieval algorithm used to calculate the missing phase of a complex wave field from intensity/amplitude measurements gathered at two different planes (such as the focal and image planes). 

The module leverages strong typing and strictly enforces domain separation between Spatial Fields and Frequency Fields via Discrete Fourier Transforms (DFT).

## Features
- **Standard Gerchberg-Saxton (Error Reduction):** The classic 4-step iterative process alternating between forward and inverse Fourier transforms while injecting target amplitudes.
- **Fienup Hybrid Input-Output (HIO) Variant:** A more robust variant that uses a relaxation factor (`Beta`) to combine current and previous iterations, preventing the algorithm from stagnating in local minima.
- **Standalone Subsystems:** Custom 1D Discrete Fourier Transform (DFT) and Inverse DFT (IDFT) functions handling Complex mathematics inherently without external C-bindings.
- **Strict Ada Typing:** Type safety enforced across `Real`, `Complex`, and variable length generic array instantiations.

## Testing
This project embraces a rigorous Verification & Validation (V&V) testing philosophy. The test suite operates on a pessimistic assumption: **the code is assumed to be broken unless proven otherwise.** 

### What The Categories Verify
1. **Functional Correctness (Tests 1-3, 11-12):** Verifies the underlying mathematics. Tests assert that the DFT/IDFT transforms behave perfectly on impulse signals, satisfy the Identity matrix inversion property, and conserve transform energy. 
2. **Error Handling & Safety (Tests 4-7):** Validates software reliability by ensuring arrays of zero size, or arrays mapping incompatible physical dimensions, instantly halt via custom exceptions (`Dimension_Mismatch_Error`, `Invalid_Input_Error`).
3. **Edge Cases & Boundaries (Tests 8-10):** Ensures safe boundaries. Iteration counts of zero safely abort without execution traps, and extracted mathematical phase calculations are mathematically validated to never exceed `[-Pi, Pi]` limits.
4. **Performance & Variant Distinctiveness (Test 13):** Proves that the HIO modification successfully alters transform state gradients compared to Standard GS.

### Why These Tests Matter
In optical computation and signal processing, phase artifacts generate destructive real-world anomalies. A mathematical shift out of phase bounds or an unhandled null array causes buffer underflows and calculation rot in production. By structurally falsifying failure states, these 13+ tests provide quantifiable confidence for critical system deployment.

## Usage

### Compilation
The codebase uses a standard GNAT Toolchain and Makefile. Ensure you have `gnatmake` and `gprbuild` installed.
```bash
# Compiles both the main executable and the test suite
make all
