# Floyd-Steinberg Dithering (Ada Implementation)

## Project Overview
This repository contains a robust Ada implementation of the Floyd-Steinberg error diffusion dithering algorithm. Dithering is used in image processing to create the illusion of color depth in images with a restricted color palette (in this case, binary black and white) by pushing residual quantization errors to neighboring, unprocessed pixels. 

## Features
- **Strong Typing**: Built on robust, strict Ada type definitions for image matrices and color spaces.
- **Standard Left-to-Right Dither**: Implements the classic 7/16, 3/16, 5/16, 1/16 error distribution matrix.
- **Serpentine Dither**: Implements a bidirectional alternating row scan (left-to-right, then right-to-left) to significantly reduce the "worming" artifacts common in the standard approach. 
- **Graceful Error Handling**: Complete matrix bounds tracking and prevention of illegal neighbor memory writes.

## Testing 

This implementation adheres to stringent Verification and Validation (V&V) principles. The test suite operates under a pessimistic initial assumption: the code is treated as incorrect and boundary-violating until proven otherwise. 

### What the Tests Verify
- **Functional Correctness**: Assertions ensure that mathematical distribution yields strictly quantized palette colors (0.0 or 1.0), and that average input luminance is mathematically preserved in the resulting dot matrix (Test 1, 2, 7).
- **Error Handling**: Deliberately provokes the system with degenerate cases (e.g., empty dimensions) to guarantee proper exceptions (`Invalid_Image_Error`) are raised instead of silent segmentation faults (Test 3, 4).
- **Edge Cases & Boundaries**: Verifies handling of extreme geometrical dimensions (1x1, 1x5, 5x1) to ensure the neighborhood error distribution logic correctly handles physical boundaries without overflowing (Test 8, 9, 10). 
- **Robustness & Idempotency**: Feeds inputs massively out of bounds (negative, > 1.0) and re-processes already processed data to guarantee internal structural stability (Test 11, 12, 13).

### Why These Tests Matter
In critical systems programming, unhandled boundary conditions in nested array loops are catastrophic. By exhaustively verifying mathematical preservation and memory safety at absolute geometrical minimums, the tests provide evidence of complete algorithmic integrity. 

## Usage

### Compilation
The codebase uses a simple GNAT Project file (`.gpr`) combined with a Makefile for rapid compilation. All source files reside strictly in the root directory.

To compile:
```bash
make all
