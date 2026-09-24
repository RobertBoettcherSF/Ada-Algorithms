# Quantum Optimization Algorithms in Ada 2023

## Project Overview
This project provides an expert, production-grade Ada 2023 implementation of core quantum optimization algorithms based on ISO/IEC 8652:2023. It models hybrid quantum-classical optimization techniques including the Quantum Approximate Optimization Algorithm (QAOA), Multi-Angle QAOA, Quantum Alternating Operator Ansatz, Quantum Annealing simulation, and the Variational Quantum Eigensolver (VQE).

## Features
- **Standard QAOA**: Evaluates combinatorial optimization cost landscapes using alternating cost and mixer Hamiltonians.
- **Multi-Angle QAOA**: Extends standard QAOA by supporting distinct angle parameters per qubit across circuit layers.
- **Quantum Alternating Operator Ansatz**: Handles constrained combinatorial problems with custom mixing operators and validation checks.
- **Quantum Annealing Simulation**: Simulates transverse field annealing schedules and quantum tunneling to locate global minima.
- **Variational Quantum Eigensolver (VQE)**: Hybrid variational optimization for estimating ground-state energy of physical systems.
- **Strong Typing**: Domain-specific types (`Cost_Value`, `Parameter_Angle`, `Iteration_Count`, `Qubit_Index`) replace bare primitives.
- **Ada Contracts**: Public subprograms annotated with formal `Pre` and `Post` aspects.
- **Robust Verification**: Standalone test suite with 13 comprehensive test categories verifying functional correctness, edge cases, and exception handling.

## Building & Usage
To build and execute the test suite, ensure GNAT (supporting Ada 2023) is installed and run:

    make test

To clean build artifacts:

    make clean

### Expected Output

    === Quantum Optimization Suite (Ada 2023) ===
      PASS — 1.1 QAOA returns valid cost value
      ...
    === 39 passed, 0 failed ===

## Testing & Verification
The test suite (`tests.adb`) covers 13 distinct verification categories:
- Functional correctness across all 5 algorithm variants.
- Edge cases including empty inputs, single element boundaries, and limit constraints.
- Exception safety and validation (`Invalid_Parameter`, `Constraint_Violation`).
- Invariant preservation and parameter boundary enforcement under `-gnatwa -gnat2022`.
