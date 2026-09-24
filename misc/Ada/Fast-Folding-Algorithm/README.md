# Fast Folding Algorithm (FFA)

## Project Overview
This repository provides a highly robust, strictly-typed Ada implementation of the **Fast Folding Algorithm (FFA)**. Originally introduced in 1969 by David H. Staelin, FFA is a computational method primarily utilized in astronomy and astrophysics (particularly pulsar detection) to reveal periodic signals hidden in noisy data. By dividing a time-series dataset into sections and strategically adding them together via logarithmic butterfly phases, FFA reveals cycles that may not maintain a constant frequency.

## Features
The codebase provides two primary implemented variants designed for varying operational needs:
- **Constant Period Fold (Non-drifting):** A brute-force baseline variant that assumes a static, unchanging period. It slices the data into fixed segments and accumulates them iteratively.
- **Fast Folding Algorithm (Dynamic Phase Drift):** Implements the recursive butterfly operations designed to detect shifting or drifting periods efficiently. Simultaneously searches multiple closely-spaced drift rates in a fraction of the brute-force computational time.

## Testing
This repository heavily relies on strong Verification and Validation (V&V) principles. The embedded test suite operates on a pessimistic baseline: *assume the codebase is broken and unsafe until proven otherwise.* Tests **PASS** only when they demonstrably disprove this assumption.

**Test Categories:**
1. **Functional Correctness (Tests 1, 4, 7, 10):** Validates that folding logic matches mathematical expectations (correct shifts, exact sum accumulations on top and bottom branches).
2. **Error Handling (Tests 2, 5, 6, 12):** Validates software robustness. Confirms the application raises specific, controlled exceptions (`Invalid_Period_Error`, `Invalid_Segments_Error`) instantly upon invalid system states (non-power-of-2 segments, array size mismatch).
3. **Edge Cases (Tests 3, 9, 11):** Challenges boundaries that commonly trigger crashes, such as evaluating empty arrays, arrays spanning offset indexing spaces (e.g., bounds `10..17` instead of `1..8`), and padding of uneven length buffers.
4. **Performance Integrity (Tests 8, 13):** Ensures scaling safety. Proves data energy conservation (output sums always equal input sums, implying no data is overwritten or lost) and verifies deep scalability without triggering stack overflows or corruption.

**Why these tests matter:**
In critical domains like automated astronomical survey pipelines, failure to handle an edge case like array offsets or power-of-two validations could corrupt lengthy analytical processing pipelines or crash distributed systems. Applying strict V&V checks ensures this Ada component behaves with aerospace-grade reliability.

## Usage
### Compilation Instructions
To build the binaries, ensure you have the GNAT Ada toolchain installed.

Using the provided Makefile:
```bash
make all
