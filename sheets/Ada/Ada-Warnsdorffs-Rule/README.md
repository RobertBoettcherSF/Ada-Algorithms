# Warnsdorff's Rule in Ada

## Project Overview
This repository provides a strict, strongly-typed Ada implementation of Warnsdorff's Rule, a heuristic algorithm for solving the Knight's Tour problem. The Knight's Tour requires moving a knight on an $N \times N$ chessboard such that it visits every square exactly once. 

## Features
* **Standard Warnsdorff Variant:** Always proceeds to the adjacent unvisited square with the minimum degree (fewest onward moves).
* **Pohl (Squirrel & Cull) Variant:** Includes an advanced tie-breaking mechanism. If multiple squares have the same minimum degree, it prefers the square where the sum of the degrees of its neighbors is also minimal.
* **Mathematical Validator (`Is_Valid_Tour`):** A rigid cryptographic-style checker that guarantees the resulting grid consists exclusively of legal L-shaped movements without duplicate square visits.
* **Dynamic Sizing:** Board dimensions are handled safely via unconstrained array parameters.

## Testing (Verification & Validation)
This project follows strict Verification & Validation (V&V) standards to disprove pessimistic assumptions about the codebase (i.e. assuming failure, proving success). 

### What the tests verify:
1. **Functional Correctness (Tests 1, 2, 3):** Proves that both variants successfully find complete tours on legal boards (5x5, 6x6) and mathematically asserts the trajectory sequence.
2. **Error Handling (Test 4):** Ensures rogue data (e.g. out-of-bounds start vectors) triggers explicit, trapped `Invalid_Start_Position` exceptions rather than buffer overflows or infinite loops.
3. **Edge Cases & Failure Toleration (Tests 5, 6, 7):** Validates deterministic degradation on mathematically impossible grids (3x3, 4x4) where the knight will inevitably hit dead ends. Asserts the system handles trivial cases securely (1x1).

### Why these tests matter:
In critical systems architecture, heuristics cannot be assumed to be absolute. Our test suite guarantees that when the heuristic fails (as Warnsdorff mathematically will on some board/start configurations), it fails safely and predictably (`Success = False`) rather than trapping the processor in an infinite loop.

## Usage 
### Compilation
The project forces all artifacts to compile directly in the root directory via the provided GNAT project and Makefile.
```bash
make
