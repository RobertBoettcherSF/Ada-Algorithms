# Quantum Artificial Life (Ada 2023 Implementation)

## Project Overview
This project provides a robust, strongly-typed Ada 2023 implementation of the Quantum Artificial Life model inspired by quantum algorithms for simulating biological behavior and Darwinian evolution (Alvarez-Rodriguez et al.). The model simulates artificial organisms possessing quantum-inspired genotypes and phenotypes on a spatial grid, incorporating core evolutionary mechanisms such as quantum-inspired self-replication, cell-based phenotype interactions, spontaneous and error-driven mutations, and lifespan aging dynamics.

## Features
- **Quantum-Inspired Genotype & Phenotype Representation**: Strongly typed states (`Genotype_State`, `Phenotype_State`) modeling quantum control and target qubits.
- **Self-Replication (`Self_Replication`)**: Simulates quantum cloning of genotypes into ancillary states to generate offspring.
- **Phenotype Interactions (`Intercept_And_Interact`)**: Implements spatial cell-based interactions where differing genotypes exchange phenotypes, creating dynamic predator-prey equilibria.
- **Mutation Operators (`Apply_Mutation`)**: Supports both spontaneous qubit rotation mutations (M operation) and self-replication error mutations (UM operation altering genotypes and lifespans).
- **Aging & Death (`Process_Lifespan`)**: Manages individual lifespans, aging decrements, and active status transitions upon expiration.
- **Environmental Grid Simulation (`Step_Environment`)**: Coordinates population-wide aging, cell occupancy, and multi-individual interactions across a 2D spatial grid.
- **Verification & Contracts**: Comprehensive Pre/Post contracts and validation functions ensuring structural and functional integrity.

## Building
Prerequisites:
- GNAT compiler with Ada 2023 support (`-gnat2022`)
- GNU Make

To build the project:
    make

## Usage
To run the test suite and verify execution:
    make test

Expected output:
    Running tests...
      PASS — 1.1 Replication reported success
      PASS — 1.2 Offspring is active
      PASS — 1.3 Offspring genotype matches parent
    ...
    === 39 passed, 0 failed ===

To clean build artifacts:
    make clean

## Testing
The test suite (`tests.adb`) contains 13 rigorous test cases comprising 39 distinct assertions. It exercises every public subprogram, variant, and edge case in the package. Categories covered include:
- **Functional Correctness**: Verifying accurate state transitions for replication, interaction, and mutation.
- **Edge Cases**: Handling inactive individuals, zero lifespans, empty grid cells, and boundary conditions.
- **Error Handling & Invariants**: Validating environment integrity and exception propagation (`Invalid_Grid_Error`).
- **Population Aggregation**: Testing accurate active population counts across spatial coordinates.
