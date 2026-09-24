# Spectral Layout Graph Drawing in Ada

## Project Overview
This project provides a standalone, strongly-typed Ada implementation of the **Spectral Layout** algorithm used in graph drawing and network visualization. It computes 2D coordinates for nodes by calculating the eigenvalues and eigenvectors of graph-derived matrices (Laplacians). Because computing eigenvectors is complex, this library implements a robust, dependency-free Jacobi eigenvalue rotation solver capable of processing any symmetric graph.

## Features
Implementation fully encompasses all primary matrix variations highlighted in modern graph theory:
1. **Unnormalized Laplacian ($L = D - A$)**: Uses the 2nd and 3rd smallest eigenvectors (Fiedler vectors) for standard force-directed-like energy minimization.
2. **Normalized Laplacian ($\mathcal{L} = D^{-1/2} L D^{-1/2}$)**: Accounts for node-degree discrepancies natively, ideal for graphs with heavily skewed degree distributions.
3. **Adjacency Matrix ($A$)**: Implements spatial visualization derived directly from the 1st and 2nd largest eigenvalues.

## Testing (Verification & Validation)
The project includes a pessimistic V&V (Verification and Validation) test suite (`tests.adb`). We follow the testing philosophy of *assuming the code is flawed*, writing tests to attempt to trigger failures, and issuing a **PASS** when the codebase definitively proves the failure assumption false.

### What is verified and why?
*   **Functional Correctness:** Verifies algorithmic invariants. For example, Test 4 asserts that the center of mass for an Unnormalized Laplacian layout strictly equals zero ($\sum v_2 = 0$). This ensures the math works correctly without graphical output.
*   **Edge Cases:** Verifies system stability at mathematical extremes (N=1 nodes, disconnected components, completely isolated vertices with degree zero).
*   **Robustness / Error Handling:** Attempts to feed asymmetric bounds or non-square matrices and validates that the package safely restricts processing and issues well-typed `Constraint_Error` or custom exceptions.

These tests guarantee reliability and memory safety per critical systems standards, proving mathematical limits (like potential Division-by-Zero in the Normalized layout) are gracefully subverted.

## Usage

### Compilation
The codebase uses a GNAT project file configured to act directly from the root directory.
Compile utilizing Make:
```bash
make all
