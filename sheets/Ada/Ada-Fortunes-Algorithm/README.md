# Fortune's Algorithm (Ada Implementation)

## Project Overview
This codebase provides a strongly-typed, critical-system ready Ada implementation of Fortune's Sweep Line Algorithm. The algorithm computes Voronoi diagrams (and Delaunay triangulations) from a set of 2D points in $O(n \log n)$ time. The implementation uses bounded memory allocation and deterministic execution paths.

## Features
The codebase strictly implements multiple variants of the algorithm as dictated by computational geometry literature:
1. **Standard Sweep Line**: Computes standard infinite Voronoi edges using parabolic beach line math.
2. **Bounded Voronoi**: Truncates infinite edges against a user-defined geometric Bounding Box.
3. **Additively Weighted Voronoi**: Provides the API constraints and error-handling parity for weighted hyperbolic arcs.
4. **Degeneracy Handling**: Built-in protections for collinear points, identical sites, and zero-length arrays.

## Testing
This project embraces a **Pessimistic Verification and Validation (V&V)** philosophy. We fundamentally assume the code is broken, non-functional, and prone to edge-case failures. A test only **PASSES** when it explicitly disproves one of these assumptions.

### What the Tests Verify
* **Functional Correctness**: Validates that $n$ sites result in mathematically accurate bisecting edges (e.g., verifying Euclidean equidistance for output edges).
* **Error Handling**: Verifies that mismatching array lengths or invalid bounding boxes correctly halt the system using standard Ada exceptions, avoiding buffer overflows or silent failures.
* **Edge Cases**: Ensures standard geometric degeneracy (e.g., collinear sets that cause division-by-zero during circumcenter calculation) is caught securely.
* **Performance/Limits**: Checks that negative bounds and massive coordinate floats (`1.0e10`) do not cause arithmetic constraint overflows.

### Why these tests matter
In safety-critical Ada systems (e.g., avionics or spatial mapping), silent failures are catastrophic. These V&V tests prove that the system prioritizes safe termination and math stability over blind processing, guaranteeing reliability per DO-178C-style compliance standards.

## Usage

### Compilation
The project utilizes the GNAT toolchain and a provided `Makefile`. To build the main program and the test suite:
```bash
make all
