# Goertzel Algorithm - Ada Implementation

## Project Overview
This repository contains a robust, statically typed implementation of the Goertzel Algorithm in Ada. The Goertzel algorithm is an incredibly efficient method for evaluating individual terms of the Discrete Fourier Transform (DFT), making it ideal for tasks like tone detection (such as DTMF in telecommunications) where computing a complete Fast Fourier Transform (FFT) would be computationally wasteful.

## Features
The code rigorously implements three distinct variants of the algorithm as specified by mathematical requirements:
1. **Basic Goertzel (Complex Output):** Returns both Real and Imaginary components of a target frequency bin, which is critical when phase extraction is required.
2. **Optimized Goertzel (Magnitude Squared):** Circumvents costly complex-domain arithmetic at the evaluation stage to return raw tone power (magnitude squared), yielding a highly optimized CPU footprint for presence-detection.
3. **Stateful / Streaming Goertzel:** A pre-computed parameter variant utilizing an internal `Goertzel_State` record. This allows continuous real-time sample-by-sample analysis without buffering blocks into memory.

## Testing
This software is built around robust **Verification and Validation (V&V)** principles intended for critical systems. The test suite operates on a "Negative Assumption" philosophy: it inherently assumes the code is incorrect, broken, or unsafe. A test `PASS` occurs strictly when the assumption is actively disproved.

### What Each Test Category Verifies
- **Functional Correctness:** Verifies that both the complex and optimized magnitude derivations mathematically align. Asserts that the algorithm accurately identifies target tones (1000 Hz) while decisively rejecting unrelated tones (2500 Hz).
- **Error Handling:** Proves that fatal conditions (empty buffers, `0` or negative sample rates) are safely caught using bounded `Goertzel_Error` exceptions rather than executing division-by-zero crashes.
- **Edge Cases:** Validates mathematical behaviors at constraints such as DC limits (`0 Hz`), Nyquist limits (`Sample_Rate / 2`), and negative symmetrical frequencies (`-1000 Hz`).
- **Performance State Integrity:** Confirms that the `Stateful/Streaming` pipeline perfectly mirrors the batch block processing outputs at a binary level, proving that loop-carried dependencies don't accumulate drift over time.

### Why These Tests Matter
In signal processing code executing in embedded or critical environments, reliability and predictability are paramount. By explicitly proving the logic handles boundary mathematical limits gracefully (e.g., negative aliasing without crash) and intercepts invalid memory constraints, the code guarantees stable, long-running deterministic execution.

## Usage

### Compilation
The project utilizes `make` and GNAT tools. To compile the executable:
```bash
make
