# Quantum Annealing Package in Ada 2023

## Project Overview
This project provides a robust, expert-level implementation of Quantum Annealing in Ada 2023 (ISO/IEC 8652:2023). Quantum annealing is a metaheuristic optimization technique used to locate the global minimum of objective functions over discrete combinatorial search spaces—such as the Ising spin glass model and QUBO problems—by leveraging quantum fluctuations, transverse fields, and quantum tunneling through potential energy barriers.

## Features
- **Core Ising Model Energy Evaluation**: Computes classical Hamiltonian energy across spin arrays with arbitrary coupling matrices and external magnetic fields.
- **Adiabatic Quantum Annealing**: Exact Schrödinger state vector evolution for small spin systems ($N \le 6$), simulating quantum superposition and adiabatic transitions.
- **Transverse Field Simulated Annealing (TFSA)**: Monte Carlo heuristic approach incorporating transverse field quantum tunneling probability for larger spin systems.
- **Scheduling Strategies**: Multiple annealing schedules including Linear, Exponential, and Diabatic acceleration.
- **Strong Typing & Contracts**: Custom domain types (`Spin`, `Coupling_Value`, `Field_Value`, `Energy_Value`, `Step_Count`) with strict precondition contracts and zero warnings under `-gnatwa`.

## Usage
To build and run the test suite, use the provided Makefile:

    make test

Expected output:

    Running tests...
      PASS — 1.1 Ferromagnetic energy alignment gives negative value
      ...
    === 39 passed, 0 failed ===

To clean build artifacts:

    make clean

## Testing
The test suite (`tests.adb`) implements 13 comprehensive tests containing 39 assertions covering:
- **Functional Correctness**: Verification of energy minimization, spin alignment, and external magnetic field coupling.
- **Algorithm Variants**: Rigorous testing of adiabatic exact evolution, transverse field heuristic annealing, and linear, exponential, and diabatic schedules.
- **Edge Cases**: Single-spin systems, extreme field parameters, and deterministic random seed reproducibility.
- **Error Handling & Contracts**: Precondition validation and contract enforcement.

## Building
Prerequisites:
- GNAT compiler with Ada 2023 support (GNAT 12 or newer recommended).
- GNU Make.

Build via GNAT project file:

    gnatmake -gnatwa -gnat2022 -Pquantum_annealing.gpr
