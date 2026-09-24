# Vector Quantization (VQ) in Ada

## Project Overview
This project implements the classical **Vector Quantization (VQ)** algorithm in Ada, commonly used for signal processing, lossy data compression, and density modeling. It includes static encoding/decoding mechanics and a dynamic training phase utilizing the Generalized Lloyd Algorithm (GLA) / Linde-Buzo-Gray (LBG) algorithm. 

## Features
*   **Static VQ (Encoding):** Highly optimized nearest-neighbor mapping from vectors to centroid indexes.
*   **Static VQ (Decoding):** Robust reverse mapping from indexes back to high-dimensional centroid representations.
*   **Dynamic VQ (LBG Training):** Implements an iterative K-Means based Generalized Lloyd Algorithm (GLA). Sub-samples data, groups iteratively, and calculates centroids to minimize Mean Squared Error (MSE).
*   **Mathematical Tooling:** Includes utilities for calculating multi-dimensional Squared Euclidean distance and evaluating dataset MSEs.

## Testing
This repository heavily relies on strong Verification and Validation (V&V) principles. We operate under the pessimistic assumption that critical paths are broken, and our suite of 14 discrete tests exists to aggressively *disprove* that assumption.

### What the Test Categories Verify:
1.  **Functional Correctness:** Asserts fundamental mathematical laws (distance between identical vectors is `0.0`, Pythagorean verification) and ensures LBG successfully converges to minimize MSE constraints. 
2.  **Error Handling:** Validates that exceptions (`Dimension_Mismatch`, `Constraint_Error`) are safely intercepted and raised immediately when invalid matrices are fed into the system.
3.  **Edge Cases:** Verifies system stability when passed degenerate states, such as `Empty_Dataset`, `Codebook_Size > Num_Data`, or iterative clusters dropping to 0 items during LBG training.
4.  **Performance Check:** Verifies bounds behavior within maximum iteration thresholds.

### Why these tests matter:
In data compression and digital signal processing (DSP), silent failures in geometric quantization can compromise massive downstream datasets. Ensuring strict boundary compliance via assertions proves that memory violations are prevented, codebook indexing aligns tightly with strict Ada types, and mathematical degradation is mathematically capped (V&V correctness standards).

### Proving correctness:
Each test injects deliberately volatile or boundary inputs. The test suite outputs **PASS** if, and only if, the system resists breaking and explicitly behaves according to the deterministic laws of the LBG definitions.

## Usage

### Compilation
The project utilizes `gnatmake` and a GNAT project file to resolve dependencies automatically.
```bash
make all
