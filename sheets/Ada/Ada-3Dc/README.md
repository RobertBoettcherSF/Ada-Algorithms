# 3Dc (BC5/ATI2N) Texture Compression Algorithm

## Project Overview
This project implements the 3Dc texture compression algorithm natively in Ada. Originally developed by ATI, 3Dc (also known as BC5 or Block Compression 5) is a lossy data compression algorithm designed primarily for normal maps. It achieves a 2:1 compression ratio by dividing textures into 4x4 pixel blocks and packing palettes and indices efficiently.

## Features
- **3Dc+ (Single Channel / BC4)**: Standard ATI1N implementation. Compresses a 16-pixel block into 8 bytes (2 min/max endpoints, 6 bytes of 3-bit indices). Useful for heightmaps, roughness maps, or alpha channels.
- **3Dc (Dual Channel / BC5)**: Standard ATI2N implementation. Compresses two channels (X and Y) independently, resulting in 16 bytes per block.
- **Z-Channel Reconstruction**: Included math functions to automatically derive the Z-axis of a normal map under the assumption that $X^2 + Y^2 + Z^2 = 1$.
- **Strong Typing**: Implements robust type safety ensuring components cannot accidentally cross-contaminate.

## Testing
This repository uses a pessimistic V&V (Verification and Validation) approach. The test suite assumes the implementation is broken and attempts to disprove this by asserting against strict boundaries and exact numeric tolerances. 

### What the Tests Verify
- **Functional Correctness**: Validates palette interpolation, min/max extraction, and correct 48-bit index packing/unpacking (Tests 1, 2, 4, 5).
- **Error Handling & Edge Cases**: Tests extreme pixel values (all 0s, all 255s), clamped bounding for Z reconstruction (guarding against imaginary numbers due to quantization errors), and endpoint proximity constraints (Tests 8, 9, 10, 11).
- **Performance & Robustness**: Tests noise spikes and broad gradient approximation to ensure the lossy compression operates within standard acceptable visual tolerances (Tests 3, 13).

### Why these tests matter
In embedded environments or graphics pipelines, invalid normal vectors (e.g., resulting in a mathematically impossible Z component) can cause engine crashes, NaN propagation in shaders, or memory corruption. These tests guarantee mathematically sound outputs and safe memory accesses in Ada. By passing these tests, we validate that the logic conforms exactly to the strict hardware specifications of BC4/BC5.

## Usage

### Compilation
Ensure you have the GNAT Ada compiler installed. The project relies on a root-level Makefile and `.gpr` file.
```bash
make
