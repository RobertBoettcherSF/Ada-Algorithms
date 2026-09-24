# Wavelet Compression in Ada

## Project Overview
This project provides a robust, strongly-typed Ada implementation of the core **Wavelet Compression** algorithm. Utilizing the Haar Wavelet family, this library allows users to decompose and reconstruct 1D arrays and 2D arrays (like images) through spatial filtering. It provides the building blocks for modern image compression systems like JPEG 2000.

## Features
*   **Lossy Compression 1D & 2D (Floating-point):** Implements standard Haar continuous averaging and high-frequency extraction.
*   **Lossless Compression 1D (Integer):** Uses a reversible lifting scheme (S-transform) to perfectly compress and decompress data with zero information loss.
*   **Quantization:** Includes an adjustable thresholding filter to create signal sparsity (the active step in actual file-size compression).
*   **Modular architecture:** Safely divided out by dimension logic and precision demands using custom subtypes (`Signal_1D`, `Signal_2D`, `Signal_1D_Int`).
*   **Safety checks:** Guards against irregular dimensions via the custom `Invalid_Dimensions` exception.

## Testing 

This project operates on stringent Verification & Validation (V&V) standards used for critical systems. 

We approach testing with the initial **pessimistic assumption that the code is incorrect or broken**. Our goal is to run a barrage of adversarial tests. If a test passes, it disproves the assumption of failure, validating the system.

### What The Categories Verify
1.  **Functional Correctness (Tests 1-6):** Verifies that the Forward transform outputs mathematically correct averages/differences, and that the Inverse transform can seamlessly recreate the raw data.
2.  **Performance / Transformations (Tests 7, 13):** Validates quantization—ensuring small coefficients are correctly targeted and zeroed out based on the chosen threshold without breaking surrounding data.
3.  **Edge Cases (Tests 9, 10, 11, 12):** Validates extreme environments: Size 1 arrays, signals containing entirely constant numbers, entirely negative boundaries. Ensures integer logic won't round improperly on negative numbers.
4.  **Error Handling (Test 8):** Validates safe failures. Feeding a size-3 array must gracefully raise an `Invalid_Dimensions` constraint rather than letting a loop buffer overflow.

### Why These Tests Matter
In V&V, verification answers *"Did we build the system right?"* while validation answers *"Did we build the right system?"* By proving out exact mathematical recreation, we prove reliability. By testing error catches, we guarantee the safety of the application consuming this library. If an image buffer feeds an odd number of pixels, our code safely halts rather than corrupting memory.

## Usage

### Compilation
The project requires an Ada compiler (GNAT). You can compile using `gnatmake` directly or by utilizing the provided `Makefile`.

```bash
# Using Makefile (recommended)
make all

# Alternatively, using gnatmake directly via the GPR project file
gnatmake -P wavelet_compression.gpr
