# Fractal Compression (Ada Implementation)

## Project Overview
This repository provides a strongly-typed Ada implementation of the **Fractal Compression** algorithm (based on Iterated Function Systems). The algorithm encodes images by finding self-similarities between larger "domain blocks" and smaller "range blocks", storing mathematical transformations (affine transforms, rotations, and color adjustments) rather than raw pixels. This allows for resolution-independent decompression.

## Features
- **Strong Typing**: Extensive use of Ada's strict type system (`Pixel`, `Coordinate`, `Symmetry_Type`) to prevent cross-domain variable pollution.
- **Affine Geometrics**: Full implementation of the 8 canonical fractal symmetries (Identity, 3 Rotations, 2 Flips, 2 Diagonals).
- **Least-Squares Calculations**: Automated optimal computation of `Contrast (s)` and `Brightness (o)` with strict mathematical contractivity enforcement (`|s| <= 1.0`).
- **Implemented Variants**:
  - `Square_Fixed`: The standard deterministic grid-based partitioning scheme.
  - `Quadtree`: Dynamic split variant implementation for hierarchical variance adaptation.
  - *Placeholders*: `Rectangular`, `Hexagonal`, and `Triangular` R-b-T topology variants are defined but safely raise `Unsupported_Variant` as they require complex non-square coordinate mappings outside standard 2D arrays.

## Testing (Verification & Validation)
This project enforces strict Verification & Validation (V&V) principles required for mission-critical engineering. The test suite operates on a "guilty until proven innocent" philosophy—it actively assumes the codebase is broken and utilizes **13 specific assertions** to disprove this assumption.

### What Each Test Category Verifies:
1. **Functional Correctness (Tests 1-4, 8, 11)**: Proves that geometric mappings, pixel downsampling, and sub-block tracking translate data precisely as modeled.
2. **Robustness (Tests 5, 7, 12)**: Proves that the algorithm handles identical data correctly and that contractivity modifiers (`s`, `o`) stay strictly clamped within bounds, preventing arithmetic overflow or fractal divergence upon decoding.
3. **Edge Cases (Test 6)**: Proves that Zero-Variance blocks do not crash the system via division-by-zero during least-squares generation.
4. **Error Handling (Tests 9, 10)**: Guarantees that passing mathematically impossible matrix configurations (e.g. odd-numbered layouts) fail safely via controlled exception handling (`Invalid_Image_Dimensions`), rather than segfaulting.

### Why These Tests Matter:
In reliability-critical systems, arbitrary logic failures are unacceptable. By validating mathematical clamping bounds, overflow protections, and matrix invariances, we establish cryptographic-level confidence that the implementation matches the strict technical requirements of Iterated Function Systems.

## Usage
### Compilation
To build both the main binary and the test suite, ensure GNAT is installed and run:
```bash
make all
