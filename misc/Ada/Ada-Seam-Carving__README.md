# Seam Carving in Ada

## Project Overview
This project is an implementation of the **Seam Carving** algorithm, a content-aware image resizing technique. The implementation operates on custom pixel matrix inputs and determines the optimal paths (seams) of lowest energy passing through the image either horizontally or vertically. Seam carving permits reducing or expanding the size of an image without distorting its most prominent features.

## Features
- **Energy Function Variants:**
  - *Backward Energy:* Utilizes a dual-gradient technique summing differences of adjacent pixels.
  - *Forward Energy:* Calculates energy dynamically during pathfinding based on the new edges created by removing a seam, improving artifact avoidance.
- **Directional Modes:** Complete support for both Vertical (reducing width) and Horizontal (reducing height) seam processing.
- **Resizing Operations:**
  - *Seam Removal:* Subtracts optimal seams from images dynamically.
  - *Seam Insertion:* Expands image dimensions by interpolating (averaging) pixels adjacent to a computed seam.
- **Robust Exception Handling:** Prevents invalid dimensional manipulations (e.g., attempting to shrink a 1xN image).

## Testing
This software is built adhering strictly to Verification and Validation (V&V) principles for reliable systems. The test suite operates under a pessimistic assumption (assuming the codebase is flawed) and enforces asserts that must prove the code behaves correctly per specifications.

### Test Categories
1. **Functional Correctness:** Verifies mathematical operations and algorithmic pathfinding are sound (e.g., Backward/Forward Energy DP pathings find the true lowest cost route).
2. **Data Integrity:** Ensures structural layout manipulations (Seam Removal/Insertion) cleanly shift unmutated regions without memory overlaps or dropping required pixels.
3. **Edge Cases:** Evaluates the engine on extreme boundaries (e.g., zero-gradient uniform images where pathfinding must fall back gracefully to geometric heuristics).
4. **Error Handling:** Validates that bounded boundaries and mathematical contradictions trigger handled system exceptions rather than silent segfaults.

### Why These Tests Matter
In critical or reliable system development, assumptions of "happy-path" runtime are dangerous. By explicitly disproving failure conditions, this V&V approach ensures the dynamic programming logic cannot silently degrade image arrays, prevents memory out-of-bounds access, and validates that dimensions perfectly mirror algorithmic expectations.

## Usage

### Compilation
The project requires an Ada compiler (GNAT). You can compile using the provided Makefile:

```bash
make all
