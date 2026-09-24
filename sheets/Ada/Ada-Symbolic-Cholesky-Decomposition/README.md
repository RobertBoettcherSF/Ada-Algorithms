# Symbolic Cholesky Decomposition in Ada

## Project Overview
This project provides a robust, strongly-typed implementation of the **Symbolic Cholesky Decomposition** algorithm in Ada 2012. Before computing the dense numerical values of the Cholesky factor $L$ of a sparse positive-definite matrix $A$, a symbolic decomposition is performed to pre-calculate the non-zero pattern (the structural fill-ins). Identifying this matrix sparsity layout beforehand significantly optimizes subsequent memory allocation and numeric computation operations.

## Features
- **Elimination Game (Parter-Rose) Variant:** Accurately simulates the graph theory process of vertex clique completion to track structure "fill-in" elements dynamically.
- **Elimination Tree Variant:** Computes the optimal dependency structure (Elimination Tree) of the underlying graph showing relationships of matrix columns.
- Strongly typed parameters mapping strictly symmetrical mathematical graph constructs to Ada Boolean Matrices.
- Defends rigorously against unconstrained bounds and irregular matrix shapes. 
- Standalone execution capabilities and automated validation mapping.

## Testing
This repository adopts rigorous **Verification and Validation (V&V)** principles critical for reliable safety systems. Using a pessimistic assumption philosophy, the testing suite considers the system defective unless explicitly disproven by 14 strict assertion blocks across 6 categories.

**What the test categories verify:**
1. **Robustness (Error Handling):** Feeding non-square, invalid matrix representations ensures the module safely traps execution into well-defined exceptions (`Invalid_Matrix`) instead of cascading into runtime segfaults or data corruption.
2. **Boundary Value Analysis (Edge Cases):** Asserts system stability when mathematical dimensions collapse (e.g., 0x0 empty matrices). Validates logical array limits don't trigger `Constraint_Error` bounds failures.
3. **Base Case Validation:** Enforces the absolute mathematical base identities (1x1 sizes).
4. **Diagonal/Identity Matrix Logic:** Proves the algorithm avoids excessive, false positive fill-ins by ensuring independent paths remain unlinked. 
5. **Fill-In Generation (Functional Correctness):** The most complex validation. It constructs a known 3x3 Graph where elimination mathematically dictates a synthetic connection (a fill-in edge). It checks this addition and validates the calculated Elimination Tree matches dependency proofs.
6. **Path Graph Dynamics:** Proves the bounds of fill-ins are strictly localized to direct neighbors and do not arbitrarily propagate transitively.

**Why these tests matter:** 
In large-scale sparse numerical solvers, incorrect matrix fill-in approximations lead directly to segmentation faults (via undersized memory buffers) or exponentially degraded computing performance (via oversized allocations). By passing these structured constraints, the code proves algorithmic integrity under both edge boundaries and intensive functional topologies.

## Usage
### Compilation
The codebase uses a GNAT Project file alongside a unified Makefile. Run:
```bash
make
