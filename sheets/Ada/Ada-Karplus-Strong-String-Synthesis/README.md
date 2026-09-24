# Karplus-Strong String Synthesis (Ada Implementation)

## Project Overview
This repository contains an Ada implementation of the Karplus-Strong (KS) string synthesis algorithm. Originally developed by Alexander Strong and Kevin Karplus, the algorithm routes a short noise burst through a delay line and a low-pass filter to realistically synthesize the sound of plucked string instruments and some percussion. This project implements the core algorithm along with its most prominent extensions.

## Features
- **Plucked String Variant**: The standard algorithm using an averaging low-pass filter to simulate string energy decay.
- **Drum Synthesis Variant**: Randomizes the sign of the feedback signal based on a blending factor to scatter harmonics, producing a synthesized percussive drum hit.
- **Tuned String Variant (Extended KS)**: Implements the Jaffe-Smith extension using an all-pass filter. This enables fractional delay in the feedback loop, allowing for precise pitch control that escapes the limits of integer-based delay lines.
- **Strong Typing & Safety**: Built with robust Ada conventions, validating all parameters (Nyquist limits, stability thresholds) prior to execution.

## Testing
This project embraces a pessimistic Verification and Validation (V&V) philosophy. The test suite operates on the strict assumption that the code is non-functional or flawed. A test yields a `PASS` only when the code successfully disproves this assumption by matching intended use constraints.

- **Functional Correctness**: Ensures mathematical transformations (like fractional delay and phase inversion) behave according to synthesis standards.
- **Error Handling**: Verifies that invalid states (negative frequencies, super-Nyquist inputs, unstable decay factors > 1.0) strictly raise appropriate Ada Exceptions rather than failing silently.
- **Edge Cases**: Validates memory robustness under strain, such as deep wrap-arounds on 10,000+ length array allocations or skipping `0`-length empty buffer inputs gracefully.
- **Why this matters**: In digital signal processing (DSP) and critical systems, failing to catch out-of-bounds frequencies can result in buffer overflows (denial of service), and unstable filters can cause infinite numerical growth (NaN outputs, system crashes). These tests ensure that the codebase is completely sanitized and reliable.

## Usage
Ensure you have the GNAT Ada compiler and `make` installed.

### Compilation
Everything resides in the root directory. Compile the project simply by running:
```bash
make all
