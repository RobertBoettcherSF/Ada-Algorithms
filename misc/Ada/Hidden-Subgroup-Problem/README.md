# Hidden Subgroup Problem (HSP) in Ada 2023

## Project Overview
This project provides a robust, strongly typed Ada 2023 implementation of algorithms and verification utilities for the Abelian Hidden Subgroup Problem (HSP), encompassing Simon's problem, period/order finding, and general abelian subgroup recovery.

## Features
- **Simon's Problem Solver**: Recovers the hidden non-zero bit string $s \in \mathbb{Z}_2^n$ ($n \le 8$) the way Simon's algorithm does. `Simon_Sample_Equations` simulates the quantum step exactly: it queries $f$ once per $x$ and returns every $y$ the circuit measures with non-zero probability (for a Simon oracle exactly the $y$ with $y \cdot s = 0$). `Simon_Null_Vector` then row-reduces these equations over $\text{GF}(2)$ and reads $s$ off the single free column. A one-to-one $f$ raises `Subgroup_Not_Found`; an $f$ invariant under more than one non-zero $s$ raises `Invalid_Oracle`. There is no search for colliding inputs (it was the solver's first step until the GF(2) fix; a brute-force null space is now only the test reference).
- **Period / Order Finding**: Determines the minimal positive period $r$ of functions over cyclic groups $\mathbb{Z}_N$. A one-to-one oracle has period $r = N$ ($H = \{0\}$), since 76ea12db.
- **General Abelian HSP**: Returns the period $r$, the generator of the hidden subgroup $H = r\mathbb{Z}_N \le \mathbb{Z}_N$. Before 97881897 it returned $N / r$, a generator of the annihilator of $H$, not of $H$.
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
