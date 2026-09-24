# Audio Data Compression Algorithms in Ada

## Project Overview
This project implements foundational algorithms used in digital audio data compression. It targets strict, strong-typed embedded environments using Ada. 

The algorithms implemented represent core techniques outlined in modern audio compression architectures (such as the G.711 telecom standard and the foundational layers of FLAC/ALAC formats).

## Features
The following algorithmic variants are implemented:
1. **Mu-law (µ-law) Companding:** A lossy audio compression algorithm primarily used in 8-bit digital telecommunications in North America and Japan.
2. **A-law Companding:** A similar lossy companding standard used in Europe and international routes, featuring slightly different quantization curves.
3. **Differential Pulse-Code Modulation (DPCM):** The predictive coding foundation used in lossless formats (like FLAC) and lossy speech codecs. Instead of storing absolute PCM values, it calculates and stores the delta (difference) between consecutive audio samples.

## Testing
This codebase adopts strict Verification and Validation (V&V) principles. The testing philosophy explicitly *assumes the code is broken or non-functional*, and tests only PASS when this assumption is disproved by the runtime behavior.

### What Each Test Category Verifies:
*   **Functional Correctness:** Ensures algorithmic formulas (logarithmic curves for Mu/A-law and linear differencing for DPCM) execute mathematically correct conversions.
*   **Edge Cases & Boundaries:** Verifies system stability at the extreme limits of the datatypes (e.g., maximum 16-bit PCM `32767` and minimum `-32768`, or absolute silence `0`).
*   **Error Handling (Robustness):** Confirms that dynamic allocations and delta accumulations (like massive swings in DPCM) do not result in unhandled `Constraint_Error` exceptions, but are safely clamped.
*   **Data Integrity:** Proves that lossless algorithms (DPCM) perfectly round-trip data, and lossy algorithms (Mu-law) stay within acceptable tolerance parameters.

### Why These Tests Matter:
In critical systems (such as telecom hardware or embedded audio DSPs), unhandled exceptions or overflow wraps result in catastrophic system crashes or ear-damaging audio glitches (e.g., integer overflow wrapping a peak positive signal into a maximum negative signal). These tests ensure reliability and adherence to safety requirements.

## Usage

### Compilation
Ensure you have the GNAT Ada toolchain installed. To build the binaries, run:
```bash
make
