# Chaitin's Register Allocation Algorithm (Ada 2023)

## Project Overview
This repository contains a purely typed, highly reliable Ada 2023 (ISO/IEC 8652:2023) implementation of Chaitin's Algorithm for graph coloring register allocation, along with the Chaitin-Briggs extension. The algorithm models compiler variables as nodes in an interference graph and attempts to assign a distinct physical register (color) to conflicting variables, deciding which ones must spill to memory when register pressure is too high. 

## Features
* **Basic Chaitin Algorithm**: Implements the classic simplify-spill-select approach. Nodes with degree >= K are immediately pessimistically spilled during simplification.
* **Chaitin-Briggs Extension**: Employs optimistic coloring. Nodes with degree >= K are still pushed to the simplification stack. Often, neighbors coalesce into shared colors, allowing the algorithm to assign a color during the select phase and drastically reduce total spill costs.
* **Pure & Safe Execution**: Avoids dynamic memory allocation entirely via bounded node arrays. Implements explicit exception safeguards, comprehensive Ada Contracts (Pre, Post, Global), and clean compilation with `-gnatwa`.
* **Zero Dependencies**: Relies solely on built-in language capabilities and standard output.

## Usage
To execute the predefined test suite and see the algorithms allocate registers, build and run the main entry point via the Makefile:

    make test

### Expected Output
The console will display the evaluation of 13 separate test categories proving mathematical graph operations and confirming that the Chaitin-Briggs optimistic heuristic outperforms the pessimistic baseline algorithm in diamond graph structures.

## Testing
The test suite explicitly acts as both usage examples and rigorous unit verification:

* **Functional Correctness**: Validates that no two interfering nodes ever receive the same register color.
* **Algorithmic Validation (The Diamond Graph)**: Concretely proves that Basic Chaitin pessimistically spills on high-degree cycle graphs, while Chaitin-Briggs resolves the very same graphs with zero spills.
* **Edge Cases**: Asserts stable behavior for empty graphs, fully disconnected graphs, isolated nodes, and trivial allocations (K=1 or K=Max).
* **Error Handling**: Verifies exceptions are correctly raised if invalid operations (such as edges to inactive nodes) are requested.

## Building
**Prerequisites:** GNAT Toolchain supporting Ada 2022/2023.

    make all      # Builds bin/tests executable
    make test     # Executes the binary
    make clean    # Removes compilation artifacts
