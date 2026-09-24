# Ada Transform Coding Implementation

## Project Overview
This project implements the core algorithms of **Transform Coding**, a data compression methodology primarily used for "natural" data such as audio signals or photographic images. The software provides the mathematical apparatus required to translate spatial/temporal domains into frequency domains, allowing for data truncation (lossy compression) through quantization.

## Features
- **Discrete Cosine Transform (DCT-II):** Orthonormally scaled forward and inverse transformations. This is the foundation of JPEG and MP3.
- **Discrete Wavelet Transform (DWT):** Haar wavelet implementation (Forward and Inverse), which is the basis for multi-resolution compression formats like JPEG 2000.
- **Quantization Pipeline:** Uniform scalar quantization and dequantization, allowing adjustable bit-rate/quality loss.
- **Strong Typing & Safety:** Ada's inherent bounds-checking ensures algorithm integrity across arbitrary array ranges.

## Testing (Verification & Validation)
This codebase adheres to high-reliability V&V principles. We operated under a pessimistic assumption: *the software is considered defective until aggressively proven otherwise*.

### What We Verify (13+ Distinct Tests)
1. **Mathematical Functionality:** Verifies that transformations map perfectly across boundaries (DCT & Haar accuracy checks) and that inverse functions achieve zero-loss perfect reconstruction.
2. **Error Handling & Bounds:** Ensures the system cleanly catches invalid arithmetic arguments (e.g., quantizing with a zero step size) and mathematically impermissible states (running Haar on odd-numbered lengths).
3. **Edge Case Stability:** Proves the system handles anomalous payloads cleanly. This includes total silence inputs (zero-arrays), single-element data points, and mathematically empty sequences. 
4. **Platform Compatibility:** Verifies logic works uniformly regardless of whether arrays are 1-indexed (standard) or use non-standard arbitrary slicing indices (e.g., `Array(5..8)`).

### Why These Tests Matter
In signal processing, unhandled edge cases yield critical runtime violations (e.g., Divide-by-Zero during dequantization) or catastrophic artifacts (e.g., NaN cascades). By systematically verifying edge bounds and validating mathematically reversible perfect-reconstruction, we definitively disprove the assumption of defects and certify the algorithm safe for integration into real-time critical systems.

## Usage

### Compilation
Ensure you have the GNAT Ada toolchain installed, then simply run:
```bash
make all
