# Ada CELP (Code-Excited Linear Prediction)

## Project Overview
This project provides a robust, strongly-typed Ada implementation of the Code-Excited Linear Prediction (CELP) algorithm, a foundational speech coding technique widely used in digital communications. It encapsulates the core Analysis-by-Synthesis (AbS) loop, Linear Predictive Coding (LPC) filter modeling, and adaptive/fixed codebook synthesis.

## Features
This module successfully implements the core logic and structurally simulates the main variants of CELP referenced in telecommunication standards:
* **Standard CELP**: Classic random-noise/stochastic fixed codebooks.
* **ACELP** (Algebraic CELP): Implements interleaved sparse grids yielding high performance with low storage.
* **VSELP** (Vector Sum Excited Linear Prediction): Calculates innovations via linear combinations of orthogonal basis vectors.
* **LD-CELP** (Low-Delay CELP): Employs backward-adaptive LPC state management to eliminate forward transmission delays.
* **PSI-CELP** (Pitch Synchronous Innovation): Synchronizes fixed-codebook pulse sequences closely with pitch-period spacing.

## Testing
This repository relies heavily on stringent **Verification and Validation (V&V)** practices. A dedicated test suite (`tests.adb`) operates under pessimistic initial assumptions (the code is presumed faulty until proven functional).

**What the test categories verify:**
1. **Functional Correctness (Tests 1, 3, 4, 5, 6, 11):** Verifies the actual structural data output of each variant's codebook. It proves ACELP outputs sparse data, LD-CELP manages sub-frame bounds, and MSE math works.
2. **Edge Cases (Tests 2, 7, 8, 12, 14):** Confirms behavior under silent (zero-energy) inputs, clipping limits, exact codebook boundaries (Index 1 and 256), and backward-state inheritance limits for LD-CELP.
3. **Error Handling & Protection (Tests 9, 13):** Purposely inputs faulty/corrupted configuration data (out-of-bounds indices, negative pitch delays) to assert that exceptions are raised before catastrophic memory or logic faults occur.
4. **Performance & Stability (Test 10):** Specifically stress-tests the autoregressive LPC IIR filter to ensure standard mathematical decay occurs and infinite loops/NaN propagation are avoided.

**Why these tests matter:** 
In critical communications, encoder failure can cascade into system-wide network faults or loud audio artifacts. By applying V&V principles, we mathematically prove that exceptions catch memory violations and the synthesis filter retains stability, satisfying high-integrity software requirements.

## Usage

### Compilation
Ensure you have the GNAT Ada compiler installed. From the root directory, simply run:
```bash
make all
