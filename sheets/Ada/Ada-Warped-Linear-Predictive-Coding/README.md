# Warped Linear Predictive Coding (WLPC) in Ada

## Project Overview
This repository implements the **Warped Linear Predictive Coding (WLPC)** algorithm along with standard **Linear Predictive Coding (LPC)**. While standard LPC evaluates the spectral envelope via unit delays, WLPC replaces these unit delays with cascaded first-order all-pass filters. This maps the spectrum to an approximated Bark (warped) frequency scale, granting high compressibility and perceptual alignment required for wideband audio codecs. 

## Features
- **Standard LPC Analysis:** Standard autocorrelation based on native signal intervals.
- **Warped LPC Analysis (WLPC):** Warped autocorrelation using state-tracking cascaded first-order all-pass filters configurable with tuning parameter $\lambda$.
- **Levinson-Durbin Recursion:** Efficiently resolves autocorrelations down to optimal predictive filter coefficients and error variance estimation.
- **Strictly Typed & Bounds-Safe:** Designed cleanly in Ada to avoid memory access issues often present in DSP libraries.

## Testing (V&V Principles)
The test suite in `tests.adb` is heavily structured around **Verification & Validation (V&V)** paradigms for critical systems. Operating under the baseline assumption that code is inherently faulty, each passing test actively disproves failure assumptions:

- **Functional Correctness:** Tests 1, 5, 6, and 9 verify that calculated energies and predictor bounds accurately mimic expected mathematics, ensuring the software reliably resolves real-world signal behavior.
- **Error Handling & Robustness:** Tests 3, 4, 7, 10, and 11 verify that mismatched bounds and empty arrays safely trigger explicit Ada exceptions rather than corrupting memory or propagating NaNs. 
- **Edge Cases & Stability:** Tests 2, 8, and 12 prove the Levinson-Durbin implementation doesn't succumb to division-by-zero crashes on zero-energy or completely deterministic (DC) signals. 

These tests prove that regardless of input anomalies, the algorithm will maintain reliability and fail safely instead of catastrophically — fulfilling core V&V requirements for DSP algorithms operating in unpredictable live scenarios.

## Usage

### Compilation
The project supports compilation directly via standard `make`.
```bash
make all
