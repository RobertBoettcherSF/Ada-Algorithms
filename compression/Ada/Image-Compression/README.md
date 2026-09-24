# Image Compression Algorithms (Ada Implementation)

## Project Overview
This repository contains a strongly-typed, critical-systems-focused implementation of fundamental image compression algorithms in Ada. Based on architectural principles of algorithm design, this project focuses on both **lossless** (exact data reproduction) and **lossy** (human-imperceptible data loss) compression methodologies. All implementations operate over single-dimensional arrays, optimizing contiguous memory processing for images.

## Features
- **Run-Length Encoding (RLE):** Lossless compression scheme optimized for graphics with continuous fields of a single color.
- **Delta Encoding:** Lossless differential compression that stores only the numeric delta (-255 to 255) between adjacent pixels, highly optimized for gradients.
- **Color Quantization:** Lossy compression technique capable of actively reducing image bit-depth in-place by masking least-significant bits.

## Testing (Verification & Validation)
This codebase is bound by rigorous Verification and Validation (V&V) standards. Our testing methodology deliberately approaches the codebase with the assumption that the algorithms are **incorrect or non-functional**. The test suite is designed specifically to *disprove* this assumption.

### What The Tests Verify
1. **Functional Correctness:** Asserts that mathematical transformations (like Delta Encoding values) correctly match absolute calculations. Ensure roundtrips (compress -> decompress) perfectly reproduce the original byte signature.
2. **Edge Cases:** Validates response logic when algorithms are handed 0-byte (empty) images or 1-pixel images.
3. **Error Handling:** Verifies that expected, strongly-typed Exceptions (`Empty_Image_Error`, `Invalid_Data_Error`) are accurately raised and caught, preventing silent failures.
4. **Boundary and Constraint Validations:** Asserts that custom constrained types (e.g., bounds of -255 to +255 for Deltas) do not result in `Constraint_Error` overflows during maximum state swings (e.g., traversing from white directly to black).

### Why These Tests Matter
In safety-critical systems, unpredictable state mutations or silent data corruption is catastrophic. By explicitly proving correct functionality against extreme boundaries (like total loss Quantization drops), we ensure algorithm safety and reliability under abnormal execution parameters.

## Usage
The system is built without external dependencies (pure Ada). All files reside in the root path.

### Compilation
Compile the project using the provided Makefile or the GNAT Project file.
```bash
make all
