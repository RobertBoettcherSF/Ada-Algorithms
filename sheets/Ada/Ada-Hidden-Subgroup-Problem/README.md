# Hidden Subgroup Problem (HSP) in Ada 2023

## Project Overview
This project provides a robust, strongly typed Ada 2023 implementation of algorithms and verification utilities for the Abelian Hidden Subgroup Problem (HSP), encompassing Simon's problem, period/order finding, and general abelian subgroup recovery.

## Features
- **Simon's Problem Solver**: Recovers the hidden non-zero bit string $s \in \mathbb{Z}_2^n$ using equation collection and Gaussian elimination over $\text{GF}(2)$.
- **Period / Order Finding**: Determines the minimal positive period $r$ of functions over cyclic groups $\mathbb{Z}_N$.
- **General Abelian HSP**: Reconstructs generating sets of hidden subgroups $H \le \mathbb{Z}_N$.
- **Subgroup & Character Verification**: Verifies coset constancy properties and dual group character orthogonality ($\chi_g(h) = 1$).
- **Strong Typing & Contracts**: Leverages custom domain types (`Group_Element`, `Bit_Mask`, `Period_Type`) and Ada pre/post conditions.

## Usage
To build and execute the test suite:
`make test`

To clean build artifacts:
`make clean`

### Expected Output
Running tests...
  PASS — 1.1 Simon solver returns non-zero
  PASS — 1.2 Simon solver detects correct hidden string 3
  PASS — 1.3 Simon solver result is within 8-bit range
  ...
=== 42 passed, 0 failed ===

## Testing
The test suite (`tests.adb`) contains 14 comprehensive test categories covering:
1. **Functional Correctness**: Simon's problem solver across different bit widths, period finding for varied cyclic group orders.
2. **Subgroup Reconstruction**: General abelian HSP generators and subgroup coset verification.
3. **Dual Group Character Evaluation**: Orthogonality checking for valid vs. invalid characters.
4. **Edge Cases**: Zero inputs, empty subgroups, GCD edge cases, and degenerate oracles.
5. **Error Handling**: Exception safety for invalid oracles and unresolvable subgroups.

## Building
- **Prerequisites**: GNAT compiler supporting Ada 2023 (ISO/IEC 8652:2023).
- **Compilation Flags**: `-gnatwa -gnat2022`.
