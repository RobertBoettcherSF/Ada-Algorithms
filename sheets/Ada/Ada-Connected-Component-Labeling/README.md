# Connected-Component Labeling (CCL) in Ada

## Project Overview
This repository provides a robust, strongly-typed Ada implementation of the **Connected-Component Labeling** algorithm. CCL is a fundamental technique in computer vision and graph theory used to detect distinct connected regions (blobs) in a binary image. 

The codebase heavily emphasizes determinism, memory safety, and comprehensive edge-case handling in accordance with Ada development standards.

## Features
- **Two-Pass Labeling Variant**: Implements the classical raster-scan algorithm leveraging a Disjoint-Set (Union-Find) data structure with path compression. Ideal for large datasets.
- **Breadth-First Search (BFS) Variant**: A sequential approach that labels one connected component at a time without requiring union-find logic.
- **Configurable Connectivity**: Support for both `Four_Connected` (von Neumann neighborhood) and `Eight_Connected` (Moore neighborhood).
- **Sequential Label Compacting**: Automatically maps chaotic internal root hashes down to contiguous sequence labels (1, 2, 3.. N).
- **Arbitrary Index Bounds**: Inherently supports Ada's non-standard array indices out-of-the-box (e.g. `array (5..10, -5..5)`).

## Testing (Verification & Validation)
Testing for critical algorithms mandates the assumption that **the code is fundamentally broken**. A test `PASS` indicates that a specific pessimistic assumption about the algorithm's failure has been explicitly falsified.

The embedded test suite (`tests.adb`) verifies:
1. **Functional Correctness (Algorithmic Semantics)**: 
   - Proves 4-connected paths appropriately separate touching diagonals.
   - Proves 8-connected paths appropriately merge diagonals.
   - Confirms Union-Find correctly merges disjoint paths (e.g., U-shapes and V-shapes).
2. **Error Handling (Robustness)**:
   - Verifies the application immediately faults (`Bounds_Mismatch_Error`) if given maliciously misaligned input and output arrays, preventing memory corruption.
3. **Edge Cases**:
   - Empty multi-dimensional arrays (`(1..0, 1..0)`).
   - Entirely empty fields (all `False`).
   - Extreme high-frequency disjoints (Checkerboard permutations).
4. **Implementation Parity**:
   - Ensures distinct structural approaches (BFS queue vs. Two-pass sequential scan) yield identical component conclusions.

**Why these tests matter:** 
In critical systems (avionics, medical imaging), silent failure is catastrophic. Guaranteeing sequential label generation, boundary enforcement, and deterministic Union-Find resolution means the system behaves safely and predictably under chaotic inputs.

## Usage

### Compilation
The project utilizes `gnatmake` and standard GNAT Project files (`.gpr`). A convenient Makefile is provided.

```bash
make all
