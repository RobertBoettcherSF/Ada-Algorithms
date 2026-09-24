# FELICS Image Compression in Ada

## Project Overview
This project implements the **Fast Efficient Lossless Image Compression System (FELICS)** algorithm in Ada, based on the foundational work by Paul G. Howard and Jeffrey S. Vitter. FELICS is a high-speed lossless image compression codec designed for continuous-tone grayscale images, performing efficient decorrelation via neighboring pixel contexts ($\Delta = H - L$) and range-based symbol coding.

## Features
- **Strong Typing**: Custom Ada types (`Pixel_Value`, `Pixel_Matrix`, `Context_Record`, `Encoded_Symbol`) ensuring data integrity.
- **Context Decorrelation**: Computes nearest neighbor causal contexts ($P_1$ left, $P_2$ above) with robust boundary handling.
- **Range Classification**: Classifies pixels into `Inside_Range`, `Below_Range`, and `Above_Range` categories.
- **Lossless Round-Trip**: Full compression and decompression pipeline guaranteeing bit-exact fidelity with original image matrices.
- **Modular Design**: Separated specification (`felics.ads`), implementation (`felics.adb`), main executable demonstration (`main.adb`), and test suite (`tests.adb`).

## Testing
The test suite (`tests.adb`) is designed under strict Verification and Validation (V&V) principles, operating under the initial pessimistic assumption that the codebase contains latent defects. Each test asserts precise functional and boundary conditions to disprove this assumption.

### Test Categories Verified
1. **Functional Correctness**: Verifies context calculation ($\Delta, L, H$), pixel encoding/decoding across inside, below, and above ranges.
2. **Edge Cases**: Validates extreme pixel boundaries (zero value `0` and maximum value `255`), uniform image matrices, and top-left corner default fallback neighborhoods.
3. **Error Handling & Robustness**: Ensures proper exception raising (`Invalid_Image_Dimensions`) when stream sizes or matrix dimensions mismatch.

### Why These Tests Matter
Ensuring mathematical and logical correctness in compression codecs is vital for safety-critical and deep-space deployments (such as HiRISE on the Mars Reconnaissance Orbiter). V&V principles guarantee that implementation adheres strictly to algorithmic specifications without data corruption or silent truncation.

## Usage

### Compilation
To compile both the main program and the test suite using `gnatmake` and the GNAT project file via Makefile:
```bash
make
