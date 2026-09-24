# Ada Fictitious Play 

## Project Overview
This project provides a robust, strongly-typed Ada implementation of the **Fictitious Play** learning algorithm used in Game Theory. Introduced by George W. Brown, fictitious play models how agents play games repeatedly by forming beliefs based on the empirical frequencies of their opponents' past actions and picking a best response to those beliefs.

## Features
The codebase provides multiple verifiable variants of the algorithm, covering discrete and stochastic behavior profiles:
- **Simultaneous Fictitious Play**: Players update their beliefs and execute their best response simultaneously.
- **Alternating (Sequential) Fictitious Play**: Players act in turns, allowing P2 to react to P1's latest strategy before updating.
- **Smoothed (Stochastic) Fictitious Play**: Introduces a soft-max (logit) response based on a temperature parameter ($\lambda$) to simulate exploratory/suboptimal play.
- **Inertial Fictitious Play**: Players only switch to a new best response with a given probability $(1 - \epsilon)$, simulating resistance to change.

## Testing (Verification and Validation)
Adhering to strict Verification and Validation (V&V) standards for reliable systems, testing operates on a pessimistic assumption ("the code is broken"). Tests PASS only when this assumption is rigorously disproven.

Our 13+ terminal-executable assertions cover:
1. **Functional Correctness**: Verifies the core `Calculate_Best_Response` utilities process utilities precisely (disproving "math is wrong" assumptions).
2. **Algorithm Integrity**: Validates convergence to Nash Equilibrium (e.g., Prisoner's Dilemma) ensuring algorithmic theory maps to the implementation. 
3. **Error Handling**: Inputs are strictly validated. Matrix dimension mismatches or history buffer mismatches correctly trip explicit Ada Exceptions.
4. **Edge Cases**: Validates functionality on 1x1 trivial matrices, non-standard matrix bounds (e.g., starting at index 5 instead of 1), and bounds testing for Float max limits to prevent `Ada.Numerics` exponentiation overflow in Smoothed Play.

These tests guarantee behavioral safety and reliability, ensuring computational limits and constraints are respected exactly.

## Usage

### Compilation
The codebase leverages the GNAT build toolchain without nested directories.
To build the binaries, simply run:
```bash
make all
