# Embedded Zerotree Wavelet (EZW) Algorithm in Ada

## Project Overview
This repository contains an Ada 2012 implementation of the **Embedded Zerotree Wavelet (EZW)** algorithm. EZW is a lossy image compression algorithm utilizing the Discrete Wavelet Transform (DWT). It efficiently encodes data by relying on the assumption that if a wavelet coefficient is insignificant at a coarse scale, its descendants (at finer scales) are highly likely to be insignificant as well, forming a "Zerotree." 

## Features
Implemented variants and core phases of the EZW algorithm include:
- **Phase 1: Initial Threshold Calculation:** Determines the optimal power of 2 based on the maximum coefficient's magnitude.
- **Phase 2: Dominant Pass:** Scans hierarchical coefficients to classify them as Positive Significant (POS), Negative Significant (NEG), Zerotree Root (ZTR), or Isolated Zero (IZ).
- **Phase 3: Subordinate Pass:** Refines coefficients flagged as significant by extracting subsequent precision bits (`SUB_1`, `SUB_0`).
- **1D Quadtree Emulation:** A flattened 1D matrix representing a 2D quadtree relationship for descendants.
- **Strong Typing & Protections:** Utilizes strict custom Ada types and buffer overflow protections in the encoded stream.

## Testing
This repository uses a rigid Validation & Verification (V&V) philosophy. 
**Core assumption:** We assume the software is broken/faulty. The tests are designed to execute assertions verifying exact behavioral requirements. A `PASS` means the test has successfully disproved the failure assumption.

### What the test categories verify:
1. **Functional Correctness (Tests 1-6):** Verifies the threshold calculations and recursive Zerotree relationship calculations exactly match the mathematical definition of the algorithm.
2. **Algorithm Phase Handling (Tests 7-11):** Ensures the Dominant Pass strictly adheres to the state machine logic of emitting the correct symbols (`POS`, `NEG`, `IZ`, `ZTR`) without mutating previously confirmed nodes.
3. **Refinement Accuracy (Tests 12-13):** Proves that the Subordinate Pass perfectly extracts trailing precision bits against fluctuating refinement thresholds.
4. **Safety & Bounds Handling (Tests 1, 14):** Confirms error handling against invalid parameters (empty matrices) and dynamic memory limits (stream buffer overloads).

### Why these tests matter:
In critical systems programming, correctness per V&V standards ensures no undefined behaviors occur at runtime. Demonstrating robust edge-case handling against memory overflows and index faults ensures the encoder is resilient enough for production streams.

## Usage
### Compilation
Ensure you have the GNAT Ada compiler installed. The project does not utilize a separate `src` folder, all files remain in the root directory.
Compile the project via the provided `Makefile`:
```bash
make all
