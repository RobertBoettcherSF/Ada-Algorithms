# Ada Garbage Collection Implementations

## Project Overview
This project provides a simulated, strongly-typed memory heap and implements classical Garbage Collection algorithms in Ada. It serves as an executable model to study the mechanical differences between memory management paradigms described in standard Computer Science literature.

## Features
- **Simulated Heap Management:** Safe allocation and explicit exception handling without touching direct system memory (preventing segfaults during study).
- **Tracing / Mark-and-Sweep:** Complete DFS graph traversal starting from Root objects to identify live memory and sweep disconnected cycles.
- **Reference Counting:** Instantaneous memory reclamation upon zero references, featuring recursive cascading deletions. 
- **Generational Collection:** Implements `Minor` and `Major` collections, separating memory by Object Age (Simulates Write-barriers/Remembered-Sets).

## Testing
This project embraces rigorous Verification and Validation (V&V) principles. Our test suite starts with a pessimistic assumption: *The code is broken, unreliable, and fails to handle boundary limits safely.*
A test **PASSES** only when the code mathematically disproves this assumption.

### What The Tests Verify
1. **Functional Correctness (Tests 1-2, 4-6, 8-9):** Validates that memory is correctly allocated, traced, tracked, and swept. (Verification: the code strictly matches the algorithm's mathematical definitions).
2. **Algorithmic Weaknesses (Test 11):** Explicitly proves that pure Reference Counting suffers from cyclic leaks—validating that the implementation behaves exactly as the literature dictates.
3. **Advanced Mechanics (Tests 12-13):** Proves generational mechanics keep Old Generation nodes safe and appropriately check references bridging Generations.
4. **Error Handling & Edge Cases (Tests 3, 14-15):** Ensures system exhaustion (`Out_Of_Memory_Error`) and invalid bounds (`Max_Edges_Error`, `Invalid_Node_Error`) result in clean exceptions, rather than corrupt states. (Validation: Safe under failure conditions).

### Why These Tests Matter
In critical systems (where Ada heavily operates), silent failures or memory leaks lead to catastrophic outcomes. V&V ensures that boundaries are known, error handling is deterministic, and algorithms behave safely under high stress. 

## Usage

### Compilation
Ensure GNAT/gprbuild is installed, then run:
```bash
make all
