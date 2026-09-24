# SPIHT Image Compression Algorithm in Ada

## Project Overview
This project implements the **Set Partitioning in Hierarchical Trees (SPIHT)** algorithm in Ada. Originally developed for encoding wavelet coefficients in image compression, SPIHT organizes wavelet trees into lists to efficiently output the most significant bits of the image first. This implementation covers the core coding loop using List of Insignificant Pixels (LIP), List of Significant Pixels (LSP), and List of Insignificant Sets (LIS).

## Features
- **Strong Typing**: Ada strictly segregates types (`Coefficient`, `Coordinate_2D`, `Coordinate_3D`) to avoid implicit casting errors and memory bugs.
- **Multiple Variants Supported**:
  - **2D SPIHT**: Standard variant for planar image data.
  - **3D SPIHT Extension**: Architectural support for volumetric data (e.g., video compression, medical imaging) as identified in standard SPIHT literature.
  - **Lossless Encoding Mode**: Processes entirely until all thresholds are covered.
  - **Lossy Rate-Constrained Mode**: Preemptively stops processing at an exact target bit-length to satisfy strict bandwidth limitations.

## Testing
This codebase is governed by rigorous Verification and Validation (V&V) standards tailored for high-reliability systems. The provided test suite operates on a **pessimistic assumption model**: it inherently assumes the implementation is broken, and a test only passes if it can empirically disprove that assumption. 

The test suite covers:
- **Functional Correctness**: Verifies the core math (Magnitude calculations, power-of-two constraints, and SPIHT tree list evaluation). *Why it matters: Guarantees Verification (the system was built right according to the SPIHT spec).*
- **Error Handling**: Inputs like empty matrices or invalid matrix dimensions (not a power of 2) immediately test exception boundaries. *Why it matters: Proves system stability preventing segmentation faults or infinite loops in production code.*
- **Edge Cases**: 1x1 matrices, zero-value matrices, and target rates equal to 0. *Why it matters: Ensures edge conditions do not cause catastrophic boundary failures or out-of-bounds index errors.*
- **Performance Constraints**: Ensures that target bandwidths in Rate-Constrained modes truncate at the exact specified bit length without overflowing into memory. *Why it matters: Validation (building the right system) for strict bandwidth scenarios.*

## Usage

### Compilation
Ensure you have the GNAT Ada compiler installed, along with `make`. To compile the suite and binaries:
```bash
make
