# Dynamic Markov Compression (DMC) - Ada Implementation

## Project Overview
This project implements the state-machine and predictive modeling core of the **Dynamic Markov Compression (DMC)** algorithm natively in Ada. DMC uses a predictive Markov model that dynamically grows (clones states) as it observes data, feeding accurate probabilities to an Arithmetic Coder backend.

## Features
- **Strict Typing:** Custom bounds for Node scaling, probability math, and Bit handling.
- **DMC Variants Included:** 
  - `Single_State`: Starts with a generic zero-knowledge root node.
  - `Order_Zero`: Initializes a 255-state binary tree representing an 8-bit context.
  - `Memory Bounded`: Caps node scaling natively to prevent Out-Of-Memory (OOM) errors in critical environments.
- **Robust Math Check:** Pre-emptive integer halving to prevent `Constraint_Error` scaling limits during deep ingestion.

## Testing
This project follows strict Verification & Validation (V&V) standards, operating on the pessimistic assumption that systems are fundamentally flawed until mathematically or logically proven functional. 

### What the test categories verify:
1. **Functional Correctness (Tests 1-5, 11, 13):** Proves initialization variants structure nodes correctly, transition logic accurately traverses the tree, and predictions update correctly based on recent context.
2. **Dynamic Behavior (Tests 6, 7):** Validates the algorithm's core feature (State Cloning) accurately calculates state-ratio splits without discarding historical statistical weight.
3. **Boundary & Edge Cases (Tests 8, 9, 10):** Ensures cloning ceases accurately based on parameterized bounds, memory limits stop state allocation without crashing, and minimum-count checks prevent Division-by-Zero errors. 
4. **Performance & Robustness (Test 12):** Validates the mathematical decay function that halves counts when integers approach standard memory bounds, ensuring long uptimes.

### Why these tests matter:
In critical systems written in Ada, memory bounds, math errors (like dividing by zero), and unhandled state limits can cause catastrophic failures. Disproving failure in boundary scenarios validates that this module can be safely deployed in robust streaming-compression environments.

## Usage
### Compilation
Ensure GNAT is installed on your system.
```bash
make all
# Or alternatively, using the GPR directly:
# gprbuild -P dmc.gpr
