# Ada Halftoning Engine

## Project Overview
This project implements digital Halftoning algorithms in Ada. Halftoning is the process of simulating continuous-tone imagery through the use of discrete binary dots, creating an optical illusion of a continuous grayscale. The codebase provides robust 2D grid processing handling matrix boundaries and arbitrary coordinate indexing seamlessly. 

## Features
- **Strong Typing Implementation:** Pixel_Value defined strictly as an 8-bit unsigned integer limits (mod 256).
- **Simple Thresholding:** The baseline non-preemptive operation applying a binary cut-off at `128` (or an injected threshold).
- **Ordered Dithering:** Static grid processing utilizing a normalized `4x4` Bayer Matrix designed to handle arbitrary 2D array coordinates without boundary faults.
- **Floyd-Steinberg Error Diffusion:** Dynamic algorithmic distribution pushing quantization error weights Left-to-Right and Top-to-Bottom. Safely handles signed integer math underflow and overflow conditions prior to writing binary clamps back to the primary buffer.

## Testing
We utilize strict Verification and Validation (V&V) standards assuming pessimistic functionality out of the gate. A test only **PASSES** when it completely disproves the assumption of failure. 

### What The Categories Verify
1. **Functional Correctness (TEST 1):** Verifies binary thresholds process basic math accurately on boundaries and limits (e.g. quantization parameters behaving as expected when exactly at `127` vs `128`).
2. **Spatial Mechanics & Robustness (TEST 2):** Asserts spatial coordinate indexing (`mod 4`) tracks properly over the matrix, specifically validating that arbitrary array bounds (e.g., indices `5..6, 10..11`) do not crash or throw unexpected exceptions.
3. **Error Handling & Edge Cases (TEST 3):** Simulates aggressive data limits to ensure `Constraint_Error` triggers are bypassed correctly on 1x1 matrix topologies. Also verifies the distribution pipeline propagates mathematical loads appropriately (Right, Down, Bottom-Left, Bottom-Right) while preventing `<0` and `>255` overflow faults during reconstruction.

### Why these tests matter
Mission-critical algorithm deployment demands absolute memory safety and exception-handling confidence. These specific tests prove that mathematical overflow caused by additive dithering mechanisms cannot crash the execution environment, adhering directly to standard V&V safety mandates. 

## Usage

### Compilation
Ensure you have the GNAT Ada toolchain installed, then simply utilize the provided Makefile commands from the root directory:
```bash
make all
