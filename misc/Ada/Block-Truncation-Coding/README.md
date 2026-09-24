# Block Truncation Coding (BTC) in Ada

## Project Overview
This project provides a robust, strongly-typed Ada implementation of the **Block Truncation Coding (BTC)** algorithm, an early but foundational lossy image compression technique. The implementation operates on standard grayscale 4x4 blocks and securely encodes them into upper/lower quantization levels alongside a reconstruction bitmap mask.

## Features
- **Standard BTC**: Quantizes using calculations based on the dataset's population standard deviation to aggressively retain spatial edges and variance.
- **Absolute Moment BTC (AMBTC)**: A variant calculating the upper/lower bounds utilizing the first absolute central moment, reducing processing overhead and guaranteeing mean preservation.
- **Strong Typing Integration**: Utilizes Ada's `mod 256` bounds for Pixel values, avoiding unexpected overflows entirely.
- **Root-flat structure**: Clean source structure suitable for immediate standalone compilation or inclusion directly via `.gpr`. 

## Testing (V&V Philosophy)
The test suite (`tests.adb`) operates on strict Verification & Validation (V&V) principles tailored for safety-critical systems. 

**Core Assumption:** The algorithm implementation is inherently broken until formally disproved by an explicitly asserted constraint.

The tests categorically verify:
1. **Functional Correctness (Tests 1, 2, 5-7):** Validates raw mathematical accuracy against theoretical models (Standard Deviation, Outlier calculations, and Mean isolation). Ensures the logic acts predictably within symmetric thresholds.
2. **Error Handling & Edge Cases (Tests 3, 4, 12, 13):** Proves runtime resilience against highly problematic data (e.g., Uniform arrays causing Zero-Variance conditions that would normally throw explicit `Constraint_Error` via divide-by-zero, as well as Maximum Variation vectors).
3. **Information Integrity Constraints (Tests 10, 11):** Ensures mathematical laws are upheld during compression (e.g., verifying that AMBTC structurally *must* preserve the exact arithmetic mean of the source block).

These tests matter because in domains reliant on deterministic behavior, visual/data encoders must guarantee continuous operation devoid of infinite loops or unhandled exceptions under *any* input noise.

## Usage

### Compilation
The codebase utilizes a `Makefile` linked to a standard `.gpr` file. To compile:

```bash
make all
