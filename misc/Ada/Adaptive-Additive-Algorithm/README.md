# Adaptive-Additive (AA) Algorithm Ada Implementation

## Project Overview
This project provides a reliable, statically typed Ada implementation of the **Adaptive-Additive (AA) Algorithm**. Originally created for reconstructing the spatial frequency phase in stellar interferometry, it iteratively bridges spatial and intensity (amplitude) domains. It uses discrete Fourier transformations while evaluating the differences between an observed amplitude and a target desired intensity constraint to deduce unknown wave variables.

## Features
- **Strictly Typed Implementations**: Built natively relying heavily on Ada's strong typing guarantees (no raw pointers, native mathematical boundary definitions).
- **Standard AA Variant**: Permits dynamic thresholding through a continuous adjustable `Mixing_Ratio` between `0.0` and `1.0`. 
- **Gerchberg-Saxton Limits (`Gerchberg_Saxton`)**: Programmatic abstraction automatically tuning the algorithm to the specific edge limit `a=1.0`.
- **Fixed-Amplitude Limit (`Fixed_Amplitude`)**: Bound to the reverse limit condition `a=0.0`.
- **Pure Ada Internal DFT Engine**: Avoids linking to external C-language Fourier implementations to strictly assure Ada safety rules encapsulate algorithm execution.

## Testing
Following rigid Verification and Validation (V&V) methodologies, testing operates on a "pessimistic" assumption: the code is inherently broken or hostile to inputs. Test suites proactively generate failure vectors, with tests registering a `PASS` only when they empirically disprove these bad assumptions.

- **Functional Correctness Verification (Tests 1-4, 8, 12)**: Verifies that core mathematical behaviors (such as trigonometric moduli, spatial phase extraction, and DFT/iDFT reversibility boundaries) perform perfectly without artifact drifting.
- **Error Handling Validation (Tests 5, 6, 7)**: Inputs malformed structures into the framework (mismatched array allocations, empty data matrices, physically impossible negative intensity measurements). By successfully aborting with trapped `Invalid_Input_Error` exceptions, it verifies the code will not silently calculate incorrect values if sensor inputs fail.
- **Edge Cases Validation (Tests 9, 10, 13)**: Verifies boundaries such that mathematical operations on the absolute extremes of variables (`0.0` and `1.0` Mixing Ratios) cannot crash the system, and explicitly verifies final outputs are bound theoretically between $[-\pi, \pi]$ radian configurations.
- **Performance Stress Tests (Test 11)**: Analyzes algorithm safety by setting impossible mathematical constraints to verify it honors `Max_Iterations` constraints, thereby eliminating the possibility of system lockups due to infinite loops.

Together, these ensure system **Reliability** and **Safety** suitable for integrating this logic into physical optical equipment arrays without fear of undefined behavior or untrapped crashes. 

## Usage

### Compilation
Compile utilizing either `make` or Ada's native GPR tooling. No deep folder nesting is used, all commands are meant for the root directory.

*Using Make:*
```bash
make all
