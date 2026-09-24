# Context Tree Weighting (CTW) - Ada Implementation

## Project Overview
This repository contains a robust, strictly-typed implementation of the **Context Tree Weighting (CTW)** algorithm in Ada. Originally conceptualized for lossless data compression and sequence prediction, CTW estimates the probabilities of bit sequences using a suffix tree of past observations mapped against the Krichevsky-Trofimov (KT) estimator. 

## Features
- **Bounded Depth (Zero-M) Variant**: Configurable maximum context depth to prevent unbounded memory growth.
- **Zero-Order Model**: Fully supports memoryless probability distributions by utilizing `Max_Depth = 0`.
- **Dynamic Node Allocation**: Tree branches are generated dynamically during updates, minimizing spatial complexity footprint.
- **Krichevsky-Trofimov (K-T) Estimator**: Continuous incremental fractional updates avoiding zero-probability traps.
- **Memory Safe**: Strict custom types (`Bit`), defensive bound checks, and verifiable tree deallocation mechanisms.

## Testing
This codebase is governed by rigorous V&V (Verification & Validation) principles standard in critical systems. We inherently treat untested code as non-functional until comprehensively proven otherwise.

### What The Tests Verify
1. **Functional Correctness**: Exact derivation testing of K-T recursive mathematics against known constants (e.g., probability tracking of sequences exactly matching mathematical integrations).
2. **Edge Cases**: Validates proper handling of empty context arrays, variable depth cutoffs, and array index misalignment bounds (`'First` / `'Last`).
3. **Error Handling**: Hard assertions against invalid uninitialized tree manipulation traps.
4. **Performance & Stability**: Extended repetitive input loops ensuring `Long_Float` values gracefully degrade without arbitrary rounding to absolute zero underflow.

### Why These Tests Matter
In probabilistic sequence prediction, off-by-one errors in state counters propagate exponentially through the weighted averages. By strictly controlling the assumptions and guaranteeing safety boundaries (memory leaks, out-of-bounds indexing, null reference trapping), the test suite guarantees software safety and reliability compliant with V&V standards.

## Usage

### Compilation
The codebase resides entirely in the root directory. To compile both the main stub and the test suite natively:
```bash
make all
