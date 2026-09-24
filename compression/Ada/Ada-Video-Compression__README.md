# Video Compression Algorithms in Ada

## Project Overview
This repository provides an Ada implementation of the core components driving modern video compression standards (like MPEG and JPEG). This covers spatial transform coding, precision reduction, color space optimization, and entropy coding. 

## Features
The codebase implements the following critical variants and algorithmic steps discussed in video compression literature:
1. **Discrete Cosine Transform (DCT):** Both Forward and Inverse 8x8 DCT processing.
2. **Quantization:** Scaling and compression using a dynamic Quantization Matrix.
3. **Chroma Subsampling:** Intelligent spatial downsampling for Chroma components supporting `4:4:4` (no loss), `4:2:2` (half horizontal), and `4:2:0` (quarter size).
4. **Entropy Coding:** Run-Length Encoding (RLE) mechanism for optimized storage of post-quantized matrices.

## Testing
We adhere to rigorous **Verification & Validation (V&V)** principles intended for critical systems. The test suite operates on an explicitly pessimistic assumption that the code is *incorrect*. 

- **Functional Correctness:** Verifies mathematical guarantees. (e.g., Passing an image plane through DCT and immediately through Inverse DCT validates that spatial energy is preserved without irrecoverable data loss).
- **Error Handling:** Validates that fault injections (like providing a `0` inside a Quantization Matrix) result in safe, documented exception states (`Quantization_Zero_Error`) instead of unpredictable division-by-zero crashes.
- **Edge Cases:** Proves that anomalous data sizes, such as attempting 4:2:0 subsampling on an odd-numbered matrix or providing empty arrays, are rejected safely (`Invalid_Input_Error`) or processed seamlessly.
- **Performance/Storage Guarantees:** Ensures that the RLE implementation correctly identifies unified matrices and compresses them down to a single memory record, verifying the fundamental promise of the compression pipeline.

Passing these tests proves that the codebase meets both its functional requirements (Verification) and behaves dependably under hostile runtime conditions (Validation).

## Usage

### Compilation
The project requires an Ada compiler (`GNAT`). Compile using the provided Makefile:
```bash
make
